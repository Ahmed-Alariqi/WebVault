import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../data/models/suggestion_model.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../l10n/app_localizations.dart';

class AdminSuggestionsScreen extends ConsumerWidget {
  const AdminSuggestionsScreen({super.key});

  void _approveSuggestion(
    BuildContext context,
    WidgetRef ref,
    SuggestionModel suggestion,
  ) {
    context.push(
      '/admin/websites/edit',
      extra: <String, dynamic>{'suggestion': suggestion},
    );
  }

  String _getStatusTranslation(BuildContext context, String status) {
    final loc = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'pending':
        return loc.statusPending;
      case 'approved':
        return loc.statusApproved;
      case 'rejected':
        return loc.statusRejected;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(adminSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.userSuggestions),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final _ = ref.refresh(adminSuggestionsProvider);
            },
          ),
        ],
      ),
      body: suggestionsAsync.when(
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noPendingSuggestions),
            );
          }
          return ListView.builder(
            itemCount: suggestions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.pageTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Text(
                              _getStatusTranslation(
                                context,
                                item.status,
                              ).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(item.pageUrl)),
                        child: Text(
                          item.pageUrl,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (item.pageDescription != null &&
                          item.pageDescription!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.pageDescription!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.suggestedDate(
                          DateFormat.yMMMd().format(item.createdAt),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              try {
                                await ref
                                    .read(suggestionRepositoryProvider)
                                    .rejectSuggestion(item.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.suggestionRejected,
                                      ),
                                    ),
                                  );
                                  final _ = ref.refresh(
                                    adminSuggestionsProvider,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.errorMessage(e.toString()),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(AppLocalizations.of(context)!.reject),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                _approveSuggestion(context, ref, item),
                            child: Text(AppLocalizations.of(context)!.approve),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideX();
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => OfflineWarningWidget(error: err),
      ),
    );
  }
}
