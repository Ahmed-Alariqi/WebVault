import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/admin_providers.dart';

import '../../../data/models/website_model.dart';
import '../../../l10n/app_localizations.dart';

class DiscoverItemPickerSheet extends ConsumerStatefulWidget {
  final Set<String>? excludedIds;
  final bool autoCloseOnSelect;
  final Widget Function(BuildContext context, WebsiteModel item)?
  trailingBuilder;
  final void Function(WebsiteModel item)? onItemSelected;

  const DiscoverItemPickerSheet({
    super.key,
    this.excludedIds,
    this.autoCloseOnSelect = true,
    this.trailingBuilder,
    this.onItemSelected,
  });

  @override
  ConsumerState<DiscoverItemPickerSheet> createState() =>
      _DiscoverItemPickerSheetState();
}

class _DiscoverItemPickerSheetState
    extends ConsumerState<DiscoverItemPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch initial items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSearchQueryProvider.notifier).state = '';
      ref.read(adminContentTypeFilterProvider.notifier).state = null;
      ref.read(adminWebsitesPaginatedProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(adminSearchQueryProvider.notifier).state = query;
    ref.read(adminWebsitesPaginatedProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(adminWebsitesPaginatedProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Discover Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    // Debounce or search directly
                    _onSearch(val);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: Builder(
                  builder: (context) {
                    final matchingItems = state.items.where((i) {
                      return widget.excludedIds == null ||
                          !widget.excludedIds!.contains(i.id);
                    }).toList();

                    if (state.isLoading && state.isInitialLoad) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (matchingItems.isEmpty && !state.hasMore) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.noMatchesFound,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: matchingItems.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (context, index) {
                        if (index >= matchingItems.length) {
                          return Center(
                            child: TextButton(
                              onPressed: () {
                                ref
                                    .read(
                                      adminWebsitesPaginatedProvider.notifier,
                                    )
                                    .loadMore();
                              },
                              child: const Text('Load More'),
                            ),
                          );
                        }
                        final item = matchingItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    child: Icon(
                                      PhosphorIcons.image(),
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.contentType,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                          trailing: widget.trailingBuilder != null
                              ? widget.trailingBuilder!(context, item)
                              : const Icon(Icons.chevron_right),
                          onTap: () {
                            if (widget.onItemSelected != null) {
                              widget.onItemSelected!(item);
                            }
                            if (widget.autoCloseOnSelect) {
                              Navigator.of(context).pop(item);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
