import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../presentation/widgets/responsive_layout.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;
  List<File> _autoBackups = [];

  @override
  void initState() {
    super.initState();
    _loadAutoBackups();
  }

  Future<void> _loadAutoBackups() async {
    final backupService = ref.read(backupServiceProvider);
    final backups = await backupService.getAutoBackups();
    if (mounted) {
      setState(() {
        _autoBackups = backups;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(backupServiceProvider).exportData();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        AdminUIUtils.showSuccess(context, l10n.backupSuccessful);
      } else {
        AdminUIUtils.showError(context, l10n.backupFailed);
      }
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(backupServiceProvider).importData();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(pagesProvider);
        ref.invalidate(foldersProvider);
        ref.invalidate(clipboardItemsProvider);
        ref.invalidate(clipboardGroupsProvider);
        AdminUIUtils.showSuccess(context, l10n.importSuccessful);
      } else {
        AdminUIUtils.showError(context, l10n.importFailed);
      }
    }
  }

  Future<void> _handleRestoreLocal(File file) async {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat.yMMMd().format(file.lastModifiedSync());
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreThisBackup),
        content: Text(l10n.restoreConfirmMessage(dateStr)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.restoreThisBackup),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await ref.read(backupServiceProvider).importFromLocalBackup(file);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(pagesProvider);
        ref.invalidate(foldersProvider);
        ref.invalidate(clipboardItemsProvider);
        ref.invalidate(clipboardGroupsProvider);
        AdminUIUtils.showSuccess(context, l10n.importSuccessful);
      } else {
        AdminUIUtils.showError(context, l10n.importFailed);
      }
    }
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppTheme.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : AppTheme.primaryColor.withValues(alpha: 0.15), // Stronger border
        width: isDark ? 1 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final autoBackupEnabled = settings['autoBackupEnabled'] as bool? ?? false;
    final autoBackupFreq = settings['autoBackupFrequency'] as String? ?? 'weekly';
    final cloudSyncEnabled = settings[kCloudSyncEnabled] as bool? ?? true;

    return ResponsiveLayout(
      maxWidth: 520,
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          l10n.backupAndRestore,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: isDark ? Colors.white70 : AppTheme.primaryColor),
            onPressed: () => AdminUIUtils.showStoragePolicy(context, isDark),
            tooltip: 'آلية تخزين البيانات',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: isDark ? AppTheme.primaryLight.withValues(alpha: 0.2) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isDark 
                            ? null 
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                        border: isDark 
                            ? Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)) 
                            : null,
                      ),
                      labelColor: isDark ? Colors.white : AppTheme.primaryColor,
                      unselectedLabelColor: isDark ? Colors.white30 : Colors.black38,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_queue_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.cloudSync),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.storage_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(l10n.localBackup),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildCloudSyncTab(l10n, isDark, cloudSyncEnabled),
                      _buildLocalBackupTab(l10n, isDark, autoBackupEnabled, autoBackupFreq),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ).animate().fadeIn(),
        ],
      ),
    ),
  );
}

  Widget _buildCloudSyncTab(AppLocalizations l10n, bool isDark, bool cloudSyncEnabled) {
    final pages = ref.watch(pagesProvider);
    final clipboardItems = ref.watch(clipboardItemsProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final lastSync = settingsRepo.getLastSyncTime();
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        _buildSectionTitle(l10n.cloudSync),
        Container(
          decoration: _cardDecoration(isDark),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  l10n.cloudSync,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  l10n.cloudSyncDesc,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
                trailing: Switch.adaptive(
                  value: cloudSyncEnabled,
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return isDark ? Colors.grey.shade400 : Colors.grey.shade100;
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
                  }),
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setCloudSyncEnabled(val);
                  },
                ),
              ),
              if (cloudSyncEnabled && lastSync != null) ...[
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: AppTheme.primaryLight),
                      const SizedBox(width: 10),
                      Text(
                        '${l10n.lastSyncTime}: ${_formatSyncTime(lastSync)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (cloudSyncEnabled) ...[
          _buildSectionTitle(l10n.cloudStorageUsage),
          Container(
            decoration: _cardDecoration(isDark),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUsageRow(l10n.pages, pages.where((p) => p.syncEnabled).length, kMaxSyncPages, isDark),
                const SizedBox(height: 20),
                _buildUsageRow(l10n.clipboard, clipboardItems.where((c) => c.syncEnabled).length, kMaxSyncClipboardItems, isDark),
                const SizedBox(height: 20),
                _buildUsageRow(l10n.folders, ref.watch(foldersProvider).where((f) => f.syncEnabled).length, kMaxSyncFolders, isDark),
                const SizedBox(height: 20),
                _buildUsageRow(l10n.clipboardGroups, ref.watch(clipboardGroupsProvider).where((g) => g.syncEnabled).length, kMaxSyncClipboardGroups, isDark),
                const SizedBox(height: 28),
                
                if (pages.where((p) => p.syncEnabled).length >= kMaxSyncPages ||
                    clipboardItems.where((c) => c.syncEnabled).length >= kMaxSyncClipboardItems ||
                    ref.watch(foldersProvider).where((f) => f.syncEnabled).length >= kMaxSyncFolders ||
                    ref.watch(clipboardGroupsProvider).where((g) => g.syncEnabled).length >= kMaxSyncClipboardGroups)
                  _buildWarningCard(isDark, 'لقد بلغت حد المزامنة لبعض العناصر. البيانات الجديدة سيتم حفظها محلياً فقط. يرجى عمل نسخة احتياطية يدوية من تبويب "النسخ الاحتياطي المحلي" لتجنب فقدان البيانات.'),
                
                _buildInfoCard(isDark, 'نظام التخزين: يتم حفظ جميع بياناتك محلياً على جهازك بدون حدود لضمان الخصوصية. المزامنة السحابية هي ميزة إضافية لحفظ بياناتك في السحابة بين الأجهزة. العناصر التي تتجاوز الحدود المسموحة أو الطول الأقصى (20,000 حرف) تبقى مخزنة محلياً فقط.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await ref.read(syncEngineProvider).drainQueue();
                      if (mounted) setState(() => _isLoading = false);
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(l10n.syncNow),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      final count = await ref.read(syncEngineProvider).pullAllFromCloud();
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ref.invalidate(pagesProvider);
                        ref.invalidate(foldersProvider);
                        ref.invalidate(clipboardItemsProvider);
                        ref.invalidate(clipboardGroupsProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.restoreSuccess} ($count)'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.cloud_download_rounded, size: 18, color: isDark ? Colors.white70 : AppTheme.primaryColor),
                    label: Text(
                      l10n.restoreFromCloud,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : AppTheme.primaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ]
      ],
    );
  }

  Widget _buildLocalBackupTab(AppLocalizations l10n, bool isDark, bool autoBackupEnabled, String autoBackupFreq) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        _buildSectionTitle(l10n.autoBackup),
        Container(
          decoration: _cardDecoration(isDark),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(l10n.autoBackup, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.autoBackupDesc, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                trailing: Switch.adaptive(
                  value: autoBackupEnabled,
                  thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return isDark ? Colors.grey.shade400 : Colors.grey.shade100;
                  }),
                  trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryColor;
                    }
                    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
                  }),
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setAutoBackupEnabled(val);
                  },
                ),
              ),
              if (autoBackupEnabled) ...[
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(l10n.backupFrequency, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: DropdownButton<String>(
                    value: autoBackupFreq,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'daily', child: Text(l10n.daily)),
                      DropdownMenuItem(value: 'weekly', child: Text(l10n.weekly)),
                      DropdownMenuItem(value: 'monthly', child: Text(l10n.monthly)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).setAutoBackupFrequency(val);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(l10n.manualBackup),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                l10n.exportBackup, 
                Icons.upload_rounded, 
                isDark ? AppTheme.primaryLight : AppTheme.primaryColor, 
                _handleExport, 
                isDark
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                l10n.importBackup, 
                Icons.download_rounded, 
                AppTheme.accentColor, 
                _handleImport, 
                isDark
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_autoBackups.isNotEmpty) ...[
          _buildSectionTitle(l10n.availableBackups),
          ..._autoBackups.map((file) => _buildBackupItem(file, isDark, l10n)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed, bool isDark) {
    return Container(
      height: 100,
      decoration: _cardDecoration(isDark),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(File file, bool isDark, AppLocalizations l10n) {
    final date = file.lastModifiedSync();
    final size = file.lengthSync();
    final sizeStr = '${(size / 1024).toStringAsFixed(1)} KB';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(isDark),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.insert_drive_file_rounded, color: isDark ? Colors.white54 : Colors.black45),
        ),
        title: Text(
          DateFormat.yMMMd().add_jm().format(date),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          sizeStr,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
        ),
        trailing: IconButton(
          icon: Icon(Icons.settings_backup_restore_rounded, color: AppTheme.primaryLight),
          onPressed: () => _handleRestoreLocal(file),
        ),
      ),
    );
  }

  Widget _buildWarningCard(bool isDark, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.red[200] : AppTheme.errorColor,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, String message) {
    final themeColor = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: themeColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUsageRow(String title, int current, int max, bool isDark) {
    final double percentage = (current / max).clamp(0.0, 1.0);
    final isWarning = percentage >= 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isWarning ? AppTheme.errorColor.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$current / $max', 
                style: TextStyle(
                  fontSize: 12,
                  color: isWarning ? AppTheme.errorColor : (isDark ? Colors.white70 : Colors.black54),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(isWarning ? AppTheme.errorColor : AppTheme.primaryColor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  String _formatSyncTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
