import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';
import '../models/folder_model.dart';

class FolderRepository {
  Box get _box => Hive.box(kFoldersBox);

  List<FolderModel> getAll() {
    return _box.values
        .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  FolderModel? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return FolderModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> save(FolderModel folder) async {
    await _box.put(folder.id, folder.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
