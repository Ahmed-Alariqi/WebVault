import 'dart:convert';

import 'package:archive/archive.dart';

/// Encodes a PlantUML source string into the URL-safe form expected by
/// `https://www.plantuml.com/plantuml/svg/<encoded>` and any compatible
/// server (Kroki accepts the same scheme as well).
///
/// Algorithm — defined by the PlantUML project:
///   1. UTF-8 encode the source.
///   2. Apply **raw** Deflate (no zlib header, no checksum).
///   3. Re-encode the bytes using PlantUML's custom base64-like alphabet
///      so the result can be embedded directly in a URL path segment.
///
/// PlantUML's alphabet differs from standard base64: it starts with
/// digits, then uppercase, then lowercase, with `-` and `_` as the
/// trailing 62/63 characters. This is intentionally URL-safe.
///
/// References:
///   - https://plantuml.com/text-encoding
///   - https://plantuml.com/code-javascript-synchronous
String encodePlantUml(String source) {
  final bytes = utf8.encode(source);
  // Raw deflate — `archive` package's [Deflate] omits the zlib header by
  // default, which is exactly what plantuml.com expects.
  final compressed = Deflate(bytes).getBytes();
  return _encode64(compressed);
}

/// PlantUML's URL-safe alphabet.
const String _alphabet =
    '0123456789'
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    'abcdefghijklmnopqrstuvwxyz'
    '-_';

/// Encodes a byte array using PlantUML's custom base64 variant. Each
/// 3-byte group becomes 4 alphabet characters; the final 1-or-2-byte
/// remainder is padded with zero bits (PlantUML does NOT use `=`).
String _encode64(List<int> data) {
  final buf = StringBuffer();
  for (var i = 0; i < data.length; i += 3) {
    final b1 = data[i];
    final b2 = (i + 1 < data.length) ? data[i + 1] : 0;
    final b3 = (i + 2 < data.length) ? data[i + 2] : 0;

    final c1 = (b1 >> 2) & 0x3F;
    final c2 = ((b1 & 0x3) << 4) | ((b2 >> 4) & 0xF);
    final c3 = ((b2 & 0xF) << 2) | ((b3 >> 6) & 0x3);
    final c4 = b3 & 0x3F;

    buf.write(_alphabet[c1]);
    buf.write(_alphabet[c2]);

    if (i + 1 < data.length) {
      buf.write(_alphabet[c3]);
    }
    if (i + 2 < data.length) {
      buf.write(_alphabet[c4]);
    }
  }
  return buf.toString();
}

/// Default PlantUML server. Stable since 2009, free, no API key.
const String kPlantUmlServer = 'https://www.plantuml.com/plantuml';

/// Builds the full SVG URL for the given PlantUML source.
String plantUmlSvgUrl(String source, {String server = kPlantUmlServer}) =>
    '$server/svg/${encodePlantUml(source)}';

/// Builds the full PNG URL for the given PlantUML source. Useful as a
/// fallback if the host blocks SVG (rare) or as the export format.
String plantUmlPngUrl(String source, {String server = kPlantUmlServer}) =>
    '$server/png/${encodePlantUml(source)}';

/// Wraps a raw fragment in `@startuml ... @enduml` if not already wrapped,
/// and prepends a sensible default `skinparam` block tuned for the chat
/// theme. Used when the model emits a code fence aliased as `dfd`,
/// `usecase`, or `uml` without explicit `@startuml`.
String ensurePlantUmlWrapped(String code, {bool isDark = false}) {
  final trimmed = code.trim();
  if (trimmed.startsWith('@start')) return trimmed; // already wrapped
  final theme = isDark
      ? '''
skinparam backgroundColor #1E293B
skinparam defaultFontColor #F9FAFB
skinparam shadowing false
skinparam ArrowColor #10B981
skinparam ActorBackgroundColor #334155
skinparam ActorBorderColor #10B981
skinparam ActorFontColor #F9FAFB
skinparam UsecaseBackgroundColor #334155
skinparam UsecaseBorderColor #10B981
skinparam UsecaseFontColor #F9FAFB
skinparam RectangleBackgroundColor #334155
skinparam RectangleBorderColor #10B981
skinparam RectangleFontColor #F9FAFB
'''
      : '''
skinparam backgroundColor #FFFFFF
skinparam shadowing false
skinparam ArrowColor #059669
skinparam ActorBorderColor #059669
skinparam UsecaseBorderColor #059669
skinparam RectangleBorderColor #059669
''';
  return '@startuml\n$theme\n$trimmed\n@enduml';
}
