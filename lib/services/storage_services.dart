// lib/services/storage_service.dart
import 'dart:typed_data';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final String bucketName = 'foto_alat';

  /// Upload image to Supabase Storage
  /// Returns public URL of uploaded image
  Future<String> uploadImage({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = 'alat_${timestamp}.$extension';

      // Detect MIME type
      final mimeType =
          lookupMimeType(fileName, headerBytes: fileBytes) ?? 'image/jpeg';

      if (kDebugMode) {
        print('📤 Uploading image: $uniqueFileName');
        print('📦 File size: ${fileBytes.length} bytes');
        print('🎨 MIME type: $mimeType');
      }

      // Upload to Supabase Storage
      final uploadPath = await supabase.storage
          .from(bucketName)
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      if (kDebugMode) {
        print('✅ Upload success: $uploadPath');
      }

      // Get URL (signed for web, public for mobile)
      String finalUrl;
      if (kIsWeb) {
        // Use signed URL for web to bypass CORS
        finalUrl = await supabase.storage
            .from(bucketName)
            .createSignedUrl(uniqueFileName, 31536000); // 1 year
        if (kDebugMode) {
          print('🔗 Signed URL (Web): $finalUrl');
        }
      } else {
        // Use public URL for mobile
        finalUrl = supabase.storage
            .from(bucketName)
            .getPublicUrl(uniqueFileName);
        if (kDebugMode) {
          print('🔗 Public URL (Mobile): $finalUrl');
        }
      }

      return finalUrl;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Upload error: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Gagal upload gambar: ${e.toString()}');
    }
  }

  /// Delete image from Supabase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (!isSupabaseUrl(imageUrl)) {
        if (kDebugMode) {
          print('⚠️ URL bukan dari Supabase Storage, skip delete: $imageUrl');
        }
        return;
      }

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // URL format: .../storage/v1/object/public/foto_alat/filename.jpg
      final publicIndex = pathSegments.indexOf('public');
      if (publicIndex == -1 || publicIndex >= pathSegments.length - 2) {
        if (kDebugMode) {
          print('⚠️ Invalid URL format, cannot extract filename: $imageUrl');
        }
        return;
      }

      // Get filename (skip 'public' and bucket name)
      final fileName = pathSegments.sublist(publicIndex + 2).join('/');

      if (kDebugMode) {
        print('🗑️ Deleting image: $fileName');
      }

      // Delete from storage
      await supabase.storage.from(bucketName).remove([fileName]);

      if (kDebugMode) {
        print('✅ Image deleted successfully');
      }
    } catch (e) {
      // Silently fail if deletion fails (image might be external URL)
      if (kDebugMode) {
        print('⚠️ Could not delete image: ${e.toString()}');
      }
    }
  }

  /// Validate if URL is from our Supabase Storage
  bool isSupabaseUrl(String url) {
    try {
      // Check if URL is from Supabase Storage and our bucket
      return url.contains('supabase.co/storage/v1/object/public/$bucketName') ||
          url.contains('supabase.co/storage/v1/object/sign/$bucketName');
    } catch (e) {
      return false;
    }
  }

  /// Get signed URL with expiration (better for web CORS)
  Future<String> getSignedUrl(
    String fileName, {
    int expiresIn = 31536000,
  }) async {
    try {
      final signedUrl = await supabase.storage
          .from(bucketName)
          .createSignedUrl(fileName, expiresIn); // 1 year

      return signedUrl;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to get signed URL, fallback to public URL');
      }
      // Fallback to public URL
      return supabase.storage.from(bucketName).getPublicUrl(fileName);
    }
  }

  /// Test connection to storage bucket
  Future<bool> testBucketAccess() async {
    try {
      // Try to list files in bucket (will fail if no access)
      await supabase.storage.from(bucketName).list();
      if (kDebugMode) {
        print('✅ Bucket access OK');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Bucket access failed: $e');
      }
      return false;
    }
  }
}
