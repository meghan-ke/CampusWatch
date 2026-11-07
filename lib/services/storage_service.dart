// lib/services/storage_service.dart
// Uploads incident photos to Cloudinary (free image hosting) and returns
// their links. The links are then saved on the incident in Firestore, so the
// rest of the app does not care where the files live.
//
// Uses an UNSIGNED upload preset, so no secret key is needed in the app.
// The preset (set in the Cloudinary dashboard) decides the target folder.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';

/// A readable error that can be shown directly to the user.
class ImageUploadException implements Exception {
  const ImageUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StorageService {
  StorageService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Uploads every picked photo and returns their https links, in order.
  /// Throws [ImageUploadException] or [TimeoutException] on failure.
  /// [incidentId] is kept so callers do not change; it names each file.
  Future<List<String>> uploadIncidentImages({
    required String incidentId,
    required List<XFile> images,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      urls.add(await _uploadOne(incidentId, images[i], i));
    }
    return urls;
  }

  Future<String> _uploadOne(String incidentId, XFile image, int index) async {
    // Bytes (not a file path) work on Android, iOS and web.
    final bytes = await image.readAsBytes();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}'
      '/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          // The report id in the name makes photos easy to match to reports.
          filename: '${incidentId}_$index.jpg',
        ),
      );

    final streamed = await _client.send(request).timeout(
          const Duration(seconds: 30),
        );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw ImageUploadException(
        'Photo upload failed: ${_errorFrom(response)}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final url = body['secure_url'] as String?;
    if (url == null) {
      throw const ImageUploadException('Photo upload failed: no link returned.');
    }
    return url;
  }

  /// Cloudinary explains problems in the response body; show that text.
  String _errorFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      return error?['message']?.toString() ?? 'HTTP ${response.statusCode}';
    } catch (_) {
      return 'HTTP ${response.statusCode}';
    }
  }
}