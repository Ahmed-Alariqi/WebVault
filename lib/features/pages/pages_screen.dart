import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/page_model.dart';

class PagesScreen extends ConsumerWidget {
  const PagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = ref.watch(filteredPagesProvider);
    final searchQuery = ref.watch(pageSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pages'),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.folder()),
            onPressed: () => context.push('/folders'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              onChanged: (v) => ref.read(pageSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search pages...',
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(PhosphorIcons.x(), size: 18),
                        onPressed: () =>
                            ref.read(pageSearchProvider.notifier).state = '',
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: pages.isEmpty
                ? _buildEmpty(isDark, searchQuery.isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: pages.length,
                    itemBuilder: (context, i) =>
                        _buildPageItem(context, ref, pages[i], isDark),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-page'),
        icon: Icon(PhosphorIcons.plus()),
        label: const Text('Add Page'),
      ),
    );
  }

  Widget _buildPageItem(
    BuildContext context,
    WidgetRef ref,
    PageModel page,
    bool isDark,
  ) {
    return Dismissible(
      key: Key(page.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          PhosphorIcons.trash(PhosphorIconsStyle.fill),
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => ref.read(pagesProvider.notifier).deletePage(page.id),
      child: GestureDetector(
        onTap: () => context.push('/browser/${page.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      page.url,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (page.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: page.tags.take(3).map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(pagesProvider.notifier)
                        .toggleFavorite(page.id),
                    child: Icon(
                      page.isFavorite
                          ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                          : PhosphorIcons.heart(),
                      size: 20,
                      color: page.isFavorite
                          ? AppTheme.errorColor
                          : (isDark ? Colors.white30 : Colors.black26),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/edit-page/${page.id}'),
                    child: Icon(
                      PhosphorIcons.pencilSimple(),
                      size: 18,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmpty(bool isDark, bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSearch
                  ? PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.duotone)
                  : PhosphorIcons.browsers(PhosphorIconsStyle.duotone),
              color: AppTheme.primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No results found' : 'No pages saved',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different search term'
                : 'Tap + to add your first page',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
