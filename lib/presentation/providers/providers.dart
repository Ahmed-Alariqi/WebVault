import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/clipboard_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/page_model.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/clipboard_item_model.dart';

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

  Future<void> setScreenshotPrevention(bool enabled) async {
    await _repo.setScreenshotPrevention(enabled);
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

  Future<void> setSecureMode(bool enabled) async {
    await _repo.setSecureModeEnabled(enabled);
    _loadSettings();
  }

  Future<void> setFirstLaunch(bool value) async {
    await _repo.setFirstLaunch(value);
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

  PagesNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> addPage(PageModel page) async {
    await _repo.save(page);
    refresh();
  }

  Future<void> updatePage(PageModel page) async {
    await _repo.save(page);
    refresh();
  }

  Future<void> deletePage(String id) async {
    await _repo.delete(id);
    refresh();
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

final clipboardItemsProvider =
    StateNotifierProvider<ClipboardNotifier, List<ClipboardItemModel>>((ref) {
      final repo = ref.read(clipboardRepositoryProvider);
      return ClipboardNotifier(repo);
    });

class ClipboardNotifier extends StateNotifier<List<ClipboardItemModel>> {
  final ClipboardRepository _repo;

  ClipboardNotifier(this._repo) : super([]) {
    refresh();
  }

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> addItem(ClipboardItemModel item) async {
    await _repo.save(item);
    refresh();
  }

  Future<void> updateItem(ClipboardItemModel item) async {
    await _repo.save(item);
    refresh();
  }

  Future<void> deleteItem(String id) async {
    await _repo.delete(id);
    refresh();
  }

  Future<void> togglePin(String id) async {
    final item = _repo.getById(id);
    if (item != null) {
      await _repo.save(item.copyWith(isPinned: !item.isPinned));
      refresh();
    }
  }

  Future<void> reorder(List<ClipboardItemModel> items) async {
    await _repo.reorder(items);
    refresh();
  }

  Future<void> cleanExpired() async {
    await _repo.cleanExpired();
    refresh();
  }
}

// ============================================================
// Dashboard stats provider
// ============================================================

final dashboardStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final pages = ref.watch(pagesProvider);
  final pageRepo = ref.read(pageRepositoryProvider);

  return {
    'totalPages': pages.length,
    'favoritesCount': pages.where((p) => p.isFavorite).length,
    'mostVisited': pageRepo.getMostVisited(),
    'recentPages': pageRepo.getRecent(limit: 5),
  };
});
