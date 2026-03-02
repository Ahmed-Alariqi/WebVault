import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../models/clipboard_item_model.dart';

class ClipboardRepository {
  Box get _itemsBox => Hive.box(kClipboardBox);
  Box get _groupsBox => Hive.box(kClipboardGroupsBox);

  // --- ITEMS ---
  List<ClipboardItemModel> getAllItems() {
    final items = _itemsBox.values
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

  ClipboardItemModel? getItemById(String id) {
    final data = _itemsBox.get(id);
    if (data == null) return null;
    return ClipboardItemModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveItem(ClipboardItemModel item) async {
    await _itemsBox.put(item.id, item.toJson());
  }

  Future<void> deleteItem(String id) async {
    await _itemsBox.delete(id);
  }

  Future<void> reorderItems(List<ClipboardItemModel> items) async {
    for (int i = 0; i < items.length; i++) {
      final updated = items[i].copyWith(sortOrder: i);
      await _itemsBox.put(updated.id, updated.toJson());
    }
  }

  Future<void> cleanExpired() async {
    final now = DateTime.now();
    final items = getAllItems();
    for (final item in items) {
      if (item.autoDeleteAt != null && item.autoDeleteAt!.isBefore(now)) {
        await _itemsBox.delete(item.id);
      }
    }
  }

  // --- GROUPS ---
  List<ClipboardGroupModel> getAllGroups() {
    final groups = _groupsBox.values
        .map(
          (e) =>
              ClipboardGroupModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
    groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return groups;
  }

  ClipboardGroupModel? getGroupById(String id) {
    final data = _groupsBox.get(id);
    if (data == null) return null;
    return ClipboardGroupModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveGroup(ClipboardGroupModel group) async {
    await _groupsBox.put(group.id, group.toJson());
  }

  Future<void> deleteGroup(String id) async {
    // Optional: cascade delete items inside this group
    final itemsInGroup = getAllItems().where((i) => i.groupId == id).toList();
    for (final i in itemsInGroup) {
      await _itemsBox.delete(i.id);
    }

    await _groupsBox.delete(id);
  }

  Future<void> reorderGroups(List<ClipboardGroupModel> groups) async {
    for (int i = 0; i < groups.length; i++) {
      final updated = groups[i].copyWith(sortOrder: i);
      await _groupsBox.put(updated.id, updated.toJson());
    }
  }
}
