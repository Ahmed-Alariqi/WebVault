/// Data models for web search and URL reading results.

/// A single web search result from Jina s.jina.ai
class WebSearchResult {
  final String title;
  final String url;
  final String description;

  const WebSearchResult({
    required this.title,
    required this.url,
    required this.description,
  });

  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  /// Domain name for display (e.g. "flutter.dev")
  String get domain {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}

/// Result of reading a URL's content via Jina r.jina.ai
class WebReadResult {
  final String title;
  final String url;
  final String content;

  const WebReadResult({
    required this.title,
    required this.url,
    required this.content,
  });

  factory WebReadResult.fromJson(Map<String, dynamic> json) {
    return WebReadResult(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

/// Result of executing code via Judge0 CE
class CodeExecResult {
  final String stdout;
  final String stderr;
  final String compileOutput;
  final int statusId;
  final String statusDescription;
  final String? time;
  final int? memory;

  const CodeExecResult({
    required this.stdout,
    required this.stderr,
    required this.compileOutput,
    required this.statusId,
    required this.statusDescription,
    this.time,
    this.memory,
  });

  factory CodeExecResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as Map<String, dynamic>? ?? {};
    return CodeExecResult(
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
      compileOutput: json['compile_output'] as String? ?? '',
      statusId: status['id'] as int? ?? 0,
      statusDescription: status['description'] as String? ?? 'Unknown',
      time: json['time'] as String?,
      memory: json['memory'] as int?,
    );
  }

  /// True when the submission ran successfully (Judge0 status 3 = Accepted)
  bool get isSuccess => statusId == 3;

  /// True when compilation failed
  bool get isCompileError => statusId == 6;

  /// True when there's a runtime error
  bool get isRuntimeError => statusId == 11 || statusId == 12;

  /// True when execution timed out
  bool get isTimeout => statusId == 5;

  /// True when the error is specifically and strictly due to missing STDIN input
  bool get isStdinError {
    // Only check stderr for specific exception messages to avoid false positives 
    // from compiler echoes or generic runtime errors.
    final err = stderr.toLowerCase();
    return !isSuccess && (
      err.contains('eoferror') ||
      err.contains('eof when reading a line') ||
      err.contains('nosuchelementexception: no line found')
    );
  }

  /// The main output to display to the user
  String get displayOutput {
    if (isCompileError && compileOutput.isNotEmpty) return compileOutput;
    if (stderr.isNotEmpty) return stderr;
    if (stdout.isNotEmpty) return stdout;
    if (compileOutput.isNotEmpty) return compileOutput;
    return statusDescription;
  }

  /// Formatted memory string
  String? get memoryFormatted {
    if (memory == null) return null;
    if (memory! > 1024) return '${(memory! / 1024).toStringAsFixed(1)} MB';
    return '$memory KB';
  }
}
