import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../repositories/page_repository.dart';
import '../repositories/folder_repository.dart';
import '../repositories/clipboard_repository.dart';
import '../models/page_model.dart';
import '../models/folder_model.dart';
import '../models/clipboard_item_model.dart';

class BackupService {
  final PageRepository _pageRepo;
  final FolderRepository _folderRepo;
  final ClipboardRepository _clipboardRepo;

  BackupService(this._pageRepo, this._folderRepo, this._clipboardRepo);

  /// Exports all data to a JSON file and shares it.
  /// Returns [true] if successful, [false] otherwise.
  Future<bool> exportData() async {
    try {
      final pages = _pageRepo.getAll().map((p) => p.toJson()).toList();
      final folders = _folderRepo.getAll().map((f) => f.toJson()).toList();
      final clipboard = _clipboardRepo.getAll().map((c) => c.toJson()).toList();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'pages': pages,
        'folders': folders,
        'clipboard': clipboard,
      };

      final jsonString = jsonEncode(backupData);

      if (kIsWeb) {
        // For web, we can't easily save a file directly using path_provider
        // We'd have to use dart:html or a package to trigger a download
        // For now, share_plus handles some web sharing. But file download is tricky.
        // Let's rely on share_plus XFile.fromData for web if needed,
        // though path_provider doesn't work on web. WebVault seems like a mobile app.
        // Assume non-web for now based on previous pubspec/features mostly.
        return false;
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/webvault_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(jsonString);

      final result = await Share.shareXFiles([
        XFile(file.path),
      ], text: 'WebVault Backup');

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }

  /// Imports data from a selected JSON file.
  /// Returns true if successful. Throws an exception or returns false on failure.
  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return false; // User canceled
      }

      final file = result.files.first;
      String content;

      if (kIsWeb || file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return false;
      }

      final dynamic data = jsonDecode(content);

      if (data is! Map<String, dynamic>) {
        return false; // Invalid format
      }

      if (!data.containsKey('pages') && !data.containsKey('folders')) {
        return false; // Valid JSON but probably not WebVault backup
      }

      // Import Pages
      if (data['pages'] != null && data['pages'] is List) {
        for (final p in data['pages']) {
          try {
            final page = PageModel.fromJson(
              Map<String, dynamic>.from(p as Map),
            );
            final existing = _pageRepo.getById(page.id);
            if (existing == null) {
              await _pageRepo.save(page);
            }
          } catch (e) {
            debugPrint('Skipping invalid page on import: $e');
          }
        }
      }

      // Import Folders
      if (data['folders'] != null && data['folders'] is List) {
        for (final f in data['folders']) {
          try {
            final folder = FolderModel.fromJson(
              Map<String, dynamic>.from(f as Map),
            );
            final existing = _folderRepo.getById(folder.id);
            if (existing == null) {
              await _folderRepo.save(folder);
            }
          } catch (e) {
            debugPrint('Skipping invalid folder on import: $e');
          }
        }
      }

      // Import Clipboard
      if (data['clipboard'] != null && data['clipboard'] is List) {
        for (final c in data['clipboard']) {
          try {
            final item = ClipboardItemModel.fromJson(
              Map<String, dynamic>.from(c as Map),
            );
            final existing = _clipboardRepo.getById(item.id);
            if (existing == null) {
              await _clipboardRepo.save(item);
            }
          } catch (e) {
            debugPrint('Skipping invalid clipboard item on import: $e');
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }
}
