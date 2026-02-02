// lib/widgets/scan/scan_gallery_mode.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import '../../providers/settings_provider.dart';
import '../../services/barcode_parser.dart';
import '../../services/taiwan_invoice_decoder.dart';
import '../../services/photo_scanner_utils.dart';
import 'scan_models.dart';
import 'scan_action_buttons.dart';
import 'scan_ar_overlay.dart';

/// Gallery/photo scan mode widget
class ScanGalleryMode extends StatefulWidget {
  final Uint8List imageBytes;
  final String imagePath;
  final Size imageSize;
  final BarcodeParser parser;
  final VoidCallback onExit;
  final Future<void> Function(DetectedCode, ScanAction) onAction;
  final Future<void> Function(DetectedCode) onSaveCode;
  final VoidCallback onPlayBeep;

  const ScanGalleryMode({
    super.key,
    required this.imageBytes,
    required this.imagePath,
    required this.imageSize,
    required this.parser,
    required this.onExit,
    required this.onAction,
    required this.onSaveCode,
    required this.onPlayBeep,
  });

  @override
  State<ScanGalleryMode> createState() => _ScanGalleryModeState();
}

class _ScanGalleryModeState extends State<ScanGalleryMode> {
  final TransformationController _transformController = TransformationController();

  List<DetectedCode> _detectedCodes = [];
  DetectedCode? _selectedCode;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
    // 先讓圖片渲染出來，再開始掃描
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanImage());
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    // Trigger rebuild to update AR overlay positions
    if (mounted && _detectedCodes.isNotEmpty) {
      setState(() {});
    }
  }

  /// 並行掃描：ML Kit (切三塊) + ZXing 同時跑，合併結果
  Future<void> _scanImage() async {
    final path = widget.imagePath;
    final bytes = widget.imageBytes;

    if (_isScanning) return;
    setState(() => _isScanning = true);

    final startTime = DateTime.now();
    const minDisplayTime = Duration(milliseconds: 400);

    try {
      debugPrint('📸 開始並行掃描: $path');

      // 全並行：ML Kit + ZXing 同時跑
      final results = await Future.wait([
        _scanWithMLKitTripleCut(path, bytes),
        _scanWithZXing(path, bytes),
      ]);

      final mlKitCodes = results[0];
      final zxingCodes = results[1];
      debugPrint('ML Kit: ${mlKitCodes.length}, ZXing: ${zxingCodes.length}');

      // 合併結果：用 rawValue 做 key，ZXing 優先
      final merged = <String, DetectedCode>{};
      for (final code in mlKitCodes) {
        merged[code.parsed.rawValue] = code;
      }
      for (final code in zxingCodes) {
        merged[code.parsed.rawValue] = code;  // ZXing 覆蓋 ML Kit
      }

      final parsedCodes = merged.values.toList();

      // Ensure minimum display time
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minDisplayTime) {
        await Future.delayed(minDisplayTime - elapsed);
      }

      if (!mounted) return;

      if (parsedCodes.isNotEmpty) {
        final settings = context.read<SettingsProvider>();
        if (settings.sound) {
          widget.onPlayBeep();
        }
      }

      debugPrint('✅ 合併後: ${parsedCodes.length} 個碼 (耗時: ${DateTime.now().difference(startTime).inMilliseconds}ms)');

      setState(() {
        _detectedCodes = parsedCodes;
        _isScanning = false;
      });
    } catch (e, stack) {
      debugPrint('Scan error: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  /// ML Kit 掃描（使用切三塊策略 + EXIF 修正）
  Future<List<DetectedCode>> _scanWithMLKitTripleCut(String path, Uint8List bytes) async {
    final codes = <DetectedCode>[];
    mlkit.BarcodeScanner? scanner;

    try {
      debugPrint('ML Kit (切三塊): 開始掃描...');
      scanner = mlkit.BarcodeScanner(formats: [mlkit.BarcodeFormat.all]);

      // 使用 PhotoScannerUtils 的切三塊 + EXIF 修正
      final photoBarcodes = await PhotoScannerUtils.scanAllWithTripleCut(path, scanner);

      debugPrint('ML Kit (切三塊): 找到 ${photoBarcodes.length} 個');

      for (final photoBarcode in photoBarcodes) {
        final rawValue = photoBarcode.barcode.rawValue;
        if (rawValue == null || rawValue.isEmpty) continue;

        final rawBytes = photoBarcode.barcode.rawBytes;

        // 檢查是否為台灣電子發票，用 Big5 解碼
        String decodedValue = rawValue;
        if (TaiwanInvoiceDecoder.isTaiwanInvoice(rawValue, rawBytes)) {
          decodedValue = TaiwanInvoiceDecoder.getDecodedText(rawBytes, rawValue);
          debugPrint('ML Kit: 台灣發票 Big5 解碼');
        }

        final parsed = widget.parser.parse(
          rawValue: decodedValue,
          format: _mlkitFormatToMsFormat(photoBarcode.barcode.format),
        );

        codes.add(DetectedCode(
          parsed: parsed,
          boundingBox: photoBarcode.originalBoundingBox,
          imageData: bytes,
          rawBytes: rawBytes,
        ));
      }
    } catch (e) {
      debugPrint('ML Kit error: $e');
    } finally {
      scanner?.close();
    }

    return codes;
  }

  /// ZXing 掃描（整面 + 反向，全並行）
  Future<List<DetectedCode>> _scanWithZXing(String path, Uint8List bytes) async {
    final codes = <String, DetectedCode>{}; // 用 rawValue 去重

    try {
      final params = zxing.DecodeParams(
        imageFormat: zxing.ImageFormat.rgb,
        format: zxing.Format.any,
        tryHarder: true,
        tryRotate: true,
        tryInverted: true,
        isMultiScan: true,
        maxSize: 9999,
      );

      // 整面 + 反向並行
      final results = await Future.wait([
        _scanWithZXingFull(path, params),
        _scanWithZXingInverted(bytes, params),
      ]);

      codes.addAll(results[0]);
      for (final entry in results[1].entries) {
        codes.putIfAbsent(entry.key, () => entry.value);
      }
    } catch (e) {
      debugPrint('ZXing error: $e');
    }

    return codes.values.toList();
  }

  /// ZXing 整面掃描
  Future<Map<String, DetectedCode>> _scanWithZXingFull(
    String path,
    zxing.DecodeParams params,
  ) async {
    final codes = <String, DetectedCode>{};

    try {
      final result = await zxing.zx.readBarcodesImagePathString(path, params);
      for (final code in result.codes) {
        _addZxingCode(code, codes, widget.imageBytes, offsetY: 0, scale: 1.0);
      }
    } catch (e) {
      debugPrint('ZXing 整面 error: $e');
    }

    return codes;
  }

  /// ZXing 手動反向掃描（先反轉圖片顏色再掃描）
  /// 用於掃描深色背景上的淺色條碼（如黑底白字 QR Code）
  Future<Map<String, DetectedCode>> _scanWithZXingInverted(
    Uint8List bytes,
    zxing.DecodeParams params,
  ) async {
    final codes = <String, DetectedCode>{};

    try {
      debugPrint('ZXing 反向: 開始掃描...');

      // 在 isolate 中反轉圖片顏色（避免阻塞主線程）
      final invertedBytes = await compute(_invertImageInIsolate, bytes);
      if (invertedBytes == null) {
        debugPrint('ZXing 反向: 圖片反轉失敗');
        return codes;
      }

      // 寫入臨時檔案
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath = '${tempDir.path}/zxing_inverted_$timestamp.jpg';
      await File(tempPath).writeAsBytes(invertedBytes);

      try {
        // ZXing 掃描反轉後的圖片
        final result = await zxing.zx.readBarcodesImagePathString(tempPath, params);
        debugPrint('ZXing 反向: 找到 ${result.codes.length} 個');

        for (final code in result.codes) {
          _addZxingCode(code, codes, bytes, offsetY: 0, scale: 1.0);
        }
      } finally {
        // 清理臨時檔案
        try {
          await File(tempPath).delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('ZXing 反向 error: $e');
    }

    return codes;
  }

  /// 將 ZXing 掃描結果加入 codes map（含座標轉換）
  void _addZxingCode(
    zxing.Code code,
    Map<String, DetectedCode> codes,
    Uint8List bytes, {
    required int offsetY,
    required double scale,
  }) {
    if (code.text == null || code.text!.isEmpty) return;

    final rawBytes = code.rawBytes;

    // 檢查是否為台灣電子發票，用 Big5 解碼
    String rawValue = code.text!;
    if (TaiwanInvoiceDecoder.isTaiwanInvoice(rawValue, rawBytes)) {
      rawValue = TaiwanInvoiceDecoder.getDecodedText(rawBytes, rawValue);
      debugPrint('ZXing: 台灣發票 Big5 解碼');
    }

    // 已存在則跳過
    if (codes.containsKey(rawValue)) return;

    final parsed = widget.parser.parse(
      rawValue: rawValue,
      format: _zxingFormatToMsFormat(code.format),
    );

    Rect? boundingBox;
    if (code.position != null) {
      final pos = code.position!;
      // 座標轉換回原圖
      boundingBox = Rect.fromLTRB(
        pos.topLeftX.toDouble() / scale,
        pos.topLeftY.toDouble() / scale + offsetY,
        pos.bottomRightX.toDouble() / scale,
        pos.bottomRightY.toDouble() / scale + offsetY,
      );
    }

    codes[rawValue] = DetectedCode(
      parsed: parsed,
      boundingBox: boundingBox,
      imageData: bytes,
      rawBytes: rawBytes,
    );
  }

  /// 在 isolate 中反轉圖片顏色（給 ZXing 反向掃描用）
  static Uint8List? _invertImageInIsolate(Uint8List bytes) {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 反轉顏色
      final inverted = img.invert(image);

      // 編碼回 JPEG
      return Uint8List.fromList(img.encodeJpg(inverted, quality: 85));
    } catch (e) {
      return null;
    }
  }

  /// ML Kit BarcodeFormat -> mobile_scanner format
  ms.BarcodeFormat _mlkitFormatToMsFormat(mlkit.BarcodeFormat format) {
    return switch (format) {
      mlkit.BarcodeFormat.qrCode => ms.BarcodeFormat.qrCode,
      mlkit.BarcodeFormat.dataMatrix => ms.BarcodeFormat.dataMatrix,
      mlkit.BarcodeFormat.pdf417 => ms.BarcodeFormat.pdf417,
      mlkit.BarcodeFormat.aztec => ms.BarcodeFormat.aztec,
      mlkit.BarcodeFormat.ean13 => ms.BarcodeFormat.ean13,
      mlkit.BarcodeFormat.ean8 => ms.BarcodeFormat.ean8,
      mlkit.BarcodeFormat.upca => ms.BarcodeFormat.upcA,
      mlkit.BarcodeFormat.upce => ms.BarcodeFormat.upcE,
      mlkit.BarcodeFormat.code128 => ms.BarcodeFormat.code128,
      mlkit.BarcodeFormat.code39 => ms.BarcodeFormat.code39,
      mlkit.BarcodeFormat.itf => ms.BarcodeFormat.itf,
      mlkit.BarcodeFormat.codabar => ms.BarcodeFormat.codabar,
      mlkit.BarcodeFormat.code93 => ms.BarcodeFormat.code93,
      _ => ms.BarcodeFormat.unknown,
    };
  }

  /// Convert ZXing Format (int) to mobile_scanner format
  ms.BarcodeFormat _zxingFormatToMsFormat(int? format) {
    if (format == null) return ms.BarcodeFormat.unknown;
    return switch (format) {
      zxing.Format.qrCode => ms.BarcodeFormat.qrCode,
      zxing.Format.dataMatrix => ms.BarcodeFormat.dataMatrix,
      zxing.Format.pdf417 => ms.BarcodeFormat.pdf417,
      zxing.Format.aztec => ms.BarcodeFormat.aztec,
      zxing.Format.ean13 => ms.BarcodeFormat.ean13,
      zxing.Format.ean8 => ms.BarcodeFormat.ean8,
      zxing.Format.upca => ms.BarcodeFormat.upcA,
      zxing.Format.upce => ms.BarcodeFormat.upcE,
      zxing.Format.code128 => ms.BarcodeFormat.code128,
      zxing.Format.code39 => ms.BarcodeFormat.code39,
      zxing.Format.itf => ms.BarcodeFormat.itf,
      zxing.Format.codabar => ms.BarcodeFormat.codabar,
      zxing.Format.code93 => ms.BarcodeFormat.code93,
      _ => ms.BarcodeFormat.unknown,
    };
  }

  /// Save selected code and show result card
  Future<void> _saveCode(DetectedCode code) async {
    await widget.onSaveCode(code);
    if (mounted) {
      final settings = context.read<SettingsProvider>();
      if (settings.sound) {
        widget.onPlayBeep();
      }
      setState(() => _selectedCode = code);
    }
  }

  void _clearSelection() {
    setState(() => _selectedCode = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with pan support
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 1.0,
              maxScale: 3.0,
              panAxis: PanAxis.vertical,
              boundaryMargin: const EdgeInsets.symmetric(vertical: 100),
              child: Center(
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // AR overlay for detected codes
          if (_detectedCodes.isNotEmpty && !_isScanning) _buildAROverlay(),

          // Loading indicator
          if (_isScanning) _buildLoadingIndicator(),

          // Top toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(colorScheme),
          ),

          // Bottom result bar (when codes found but none selected)
          if (_detectedCodes.isNotEmpty && _selectedCode == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + bottomPadding,
              child: _buildResultBar(),
            ),

          // Selected code result card
          if (_selectedCode != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildResultCard(),
            ),

          // No codes found hint (only show after scanning completes)
          if (_detectedCodes.isEmpty && !_isScanning)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + bottomPadding,
              child: _buildNoResultHint(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        8,
        8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(180), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onExit,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAROverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final imageSize = widget.imageSize;

        // Calculate image display area (contain fit, centered)
        final imageAspect = imageSize.width / imageSize.height;
        final screenAspect = screenSize.width / screenSize.height;

        double displayWidth, displayHeight;
        double offsetX = 0, offsetY = 0;

        if (imageAspect > screenAspect) {
          displayWidth = screenSize.width;
          displayHeight = screenSize.width / imageAspect;
          offsetY = (screenSize.height - displayHeight) / 2;
        } else {
          displayHeight = screenSize.height;
          displayWidth = screenSize.height * imageAspect;
          offsetX = (screenSize.width - displayWidth) / 2;
        }

        // Get transform from InteractiveViewer
        final matrix = _transformController.value;
        final scale = matrix.getMaxScaleOnAxis();
        final translation = matrix.getTranslation();

        return Stack(
          children: _detectedCodes.where((code) => code.boundingBox != null).map((code) {
            final box = code.boundingBox!;
            final scaleX = displayWidth / imageSize.width;
            final scaleY = displayHeight / imageSize.height;

            // Calculate position with transform
            final left = (box.left * scaleX + offsetX) * scale + translation.x;
            final top = (box.top * scaleY + offsetY) * scale + translation.y;
            final width = box.width * scaleX * scale;
            final height = box.height * scaleY * scale;

            // Skip if outside screen
            if (left + width < 0 || left > screenSize.width ||
                top + height < -50 || top > screenSize.height + 50) {
              return const SizedBox.shrink();
            }

            // Calculate label position
            final labelTop = (top - 40).clamp(8.0, screenSize.height - 50);

            return Positioned(
              left: left,
              top: labelTop,
              child: GestureDetector(
                onTap: () => _saveCode(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: getTypeColor(code.parsed.semanticType),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code.parsed.semanticType.icon,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          code.parsed.displayText.length > 12
                              ? '${code.parsed.displayText.substring(0, 12)}...'
                              : code.parsed.displayText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResultBar() {
    final count = _detectedCodes.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppText.galleryFoundCodesTapToSelect(count),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.white.withAlpha(180)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppText.galleryNoCodeFound,
              style: TextStyle(color: Colors.white.withAlpha(180)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16 + bottomPadding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '⏳ ${AppText.galleryScanning}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final code = _selectedCode!;
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final backgroundColor = Color.alphaBlend(
      colorScheme.surface,
      colorScheme.brightness == Brightness.dark ? Colors.black : Colors.white,
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type label with icon + thumbnail + close button
                Row(
                  children: [
                    Text(
                      code.parsed.semanticType.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code.parsed.semanticType.label,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            code.parsed.barcodeFormat.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Thumbnail
                    if (settings.saveImage && code.imageData != null)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withAlpha(50),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          code.imageData!,
                          fit: BoxFit.cover,
                          cacheWidth: 100,
                        ),
                      ),
                    // Close button
                    IconButton(
                      onPressed: _clearSelection,
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.outline,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    code.parsed.rawValue,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      fontFamily: code.parsed.semanticType == SemanticType.isbn
                          ? 'monospace'
                          : null,
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildActionButtons(code),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(DetectedCode code) {
    final buttons = <Widget>[];

    // Copy
    buttons.add(ScanActionButton(
      icon: Icons.copy,
      label: AppText.scanCopy,
      onTap: () => widget.onAction(code, ScanAction.copy),
    ));

    // Share
    buttons.add(ScanActionButton(
      icon: Icons.share,
      label: AppText.scanShare,
      onTap: () => widget.onAction(code, ScanAction.share),
    ));

    // Type-specific action
    switch (code.parsed.semanticType) {
      case SemanticType.url:
        buttons.add(ScanActionButton(
          icon: Icons.open_in_new,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.email:
        buttons.add(ScanActionButton(
          icon: Icons.email,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.wifi:
        buttons.add(ScanActionButton(
          icon: Icons.wifi,
          label: AppText.scanConnect,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.connect),
        ));
        break;

      case SemanticType.isbn:
        buttons.add(ScanActionButton(
          icon: Icons.search,
          label: AppText.scanSearch,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.search),
        ));
        break;

      case SemanticType.vcard:
        buttons.add(ScanActionButton(
          icon: Icons.contact_page,
          label: AppText.scanSave,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.save),
        ));
        break;

      case SemanticType.sms:
        buttons.add(ScanActionButton(
          icon: Icons.sms,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.geo:
        buttons.add(ScanActionButton(
          icon: Icons.map,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => widget.onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.text:
        break;
    }

    return buttons;
  }
}
