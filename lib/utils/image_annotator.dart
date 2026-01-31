// lib/utils/image_annotator.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Image annotator for adding circle letter labels (A/B/C/D) to QR/Barcode images
class ImageAnnotator {
  ImageAnnotator._();

  // Label style constants
  static const int _labelSize = 48; // Circle diameter in pixels
  static const int _labelPadding = 12; // Distance from barcode edge
  static const int _labelBgColor = 0xDD000000; // Semi-transparent black (0xAARRGGBB)

  /// Letter sequence for labeling multiple codes
  static const List<String> _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  /// Get letter for index (A, B, C, ...)
  static String getLetter(int index) {
    if (index < _letters.length) {
      return _letters[index];
    }
    return (index + 1).toString(); // Fallback to numbers
  }

  /// Annotate image with circle letter labels for each detected code
  /// Returns annotated image bytes (PNG format for lossless intermediate)
  static Future<Uint8List> annotateImage(
    Uint8List imageBytes,
    List<Rect?> boundingBoxes,
    Size? previewSize,
  ) async {
    // No bounding boxes or preview size → return original
    if (boundingBoxes.isEmpty || previewSize == null) {
      return imageBytes;
    }

    // Filter out null boxes
    final validBoxes = <int, Rect>{};
    for (int i = 0; i < boundingBoxes.length; i++) {
      if (boundingBoxes[i] != null) {
        validBoxes[i] = boundingBoxes[i]!;
      }
    }

    if (validBoxes.isEmpty) {
      return imageBytes;
    }

    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }

      // Scale factors from preview to image coordinates
      final scaleX = image.width / previewSize.width;
      final scaleY = image.height / previewSize.height;

      // Dynamic label size based on image resolution
      final labelSize = (_labelSize * scaleX).round().clamp(32, 96);
      final padding = (_labelPadding * scaleX).round().clamp(8, 24);

      // Draw label for each code
      for (final entry in validBoxes.entries) {
        final index = entry.key;
        final box = entry.value;

        // Scale bounding box to image coordinates
        final scaledBox = Rect.fromLTRB(
          box.left * scaleX,
          box.top * scaleY,
          box.right * scaleX,
          box.bottom * scaleY,
        );

        // Calculate label position (prefer top-right outside the code)
        final labelPos = _calculateLabelPosition(
          scaledBox,
          Size(image.width.toDouble(), image.height.toDouble()),
          labelSize,
          padding,
        );

        // Draw circle background
        _drawFilledCircle(
          image,
          labelPos.dx.round(),
          labelPos.dy.round(),
          labelSize ~/ 2,
          img.ColorRgba8(
            (_labelBgColor >> 16) & 0xFF, // R
            (_labelBgColor >> 8) & 0xFF,  // G
            _labelBgColor & 0xFF,         // B
            (_labelBgColor >> 24) & 0xFF, // A
          ),
        );

        // Draw letter
        final letter = getLetter(index);
        _drawLetter(
          image,
          letter,
          labelPos.dx.round(),
          labelPos.dy.round(),
        );
      }

      // Encode as PNG (lossless) - final JPEG encoding done by FlutterImageCompress
      // This avoids double JPEG encoding which degrades quality
      final result = img.encodePng(image);
      return Uint8List.fromList(result);
    } catch (e) {
      debugPrint('Error annotating image: $e');
      return imageBytes;
    }
  }

  /// Calculate best position for label (avoiding going outside image bounds)
  /// Priority: top-right → top-left → bottom-right → bottom-left
  static Offset _calculateLabelPosition(
    Rect box,
    Size imageSize,
    int labelSize,
    int padding,
  ) {
    final halfLabel = labelSize / 2;

    // Try positions in priority order
    final positions = [
      // Top-right (outside box)
      Offset(box.right + padding + halfLabel, box.top - padding - halfLabel),
      // Top-left (outside box)
      Offset(box.left - padding - halfLabel, box.top - padding - halfLabel),
      // Bottom-right (outside box)
      Offset(box.right + padding + halfLabel, box.bottom + padding + halfLabel),
      // Bottom-left (outside box)
      Offset(box.left - padding - halfLabel, box.bottom + padding + halfLabel),
      // Top-right (inside box corner) - fallback
      Offset(box.right - halfLabel - 4, box.top + halfLabel + 4),
    ];

    for (final pos in positions) {
      if (_isValidPosition(pos, imageSize, halfLabel)) {
        return pos;
      }
    }

    // Ultimate fallback: center of box
    return Offset(box.center.dx, box.center.dy);
  }

  /// Check if label position is within image bounds
  static bool _isValidPosition(Offset center, Size imageSize, double radius) {
    return center.dx - radius >= 0 &&
           center.dx + radius <= imageSize.width &&
           center.dy - radius >= 0 &&
           center.dy + radius <= imageSize.height;
  }

  /// Draw a filled circle on the image
  static void _drawFilledCircle(
    img.Image image,
    int centerX,
    int centerY,
    int radius,
    img.Color color,
  ) {
    // Use image package's fillCircle
    img.fillCircle(
      image,
      x: centerX,
      y: centerY,
      radius: radius,
      color: color,
    );
  }

  /// Draw a letter centered at the given position
  /// Uses arial48 built-in font (largest available in image package)
  static void _drawLetter(
    img.Image image,
    String letter,
    int centerX,
    int centerY,
  ) {
    // arial48 characters are roughly 24px wide and 48px tall
    const charWidth = 24;
    const charHeight = 48;
    final textX = centerX - (charWidth ~/ 2);
    final textY = centerY - (charHeight ~/ 2);

    img.drawString(
      image,
      letter,
      font: img.arial48,
      x: textX,
      y: textY,
      color: img.ColorRgba8(255, 255, 255, 255), // White
    );
  }
}
