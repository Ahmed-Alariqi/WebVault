import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/admin_providers.dart';
import '../../data/models/suggestion_model.dart';
import '../../data/models/website_model.dart';

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve & Publish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
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
          isTrending: false,
          isPopular: false,
          isFeatured: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref
            .read(suggestionRepositoryProvider)
            .approveSuggestion(suggestion.id, website);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suggestion approved and published!')),
          );
          // Refresh the list
          final _ = ref.refresh(adminSuggestionsProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(adminSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Suggestions'),
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
            return const Center(child: Text('No pending suggestions'));
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
                        'Suggested: ${DateFormat.yMMMd().format(item.createdAt)}',
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
                                    const SnackBar(
                                      content: Text('Suggestion rejected'),
                                    ),
                                  );
                                  final _ = ref.refresh(
                                    adminSuggestionsProvider,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                _approveSuggestion(context, ref, item),
                            child: const Text('Approve'),
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
