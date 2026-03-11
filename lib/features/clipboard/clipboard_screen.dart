import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../presentation/providers/providers.dart';
import '../../data/models/clipboard_item_model.dart';
import '../../presentation/widgets/modern_form_widgets.dart';
import '../../presentation/widgets/modern_fab.dart';
import '../../l10n/app_localizations.dart';

class ClipboardScreen extends ConsumerStatefulWidget {
  const ClipboardScreen({super.key});

  @override
  ConsumerState<ClipboardScreen> createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends ConsumerState<ClipboardScreen> {
  final Set<String> _selectedIds = {};
  bool _isMultiSelectMode = false;

  IconData _getIconData(String id) {
    switch (id) {
      case 'api':
        return PhosphorIcons.plugs();
      case 'code':
        return PhosphorIcons.code();
      case 'text':
        return PhosphorIcons.textT();
      case 'emails':
        return PhosphorIcons.envelope();
      case 'passwords':
        return PhosphorIcons.password();
      case 'keys':
        return PhosphorIcons.key();
      case 'urls':
        return PhosphorIcons.link();
      case 'apps':
        return PhosphorIcons.appWindow();
      case 'tools':
        return PhosphorIcons.wrench();
      case 'folder':
      default:
        return PhosphorIcons.folder();
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isMultiSelectMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _selectedIds.clear();
      _isMultiSelectMode = false;
    });
  }

  void _enterMultiSelect(String firstId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedIds.add(firstId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = ref.watch(clipboardItemsProvider);
    final groups = ref.watch(clipboardGroupsProvider);
    final activeGroupId = ref.watch(selectedClipboardGroupProvider);

    // Filter items
    final items = activeGroupId == null
        ? allItems
        : activeGroupId == 'uncategorized'
        ? allItems.where((i) => i.groupId == null).toList()
        : allItems.where((i) => i.groupId == activeGroupId).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('${_selectedIds.length} selected')
            : Text(AppLocalizations.of(context)!.clipboard),
        forceMaterialTransparency: true,
        leading: _isMultiSelectMode
            ? IconButton(
                icon: Icon(PhosphorIcons.x()),
                onPressed: _exitMultiSelect,
              )
            : null,
        actions: [
          if (_isMultiSelectMode) ...[
            // Select / Deselect all
            IconButton(
              icon: Icon(
                _selectedIds.length == items.length
                    ? PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)
                    : PhosphorIcons.square(),
              ),
              tooltip: 'Select All',
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == items.length) {
                    _selectedIds.clear();
                    _isMultiSelectMode = false;
                  } else {
                    _selectedIds.addAll(items.map((i) => i.id));
                  }
                });
              },
            ),
            // Move selected
            IconButton(
              icon: Icon(PhosphorIcons.arrowBendUpRight()),
              tooltip: 'Move to Group',
              onPressed: () => _showMoveToGroupDialog(
                context,
                ref,
                isDark,
                _selectedIds.toList(),
              ),
            ),
            // Delete selected
            IconButton(
              icon: Icon(PhosphorIcons.trash(), color: AppTheme.errorColor),
              tooltip: 'Delete Selected',
              onPressed: () {
                for (final id in _selectedIds) {
                  ref.read(clipboardItemsProvider.notifier).deleteItem(id);
                }
                _exitMultiSelect();
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(PhosphorIcons.gear()),
              tooltip: 'Clipboard Settings',
              onPressed: () => context.push('/clipboard-settings'),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildGroupsBar(context, ref, groups, activeGroupId, isDark),
          Expanded(
            child: items.isEmpty
                ? _buildEmpty(isDark)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: items.length,
                    onReorder: (oldIdx, newIdx) {
                      if (_isMultiSelectMode) {
                        return; // Disable reorder in multi-select
                      }
                      final mutable = List<ClipboardItemModel>.from(items);
                      if (newIdx > oldIdx) newIdx--;
                      final item = mutable.removeAt(oldIdx);
                      mutable.insert(newIdx, item);
                      ref
                          .read(clipboardItemsProvider.notifier)
                          .reorder(mutable);
                    },
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final isSelected = _selectedIds.contains(item.id);
                      return _ClipboardTile(
                        key: ValueKey(item.id),
                        item: item,
                        isDark: isDark,
                        isMultiSelectMode: _isMultiSelectMode,
                        isSelected: isSelected,
                        onToggleSelect: () => _toggleSelection(item.id),
                        onLongPress: () {
                          if (!_isMultiSelectMode) {
                            _enterMultiSelect(item.id);
                          }
                        },
                        onMoveToGroup: () => _showMoveToGroupDialog(
                          context,
                          ref,
                          isDark,
                          [item.id],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isMultiSelectMode
          ? null
          : ModernFab.extended(
              onPressed: () =>
                  _showAddDialog(context, ref, isDark, activeGroupId),
              icon: Icon(PhosphorIcons.plusCircle(PhosphorIconsStyle.fill)),
              label: Text(AppLocalizations.of(context)!.addValue),
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

  Widget _buildGroupsBar(
    BuildContext context,
    WidgetRef ref,
    List<ClipboardGroupModel> groups,
    String? activeGroupId,
    bool isDark,
  ) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _GroupChip(
            label: AppLocalizations.of(context)!.allItems,
            icon: PhosphorIcons.infinity(),
            isSelected: activeGroupId == null,
            onTap: () =>
                ref.read(selectedClipboardGroupProvider.notifier).state = null,
            isDark: isDark,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: _GroupChip(
              label: AppLocalizations.of(context)!.uncategorized,
              icon: PhosphorIcons.tray(),
              isSelected: activeGroupId == 'uncategorized',
              onTap: () =>
                  ref.read(selectedClipboardGroupProvider.notifier).state =
                      'uncategorized',
              isDark: isDark,
            ),
          ),
          ...groups.map((g) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: _GroupChip(
                label: g.name,
                icon: _getIconData(g.iconStr),
                color: Color(int.parse(g.colorHex.replaceFirst('#', '0xFF'))),
                isSelected: activeGroupId == g.id,
                onTap: () =>
                    ref.read(selectedClipboardGroupProvider.notifier).state =
                        g.id,
                onLongPress: () => _showGroupOptions(context, ref, g, isDark),
                isDark: isDark,
              ),
            );
          }),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: ActionChip(
              backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              side: BorderSide(
                color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
              ),
              label: const Icon(Icons.add, size: 18),
              onPressed: () =>
                  _showManageGroupDialog(context, ref, null, isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Move to Group Dialog ──
  void _showMoveToGroupDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    List<String> itemIds,
  ) {
    final groups = ref.read(clipboardGroupsProvider);
    final count = itemIds.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            Row(
              children: [
                Icon(
                  PhosphorIcons.arrowBendUpRight(),
                  size: 22,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                Text(
                  count == 1 ? 'Move to Group' : 'Move $count items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Uncategorized option
            ListTile(
              leading: Icon(PhosphorIcons.tray(), color: Colors.grey),
              title: Text(AppLocalizations.of(context)!.uncategorized),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () {
                ref
                    .read(clipboardItemsProvider.notifier)
                    .moveItemsToGroup(itemIds, null);
                Navigator.pop(ctx);
                _exitMultiSelect();
                _showMovedSnackbar(context, 'Uncategorized');
              },
            ),
            // Group options
            ...groups.map((g) {
              final gColor = Color(
                int.parse(g.colorHex.replaceFirst('#', '0xFF')),
              );
              return ListTile(
                leading: Icon(_getIconData(g.iconStr), color: gColor, size: 28),
                title: Text(g.name),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  ref
                      .read(clipboardItemsProvider.notifier)
                      .moveItemsToGroup(itemIds, g.id);
                  Navigator.pop(ctx);
                  _exitMultiSelect();
                  _showMovedSnackbar(context, g.name);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMovedSnackbar(BuildContext context, String groupName) {
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
            Text(AppLocalizations.of(context)!.movedTo(groupName)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.successColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    String? currentGroupId,
  ) {
    final labelCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    var selectedType = ClipboardItemType.text;
    String? assignedGroupId = currentGroupId == 'uncategorized'
        ? null
        : currentGroupId;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      label: AppLocalizations.of(context)!.label,
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
                      label: AppLocalizations.of(context)!.value,
                      hint: AppLocalizations.of(context)!.contentToCopy,
                      icon: PhosphorIcons.textT(),
                      isDark: isDark,
                    ),
                  ),

                  const SizedBox(height: 32),

                  ModernFormWidgets.gradientButton(
                    label: AppLocalizations.of(context)!.saveToClipboard,
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
                        groupId: assignedGroupId,
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
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onLongPress;
  final VoidCallback onMoveToGroup;

  const _ClipboardTile({
    super.key,
    required this.item,
    required this.isDark,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onToggleSelect,
    required this.onLongPress,
    required this.onMoveToGroup,
  });

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
        if (isMultiSelectMode) {
          onToggleSelect();
          return;
        }
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
                Text(AppLocalizations.of(context)!.copiedItem(item.label)),
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
        if (isMultiSelectMode) return;
        _showItemOptions(context, ref);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                : item.isPinned
                ? AppTheme.accentColor.withValues(alpha: 0.3)
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            width: isSelected || item.isPinned ? 1.5 : 1,
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
            // Selection checkbox or type icon
            if (isMultiSelectMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                      : (isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isSelected
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.circle(),
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white38 : Colors.black26),
                  size: 24,
                ),
              )
            else
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
            if (!isMultiSelectMode)
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

  void _showItemOptions(BuildContext context, WidgetRef ref) {
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
                ref.read(clipboardItemsProvider.notifier).togglePin(item.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(
                PhosphorIcons.arrowBendUpRight(),
                color: AppTheme.primaryColor,
              ),
              title: Text(AppLocalizations.of(context)!.moveToGroup),
              onTap: () {
                Navigator.pop(ctx);
                onMoveToGroup();
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.checks(), color: Colors.teal),
              title: Text(AppLocalizations.of(context)!.selectMultiple),
              onTap: () {
                Navigator.pop(ctx);
                onLongPress();
              },
            ),
            ListTile(
              leading: Icon(PhosphorIcons.trash(), color: AppTheme.errorColor),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onTap: () {
                ref.read(clipboardItemsProvider.notifier).deleteItem(item.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final bool isDark;

  const _GroupChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showGroupOptions(
  BuildContext context,
  WidgetRef ref,
  ClipboardGroupModel group,
  bool isDark,
) {
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
              PhosphorIcons.pencilSimple(),
              color: AppTheme.primaryColor,
            ),
            title: Text(AppLocalizations.of(context)!.editGroup),
            onTap: () {
              Navigator.pop(ctx);
              _showManageGroupDialog(context, ref, group, isDark);
            },
          ),
          ListTile(
            leading: Icon(PhosphorIcons.trash(), color: AppTheme.errorColor),
            title: const Text(
              'Delete Group & Items',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () {
              if (ref.read(selectedClipboardGroupProvider) == group.id) {
                ref.read(selectedClipboardGroupProvider.notifier).state = null;
              }
              ref.read(clipboardGroupsProvider.notifier).deleteGroup(group.id);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}

void _showManageGroupDialog(
  BuildContext context,
  WidgetRef ref,
  ClipboardGroupModel? existingGroup,
  bool isDark,
) {
  showDialog(
    context: context,
    builder: (ctx) => _ManageGroupDialogBody(
      existingGroup: existingGroup,
      isDark: isDark,
      onSave: (name, iconStr, colorHex) {
        final notifier = ref.read(clipboardGroupsProvider.notifier);
        if (existingGroup == null) {
          notifier.addGroup(
            ClipboardGroupModel(
              id: const Uuid().v4(),
              name: name,
              iconStr: iconStr,
              colorHex: colorHex,
              createdAt: DateTime.now(),
            ),
          );
        } else {
          notifier.updateGroup(
            existingGroup.copyWith(
              name: name,
              iconStr: iconStr,
              colorHex: colorHex,
            ),
          );
        }
      },
    ),
  );
}

class _ManageGroupDialogBody extends StatefulWidget {
  final ClipboardGroupModel? existingGroup;
  final bool isDark;
  final void Function(String name, String iconStr, String colorHex) onSave;

  const _ManageGroupDialogBody({
    this.existingGroup,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_ManageGroupDialogBody> createState() => _ManageGroupDialogBodyState();
}

class _ManageGroupDialogBodyState extends State<_ManageGroupDialogBody> {
  late TextEditingController _nameCtrl;
  String _selectedIcon = 'folder';
  String _selectedColor = '#6366F1';

  final List<Map<String, dynamic>> _availableIcons = [
    {'id': 'folder', 'icon': PhosphorIcons.folder(), 'label': 'Folder'},
    {'id': 'api', 'icon': PhosphorIcons.plugs(), 'label': 'API'},
    {'id': 'code', 'icon': PhosphorIcons.code(), 'label': 'Code'},
    {'id': 'text', 'icon': PhosphorIcons.textT(), 'label': 'Text'},
    {'id': 'emails', 'icon': PhosphorIcons.envelope(), 'label': 'Emails'},
    {'id': 'passwords', 'icon': PhosphorIcons.password(), 'label': 'Passwords'},
    {'id': 'keys', 'icon': PhosphorIcons.key(), 'label': 'Keys'},
    {'id': 'urls', 'icon': PhosphorIcons.link(), 'label': 'URLs'},
    {'id': 'apps', 'icon': PhosphorIcons.appWindow(), 'label': 'Apps'},
    {'id': 'tools', 'icon': PhosphorIcons.wrench(), 'label': 'Tools'},
  ];

  final List<String> _availableColors = [
    '#6366F1', // Indigo (Primary)
    '#EF4444', // Red
    '#F97316', // Orange
    '#EAB308', // Yellow
    '#22C55E', // Green
    '#06B6D4', // Cyan
    '#3B82F6', // Blue
    '#A855F7', // Purple
    '#EC4899', // Pink
    '#64748B', // Slate
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingGroup?.name ?? '');
    if (widget.existingGroup != null) {
      _selectedIcon = widget.existingGroup!.iconStr;
      _selectedColor = widget.existingGroup!.colorHex;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.existingGroup == null ? 'New Group' : 'Edit Group'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: ModernFormWidgets.inputDecoration(
                context,
                label: AppLocalizations.of(context)!.groupName,
                hint: 'e.g. Work, Social',
                icon:
                    _availableIcons.firstWhere(
                          (e) => e['id'] == _selectedIcon,
                        )['icon']
                        as IconData,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((item) {
                final isSelected = _selectedIcon == item['id'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedIcon = item['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.2)
                          : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : isDark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((hex) {
                final isSelected =
                    _selectedColor.toUpperCase() == hex.toUpperCase();
                final color = _colorFromHex(hex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.trim().isEmpty) return;
            widget.onSave(_nameCtrl.text.trim(), _selectedIcon, _selectedColor);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
