import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

class TextUtils {
  static String getPlainTextFromDescription(String description) {
    if (description.isEmpty) return '';
    try {
      final decoded = jsonDecode(description);
      final doc = Document.fromJson(decoded);
      return doc.toPlainText();
    } catch (_) {
      return description; // Fallback to raw string
    }
  }
}
