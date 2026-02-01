import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Remove.bg API Service
/// Handles background removal for clothing images
class RemoveBgService {
  static const String _apiKey = 'Mik1b9PRzcAQxskFudMhUhSh';
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';

  /// Remove background from image file
  /// Returns processed image as Uint8List (PNG format)
  Future<Uint8List?> removeBackground({
    dynamic imageFile, // File on mobile, Uint8List on web (optional if imageUrl provided)
    String? imageUrl, // Alternative: provide image URL
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['X-Api-Key'] = _apiKey;

      if (imageUrl != null) {
        // Use image URL
        request.fields['image_url'] = imageUrl;
        request.fields['size'] = 'auto';
      } else if (imageFile != null) {
        // Use image file
        if (kIsWeb) {
          // Web: Uint8List only
          if (imageFile is Uint8List) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'image_file',
                imageFile,
                filename: 'image.jpg',
              ),
            );
          } else {
            throw Exception('Invalid image file type for web. Expected Uint8List.');
          }
        } else {
          // Mobile: File from dart:io or Uint8List
          // Use dynamic type check since File is platform-specific
          if (imageFile is Uint8List) {
            request.files.add(
              http.MultipartFile.fromBytes(
                'image_file',
                imageFile,
                filename: 'image.jpg',
              ),
            );
          } else {
            // Try to handle as File (dart:io) - only available on mobile
            try {
              // On mobile, File has readAsBytes() method
              final fileBytes = await (imageFile as dynamic).readAsBytes();
              final filePath = (imageFile as dynamic).path as String;
              request.files.add(
                http.MultipartFile.fromBytes(
                  'image_file',
                  fileBytes,
                  filename: filePath.split('/').last,
                ),
              );
            } catch (e) {
              throw Exception('Invalid image file type. Expected File or Uint8List: $e');
            }
          }
        }
        request.fields['size'] = 'auto';
      } else {
        throw Exception('Either imageFile or imageUrl must be provided');
      }

      final response = await request.send();
      final responseBody = await response.stream.toBytes();

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        final errorText = utf8.decode(responseBody);
        print('❌ Remove.bg API error: ${response.statusCode} - $errorText');
        return null;
      }
    } catch (e) {
      print('❌ Remove.bg service error: $e');
      return null;
    }
  }

  /// Remove background from image URL
  /// Returns processed image as Uint8List (PNG format)
  Future<Uint8List?> removeBackgroundFromUrl(String imageUrl) async {
    return removeBackground(imageUrl: imageUrl);
  }
}
