import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Tiny CSV helper used by export features (e.g. the personal tracker). Builds
/// an RFC-4180-ish CSV string and shares it as a downloadable file so the user
/// can open it in a spreadsheet for their own calculations.
class CsvExport {
  /// Quote a single field only when it contains a comma, quote, or newline,
  /// doubling any embedded quotes — the standard CSV escaping.
  static String _cell(Object? value) {
    final s = value?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Build a CSV document from a header row and data rows.
  static String build({required List<String> header, required List<List<Object?>> rows}) {
    final buffer = StringBuffer();
    buffer.writeln(header.map(_cell).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_cell).join(','));
    }
    return buffer.toString();
  }

  /// Write [csv] to a temp file named [fileName] and open the share sheet.
  /// Returns false if sharing isn't possible (e.g. unsupported platform).
  static Future<bool> share({
    required String csv,
    required String fileName,
    String? subject,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: fileName)],
        subject: subject,
      );
      return true;
    } catch (e) {
      debugPrint('CSV share failed: $e');
      return false;
    }
  }
}
