import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeSkFileService {
  EmployeeSkFileService._();

  static final EmployeeSkFileService instance =
      EmployeeSkFileService._();

  static const String _bucket = 'sk';

  SupabaseClient get _client => Supabase.instance.client;

  Future<Uint8List> preparePreviewData({
    required String storagePath,
  }) {
    return _downloadBytes(storagePath);
  }

  Future<String?> downloadFile({
    required String storagePath,
    required String fileName,
  }) async {
    final Uint8List bytes = await _downloadBytes(storagePath);
    final String safeName = _safeFileName(fileName);

    try {
      return await FilePicker.saveFile(
        dialogTitle: 'Simpan dokumen SK',
        fileName: safeName,
        type: FileType.custom,
        allowedExtensions: const <String>['pdf'],
        bytes: bytes,
      );
    } catch (error) {
      throw EmployeeSkFileException(
        'Gagal menyimpan dokumen: $error',
      );
    }
  }

  Future<Uint8List> _downloadBytes(
    String storagePath,
  ) async {
    final String cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) {
      throw const EmployeeSkFileException(
        'File PDF belum tersedia.',
      );
    }

    try {
      if (cleanPath.startsWith('http://') ||
          cleanPath.startsWith('https://')) {
        return _downloadFromUrl(cleanPath);
      }

      return await _client.storage
          .from(_bucket)
          .download(cleanPath);
    } on StorageException catch (error) {
      final String lower = error.message.toLowerCase();

      if (lower.contains('unauthorized') ||
          lower.contains('forbidden') ||
          lower.contains('permission') ||
          lower.contains('row-level security')) {
        throw const EmployeeSkFileException(
          'Kamu tidak memiliki izin membuka dokumen SK ini.',
        );
      }

      throw EmployeeSkFileException(
        error.message.trim().isEmpty
            ? 'Gagal mengambil dokumen dari Storage.'
            : error.message,
      );
    } on EmployeeSkFileException {
      rethrow;
    } catch (error) {
      throw EmployeeSkFileException(
        'Gagal mengambil dokumen: $error',
      );
    }
  }

  Future<Uint8List> _downloadFromUrl(
    String url,
  ) async {
    try {
      final ByteData data = await NetworkAssetBundle(
        Uri.parse(url),
      ).load(url);

      return data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    } catch (error) {
      throw EmployeeSkFileException(
        'Gagal mengambil dokumen dari URL: $error',
      );
    }
  }

  static String _safeFileName(
    String fileName,
  ) {
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

class EmployeeSkFileException implements Exception {
  final String message;

  const EmployeeSkFileException(this.message);

  @override
  String toString() => message;
}
