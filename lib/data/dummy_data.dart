import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'models/page_model.dart';
import 'models/folder_model.dart';
import 'models/clipboard_item_model.dart';
import 'repositories/page_repository.dart';
import 'repositories/folder_repository.dart';
import 'repositories/clipboard_repository.dart';

class DummyData {
  static Future<void> seed({
    required PageRepository pageRepo,
    required FolderRepository folderRepo,
    required ClipboardRepository clipboardRepo,
  }) async {
    // Check if already seeded
    if (pageRepo.getAll().isNotEmpty) return;

    // Folders
    final folders = [
      FolderModel(
        id: 'folder-1',
        name: 'Work',
        iconCodePoint: PhosphorIcons.briefcase().codePoint,
        colorValue: 0xFF3F51B5,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      FolderModel(
        id: 'folder-2',
        name: 'Personal',
        iconCodePoint: PhosphorIcons.usersThree().codePoint,
        colorValue: 0xFF009688,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      FolderModel(
        id: 'folder-3',
        name: 'Research',
        iconCodePoint: PhosphorIcons.newspaper().codePoint,
        colorValue: 0xFF9C27B0,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    for (final f in folders) {
      await folderRepo.save(f);
    }

    // Pages
    final pages = [
      PageModel(
        id: 'page-1',
        url: 'https://flutter.dev',
        title: 'Flutter Official',
        notes: 'Flutter framework homepage',
        tags: ['flutter', 'mobile', 'dev'],
        folderId: 'folder-1',
        isFavorite: true,
        visitCount: 12,
        lastOpened: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      PageModel(
        id: 'page-2',
        url: 'https://pub.dev',
        title: 'Pub.dev Packages',
        notes: 'Dart package repository',
        tags: ['packages', 'dart'],
        folderId: 'folder-1',
        isFavorite: false,
        visitCount: 8,
        lastOpened: DateTime.now().subtract(const Duration(hours: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      PageModel(
        id: 'page-3',
        url: 'https://github.com',
        title: 'GitHub',
        notes: 'Source code hosting',
        tags: ['git', 'code', 'dev'],
        folderId: 'folder-1',
        isFavorite: true,
        visitCount: 25,
        lastOpened: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      PageModel(
        id: 'page-4',
        url: 'https://medium.com',
        title: 'Medium',
        notes: 'Articles and blogs',
        tags: ['reading', 'articles'],
        folderId: 'folder-2',
        isFavorite: false,
        visitCount: 5,
        lastOpened: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      PageModel(
        id: 'page-5',
        url: 'https://stackoverflow.com',
        title: 'Stack Overflow',
        notes: 'Q&A for developers',
        tags: ['dev', 'help', 'community'],
        folderId: 'folder-3',
        isFavorite: true,
        visitCount: 18,
        lastOpened: DateTime.now().subtract(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];
    for (final p in pages) {
      await pageRepo.save(p);
    }

    // Clipboard items
    final clipboardItems = [
      ClipboardItemModel(
        id: 'clip-1',
        label: 'Verification Code',
        value: '847293',
        type: ClipboardItemType.otp,
        isPinned: true,
        sortOrder: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ClipboardItemModel(
        id: 'clip-2',
        label: 'API Key',
        value: 'sk-proj-abc123def456',
        type: ClipboardItemType.code,
        isPinned: true,
        sortOrder: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ClipboardItemModel(
        id: 'clip-3',
        label: 'Support Email',
        value: 'support@example.com',
        type: ClipboardItemType.email,
        isPinned: false,
        sortOrder: 2,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ClipboardItemModel(
        id: 'clip-4',
        label: 'Tracking Number',
        value: '1Z999AA10123456784',
        type: ClipboardItemType.text,
        isPinned: false,
        sortOrder: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ClipboardItemModel(
        id: 'clip-5',
        label: 'Phone Number',
        value: '+1 (555) 123-4567',
        type: ClipboardItemType.number,
        isPinned: false,
        sortOrder: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    for (final c in clipboardItems) {
      await clipboardRepo.save(c);
    }
  }
}
