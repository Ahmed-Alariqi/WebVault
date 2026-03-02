import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../data/models/clipboard_item_model.dart';

// ─────────────────────────────────────────────
//  Overlay Dimensions (dp)
// ─────────────────────────────────────────────
const int _kBubbleSize = 58;
const int _kPanelW = 340;
const int _kPanelH = 480;

/// Standalone overlay clipboard — runs in its own isolate.
/// NO Riverpod. Reads / writes Hive directly.
class OverlayClipboard extends StatefulWidget {
  const OverlayClipboard({super.key});

  @override
  State<OverlayClipboard> createState() => _OverlayClipboardState();
}

class _OverlayClipboardState extends State<OverlayClipboard>
    with SingleTickerProviderStateMixin {
  // ── Data ──────────────────────────────────────
  List<ClipboardItemModel> _items = [];
  List<ClipboardGroupModel> _groups = [];
  String? _selectedGroupId;
  bool _isLoading = true;

  // ── UI State ──────────────────────────────────
  bool _isExpanded = false;
  bool _isAddMode = false;
  final _labelCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  // ── Animation ─────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _labelCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  // ── Load from Hive ────────────────────────────
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (!Hive.isBoxOpen(kClipboardBox)) {
        await Hive.openBox(kClipboardBox);
      }
      if (!Hive.isBoxOpen(kClipboardGroupsBox)) {
        await Hive.openBox(kClipboardGroupsBox);
      }

      final itemBox = Hive.box(kClipboardBox);
      final groupBox = Hive.box(kClipboardGroupsBox);

      final items = <ClipboardItemModel>[];
      for (final val in itemBox.values) {
        try {
          items.add(
            ClipboardItemModel.fromJson(Map<String, dynamic>.from(val as Map)),
          );
        } catch (_) {}
      }
      items.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

      final groups = <ClipboardGroupModel>[];
      for (final val in groupBox.values) {
        try {
          groups.add(
            ClipboardGroupModel.fromJson(Map<String, dynamic>.from(val as Map)),
          );
        } catch (_) {}
      }
      groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (mounted) {
        setState(() {
          _items = items;
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Save new item ─────────────────────────────
  Future<void> _saveNewItem() async {
    final label = _labelCtrl.text.trim();
    final value = _valueCtrl.text.trim();
    if (label.isEmpty || value.isEmpty) return;

    final item = ClipboardItemModel(
      id: const Uuid().v4(),
      label: label,
      value: value,
      createdAt: DateTime.now(),
      sortOrder: _items.length,
      groupId: _selectedGroupId == 'uncategorized' ? null : _selectedGroupId,
    );

    final box = Hive.box(kClipboardBox);
    await box.put(item.id, item.toJson());
    _labelCtrl.clear();
    _valueCtrl.clear();
    setState(() => _isAddMode = false);
    _loadData();
  }

  // ── Expand / Collapse ─────────────────────────
  Future<void> _expand() async {
    setState(() {
      _isExpanded = true;
      _isAddMode = false;
    });
    // Resize to panel, then centre it
    await FlutterOverlayWindow.resizeOverlay(_kPanelW, _kPanelH, true);
    await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    // Move to centre of screen (x=0, y=0 with center gravity)
    await FlutterOverlayWindow.moveOverlay(OverlayPosition(0, 0));
    _animCtrl.forward(from: 0);
  }

  Future<void> _collapse() async {
    _animCtrl.reverse();
    await Future.delayed(const Duration(milliseconds: 180));
    setState(() {
      _isExpanded = false;
      _isAddMode = false;
    });
    await FlutterOverlayWindow.resizeOverlay(_kBubbleSize, _kBubbleSize, true);
    await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
  }

  // ── Filtered items ────────────────────────────
  List<ClipboardItemModel> get _filtered {
    if (_selectedGroupId == null) return _items;
    if (_selectedGroupId == 'uncategorized') {
      return _items.where((i) => i.groupId == null).toList();
    }
    return _items.where((i) => i.groupId == _selectedGroupId).toList();
  }

  // ──────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) return _buildBubble();

    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xEC1A1B2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  _buildHeader(),
                  if (_groups.isNotEmpty) _buildGroupsBar(),
                  const Divider(height: 1, color: Color(0x18FFFFFF)),
                  if (_isAddMode)
                    _buildAddForm()
                  else
                    Expanded(child: _buildList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bubble (collapsed) ────────────────────────
  Widget _buildBubble() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _expand,
        child: Container(
          width: _kBubbleSize.toDouble(),
          height: _kBubbleSize.toDouble(),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3F51B5), Color(0xFF009688)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.content_paste_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ── Header row ────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF009688)],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.content_paste_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Clipboard',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF0F0F5),
              ),
            ),
          ),
          // ─ Add button ─
          _iconBtn(
            icon: _isAddMode ? Icons.close_rounded : Icons.add_rounded,
            tooltip: _isAddMode ? 'Cancel' : 'Add new',
            color: _isAddMode ? Colors.red.shade400 : const Color(0xFF009688),
            onTap: () => setState(() => _isAddMode = !_isAddMode),
          ),
          const SizedBox(width: 4),
          // ─ Refresh ─
          _iconBtn(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: _loadData,
          ),
          const SizedBox(width: 4),
          // ─ Close (back to bubble) ─
          _iconBtn(
            icon: Icons.close_rounded,
            tooltip: 'Minimise',
            onTap: _collapse,
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color ?? Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  // ── Group filter bar ──────────────────────────
  Widget _buildGroupsBar() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          _groupChip('All', null),
          _groupChip('Uncat.', 'uncategorized'),
          ..._groups.map(
            (g) => _groupChip(g.name, g.id, color: _parseColor(g.colorHex)),
          ),
        ],
      ),
    );
  }

  Widget _groupChip(String label, String? id, {Color? color}) {
    final selected = _selectedGroupId == id;
    final col = color ?? const Color(0xFF3F51B5);
    return GestureDetector(
      onTap: () => setState(() => _selectedGroupId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? col : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? col : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  // ── Quick-Add form ────────────────────────────
  Widget _buildAddForm() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _inputField(controller: _labelCtrl, hint: 'Label (e.g. "API Key")'),
          const SizedBox(height: 8),
          _inputField(controller: _valueCtrl, hint: 'Value', maxLines: 3),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _saveNewItem,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3F51B5), Color(0xFF009688)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Save to Clipboard',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF009688), width: 1.2),
        ),
      ),
    );
  }

  // ── Items list ────────────────────────────────
  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            color: Color(0xFF009688),
            strokeWidth: 2,
          ),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.content_paste_off_rounded,
                size: 36,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 10),
              Text(
                'No items saved',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap  +  to add one',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildTile(items[i]),
    );
  }

  Widget _buildTile(ClipboardItemModel item) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: item.value));
        FlutterOverlayWindow.shareData('copied:${item.label}');
        await _collapse();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(12),
          border: item.isPinned
              ? Border.all(
                  color: const Color(0xFF009688).withValues(alpha: 0.4),
                )
              : Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // ─ Type icon ─
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _typeColor(item.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _typeIcon(item.type),
                size: 14,
                color: _typeColor(item.type),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.push_pin_rounded,
                            size: 10,
                            color: const Color(0xFF009688),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF0F0F5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 14,
                color: Color(0xFF7986CB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────
  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData _typeIcon(ClipboardItemType t) {
    switch (t) {
      case ClipboardItemType.email:
        return Icons.email_outlined;
      case ClipboardItemType.number:
        return Icons.numbers_rounded;
      case ClipboardItemType.otp:
        return Icons.lock_clock_outlined;
      case ClipboardItemType.code:
        return Icons.code_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  Color _typeColor(ClipboardItemType t) {
    switch (t) {
      case ClipboardItemType.email:
        return const Color(0xFF4FC3F7);
      case ClipboardItemType.number:
        return const Color(0xFFFFA726);
      case ClipboardItemType.otp:
        return const Color(0xFFEF5350);
      case ClipboardItemType.code:
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF9575CD);
    }
  }
}
