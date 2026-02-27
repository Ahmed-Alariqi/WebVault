import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service for uploading images to ImageKit.io
class ImageKitService {
  static const String _privateKey = 'private_ZgleTn7f1G80z1FMSuyfZel66sw=';
  static const String _publicKey = 'public_tOCKDDHCso2zd1XskBNmHaqcjPA=';
  static const String _urlEndpoint = 'https://ik.imagekit.io/webvault';
  static const String _uploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';

  /// Pick an image from gallery and upload it to ImageKit.
  /// Returns the uploaded image URL, or null if cancelled/failed.
  static Future<String?> pickAndUpload({
    String folder = '/discover',
    void Function(double progress)? onProgress,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return null;

      onProgress?.call(0.1);

      final Uint8List bytes = await picked.readAsBytes();
      final String fileName = picked.name.isNotEmpty
          ? picked.name
          : 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      onProgress?.call(0.3);

      // Basic Auth: private_key:
      final String authHeader =
          'Basic ${base64Encode(utf8.encode('$_privateKey:'))}';

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.headers['Authorization'] = authHeader;
      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;
      request.fields['publicKey'] = _publicKey;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      onProgress?.call(0.5);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(0.9);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String url = data['url'] as String;
        onProgress?.call(1.0);
        debugPrint('ImageKit upload success: $url');
        return url;
      } else {
        debugPrint(
          'ImageKit upload failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('ImageKit upload error: $e');
      return null;
    }
  }

  /// Get a thumbnail URL (400px wide, quality 80).
  static String thumbnail(String url) {
    if (!url.contains(_urlEndpoint)) return url;
    return url.replaceFirst(_urlEndpoint, '$_urlEndpoint/tr:w-400,q-80');
  }

  /// Pick a video from gallery and upload it to ImageKit.
  /// Returns the uploaded video URL, or null if cancelled/failed.
  static Future<String?> pickAndUploadVideo({
    String folder = '/discover/videos',
    void Function(double progress)? onProgress,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (picked == null) return null;

      onProgress?.call(0.05);

      final Uint8List bytes = await picked.readAsBytes();

      // 50MB limit
      if (bytes.length > 50 * 1024 * 1024) {
        debugPrint('Video too large: ${bytes.length} bytes');
        return null;
      }

      final String fileName = picked.name.isNotEmpty
          ? picked.name
          : 'vid_${DateTime.now().millisecondsSinceEpoch}.mp4';

      onProgress?.call(0.15);

      final String authHeader =
          'Basic ${base64Encode(utf8.encode('$_privateKey:'))}';

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.headers['Authorization'] = authHeader;
      request.fields['fileName'] = fileName;
      request.fields['folder'] = folder;
      request.fields['publicKey'] = _publicKey;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      onProgress?.call(0.3);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      onProgress?.call(0.9);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String url = data['url'] as String;
        onProgress?.call(1.0);
        debugPrint('ImageKit video upload success: $url');
        return url;
      } else {
        debugPrint(
          'ImageKit video upload failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('ImageKit video upload error: $e');
      return null;
    }
  }
}
