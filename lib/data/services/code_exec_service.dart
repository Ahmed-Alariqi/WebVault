import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/supabase_config.dart';
import '../models/web_tools_models.dart';

/// Service for remote code execution via the Judge0 CE proxy.
///
/// Calls the `code-exec` Edge Function which securely proxies code
/// to Judge0 CE's free public API.
class CodeExecService {
  static const _functionName = 'code-exec';

  static String get _baseUrl =>
      '${SupabaseConfig.url}/functions/v1/$_functionName';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
      };

  /// Execute source code in the given language.
  ///
  /// [language] should be a common name like "python", "javascript", "dart".
  /// [code] is the source code to execute.
  /// [stdin] is optional standard input for the program.
  static Future<CodeExecResult> execute({
    required String language,
    required String code,
    String? stdin,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'language': language,
        'code': code,
        if (stdin != null && stdin.isNotEmpty) 'stdin': stdin,
      }),
    );

    if (response.statusCode != 200) {
      // Try to parse a structured error from the Edge Function
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.containsKey('status')) {
          return CodeExecResult.fromJson(data);
        }
        throw Exception(data['error'] ?? 'Unknown error');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception(
          'Code execution failed (${response.statusCode}): ${response.body}',
        );
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CodeExecResult.fromJson(data);
  }

  /// Languages that can be executed by our code-exec service.
  /// Used to show/hide the "Run" button on code blocks.
  static const executableLanguages = {
    'python', 'python3', 'javascript', 'js', 'node',
    'typescript', 'ts', 'java', 'c', 'cpp', 'c++',
    'csharp', 'c#', 'go', 'golang', 'rust', 'ruby',
    'php', 'swift', 'kotlin', 'r', 'dart',
    'bash', 'shell', 'sh', 'sql', 'sqlite',
    'perl', 'lua', 'scala',
  };

  /// Returns true if the given language tag is executable.
  static bool isExecutable(String? language) {
    if (language == null || language.isEmpty) return false;
    return executableLanguages.contains(language.toLowerCase().trim());
  }
}
