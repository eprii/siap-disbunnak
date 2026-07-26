
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final SupabaseStorageService instance =
      SupabaseStorageService._internal();

  factory SupabaseStorageService() {
    return instance;
  }

  SupabaseStorageService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadSKPdf({
    required File file,
    required String uid,
    required String jenisSK,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.pdf';

    final path = '$uid/$jenisSK/$fileName';

    await _client.storage
        .from('surat-keputusan')
        .upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return path;
  }

  Future<String> createSignedUrl(String path) async {
    return await _client.storage
        .from('surat-keputusan')
        .createSignedUrl(
          path,
          3600,
        );
  }

  Future<void> deleteFile(String path) async {
    await _client.storage
        .from('surat-keputusan')
        .remove([path]);
  }
}
