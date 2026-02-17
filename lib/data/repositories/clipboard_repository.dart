import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../models/clipboard_item_model.dart';

class ClipboardRepository {
  Box get _box => Hive.box(kClipboardBox);

  List<ClipboardItemModel> getAll() {
    final items = _box.values
        .map(
          (e) =>
              ClipboardItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    items.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return items;
  }

  ClipboardItemModel? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return ClipboardItemModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> save(ClipboardItemModel item) async {
    await _box.put(item.id, item.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> reorder(List<ClipboardItemModel> items) async {
    for (int i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(sortOrder: i);
      await _box.put(updated.id, updated.toJson());
    }
  }

  Future<void> cleanExpired() async {
    final now = DateTime.now();
    final items = getAll();
    for (final item in items) {
      if (item.autoDeleteAt != null && item.autoDeleteAt!.isBefore(now)) {
        await _box.delete(item.id);
      }
    }
  }
}
