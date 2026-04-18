// ══════════════════════════════════════════════════════════════════════════
// TranscriptionService — Voice Input via Groq Whisper (STT)
// ══════════════════════════════════════════════════════════════════════════
//
// Records audio from the device microphone and transcribes it using the
// `transcribe-audio` Supabase Edge Function (which proxies Groq Whisper).
//
// Supports Arabic, English, and mixed Arabic+English (code-switching).
// ══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/supabase_config.dart';

class TranscriptionService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  /// Returns true when a recording session is currently active.
  Future<bool> get isRecording => _recorder.isRecording();

  /// Starts recording audio.
  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('microphone_permission_denied');
    }

    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      _currentPath = '${dir.path}/zaad_voice_input.m4a';
    }

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 16000,
      ),
      path: _currentPath ?? '',
    );

    debugPrint('[TranscriptionService] Recording started → $_currentPath');
  }

  /// Stops the current recording and sends audio to Groq Whisper.
  /// Returns the transcribed text string.
  Future<String> stopAndTranscribe() async {
    final stoppedPath = await _recorder.stop();
    debugPrint('[TranscriptionService] Recording stopped → $stoppedPath');

    Uint8List audioBytes;
    String filename;

    if (kIsWeb) {
      throw UnimplementedError(
        'Web recording via blob URLs is not yet supported.',
      );
    } else {
      final path = stoppedPath ?? _currentPath;
      if (path == null) throw Exception('no_audio_file');
      final file = File(path);
      if (!await file.exists()) throw Exception('audio_file_not_found');
      audioBytes = await file.readAsBytes();
      filename = 'audio.m4a';

      // Delete the temp file immediately after reading — frees storage now.
      // Each new recording overwrites the same path anyway.
      try { await file.delete(); } catch (_) { /* ignore if already gone */ }
    }

    if (audioBytes.isEmpty) throw Exception('empty_audio_recording');
    debugPrint('[TranscriptionService] Audio size: ${audioBytes.length} bytes');

    final audioBase64 = base64Encode(audioBytes);

    final url = '${SupabaseConfig.url}/functions/v1/transcribe-audio';

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'apikey': SupabaseConfig.anonKey,
          },
          body: jsonEncode({
            'audio_base64': audioBase64,
            'filename': filename,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      String msg = 'Transcription failed (${response.statusCode})';
      try {
        final err = jsonDecode(response.body);
        if (err['error'] != null) msg = err['error'].toString();
      } catch (_) {}
      throw Exception(msg);
    }

    final data = jsonDecode(response.body);
    final text = (data['text'] as String? ?? '').trim();
    debugPrint(
        '[TranscriptionService] Transcribed: "$text" (lang: ${data['language']})');
    return text;
  }

  /// Cancels an in-progress recording without transcribing.
  Future<void> cancel() async {
    await _recorder.cancel();
  }

  /// Release resources.
  void dispose() {
    _recorder.dispose();
  }
}
