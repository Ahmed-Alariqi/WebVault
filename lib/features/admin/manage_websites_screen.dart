import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/website_model.dart';
import '../../presentation/providers/admin_providers.dart';

class ManageWebsitesScreen extends ConsumerStatefulWidget {
  const ManageWebsitesScreen({super.key});

  @override
  ConsumerState<ManageWebsitesScreen> createState() =>
      _ManageWebsitesScreenState();
}

class _ManageWebsitesScreenState extends ConsumerState<ManageWebsitesScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final websites = ref.watch(adminWebsitesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Manage Websites'),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEditDialog(context, ref, isDark),
          ),
        ],
      ),
      body: websites.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.globe(PhosphorIconsStyle.duotone),
                    size: 56,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No websites yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add one',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (ctx, i) =>
                _websiteTile(context, ref, list[i], isDark, i),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _websiteTile(
    BuildContext context,
    WidgetRef ref,
    WebsiteModel site,
    bool isDark,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              PhosphorIcons.globe(),
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  site.url,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (site.isTrending)
                      _badge('Trending', const Color(0xFFFF6B6B), isDark),
                    if (site.isPopular)
                      _badge('Popular', const Color(0xFFFF9800), isDark),
                    if (site.isFeatured)
                      _badge('Featured', const Color(0xFF4CAF50), isDark),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                _showAddEditDialog(context, ref, isDark, existing: site);
              } else if (v == 'delete') {
                await adminDeleteWebsite(site.id);
                ref.invalidate(adminWebsitesProvider);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideX(begin: 0.04);
  }

  Widget _badge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark, {
    WebsiteModel? existing,
  }) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    bool isTrending = existing?.isTrending ?? false;
    bool isPopular = existing?.isPopular ?? false;
    bool isFeatured = existing?.isFeatured ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(existing == null ? 'Add Website' : 'Edit Website'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleCtrl, 'Title', isDark),
                const SizedBox(height: 12),
                _dialogField(urlCtrl, 'URL', isDark),
                const SizedBox(height: 12),
                _dialogField(descCtrl, 'Description', isDark, maxLines: 3),
                const SizedBox(height: 12),
                _dialogField(imgCtrl, 'Image URL (optional)', isDark),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Trending', style: TextStyle(fontSize: 14)),
                  value: isTrending,
                  onChanged: (v) =>
                      setDialogState(() => isTrending = v ?? false),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Popular', style: TextStyle(fontSize: 14)),
                  value: isPopular,
                  onChanged: (v) =>
                      setDialogState(() => isPopular = v ?? false),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Featured', style: TextStyle(fontSize: 14)),
                  value: isFeatured,
                  onChanged: (v) =>
                      setDialogState(() => isFeatured = v ?? false),
                  activeColor: AppTheme.primaryColor,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleCtrl.text.trim(),
                  'url': urlCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'image_url': imgCtrl.text.trim().isEmpty
                      ? null
                      : imgCtrl.text.trim(),
                  'is_trending': isTrending,
                  'is_popular': isPopular,
                  'is_featured': isFeatured,
                };
                if (existing == null) {
                  await adminAddWebsite(data);
                } else {
                  await adminUpdateWebsite(existing.id, data);
                }
                ref.invalidate(adminWebsitesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                existing == null ? 'Add' : 'Save',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    bool isDark, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
