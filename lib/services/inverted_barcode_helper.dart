// lib/services/inverted_barcode_helper.dart

import 'dart:ui' show Rect;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

/// Helper for detecting and handling inverted barcodes
/// (light bars on dark background instead of standard dark bars on light background)
class InvertedBarcodeHelper {
  /// Check if the barcode region appears to be inverted (light bars on dark background)
  ///
  /// Returns true if the barcode appears inverted (more dark pixels than light)
  /// This works because:
  /// - Normal barcode: dark bars + light background → more light pixels after binarization
  /// - Inverted barcode: light bars + dark background → more dark pixels after binarization
  static bool isInvertedBarcode(Uint8List imageBytes, {Rect? boundingBox}) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return false;

      // If we have a bounding box, crop to that region
      img.Image region;
      if (boundingBox != null) {
        final x = boundingBox.left.clamp(0, image.width - 1).toInt();
        final y = boundingBox.top.clamp(0, image.height - 1).toInt();
        final w = boundingBox.width.clamp(1, image.width - x).toInt();
        final h = boundingBox.height.clamp(1, image.height - y).toInt();
        region = img.copyCrop(image, x: x, y: y, width: w, height: h);
      } else {
        region = image;
      }

      // Convert to grayscale and analyze
      final grayscale = img.grayscale(region);

      // Calculate histogram and find threshold using Otsu's method (simplified)
      final histogram = List<int>.filled(256, 0);
      for (final pixel in grayscale) {
        final gray = img.getLuminance(pixel).toInt().clamp(0, 255);
        histogram[gray]++;
      }

      final totalPixels = grayscale.width * grayscale.height;
      final threshold = _otsuThreshold(histogram, totalPixels);

      // Count pixels above and below threshold
      int darkPixels = 0;
      int lightPixels = 0;
      for (final pixel in grayscale) {
        final gray = img.getLuminance(pixel).toInt();
        if (gray > threshold) {
          lightPixels++;
        } else {
          darkPixels++;
        }
      }

      // If dark pixels > light pixels, it's likely an inverted barcode
      final isInverted = darkPixels > lightPixels;
      debugPrint('InvertedBarcodeHelper: dark=$darkPixels, light=$lightPixels, threshold=$threshold, inverted=$isInverted');

      return isInverted;
    } catch (e) {
      debugPrint('InvertedBarcodeHelper error: $e');
      return false;
    }
  }

  /// Get average luminance of a region's center (fast version for ghost filter)
  /// Returns luminance 0-255, or null if failed
  static double? getRegionLuminance(Uint8List imageBytes, Rect rect) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // 取中心點座標
      final centerX = (rect.left + rect.width / 2).clamp(0, image.width - 1).toInt();
      final centerY = (rect.top + rect.height / 2).clamp(0, image.height - 1).toInt();

      // 採樣中心點周圍 5x5 區域取平均亮度
      double totalLuminance = 0;
      int sampleCount = 0;
      const sampleRadius = 2; // 5x5 區域

      for (int dy = -sampleRadius; dy <= sampleRadius; dy++) {
        for (int dx = -sampleRadius; dx <= sampleRadius; dx++) {
          final x = (centerX + dx).clamp(0, image.width - 1);
          final y = (centerY + dy).clamp(0, image.height - 1);
          final pixel = image.getPixel(x, y);

          // 計算亮度 (ITU-R BT.601)
          final luminance = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
          totalLuminance += luminance;
          sampleCount++;
        }
      }

      return totalLuminance / sampleCount;
    } catch (e) {
      debugPrint('InvertedBarcodeHelper getRegionLuminance error: $e');
      return null;
    }
  }

  /// Check if a specific region of the image is inverted (fast version)
  /// Only samples center point for performance
  static bool isInvertedRegion(Uint8List imageBytes, Rect rect) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return false;

      // 取中心點座標
      final centerX = (rect.left + rect.width / 2).clamp(0, image.width - 1).toInt();
      final centerY = (rect.top + rect.height / 2).clamp(0, image.height - 1).toInt();

      // 採樣中心點周圍 5x5 區域取平均亮度
      double totalLuminance = 0;
      int sampleCount = 0;
      const sampleRadius = 2; // 5x5 區域

      for (int dy = -sampleRadius; dy <= sampleRadius; dy++) {
        for (int dx = -sampleRadius; dx <= sampleRadius; dx++) {
          final x = (centerX + dx).clamp(0, image.width - 1);
          final y = (centerY + dy).clamp(0, image.height - 1);
          final pixel = image.getPixel(x, y);

          // 計算亮度 (ITU-R BT.601)
          final luminance = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
          totalLuminance += luminance;
          sampleCount++;
        }
      }

      final avgLuminance = totalLuminance / sampleCount;

      // 亮度 < 100 → 背景暗 → 反色條碼
      final isInverted = avgLuminance < 100;
      debugPrint('InvertedBarcodeHelper: center($centerX,$centerY) luminance=$avgLuminance, inverted=$isInverted');

      return isInverted;
    } catch (e) {
      debugPrint('InvertedBarcodeHelper isInvertedRegion error: $e');
      return false;
    }
  }

  /// Crop center region and invert colors (for strobe inverted scan)
  /// cropRatio: 0.5 means center 50% of the image
  static Uint8List? cropCenterAndInvert(Uint8List imageBytes, {double cropRatio = 0.5}) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // 計算中間裁切區域
      final cropWidth = (image.width * cropRatio).toInt();
      final cropHeight = (image.height * cropRatio).toInt();
      final x = (image.width - cropWidth) ~/ 2;
      final y = (image.height - cropHeight) ~/ 2;

      // 裁切
      final cropped = img.copyCrop(image, x: x, y: y, width: cropWidth, height: cropHeight);

      // 反轉顏色
      final inverted = img.invert(cropped);

      // 編碼回 JPEG（較小品質以加速）
      return Uint8List.fromList(img.encodeJpg(inverted, quality: 80));
    } catch (e) {
      debugPrint('InvertedBarcodeHelper cropCenterAndInvert error: $e');
      return null;
    }
  }

  /// Invert image colors (for re-scanning inverted barcodes)
  static Uint8List? invertImage(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Invert colors
      final inverted = img.invert(image);

      // Encode back to JPEG
      return Uint8List.fromList(img.encodeJpg(inverted, quality: 90));
    } catch (e) {
      debugPrint('InvertedBarcodeHelper invertImage error: $e');
      return null;
    }
  }

  /// Calculate Otsu's threshold (simplified version)
  static int _otsuThreshold(List<int> histogram, int totalPixels) {
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;

    double maxVariance = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = totalPixels - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }

    return threshold;
  }
}

