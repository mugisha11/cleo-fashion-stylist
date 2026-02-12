import '../utils/io_stub.dart' if (dart.library.io) 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling file storage in Supabase Storage
class SupabaseStorageService {
  final SupabaseClient _supabase;
  
  SupabaseStorageService(this._supabase);

  /// Upload a file to Supabase Storage
  /// Accepts File (mobile) or Uint8List (web)
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file, // File on mobile, Uint8List on web
    String? contentType,
  }) async {
    try {
      Uint8List fileBytes;
      
      // Convert file to bytes (Uint8List on any platform, or File on mobile)
      if (file is Uint8List) {
        fileBytes = file;
      } else if (!kIsWeb && file is io.File) {
        fileBytes = await (file as dynamic).readAsBytes();
      } else {
        throw Exception('Invalid file type for current platform');
      }

      // Upload to Supabase Storage (on mobile with bytes, write to temp file first)
      if (!kIsWeb && file is Uint8List) {
        final tempDir = await getTemporaryDirectory();
        final fileName = path.split('/').last;
        final tempFile = io.File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileBytes);
        try {
          await _supabase.storage.from(bucket).upload(
            path,
            tempFile as dynamic,
            fileOptions: FileOptions(
              contentType: contentType ?? 'image/jpeg',
              upsert: true,
            ),
          );
        } catch (e) {
          if (e.toString().contains('Bucket not found') || e.toString().contains('does not exist')) {
            throw Exception('Storage bucket "$bucket" does not exist. Please create it in Supabase Dashboard > Storage.');
          }
          if (e.toString().contains('permission') || e.toString().contains('unauthorized') ||
              e.toString().contains('policy') || e.toString().contains('Forbidden')) {
            throw Exception('Permission denied for bucket "$bucket". Check Supabase Storage bucket policies.');
          }
          rethrow;
        } finally {
          try { await tempFile.delete(); } catch (_) {}
        }
      } else if (kIsWeb) {
        // On web, use uploadBinary with bytes
        try {
        await _supabase.storage.from(bucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'image/jpeg',
            upsert: true,
          ),
        );
        } catch (e) {
          // Check if bucket doesn't exist
          if (e.toString().contains('Bucket not found') || 
              e.toString().contains('does not exist')) {
            throw Exception('Storage bucket "$bucket" does not exist. Please create it in Supabase Dashboard > Storage.');
          }
          // Check for permission errors
          if (e.toString().contains('permission') || 
              e.toString().contains('unauthorized') ||
              e.toString().contains('policy') ||
              e.toString().contains('Forbidden')) {
            throw Exception('Permission denied for bucket "$bucket". Check Supabase Storage bucket policies. Make sure authenticated users can INSERT files.');
          }
          rethrow;
        }
      } else {
        // On mobile, always create temp file from bytes to avoid type issues
        final tempDir = await getTemporaryDirectory();
        final fileName = path.split('/').last;
        final tempFile = io.File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(fileBytes);
        try {
          // Use dynamic to avoid File type mismatch between stub and real File
          try {
          await _supabase.storage.from(bucket).upload(
            path,
            tempFile as dynamic,
            fileOptions: FileOptions(
              contentType: contentType ?? 'image/jpeg',
              upsert: true,
            ),
          );
          } catch (e) {
            // Check if bucket doesn't exist
            if (e.toString().contains('Bucket not found') || 
                e.toString().contains('does not exist')) {
              throw Exception('Storage bucket "$bucket" does not exist. Please create it in Supabase Dashboard > Storage.');
            }
            // Check for permission errors
            if (e.toString().contains('permission') || 
                e.toString().contains('unauthorized') ||
                e.toString().contains('policy') ||
                e.toString().contains('Forbidden')) {
              throw Exception('Permission denied for bucket "$bucket". Check Supabase Storage bucket policies. Make sure authenticated users can INSERT files.');
            }
            rethrow;
          }
        } finally {
          // Clean up temp file
          try {
          await tempFile.delete();
          } catch (_) {
            // Ignore cleanup errors
          }
        }
      }

      // Get public URL
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      // Provide more detailed error message
      final errorMsg = e.toString();
      if (errorMsg.contains('Bucket not found') || errorMsg.contains('does not exist')) {
        throw Exception('Storage bucket "$bucket" does not exist. Please create it in Supabase Dashboard > Storage.');
      } else if (errorMsg.contains('permission') || errorMsg.contains('unauthorized')) {
        throw Exception('Permission denied. Check Supabase Storage bucket policies.');
      } else if (errorMsg.contains('size') || errorMsg.contains('too large')) {
        throw Exception('File is too large. Maximum size is 5MB.');
      }
      throw Exception('Failed to upload file to Supabase: $e');
    }
  }

  /// Delete a file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file from Supabase: $e');
    }
  }

  /// Get public URL for a file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// List files in a bucket path
  Future<List<String>> listFiles({
    required String bucket,
    String path = '',
  }) async {
    try {
      final files = await _supabase.storage.from(bucket).list(path: path);
      return files.map((file) => file.name).toList();
    } catch (e) {
      throw Exception('Failed to list files from Supabase: $e');
    }
  }
}

