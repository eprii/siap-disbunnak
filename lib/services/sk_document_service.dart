import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';
import 'profile_completion_service.dart';

class SkDocumentService {
  SkDocumentService._();

  static final SkDocumentService instance =
      SkDocumentService._();

  static const String _bucket = 'sk';
  static const int maxFileBytes = 3 * 1024 * 1024;

  final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  SupabaseClient get _supabase =>
      Supabase.instance.client;

  Future<String> createDocument({
    required String collection,
    required String storageFolder,
    required Uint8List fileBytes,
    required String originalFileName,
    required Map<String, dynamic> data,
  }) async {
    final firebase_auth.User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      throw const SkDocumentException(
        'Sesi pengguna tidak ditemukan. Silakan login kembali.',
      );
    }

    try {
      await ProfileCompletionService.instance.requireCompleteProfile(
        actionLabel: 'mengunggah dokumen SK',
      );
    } on ProfileCompletionException catch (error) {
      throw SkDocumentException(error.message);
    }

    if (fileBytes.isEmpty) {
      throw const SkDocumentException(
        'File PDF kosong atau tidak dapat dibaca.',
      );
    }

    if (fileBytes.length > maxFileBytes) {
      throw const SkDocumentException(
        'Ukuran PDF maksimal 3 MB.',
      );
    }

    final String cleanCollection = collection.trim();
    final String cleanFolder = _safeSegment(storageFolder);
    final String safeFileName =
        _safePdfFileName(originalFileName);

    if (cleanCollection.isEmpty || cleanFolder.isEmpty) {
      throw const SkDocumentException(
        'Jenis dokumen SK tidak valid.',
      );
    }

    final String uid = currentUser.uid;
    final String storagePath =
        '$uid/$cleanFolder/'
        '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    bool uploaded = false;

    try {
      final String? token =
          await currentUser.getIdToken(false);

      if (token == null || token.trim().isEmpty) {
        throw const SkDocumentException(
          'Token Firebase tidak tersedia. Silakan login kembali.',
        );
      }

      await _supabase.storage.from(_bucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'application/pdf',
              cacheControl: '3600',
            ),
          );
      uploaded = true;

      final DocumentReference<Map<String, dynamic>> documentRef =
          _db.collection(cleanCollection).doc();

      await documentRef.set(
        <String, dynamic>{
          ...data,
          'owner_id': uid,
          'file_pdf': storagePath,
          'file_name': originalFileName.trim().isEmpty
              ? safeFileName
              : originalFileName.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        },
      );

      try {
        await NotificationService.instance.notifySkSubmitted(
          ownerId: uid,
          collection: cleanCollection,
          documentId: documentRef.id,
        );
      } catch (_) {
        // Notifikasi bersifat best effort dan tidak membatalkan upload SK.
      }

      return storagePath;
    } on StorageException catch (error) {
      throw SkDocumentException(
        _storageMessage(error),
      );
    } on FirebaseException catch (error) {
      if (uploaded) {
        await _deleteSilently(storagePath);
      }

      if (error.code == 'permission-denied') {
        throw const SkDocumentException(
          'Firestore menolak penyimpanan SK. '
          'Pastikan rules collection SK sudah dipublikasikan.',
        );
      }

      throw SkDocumentException(
        error.message ??
            'Firestore gagal menyimpan metadata SK.',
      );
    } on SkDocumentException {
      if (uploaded) {
        await _deleteSilently(storagePath);
      }
      rethrow;
    } catch (error) {
      if (uploaded) {
        await _deleteSilently(storagePath);
      }

      throw SkDocumentException(
        'Gagal menyimpan dokumen SK: $error',
      );
    }
  }

  Future<void> _deleteSilently(String storagePath) async {
    try {
      await _supabase.storage
          .from(_bucket)
          .remove(<String>[storagePath]);
    } catch (_) {
      // Cleanup best effort.
    }
  }

  static String _storageMessage(StorageException error) {
    final String message = error.message.trim();
    final String lower = message.toLowerCase();

    if (lower.contains('row-level security') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('permission')) {
      return 'Supabase Storage menolak upload PDF. '
          'Jalankan policy bucket "sk" yang disertakan.';
    }

    if (lower.contains('bucket') &&
        lower.contains('not found')) {
      return 'Bucket Supabase "sk" belum dibuat.';
    }

    if (lower.contains('jwt') || lower.contains('token')) {
      return 'Token Firebase tidak diterima Supabase. '
          'Logout lalu login kembali.';
    }

    return message.isEmpty
        ? 'Gagal mengunggah PDF ke Supabase Storage.'
        : message;
  }

  static String _safeSegment(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  static String _safePdfFileName(String fileName) {
    String result = fileName.trim();

    if (result.isEmpty) {
      result = 'dokumen_sk.pdf';
    }

    result = result.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    if (!result.toLowerCase().endsWith('.pdf')) {
      result = '$result.pdf';
    }

    return result;
  }
}

class SkDocumentException implements Exception {
  final String message;

  const SkDocumentException(this.message);

  @override
  String toString() => message;
}
