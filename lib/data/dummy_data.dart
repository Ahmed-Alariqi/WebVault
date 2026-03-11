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
        name: 'عام', // General
        iconCodePoint: PhosphorIcons.folder().codePoint,
        colorValue: 0xFF3F51B5,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
    for (final f in folders) {
      await folderRepo.save(f);
    }

    // Pages
    final pages = [
      PageModel(
        id: 'page-1',
        url: 'https://chat.openai.com',
        title: 'شات جي بي تي',
        notes: 'مساعد الذكاء الاصطناعي',
        tags: ['ai', 'chatgpt'],
        folderId: 'folder-1',
        isFavorite: true,
        visitCount: 15,
        lastOpened: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PageModel(
        id: 'page-2',
        url: 'https://www.w3schools.com',
        title: 'W3Schools',
        notes: 'موقع تعليم البرمجة',
        tags: ['programming', 'learning'],
        folderId: 'folder-1',
        isFavorite: true,
        visitCount: 22,
        lastOpened: DateTime.now().subtract(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      PageModel(
        id: 'page-3',
        url: 'https://gemini.google.com',
        title: 'Gemini',
        notes: 'نموذج الذكاء الاصطناعي من جوجل',
        tags: ['ai', 'google'],
        folderId: 'folder-1',
        isFavorite: true,
        visitCount: 8,
        lastOpened: DateTime.now().subtract(const Duration(hours: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
    for (final p in pages) {
      await pageRepo.save(p);
    }

    // Clipboard items
    final clipboardItems = [
      ClipboardItemModel(
        id: 'clip-1',
        label: 'البريد الإلكتروني', // Email
        value: 'demo@example.com',
        type: ClipboardItemType.email,
        isPinned: true,
        sortOrder: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ClipboardItemModel(
        id: 'clip-2',
        label: 'مفتاح API', // API Key
        value: 'sk-proj-abc123def456',
        type: ClipboardItemType.code,
        isPinned: false,
        sortOrder: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      ClipboardItemModel(
        id: 'clip-3',
        label: 'كلمة مرور Gmail', // Password
        value: 'SuperSecretPass123!',
        type: ClipboardItemType.otp,
        isPinned: false,
        sortOrder: 2,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
    for (final c in clipboardItems) {
      await clipboardRepo.saveItem(c);
    }
  }
}
