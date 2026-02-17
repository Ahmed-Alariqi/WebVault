import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/clipboard_item_model.dart';
import '../../presentation/widgets/modern_form_widgets.dart';

class ClipboardScreen extends ConsumerWidget {
  const ClipboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ref.watch(clipboardItemsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('Clipboard'),
        forceMaterialTransparency: true,
      ),
      body: items.isEmpty
          ? _buildEmpty(isDark)
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: items.length,
              onReorder: (oldIdx, newIdx) {
                final mutable = List<ClipboardItemModel>.from(items);
                if (newIdx > oldIdx) newIdx--;
                final item = mutable.removeAt(oldIdx);
                mutable.insert(newIdx, item);
                ref.read(clipboardItemsProvider.notifier).reorder(mutable);
              },
              itemBuilder: (context, i) {
                final item = items[i];
                return _ClipboardTile(
                  key: ValueKey(item.id),
                  item: item,
                  isDark: isDark,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, isDark),
        icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
        label: const Text('Add Value'),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              PhosphorIcons.clipboardText(PhosphorIconsStyle.duotone),
              color: AppTheme.accentColor,
              size: 40,
            ),
          ).animate().fadeIn(duration: 400.ms).scale(),
          const SizedBox(height: 24),
          Text(
            'No clipboard items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save values for quick copy while browsing',
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, bool isDark) {
    final labelCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    var selectedType = ClipboardItemType.text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment
                    .stretch, // Stretch for full width buttons
                children: [
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
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.copySimple(),
                        size: 24,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'New Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Modern Type Selector
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ClipboardItemType.values.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final t = ClipboardItemType.values[index];
                        final isSelected = t == selectedType;
                        final color = isSelected
                            ? AppTheme.primaryColor
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05));
                        final textColor = isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87);

                        return GestureDetector(
                          onTap: () => setModalState(() => selectedType = t),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              t.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: labelCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: ModernFormWidgets.inputDecoration(
                      context,
                      label: 'Label',
                      hint: 'e.g. My OTP code',
                      icon: PhosphorIcons.tag(),
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: valueCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines:
                        selectedType == ClipboardItemType.text ||
                            selectedType == ClipboardItemType.code
                        ? 3
                        : 1,
                    decoration: ModernFormWidgets.inputDecoration(
                      context,
                      label: 'Value',
                      hint: 'Content to copy',
                      icon: PhosphorIcons.textT(),
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(height: 32),

                  ModernFormWidgets.gradientButton(
                    label: 'Save to Clipboard',
                    icon: PhosphorIcons.floppyDisk(),
                    onPressed: () {
                      if (valueCtrl.text.trim().isEmpty) return;
                      final item = ClipboardItemModel(
                        id: const Uuid().v4(),
                        label: labelCtrl.text.trim().isEmpty
                            ? valueCtrl.text.trim()
                            : labelCtrl.text.trim(),
                        value: valueCtrl.text.trim(),
                        type: selectedType,
                        createdAt: DateTime.now(),
                      );
                      ref.read(clipboardItemsProvider.notifier).addItem(item);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ClipboardTile extends ConsumerWidget {
  final ClipboardItemModel item;
  final bool isDark;

  const _ClipboardTile({super.key, required this.item, required this.isDark});

  IconData _typeIcon(ClipboardItemType type) {
    switch (type) {
      case ClipboardItemType.number:
        return PhosphorIcons.numpad();
      case ClipboardItemType.code:
        return PhosphorIcons.code();
      case ClipboardItemType.email:
        return PhosphorIcons.envelope();
      case ClipboardItemType.otp:
        return PhosphorIcons.password();
      case ClipboardItemType.text:
        return PhosphorIcons.textAa();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: item.value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text('Copied "${item.label}"'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    item.isPinned
                        ? PhosphorIcons.pushPinSlash()
                        : PhosphorIcons.pushPin(),
                    color: AppTheme.accentColor,
                  ),
                  title: Text(item.isPinned ? 'Unpin Item' : 'Pin to Top'),
                  onTap: () {
                    ref
                        .read(clipboardItemsProvider.notifier)
                        .togglePin(item.id);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(
                    PhosphorIcons.trash(),
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    ref
                        .read(clipboardItemsProvider.notifier)
                        .deleteItem(item.id);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isPinned
                ? AppTheme.accentColor.withValues(alpha: 0.3)
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            width: item.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _typeIcon(item.type),
                color: AppTheme.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            PhosphorIcons.pushPin(PhosphorIconsStyle.fill),
                            size: 14,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.copySimple(),
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
