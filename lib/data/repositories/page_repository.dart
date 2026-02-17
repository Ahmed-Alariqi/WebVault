import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../models/page_model.dart';

class PageRepository {
  Box get _box => Hive.box(kPagesBox);

  List<PageModel> getAll() {
    return _box.values
        .map((e) => PageModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  PageModel? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return PageModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> save(PageModel page) async {
    await _box.put(page.id, page.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<PageModel> search(String query) {
    final q = query.toLowerCase();
    return getAll().where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.url.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  List<PageModel> getFavorites() {
    return getAll().where((p) => p.isFavorite).toList();
  }

  List<PageModel> getByFolder(String folderId) {
    return getAll().where((p) => p.folderId == folderId).toList();
  }

  List<PageModel> getRecent({int limit = 10}) {
    final pages = getAll().where((p) => p.lastOpened != null).toList();
    pages.sort((a, b) => b.lastOpened!.compareTo(a.lastOpened!));
    return pages.take(limit).toList();
  }

  PageModel? getMostVisited() {
    final pages = getAll();
    if (pages.isEmpty) return null;
    pages.sort((a, b) => b.visitCount.compareTo(a.visitCount));
    return pages.first;
  }

  Future<void> incrementVisit(String id) async {
    final page = getById(id);
    if (page != null) {
      await save(
        page.copyWith(
          visitCount: page.visitCount + 1,
          lastOpened: DateTime.now(),
        ),
      );
    }
  }

  Future<void> updateScrollPosition(String id, double position) async {
    final page = getById(id);
    if (page != null) {
      await save(page.copyWith(scrollPosition: position));
    }
  }
}
