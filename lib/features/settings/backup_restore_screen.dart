import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.backupSuccessful : l10n.backupFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final success = await ref.read(backupServiceProvider).importData();

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Refresh all data
        ref.invalidate(pagesProvider);
        ref.invalidate(foldersProvider);
        ref.invalidate(clipboardItemsProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.importSuccessful : l10n.importFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
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
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.importSuccessful : l10n.importFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final settings = ref.watch(settingsProvider);
    final autoBackupEnabled = settings['autoBackupEnabled'] as bool? ?? false;
    final autoBackupFreq = settings['autoBackupFrequency'] as String? ?? 'weekly';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupAndRestore),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Auto Backup Section ─────────────────────────────────────────
              _buildSectionTitle(l10n.autoBackup),
              Container(
                decoration: _cardDecoration(isDark),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l10n.autoBackup),
                      subtitle: Text(l10n.autoBackupDesc),
                      value: autoBackupEnabled,
                      activeTrackColor: AppTheme.primaryLight,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).setAutoBackupEnabled(val);
                      },
                    ),
                    if (autoBackupEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: Text(l10n.backupFrequency),
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

              // ── Available Auto Backups ──────────────────────────────────────
              if (autoBackupEnabled) ...[
                _buildSectionTitle(l10n.availableBackups),
                if (_autoBackups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.noAutoBackupsYet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                    ),
                  )
                else
                  Container(
                    decoration: _cardDecoration(isDark),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _autoBackups.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _autoBackups[index];
                        final date = file.lastModifiedSync();
                        final dateStr = DateFormat.yMMMd().add_jm().format(date);
                        final sizeStr = '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB';
                        
                        return ListTile(
                          leading: const Icon(Icons.restore_page_outlined, color: AppTheme.primaryLight),
                          title: Text(dateStr),
                          subtitle: Text(sizeStr),
                          trailing: TextButton(
                            onPressed: () => _handleRestoreLocal(file),
                            child: Text(l10n.openButton), // "Open" or "Restore"
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // ── Manual Backup Section ───────────────────────────────────────
              _buildSectionTitle(l10n.manualBackup),
              Container(
                decoration: _cardDecoration(isDark),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: Text(l10n.exportBackup),
                      subtitle: Text(l10n.saveAllDataAsJson),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _handleExport,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: Text(l10n.importBackup),
                      subtitle: Text(l10n.restoreFromJson),
                      trailing: const Icon(Icons.chevron_right),
                      iconColor: AppTheme.errorColor,
                      textColor: AppTheme.errorColor,
                      onTap: _handleImport,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
