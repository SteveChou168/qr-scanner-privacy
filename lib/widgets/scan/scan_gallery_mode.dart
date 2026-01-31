// lib/widgets/scan/scan_gallery_mode.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:provider/provider.dart';

import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import '../../providers/settings_provider.dart';
import '../../services/barcode_parser.dart';
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
    _scanImage();
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

  /// Scan the gallery image using ML Kit with triple-cut parallel processing
  Future<void> _scanImage() async {
    final path = widget.imagePath;
    final bytes = widget.imageBytes;

    if (_isScanning) return;
    setState(() => _isScanning = true);

    final startTime = DateTime.now();
    const minDisplayTime = Duration(milliseconds: 400);

    try {
      final barcodeScanner = mlkit.BarcodeScanner(formats: [
        mlkit.BarcodeFormat.all,
      ]);

      // Full image scan with triple-cut parallel processing
      final photoBarcodes = await PhotoScannerUtils.scanAllWithTripleCut(
        path,
        barcodeScanner,
      );

      barcodeScanner.close();

      // Ensure minimum display time for smooth transition
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minDisplayTime) {
        await Future.delayed(minDisplayTime - elapsed);
      }

      if (!mounted) return;

      if (photoBarcodes.isEmpty) {
        setState(() {
          _detectedCodes = [];
          _isScanning = false;
        });
        return;
      }

      // Process detected barcodes
      final parsedCodes = <DetectedCode>[];

      for (final photoBarcode in photoBarcodes) {
        final rawValue = photoBarcode.barcode.rawValue;
        if (rawValue == null || rawValue.isEmpty) continue;

        final parsed = widget.parser.parse(
          rawValue: rawValue,
          format: _mlkitFormatToMsFormat(photoBarcode.barcode.format),
        );

        parsedCodes.add(DetectedCode(
          parsed: parsed,
          boundingBox: photoBarcode.originalBoundingBox,
          imageData: bytes,
        ));
      }

      // Play sound if codes found
      if (parsedCodes.isNotEmpty) {
        final settings = context.read<SettingsProvider>();
        if (settings.sound) {
          widget.onPlayBeep();
        }
      }

      setState(() {
        _detectedCodes = parsedCodes;
        _isScanning = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  /// Convert ML Kit BarcodeFormat to mobile_scanner format
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
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppText.galleryFoundCodesTapToSelect(count),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppText.galleryScanning,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
