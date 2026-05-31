import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';

/// Uploads / deletes receipt images via the backend `/uploads/receipt`
/// endpoints (which proxy to S3, with a local-disk dev fallback).
class ReceiptRepository {
  ReceiptRepository(this._client);
  final DioClient _client;

  /// Upload compressed image [bytes] and return the stored URL.
  Future<String> upload({
    required Uint8List bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _client.raw.post('/uploads/receipt', data: form);
    final data = res.data;
    if (data is Map && data['ok'] == true && data['data'] is Map) {
      final url = (data['data']['url'] ?? '').toString();
      if (url.isNotEmpty) return url;
    }
    throw Exception('Receipt upload failed');
  }

  /// Best-effort delete of an orphaned receipt (uploaded but never attached
  /// because the expense save failed). Never throws.
  Future<void> delete(String url) async {
    if (url.isEmpty) return;
    try {
      await _client.raw.delete('/uploads/receipt', data: {'url': url});
    } catch (_) {
      // Cleanup is best-effort; a leftover object is harmless.
    }
  }
}

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(DioClient.instance),
);
