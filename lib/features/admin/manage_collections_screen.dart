import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/imagekit_service.dart';
import '../../data/models/collection_model.dart';
import '../../presentation/providers/admin_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';

class ManageCollectionsScreen extends ConsumerStatefulWidget {
  const ManageCollectionsScreen({super.key});

  @override
  ConsumerState<ManageCollectionsScreen> createState() =>
      _ManageCollectionsScreenState();
}

class _ManageCollectionsScreenState
    extends ConsumerState<ManageCollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final collectionsAsync = ref.watch(adminCollectionsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(loc.manageCollections),
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCollectionDialog(context, null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          loc.newCollection,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (collections) {
          if (collections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.folder(PhosphorIconsStyle.fill),
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.collectionsEmpty,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: collections.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final col = collections[oldIndex];
              await adminUpdateCollection(col.id, {'sort_order': newIndex});
              ref.invalidate(adminCollectionsProvider);
            },
            itemBuilder: (ctx, i) {
              final col = collections[i];
              return _buildCollectionTile(context, col, isDark, loc, i);
            },
          );
        },
      ),
    );
  }

  Widget _buildCollectionTile(
    BuildContext context,
    CollectionModel col,
    bool isDark,
    AppLocalizations loc,
    int index,
  ) {
    final color = Color(col.colorValue);
    return Card(
      key: ValueKey(col.id),
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showItemsManager(context, col),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Color icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  IconData(col.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            loc.collectionItems(col.itemCount),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!col.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: Icon(
                  PhosphorIcons.pencilSimple(),
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                onPressed: () => _showCollectionDialog(context, col),
              ),
              IconButton(
                icon: Icon(
                  PhosphorIcons.trash(),
                  size: 20,
                  color: Colors.redAccent,
                ),
                onPressed: () => _confirmDelete(context, col, loc),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  PhosphorIcons.dotsSixVertical(),
                  size: 20,
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CollectionModel col,
    AppLocalizations loc,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteCollectionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await adminDeleteCollection(col.id);
              ref.invalidate(adminCollectionsProvider);
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(loc.collectionDeleted)));
              }
            },
            child: Text(
              loc.delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectionDialog(BuildContext context, CollectionModel? existing) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final coverCtrl = TextEditingController(
      text: existing?.coverImageUrl ?? '',
    );
    bool isActive = existing?.isActive ?? true;

    bool isUploading = false;
    double uploadProgress = 0.0;

    // Pickers State
    int selectedColor = existing?.colorValue ?? AppTheme.primaryColor.value;
    int selectedIcon =
        existing?.iconCodePoint ??
        PhosphorIcons.folder(PhosphorIconsStyle.fill).codePoint;

    final colorOptions = [
      AppTheme.primaryColor.value,
      0xFFE91E63, // Pink
      0xFF9C27B0, // Purple
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFFF44336, // Red
      0xFF607D8B, // Blue Grey
    ];

    final iconOptions = [
      PhosphorIcons.folder(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.star(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.fire(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.lightning(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.graduationCap(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.monitorPlay(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.bookBookmark(PhosphorIconsStyle.fill).codePoint,
      PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill).codePoint,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(selectedColor).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          IconData(selectedIcon, fontFamily: 'MaterialIcons'),
                          color: Color(selectedColor),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        existing == null
                            ? loc.newCollection
                            : loc.editCollection,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Pickers
                  Text(
                    'Color & Icon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: colorOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        final color = Color(colorOptions[i]);
                        final isSelected = selectedColor == colorOptions[i];
                        return GestureDetector(
                          onTap: () => setSheetState(
                            () => selectedColor = colorOptions[i],
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: iconOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        final iconCode = iconOptions[i];
                        final isSelected = selectedIcon == iconCode;
                        final color = Color(selectedColor);
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedIcon = iconCode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.15)
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              IconData(iconCode, fontFamily: 'MaterialIcons'),
                              color: isSelected
                                  ? color
                                  : (isDark ? Colors.white54 : Colors.black54),
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Fields
                  _buildStyledTextField(
                    controller: titleCtrl,
                    label: loc.collectionName,
                    hint: loc.collectionNameHint,
                    icon: PhosphorIcons.textT(),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: descCtrl,
                    label: loc.collectionDescription,
                    hint: loc.collectionDescriptionHint,
                    icon: PhosphorIcons.textAlignLeft(),
                    isDark: isDark,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Cover Image Upload
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    setSheetState(() {
                                      isUploading = true;
                                      uploadProgress = 0;
                                    });
                                    try {
                                      final url =
                                          await ImageKitService.pickAndUpload(
                                            folder: '/collections',
                                            onProgress: (p) {
                                              if (mounted) {
                                                setSheetState(
                                                  () => uploadProgress = p,
                                                );
                                              }
                                            },
                                          );
                                      if (url != null && context.mounted) {
                                        setSheetState(
                                          () => coverCtrl.text = url,
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setSheetState(() {
                                          isUploading = false;
                                          uploadProgress = 0;
                                        });
                                      }
                                    }
                                  },
                            icon: isUploading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      value: uploadProgress > 0
                                          ? uploadProgress
                                          : null,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(PhosphorIcons.uploadSimple(), size: 18),
                            label: Text(
                              isUploading
                                  ? loc.formUploading
                                  : loc.formUploadDevice,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(selectedColor),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildStyledTextField(
                    controller: coverCtrl,
                    label: loc.collectionCoverImage,
                    hint: 'https://...',
                    icon: PhosphorIcons.link(),
                    isDark: isDark,
                  ),
                  if (coverCtrl.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: coverCtrl.text.trim(),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 120,
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                            child: Icon(
                              Icons.broken_image,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Active Switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isActive ? 'Active Status' : 'Inactive Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Color(selectedColor)
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                      value: isActive,
                      onChanged: (v) => setSheetState(() => isActive = v),
                      activeColor: Color(selectedColor),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Color(selectedColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        final data = {
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'cover_image_url': coverCtrl.text.trim().isEmpty
                              ? null
                              : coverCtrl.text.trim(),
                          'is_active': isActive,
                          'icon_code_point': selectedIcon,
                          'color_value': selectedColor & 0xFFFFFF,
                        };
                        if (existing != null) {
                          await adminUpdateCollection(existing.id, data);
                        } else {
                          await adminCreateCollection(data);
                        }
                        ref.invalidate(adminCollectionsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.collectionSaved)),
                          );
                        }
                      },
                      child: Text(
                        loc.save,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
      ),
    );
  }

  void _showItemsManager(BuildContext context, CollectionModel col) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        col.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showAddItemDialog(context, col),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(loc.addItems),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Consumer(
                  builder: (ctx, ref, _) {
                    final itemsAsync = ref.watch(
                      collectionItemsProvider(col.id),
                    );
                    return itemsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              loc.noItemsInCollection,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final item = items[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      item.imageUrl != null &&
                                          item.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 48,
                                                height: 48,
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.black.withValues(
                                                        alpha: 0.05,
                                                      ),
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 20,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          width: 48,
                                          height: 48,
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          child: const Icon(
                                            Icons.language,
                                            size: 20,
                                          ),
                                        ),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  item.contentType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    await adminRemoveItemFromCollection(
                                      col.id,
                                      item.id,
                                    );
                                    ref.invalidate(
                                      collectionItemsProvider(col.id),
                                    );
                                    ref.invalidate(adminCollectionsProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(loc.itemRemoved),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, CollectionModel col) {
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String search = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (ctx, scrollController) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: TextField(
                    onChanged: (v) => setSheetState(() => search = v),
                    decoration: InputDecoration(
                      hintText: loc.searchItemsToAdd,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (ctx, ref, _) {
                      final allItemsAsync = ref.watch(adminWebsitesProvider);
                      final currentItemsAsync = ref.watch(
                        collectionItemsProvider(col.id),
                      );

                      return allItemsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (allItems) {
                          final currentIds =
                              currentItemsAsync.valueOrNull
                                  ?.map((e) => e.id)
                                  .toSet() ??
                              {};

                          var filtered = allItems
                              .where((item) => !currentIds.contains(item.id))
                              .toList();

                          if (search.isNotEmpty) {
                            filtered = filtered
                                .where(
                                  (item) =>
                                      item.title.toLowerCase().contains(
                                        search.toLowerCase(),
                                      ) ||
                                      item.description.toLowerCase().contains(
                                        search.toLowerCase(),
                                      ),
                                )
                                .toList();
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(
                                loc.noItemsInCollection,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final item = filtered[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        item.imageUrl != null &&
                                            item.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black.withValues(
                                                          alpha: 0.05,
                                                        ),
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 20,
                                                  ),
                                                ),
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                            child: const Icon(
                                              Icons.language,
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    item.contentType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: AppTheme.primaryColor,
                                    ),
                                    onPressed: () async {
                                      await adminAddItemToCollection(
                                        col.id,
                                        item.id,
                                      );
                                      ref.invalidate(
                                        collectionItemsProvider(col.id),
                                      );
                                      ref.invalidate(adminCollectionsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(loc.itemAdded),
                                          ),
                                        );
                                      }
                                      setSheetState(() {});
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
