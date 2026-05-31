import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../presentation/widgets/responsive_layout.dart';
import '../../core/utils/admin_ui_utils.dart';
import '../../presentation/providers/providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';

class CloudRestoreScreen extends ConsumerStatefulWidget {
  const CloudRestoreScreen({super.key});

  @override
  ConsumerState<CloudRestoreScreen> createState() => _CloudRestoreScreenState();
}

class _CloudRestoreScreenState extends ConsumerState<CloudRestoreScreen> {
  Map<String, int> _counts = {};
  bool _isLoading = true;
  bool _isRestoring = false;


  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final syncEngine = ref.read(syncEngineProvider);
    final counts = await syncEngine.getCloudItemCounts();
    if (mounted) {
      final total = (counts['pages'] ?? 0) +
          (counts['folders'] ?? 0) +
          (counts['clipboard'] ?? 0) +
          (counts['groups'] ?? 0);

      if (total == 0) {
        final settingsRepo = SettingsRepository();
        await settingsRepo.setHasRestoredFromCloud(true);
        if (mounted) {
          context.go('/dashboard');
        }
        return;
      }

      setState(() {
        _counts = counts;
        _isLoading = false;
      });
    }
  }

  int get _totalItems =>
      (_counts['pages'] ?? 0) +
      (_counts['folders'] ?? 0) +
      (_counts['clipboard'] ?? 0) +
      (_counts['groups'] ?? 0);

  Future<void> _restore() async {
    setState(() => _isRestoring = true);

    final syncEngine = ref.read(syncEngineProvider);
    final restored = await syncEngine.pullAllFromCloud();

    if (mounted) {
      setState(() {
        _isRestoring = false;
      });

      // Mark as restored so we don't show this screen again
      final settingsRepo = SettingsRepository();
      await settingsRepo.setHasRestoredFromCloud(true);

      // Refresh all providers
      ref.invalidate(pagesProvider);
      ref.invalidate(foldersProvider);
      ref.invalidate(clipboardItemsProvider);
      ref.invalidate(clipboardGroupsProvider);

      if (mounted) {
        AdminUIUtils.showSuccess(context, 'تم استعادة $restored عنصر بنجاح!');
        // Small delay so user sees the success, then navigate
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/dashboard');
      }
    }
  }

  void _skip() {
    final settingsRepo = SettingsRepository();
    settingsRepo.setHasRestoredFromCloud(true);
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return ResponsiveLayout(
      maxWidth: 520,
      child: Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          // ── Decorative Background ──
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryLight.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.5, 0.5)),

          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 3),
                        const SizedBox(height: 20),
                        Text(
                          'جاري التحقق من السحابة...',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              // ── Icon Section (More Compact) ──
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryLight.withValues(alpha: 0.15),
                                        AppTheme.primaryLight.withValues(alpha: 0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                    border: Border.all(
                                      color: AppTheme.primaryLight.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_queue_rounded,
                                        size: 54,
                                        color: AppTheme.primaryLight.withValues(alpha: 0.3),
                                      ),
                                      Icon(
                                        Icons.cloud_download_rounded,
                                        size: 40,
                                        color: AppTheme.primaryLight,
                                      ),
                                    ],
                                  ),
                                )
                                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                    .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut),
                              ),

                              const SizedBox(height: 32),

                              // ── Text Section ──
                              Text(
                                l10n.cloudRestoreTitle,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                  letterSpacing: -0.8,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn().slideY(begin: 0.2),

                              const SizedBox(height: 12),

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  l10n.cloudRestoreSubtitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ).animate().fadeIn(delay: 200.ms),

                              const SizedBox(height: 32),

                              // ── Data Content ──
                              if (_totalItems > 0)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.white.withValues(alpha: 0.05) 
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: isDark 
                                          ? Colors.white.withValues(alpha: 0.1) 
                                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ملخص البيانات المتاحة'.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Column(
                                        children: [
                                          if ((_counts['pages'] ?? 0) > 0)
                                            _buildCountRow(Icons.web_rounded, l10n.pages, _counts['pages']!, isDark),
                                          if ((_counts['folders'] ?? 0) > 0)
                                            _buildCountRow(Icons.folder_copy_rounded, l10n.folders, _counts['folders']!, isDark),
                                          if ((_counts['clipboard'] ?? 0) > 0)
                                            _buildCountRow(Icons.copy_rounded, l10n.clipboard, _counts['clipboard']!, isDark),
                                          if ((_counts['groups'] ?? 0) > 0)
                                            _buildCountRow(Icons.folder_shared_rounded, l10n.clipboardGroups, _counts['groups']!, isDark),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95))
                              else if (_totalItems == 0)
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.noCloudData,
                                        style: TextStyle(
                                          color: isDark ? Colors.white54 : Colors.black54,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 400.ms),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      // ── Fixed Bottom Actions ──
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_totalItems > 0 && !_isRestoring)
                              Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _restore,
                                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                      label: Text(l10n.restoreMyData),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
                                  
                                  const SizedBox(height: 12),
                                  
                                  TextButton(
                                    onPressed: _skip,
                                    child: Text(
                                      l10n.skipStartFresh,
                                      style: TextStyle(
                                        color: isDark ? Colors.white30 : Colors.black38,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 800.ms),
                                ],
                              ),

                            if (_isRestoring)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      l10n.restoringData,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (_totalItems == 0 && !_isRestoring)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _skip,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                    foregroundColor: isDark ? Colors.white : AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    l10n.skipStartFresh,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 600.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCountRow(IconData icon, String label, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
