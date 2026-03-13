import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/advertisement.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/widgets/modern_fab.dart';

// Provides the list of ALL advertisements for the admin (including inactive ones)
final adminAdvertisementsProvider =
    FutureProvider.autoDispose<List<Advertisement>>((ref) async {
      final response = await SupabaseConfig.client
          .from('advertisements')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Advertisement.fromJson(json))
          .toList();
    });

class ManageAdvertisementsScreen extends ConsumerWidget {
  const ManageAdvertisementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Admin privileges required.')),
      );
    }

    final adsAsync = ref.watch(adminAdvertisementsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.manageAdPanels,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: adsAsync.when(
        data: (ads) {
          if (ads.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return _AdCard(ad: ad, isDark: isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ModernFab.extended(
        onPressed: () {
          context.push('/admin/advertisements/edit').then((_) {
            ref.invalidate(adminAdvertisementsProvider);
          });
        },
        icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
        label: Text(AppLocalizations.of(context)!.newAd),
      ),
    );
  }
}

class _AdCard extends ConsumerWidget {
  final Advertisement ad;
  final bool isDark;

  const _AdCard({required this.ad, required this.isDark});

  Future<void> _toggleActive(
    WidgetRef ref,
    BuildContext context,
    bool newValue,
  ) async {
    try {
      await SupabaseConfig.client
          .from('advertisements')
          .update({'is_active': newValue})
          .eq('id', ad.id);

      if (context.mounted) {
        ref.invalidate(adminAdvertisementsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newValue
                  ? AppLocalizations.of(context)!.adActivated
                  : AppLocalizations.of(context)!.adHiddenMsg,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAd(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAdTitle),
        content: Text(AppLocalizations.of(context)!.deleteAdConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.cardButtonDelete),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await SupabaseConfig.client
          .from('advertisements')
          .delete()
          .eq('id', ad.id);
      if (context.mounted) {
        ref.invalidate(adminAdvertisementsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.adDeleted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Image with text overlay
          SizedBox(
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: Colors.grey),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ad.textContent != null && ad.textContent!.isNotEmpty)
                        Text(
                          ad.textContent!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ad.isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ad.isActive
                          ? AppLocalizations.of(context)!.adActive
                          : AppLocalizations.of(context)!.adHidden,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
                        text: AppLocalizations.of(
                          context,
                        )!.adDurationFormat(ad.displayDurationSeconds),
                      ),
                      const SizedBox(height: 4),
                      _DetailRow(
                        icon: PhosphorIcons.monitor(PhosphorIconsStyle.fill),
                        text: AppLocalizations.of(
                          context,
                        )!.adScreenFormat(ad.targetScreen),
                      ),
                      if (ad.adEndDate != null) ...[
                        const SizedBox(height: 4),
                        _DetailRow(
                          icon: PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                          text: AppLocalizations.of(context)!.adEndsFormat(
                            timeago.format(
                              ad.adEndDate!,
                              allowFromNow: true,
                              locale: Localizations.localeOf(
                                context,
                              ).languageCode,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                Switch(
                  value: ad.isActive,
                  onChanged: (val) => _toggleActive(ref, context, val),
                  activeThumbColor: const Color(0xFF8B5CF6),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    context.push('/admin/advertisements/edit', extra: ad).then((
                      _,
                    ) {
                      ref.invalidate(adminAdvertisementsProvider);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAd(ref, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.presentationChart(PhosphorIconsStyle.duotone),
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noAdvertisements,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createFirstAd,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
