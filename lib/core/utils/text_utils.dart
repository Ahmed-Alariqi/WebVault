import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

class TextUtils {
  /// Safely extracts a plain string representation from a potentially JSON-encoded Rich Text payload.
  /// If the string is a legacy standard string, it simply returns itself.
  static String getPlainTextFromDescription(String rawDescription) {
    if (rawDescription.isEmpty) return '';

    try {
      final decoded = jsonDecode(rawDescription);
      final doc = Document.fromJson(decoded);
      return doc.toPlainText();
    } catch (_) {
      // It is not structured JSON, meaning it originated as pure text
      return rawDescription;
    }
  }
}
