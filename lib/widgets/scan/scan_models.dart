// lib/widgets/scan/scan_models.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/barcode_parser.dart';

/// Represents a detected barcode with its parsed data and visual information
class DetectedCode {
  final ParsedBarcode parsed;
  final Rect? boundingBox;
  final Uint8List? imageData;
  final Uint8List? rawBytes;  // Raw bytes for Big5 decoding (Taiwan invoice)
  final int frameCount; // Number of frames detected, for confidence display

  DetectedCode({
    required this.parsed,
    this.boundingBox,
    this.imageData,
    this.rawBytes,
    this.frameCount = 1,
  });

  DetectedCode copyWith({
    ParsedBarcode? parsed,
    Rect? boundingBox,
    Uint8List? imageData,
    Uint8List? rawBytes,
    int? frameCount,
  }) {
    return DetectedCode(
      parsed: parsed ?? this.parsed,
      boundingBox: boundingBox ?? this.boundingBox,
      imageData: imageData ?? this.imageData,
      rawBytes: rawBytes ?? this.rawBytes,
      frameCount: frameCount ?? this.frameCount,
    );
  }
}

/// Accumulated code for multi-frame detection
/// Tracks detection count across frames for stability
class AccumulatedCode {
  DetectedCode code;
  int frameCount;
  DateTime lastSeen;

  AccumulatedCode({
    required this.code,
    required this.lastSeen,
  }) : frameCount = 1;

  void update(DetectedCode newCode, {int maxFrameCount = 10, int minFrameCount = 3}) {
    // Cap frameCount to avoid infinite growth
    if (frameCount < maxFrameCount) {
      frameCount++;
    }
    // Update bounding box only before stabilization, lock position after
    if (frameCount <= minFrameCount && newCode.boundingBox != null) {
      code = DetectedCode(
        parsed: code.parsed,
        boundingBox: newCode.boundingBox,
        imageData: newCode.imageData ?? code.imageData,
        rawBytes: newCode.rawBytes ?? code.rawBytes,
        frameCount: frameCount,
      );
    }
    lastSeen = DateTime.now();
  }
}

/// Actions available for scanned codes
enum ScanAction { copy, open, save, share, search, connect }
