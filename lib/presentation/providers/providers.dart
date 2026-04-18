import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../../core/supabase_config.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/clipboard_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/page_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/clipboard_item_model.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/backup_service.dart';
import '../../core/services/analytics_service.dart';

// ============================================================
// Repository providers
// ============================================================

final pageRepositoryProvider = Provider<PageRepository>((ref) {
  return PageRepository();
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository();
});

final clipboardRepositoryProvider = Provider<ClipboardRepository>((ref) {
  return ClipboardRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final pageRepo = ref.read(pageRepositoryProvider);
  final folderRepo = ref.read(folderRepositoryProvider);
  final clipboardRepo = ref.read(clipboardRepositoryProvider);
  return BackupService(pageRepo, folderRepo, clipboardRepo);
});

// ============================================================
// App lock state
// ============================================================

final appLockedProvider = StateProvider<bool>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return settings.isPinEnabled();
});

// ============================================================
// Settings provider
// ============================================================

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
      final repo = ref.read(settingsRepositoryProvider);
      return SettingsNotifier(repo);
    });

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super({}) {
    _loadSettings();
  }

  void _loadSettings() {
    state = _repo.getAllSettings();
  }

  Future<void> setPin(String pin) async {
    await _repo.setPin(pin);
    await _repo.setPinEnabled(true);
    _loadSettings();
  }

  Future<void> removePin() async {
    await _repo.removePin();
    await _repo.setPinEnabled(false);
    _loadSettings();
  }

  bool verifyPin(String pin) {
    return _repo.getPin() == pin;
  }

  String? getStoredPin() => _repo.getPin();

  Future<void> setBiometric(bool enabled) async {
    await _repo.setBiometricEnabled(enabled);
    _loadSettings();
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    await _repo.setAutoLockTimeout(seconds);
    _loadSettings();
  }

  Future<void> setThemeMode(String mode) async {
    await _repo.setThemeMode(mode);
    _loadSettings();
  }

  Future<void> setAutoDeleteDays(int days) async {
    await _repo.setAutoDeleteDays(days);
    _loadSettings();
  }

  Future<void> setFirstLaunch(bool value) async {
    await _repo.setFirstLaunch(value);
    _loadSettings();
  }

  Future<void> setAdvancedCopyEnabled(bool enabled) async {
    await _repo.setAdvancedCopyEnabled(enabled);
    _loadSettings();
  }

  Future<void> setLocale(String locale) async {
    await _repo.setLocale(locale);
    _loadSettings();
  }
}

// ============================================================
// Theme provider
// ============================================================

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings['themeMode'] as String? ?? 'system') {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

// ============================================================
// Pages providers
// ============================================================

final pagesProvider = StateNotifierProvider<PagesNotifier, List<PageModel>>((
  ref,
) {
  final repo = ref.read(pageRepositoryProvider);
  return PagesNotifier(repo);
});

class PagesNotifier extends StateNotifier<List<PageModel>> {
  final PageRepository _repo;
  PageModel? _lastDeletedPage;

  PagesNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> addPage(PageModel page) async {
    await _repo.save(page);
    refresh();
    // Track for referral activity verification
    AnalyticsService.trackPageAdd();
  }

  Future<void> updatePage(PageModel page) async {
    await _repo.save(page);
    refresh();
  }

  Future<void> deletePage(String id) async {
    final page = _repo.getById(id);
    if (page != null) {
      _lastDeletedPage = page;
    }
    await _repo.delete(id);
    refresh();
  }

  void restoreLastPage() {
    if (_lastDeletedPage != null) {
      _repo.save(_lastDeletedPage!);
      refresh();
      _lastDeletedPage = null;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final page = _repo.getById(id);
    if (page != null) {
      await _repo.save(page.copyWith(isFavorite: !page.isFavorite));
      refresh();
    }
  }

  Future<void> incrementVisit(String id) async {
    await _repo.incrementVisit(id);
    refresh();
  }

  Future<void> removeFromFolder(String id) async {
    final page = _repo.getById(id);
    if (page != null) {
      // We cannot use copyWith because it ignores nulls
      final updated = PageModel(
        id: page.id,
        url: page.url,
        title: page.title,
        notes: page.notes,
        tags: page.tags,
        folderId: null, // Clear folder
        isFavorite: page.isFavorite,
        visitCount: page.visitCount,
        lastOpened: page.lastOpened,
        createdAt: page.createdAt,
        scrollPosition: page.scrollPosition,
      );
      await _repo.save(updated);
      refresh();
    }
  }

  Future<void> addToFolder(String pageId, String folderId) async {
    final page = _repo.getById(pageId);
    if (page != null) {
      final updated = page.copyWith(folderId: folderId);
      await _repo.save(updated);
      refresh();
    }
  }
}

final pageSearchProvider = StateProvider<String>((ref) => '');

final filteredPagesProvider = Provider<List<PageModel>>((ref) {
  final pages = ref.watch(pagesProvider);
  final search = ref.watch(pageSearchProvider);
  if (search.isEmpty) return pages;
  final q = search.toLowerCase();
  return pages.where((p) {
    return p.title.toLowerCase().contains(q) ||
        p.url.toLowerCase().contains(q) ||
        p.tags.any((t) => t.toLowerCase().contains(q));
  }).toList();
});

// ============================================================
// Folders provider
// ============================================================

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, List<FolderModel>>((ref) {
      final repo = ref.read(folderRepositoryProvider);
      return FoldersNotifier(repo);
    });

class FoldersNotifier extends StateNotifier<List<FolderModel>> {
  final FolderRepository _repo;

  FoldersNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> addFolder(FolderModel folder) async {
    await _repo.save(folder);
    refresh();
  }

  Future<void> updateFolder(FolderModel folder) async {
    await _repo.save(folder);
    refresh();
  }

  Future<void> deleteFolder(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

// ============================================================
// Clipboard provider
// ============================================================

final clipboardVisibilityProvider = StateProvider<bool>((ref) => false);

final clipboardItemsProvider =
    StateNotifierProvider<ClipboardNotifier, List<ClipboardItemModel>>((ref) {
      final repo = ref.read(clipboardRepositoryProvider);
      return ClipboardNotifier(repo, ref);
    });

class ClipboardNotifier extends StateNotifier<List<ClipboardItemModel>> {
  final ClipboardRepository _repo;
  final Ref _ref; // Passed internally to check settings provider dynamically
  Timer? _pollingTimer;
  String _lastPolledText = '';
  ClipboardItemModel? _lastDeletedItem;

  ClipboardNotifier(this._repo, this._ref) : super([]) {
    refresh();
    _startPollingListener();
  }

  void _startPollingListener() {
    // 2 Second Timer interval
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      // Step 1: Query global setting
      final Map<String, dynamic> currentSettings;
      try {
        currentSettings = _ref.read(settingsProvider);
      } catch (e) {
        return; // Guard if disposed
      }

      final isAdvanced =
          currentSettings['isAdvancedCopyEnabled'] as bool? ?? false;

      // Step 2: Skip polling if explicitly disabled or app locked
      if (!isAdvanced) return;

      try {
        final lockState = _ref.read(appLockedProvider);
        if (lockState) return;
      } catch (e) {
        return; // If locked out, prevent polling
      }

      // Step 3: Extract from native system clipboard
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final textData = clipboardData?.text;

      if (textData != null && textData.trim().isNotEmpty) {
        // Did the payload change from what we already tracked?
        if (textData != _lastPolledText) {
          _lastPolledText = textData;

          // Check if this explicit text entry already exists to avoid redundant UI loops
          final existingMatch = state
              .where((item) => item.value == textData)
              .toList();

          if (existingMatch.isEmpty) {
            // 100% brand new background clipboard capture! Insert silently.
            final newItem = ClipboardItemModel(
              id: const Uuid().v4(),
              label: 'Smart Capture',
              value: textData,
              createdAt: DateTime.now(),
              isPinned: false,
            );
            await addItem(newItem);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void refresh() {
    state = _repo.getAllItems();
  }

  Future<void> addItem(ClipboardItemModel item) async {
    await _repo.saveItem(item);
    refresh();
    // Track for referral activity verification
    AnalyticsService.trackClipboardAdd();
  }

  Future<void> updateItem(ClipboardItemModel item) async {
    await _repo.saveItem(item);
    refresh();
  }

  Future<void> deleteItem(String id) async {
    final item = _repo.getItemById(id);
    if (item != null) {
      _lastDeletedItem = item;
    }
    await _repo.deleteItem(id);
    refresh();
  }

  void restoreLastItem() {
    if (_lastDeletedItem != null) {
      _repo.saveItem(_lastDeletedItem!);
      refresh();
      _lastDeletedItem = null;
    }
  }

  Future<void> togglePin(String id) async {
    final item = _repo.getItemById(id);
    if (item != null) {
      await _repo.saveItem(item.copyWith(isPinned: !item.isPinned));
      refresh();
    }
  }

  Future<void> reorder(List<ClipboardItemModel> items) async {
    await _repo.reorderItems(items);
    refresh();
  }

  Future<void> cleanExpired() async {
    await _repo.cleanExpired();
    refresh();
  }

  Future<void> moveItemToGroup(String itemId, String? groupId) async {
    final item = _repo.getItemById(itemId);
    if (item != null) {
      final updated = groupId == null
          ? item.copyWith(clearGroupId: true)
          : item.copyWith(groupId: groupId);
      await _repo.saveItem(updated);
      refresh();
    }
  }

  Future<void> moveItemsToGroup(List<String> itemIds, String? groupId) async {
    for (final id in itemIds) {
      final item = _repo.getItemById(id);
      if (item != null) {
        final updated = groupId == null
            ? item.copyWith(clearGroupId: true)
            : item.copyWith(groupId: groupId);
        await _repo.saveItem(updated);
      }
    }
    refresh();
  }
}

// ============================================================
// Clipboard Groups provider
// ============================================================

final clipboardGroupsProvider =
    StateNotifierProvider<ClipboardGroupsNotifier, List<ClipboardGroupModel>>((
      ref,
    ) {
      final repo = ref.read(clipboardRepositoryProvider);
      return ClipboardGroupsNotifier(repo);
    });

final selectedClipboardGroupProvider = StateProvider<String?>((ref) => null);

class ClipboardGroupsNotifier extends StateNotifier<List<ClipboardGroupModel>> {
  final ClipboardRepository _repo;

  ClipboardGroupsNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAllGroups();
  }

  Future<void> addGroup(ClipboardGroupModel group) async {
    await _repo.saveGroup(group);
    refresh();
  }

  Future<void> updateGroup(ClipboardGroupModel group) async {
    await _repo.saveGroup(group);
    refresh();
  }

  Future<void> deleteGroup(String id) async {
    await _repo.deleteGroup(id);
    refresh();
  }

  Future<void> reorder(List<ClipboardGroupModel> groups) async {
    await _repo.reorderGroups(groups);
    refresh();
  }
}

// ============================================================
// Dashboard stats provider
// ============================================================

final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final pages = ref.watch(pagesProvider);
  final folders = ref.watch(foldersProvider);
  final clipboardItems = ref.watch(clipboardItemsProvider);
  final pageRepo = ref.read(pageRepositoryProvider);

  return {
    'totalPages': pages.length,
    'favoritesCount': pages.where((p) => p.isFavorite).length,
    'foldersCount': folders.length,
    'clipboardCount': clipboardItems.length,
    'mostVisited': pageRepo.getMostVisited(),
    'recentPages': pageRepo.getRecent(limit: 5),
  };
});

// ============================================================
// Locale provider
// ============================================================

final localeProvider = Provider<Locale>((ref) {
  final settings = ref.watch(settingsProvider);
  return Locale(settings['locale'] as String? ?? 'ar');
});

// ============================================================
// Notification provider
// ============================================================

/// Tracks the last time the user opened the notifications screen.
/// Notifications created after this timestamp are considered "unread".
final lastSeenNotificationProvider = StateProvider<DateTime>((ref) {
  final box = Hive.box(kSettingsBox);
  final stored = box.get('lastSeenNotification') as String?;
  if (stored != null) {
    return DateTime.parse(stored);
  }
  // Default to a completely old date so all notifications show as unread if never opened
  return DateTime.fromMillisecondsSinceEpoch(0);
});

/// Counts unread notifications from Supabase (created after lastSeen timestamp).
final notificationCountProvider = FutureProvider<int>((ref) async {
  final lastSeen = ref.watch(lastSeenNotificationProvider);
  try {
    final response = await SupabaseConfig.client
        .from('notifications')
        .select('id')
        .gt('created_at', lastSeen.toIso8601String());
    return (response as List).length;
  } catch (_) {
    return 0;
  }
});

/// Marks all notifications as read by updating the lastSeen timestamp.
Future<void> markNotificationsRead(WidgetRef ref) async {
  final now = DateTime.now().toUtc();
  final box = Hive.box(kSettingsBox);
  await box.put('lastSeenNotification', now.toIso8601String());
  ref.read(lastSeenNotificationProvider.notifier).state = now;
  ref.invalidate(notificationCountProvider);
}
