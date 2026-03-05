import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../presentation/providers/discover_providers.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/models/website_model.dart';
import '../../presentation/widgets/offline_warning_widget.dart';
import '../../l10n/app_localizations.dart';

class AdminSuggestionsScreen extends ConsumerWidget {
  const AdminSuggestionsScreen({super.key});

  Future<void> _approveSuggestion(
    BuildContext context,
    WidgetRef ref,
    SuggestionModel suggestion,
  ) async {
    // 1. Show dialog to edit/confirm details
    final titleController = TextEditingController(text: suggestion.pageTitle);
    final descController = TextEditingController(
      text: suggestion.pageDescription ?? '',
    );
    final urlController = TextEditingController(text: suggestion.pageUrl);
    bool isTrending = false;
    bool isPopular = false;
    bool isFeatured = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.approvePublish),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.titleLabel,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.urlLabel,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.descriptionLabel,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.of(context)!.trending,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: isTrending,
                  onChanged: (v) =>
                      setDialogState(() => isTrending = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.of(context)!.popular,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: isPopular,
                  onChanged: (v) =>
                      setDialogState(() => isPopular = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.of(context)!.featured,
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: isFeatured,
                  onChanged: (v) =>
                      setDialogState(() => isFeatured = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.publish),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      try {
        // Construct WebsiteModel
        // We use a random UUID for the local object, but Supabase will likely generate its own or use this one
        // depending on the policy. Since toJson excludes ID, Supabase generates it.
        final website = WebsiteModel(
          id: const Uuid().v4(),
          title: titleController.text,
          url: urlController.text,
          description: descController.text,
          imageUrl: null, // Could be enhanced to fetch OG image
          tags: [], // Could be enhanced to allow tag editing
          isTrending: isTrending,
          isPopular: isPopular,
          isFeatured: isFeatured,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref
            .read(suggestionRepositoryProvider)
            .approveSuggestion(suggestion.id, website);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.suggestionApprovedPublished,
              ),
            ),
          );
          // Refresh the list
          final _ = ref.refresh(adminSuggestionsProvider);
          ref.invalidate(trendingWebsitesProvider);
          ref.invalidate(popularWebsitesProvider);
          ref.invalidate(featuredWebsitesProvider);
          ref.invalidate(discoverWebsitesProvider);
          ref.invalidate(adminWebsitesProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.errorMessage(e.toString()),
              ),
            ),
          );
        }
      }
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
                              item.status.toUpperCase(),
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
