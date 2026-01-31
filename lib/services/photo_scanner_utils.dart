// lib/services/photo_scanner_utils.dart

import 'dart:io';
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Result from a slice scan, includes barcodes and their offset for coordinate mapping
class SliceScanResult {
  final List<Barcode> barcodes;
  final int offsetY;
  final double scale;
  final String tag;

  SliceScanResult({
    required this.barcodes,
    required this.offsetY,
    required this.scale,
    required this.tag,
  });
}

/// Unified barcode result with original image coordinates
class PhotoBarcode {
  final Barcode barcode;
  final Rect? originalBoundingBox;

  PhotoBarcode({
    required this.barcode,
    this.originalBoundingBox,
  });
}

/// Utility class for enhanced photo scanning with smart strategy
class PhotoScannerUtils {
  /// Maximum width for processed slices (for performance)
  static const int _maxSliceWidth = 1200;

  /// JPEG quality for temp slice files (80 is sufficient for recognition)
  static const int _jpegQuality = 80;

  /// Overlap ratio for slices (50% overlap)
  static const double _overlapRatio = 0.5;

  /// Minimum image dimension to consider triple-cut strategy
  /// Images smaller than this won't benefit from cutting
  static const int _minSizeForTripleCut = 800;

  /// Smart scan: uses appropriate strategy based on image size
  /// - Small images (< 800px): full image scan only (cutting would hurt recognition)
  /// - Large images (>= 800px): triple-cut to find all QR codes
  /// Returns all unique barcodes found with original coordinates
  static Future<List<PhotoBarcode>> scanAllWithTripleCut(
    String path,
    BarcodeScanner scanner,
  ) async {
    // 1. Read and decode image in isolate
    final bytes = await File(path).readAsBytes();
    var original = await compute(_decodeImage, bytes);
    if (original == null) return [];

    // 2. Handle EXIF orientation (bakeOrientation is a no-op if no orientation tag)
    original = img.bakeOrientation(original);

    final originalWidth = original.width;
    final originalHeight = original.height;

    // 3. Smart Strategy based on image size
    // Small images: full scan only (cutting small images hurts recognition)
    if (originalWidth < _minSizeForTripleCut && originalHeight < _minSizeForTripleCut) {
      return _scanFullImage(path, scanner, originalWidth, originalHeight);
    }

    // 4. Large images: use triple-cut to ensure all QR codes are found
    // Triple-cut with 50% overlap ensures each code is fully contained in at least one slice
    return _scanWithTripleCut(original, scanner, originalWidth, originalHeight);
  }

  /// Scan full image directly (most efficient for simple cases)
  static Future<List<PhotoBarcode>> _scanFullImage(
    String path,
    BarcodeScanner scanner,
    int originalWidth,
    int originalHeight,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final barcodes = await scanner.processImage(inputImage);

      if (barcodes.isEmpty) return [];

      // Convert to PhotoBarcode with bounding boxes (already in original coordinates)
      return barcodes
          .where((b) => b.rawValue != null && b.rawValue!.isNotEmpty)
          .map((barcode) => PhotoBarcode(
                barcode: barcode,
                originalBoundingBox: barcode.boundingBox,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Triple-cut parallel scan for large images where full scan failed
  static Future<List<PhotoBarcode>> _scanWithTripleCut(
    img.Image original,
    BarcodeScanner scanner,
    int originalWidth,
    int originalHeight,
  ) async {
    // Calculate slice parameters
    final windowHeight = (originalHeight * _overlapRatio).toInt();
    final targetWidth = originalWidth > _maxSliceWidth ? _maxSliceWidth : originalWidth;
    final scale = targetWidth / originalWidth;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Define three slice tasks (50% overlap strategy)
    // Bottom slice: covers bottom 50%
    // Center slice: covers middle 50%
    // Top slice: covers top 50%
    final List<Future<SliceScanResult>> tasks = [
      _processSlice(
        original: original,
        y: originalHeight - windowHeight, // Bottom
        height: windowHeight,
        targetWidth: targetWidth,
        scale: scale,
        tempPath: '${tempDir.path}/scan_${timestamp}_bottom.jpg',
        scanner: scanner,
        tag: 'bottom',
      ),
      _processSlice(
        original: original,
        y: (originalHeight * 0.25).toInt(), // Center
        height: windowHeight,
        targetWidth: targetWidth,
        scale: scale,
        tempPath: '${tempDir.path}/scan_${timestamp}_center.jpg',
        scanner: scanner,
        tag: 'center',
      ),
      _processSlice(
        original: original,
        y: 0, // Top
        height: windowHeight,
        targetWidth: targetWidth,
        scale: scale,
        tempPath: '${tempDir.path}/scan_${timestamp}_top.jpg',
        scanner: scanner,
        tag: 'top',
      ),
    ];

    // Parallel execution
    final results = await Future.wait(tasks);

    // Aggregate and deduplicate results
    final uniqueBarcodes = <String, PhotoBarcode>{};

    for (final result in results) {
      for (final barcode in result.barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue == null || rawValue.isEmpty) continue;

        // Only add if not already seen (deduplication by content)
        if (!uniqueBarcodes.containsKey(rawValue)) {
          // Map bounding box back to original image coordinates
          final sliceBox = barcode.boundingBox;

          // Convert slice coordinates back to original image coordinates
          final boxLeft = sliceBox.left / result.scale;
          final boxTop = (sliceBox.top / result.scale) + result.offsetY;
          final boxWidth = sliceBox.width / result.scale;
          final boxHeight = sliceBox.height / result.scale;

          final originalBox = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);

          uniqueBarcodes[rawValue] = PhotoBarcode(
            barcode: barcode,
            originalBoundingBox: originalBox,
          );
        }
      }
    }

    return uniqueBarcodes.values.toList();
  }

  /// Process a single slice of the image
  static Future<SliceScanResult> _processSlice({
    required img.Image original,
    required int y,
    required int height,
    required int targetWidth,
    required double scale,
    required String tempPath,
    required BarcodeScanner scanner,
    required String tag,
  }) async {
    try {
      // Ensure y and height are within bounds
      final safeY = y.clamp(0, original.height - 1);
      final safeHeight = (height).clamp(1, original.height - safeY);

      // Crop the slice
      final cropped = img.copyCrop(
        original,
        x: 0,
        y: safeY,
        width: original.width,
        height: safeHeight,
      );

      // Resize for performance
      final processed = img.copyResize(cropped, width: targetWidth);

      // Save to temp file
      final jpegBytes = img.encodeJpg(processed, quality: _jpegQuality);
      await File(tempPath).writeAsBytes(jpegBytes);

      // Scan with ML Kit
      final inputImage = InputImage.fromFilePath(tempPath);
      final barcodes = await scanner.processImage(inputImage);

      // Clean up temp file
      try {
        await File(tempPath).delete();
      } catch (_) {}

      return SliceScanResult(
        barcodes: barcodes,
        offsetY: safeY,
        scale: scale,
        tag: tag,
      );
    } catch (_) {
      return SliceScanResult(
        barcodes: [],
        offsetY: y,
        scale: scale,
        tag: tag,
      );
    }
  }

  /// Decode image in isolate for better performance
  static img.Image? _decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// Quick scan without slicing (for small images or viewport crops)
  static Future<List<Barcode>> scanDirect(
    String path,
    BarcodeScanner scanner,
  ) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      return await scanner.processImage(inputImage);
    } catch (_) {
      return [];
    }
  }

  /// Determine if triple-cut scanning should be used based on image dimensions
  static Future<bool> shouldUseTripleCut(String path, {int threshold = 1500}) async {
    try {
      final bytes = await File(path).readAsBytes();
      final cmd = img.Command()..decodeImage(bytes);
      await cmd.executeThread();
      final image = cmd.outputImage;
      if (image == null) return false;

      // Use triple-cut for tall or large images
      return image.height > threshold || image.width > threshold;
    } catch (e) {
      return false;
    }
  }
}
