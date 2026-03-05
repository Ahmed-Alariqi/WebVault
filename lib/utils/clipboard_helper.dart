import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/clipboard_item_model.dart';
import '../presentation/providers/providers.dart';
import '../l10n/app_localizations.dart';

class ClipboardHelper {
  static Future<void> copyAndPrompt(
    BuildContext context,
    WidgetRef ref,
    String content,
  ) async {
    // 1. Copy to native system clipboard
    await Clipboard.setData(ClipboardData(text: content));

    // 2. Prompt user
    if (!context.mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.copied),
        content: Text(AppLocalizations.of(context)!.promptSaveToVault),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // Create new clipboard item
      final newItem = ClipboardItemModel(
        id: const Uuid().v4(),
        label: AppLocalizations.of(context)!.copiedText,
        value: content,
        createdAt: DateTime.now(),
        isPinned: false,
      );

      // Save to internal app clipboard
      ref.read(clipboardItemsProvider.notifier).addItem(newItem);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.savedExplicitlyToClipboard,
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> showManualEntrySheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final textController = TextEditingController();

    // Auto-fill field with whatever is natively inside device clipboard!
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      textController.text = clipboardData!.text!;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.quickAddToClipboard,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  minLines: 1,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.pasteOrTypeText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final content = textController.text.trim();
                    if (content.isNotEmpty) {
                      final newItem = ClipboardItemModel(
                        id: const Uuid().v4(),
                        label: AppLocalizations.of(context)!.manualEntry,
                        value: content,
                        createdAt: DateTime.now(),
                        isPinned: false,
                      );
                      ref
                          .read(clipboardItemsProvider.notifier)
                          .addItem(newItem);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.savedToClipboard,
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.saveToVaultBtn),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
