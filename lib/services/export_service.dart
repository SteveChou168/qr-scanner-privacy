// lib/services/export_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/scan_record.dart';

enum ExportAction { saveToDevice, share }

class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;

  ExportResult({required this.success, this.filePath, this.error});
}

class ExportService {
  static String _escapeCSV(String value) {
    // Escape quotes and handle special characters
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Build CSV content from records
  static String buildCsvContent(List<ScanRecord> records) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('ID,Type,Format,Content,DisplayText,Timestamp,Place,Favorite');

    // Data rows
    for (final r in records) {
      buffer.writeln([
        r.id.toString(),
        r.semanticType.name,
        r.barcodeFormat.name,
        _escapeCSV(r.rawText),
        _escapeCSV(r.displayText ?? ''),
        r.scannedAt.toIso8601String(),
        _escapeCSV(r.placeName ?? ''),
        r.isFavorite ? '1' : '0',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Build JSON content from records
  static String buildJsonContent(List<ScanRecord> records) {
    final data = records.map((r) => {
      'id': r.id,
      'type': r.semanticType.name,
      'format': r.barcodeFormat.name,
      'rawText': r.rawText,
      'displayText': r.displayText,
      'scannedAt': r.scannedAt.toIso8601String(),
      'placeName': r.placeName,
      'isFavorite': r.isFavorite,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'recordCount': records.length,
      'records': data,
    });
  }

  /// Export records to CSV with chosen action
  static Future<ExportResult> exportToCsv(
    List<ScanRecord> records,
    ExportAction action,
  ) async {
    try {
      final content = buildCsvContent(records);
      if (action == ExportAction.saveToDevice) {
        final file = await _writeToDownloads(content, 'csv');
        return ExportResult(success: true, filePath: file.path);
      } else {
        final file = await _writeToTemp(content, 'csv');
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: 'QR Scanner Export',
        ));
        return ExportResult(success: true);
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Export records to JSON with chosen action
  static Future<ExportResult> exportToJson(
    List<ScanRecord> records,
    ExportAction action,
  ) async {
    try {
      final content = buildJsonContent(records);
      if (action == ExportAction.saveToDevice) {
        final file = await _writeToDownloads(content, 'json');
        return ExportResult(success: true, filePath: file.path);
      } else {
        final file = await _writeToTemp(content, 'json');
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: 'QR Scanner Export',
        ));
        return ExportResult(success: true);
      }
    } catch (e) {
      debugPrint('Error exporting JSON: $e');
      return ExportResult(success: false, error: e.toString());
    }
  }

  /// Write to Downloads directory (most intuitive for users)
  static Future<File> _writeToDownloads(String content, String extension) async {
    Directory? downloadDir;

    if (Platform.isAndroid) {
      // Android: Use public Downloads directory
      downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        // Fallback to external storage
        downloadDir = await getExternalStorageDirectory();
      }
    } else {
      // iOS: Use Documents directory (no public Downloads)
      downloadDir = await getApplicationDocumentsDirectory();
    }

    downloadDir ??= await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${downloadDir.path}/qr_export_$timestamp.$extension');
    await file.writeAsString(content);
    return file;
  }

  /// Write to temp directory (for sharing)
  static Future<File> _writeToTemp(String content, String extension) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/qr_export_$timestamp.$extension');
    await file.writeAsString(content);
    return file;
  }
}
