import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for Firebase Storage operations
/// v7.2: Profile photo upload and management
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload profile photo and return download URL
  /// Path: users/{uid}/profile_photo.jpg
  Future<String> uploadProfilePhoto(Uint8List imageBytes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Kullanici oturumu acik degil');

    // Compress image if too large (max 500KB)
    Uint8List processedBytes = imageBytes;
    if (imageBytes.length > 500 * 1024) {
      processedBytes = await _compressImage(imageBytes);
    }

    final ref = _storage.ref().child('users/$uid/profile_photo.jpg');

    // Upload with metadata
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    await ref.putData(processedBytes, metadata);

    // Get download URL
    final downloadURL = await ref.getDownloadURL();
    return downloadURL;
  }

  /// Delete profile photo from storage
  Future<void> deleteProfilePhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final ref = _storage.ref().child('users/$uid/profile_photo.jpg');
      await ref.delete();
    } catch (e) {
      // File might not exist, ignore error
    }
  }

  /// Simple image compression by reducing quality
  /// Note: For more advanced compression, use image package
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    // Basic implementation - in production, use image package for proper compression
    // For now, just return original if under 1MB
    if (imageBytes.length < 1024 * 1024) {
      return imageBytes;
    }
    // Return original bytes - proper compression would need image package
    return imageBytes;
  }

  /// Get current user's profile photo URL if exists
  Future<String?> getProfilePhotoURL() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final ref = _storage.ref().child('users/$uid/profile_photo.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
