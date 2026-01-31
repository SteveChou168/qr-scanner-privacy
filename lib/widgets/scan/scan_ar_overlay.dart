// lib/widgets/scan/scan_ar_overlay.dart

import 'package:flutter/material.dart';
import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import 'scan_models.dart';
import 'scan_action_buttons.dart';

/// Utility function to scale a rect from one size to another
Rect scaleRect(Rect rect, Size fromSize, Size toSize) {
  final scaleX = toSize.width / fromSize.width;
  final scaleY = toSize.height / fromSize.height;

  return Rect.fromLTRB(
    rect.left * scaleX,
    rect.top * scaleY,
    rect.right * scaleX,
    rect.bottom * scaleY,
  );
}

/// Get color for semantic type
Color getTypeColor(SemanticType type) {
  return switch (type) {
    SemanticType.url => Colors.blue,
    SemanticType.email => Colors.orange,
    SemanticType.wifi => Colors.purple,
    SemanticType.isbn => Colors.brown,
    SemanticType.vcard => Colors.teal,
    SemanticType.sms => Colors.pink,
    SemanticType.geo => Colors.indigo,
    SemanticType.text => Colors.grey,
  };
}

/// AR overlay showing detected codes with tap-to-select
class ScanArOverlay extends StatelessWidget {
  final List<DetectedCode> detectedCodes;
  final Size previewSize;
  final int stableFrameCount;
  final Function(DetectedCode) onCodeTap;

  const ScanArOverlay({
    super.key,
    required this.detectedCodes,
    required this.previewSize,
    required this.onCodeTap,
    this.stableFrameCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        const overlayHeight = 44.0;
        const overlapThreshold = 50.0; // Overlap detection threshold

        // Calculate default positions for all overlays
        final codes = detectedCodes.where((code) => code.boundingBox != null).toList();
        final positions = <int, bool>{}; // index -> whether to show below

        for (int i = 0; i < codes.length; i++) {
          final box = scaleRect(codes[i].boundingBox!, previewSize, screenSize);
          positions[i] = false; // Default: show above

          // Check overlap with previous overlays
          for (int j = 0; j < i; j++) {
            final otherBox = scaleRect(codes[j].boundingBox!, previewSize, screenSize);
            final verticalDiff = (box.top - otherBox.top).abs();
            final horizontalDiff = (box.left - otherBox.left).abs();

            // If both vertical and horizontal distance are close, consider overlapping
            if (verticalDiff < overlapThreshold && horizontalDiff < 120) {
              // Move current overlay below the QR Code
              positions[i] = true;
              break;
            }
          }
        }

        return Stack(
          children: codes.asMap().entries.map((entry) {
            final index = entry.key;
            final code = entry.value;
            final box = scaleRect(code.boundingBox!, previewSize, screenSize);
            final showBelow = positions[index] ?? false;

            // Opacity based on frame count (more frames = more opaque)
            final isStable = code.frameCount >= stableFrameCount;
            final opacity = isStable ? 1.0 : (0.4 + (code.frameCount / stableFrameCount) * 0.4);

            return Positioned(
              left: box.left,
              top: showBelow ? box.bottom + 4 : box.top - overlayHeight,
              child: GestureDetector(
                onTap: isStable ? () => onCodeTap(code) : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: opacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isStable
                            ? getTypeColor(code.parsed.semanticType)
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Detecting spinner or icon
                        if (!isStable)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          )
                        else
                          Text(
                            code.parsed.semanticType.icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            isStable
                                ? (code.parsed.displayText.length > 12
                                    ? '${code.parsed.displayText.substring(0, 12)}...'
                                    : code.parsed.displayText)
                                : AppText.detecting,
                            style: TextStyle(
                              color: isStable ? Colors.white : Colors.white54,
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
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// AR result card shown when a code is selected
class ScanArResultCard extends StatelessWidget {
  final DetectedCode code;
  final bool showThumbnail;
  final VoidCallback onClose;
  final Function(DetectedCode, ScanAction) onAction;

  const ScanArResultCard({
    super.key,
    required this.code,
    required this.onClose,
    required this.onAction,
    this.showThumbnail = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Ensure fully opaque background
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
                    if (showThumbnail && code.imageData != null)
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
                      onPressed: onClose,
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
      onTap: () => onAction(code, ScanAction.copy),
    ));

    // Share
    buttons.add(ScanActionButton(
      icon: Icons.share,
      label: AppText.scanShare,
      onTap: () => onAction(code, ScanAction.share),
    ));

    // Type-specific action
    switch (code.parsed.semanticType) {
      case SemanticType.url:
        buttons.add(ScanActionButton(
          icon: Icons.open_in_new,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.email:
        buttons.add(ScanActionButton(
          icon: Icons.email,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.wifi:
        buttons.add(ScanActionButton(
          icon: Icons.wifi,
          label: AppText.scanConnect,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.connect),
        ));
        break;

      case SemanticType.isbn:
        buttons.add(ScanActionButton(
          icon: Icons.search,
          label: AppText.scanSearch,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.search),
        ));
        break;

      case SemanticType.vcard:
        buttons.add(ScanActionButton(
          icon: Icons.contact_page,
          label: AppText.scanSave,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.save),
        ));
        break;

      case SemanticType.sms:
        buttons.add(ScanActionButton(
          icon: Icons.sms,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.geo:
        buttons.add(ScanActionButton(
          icon: Icons.map,
          label: AppText.scanOpen,
          isPrimary: true,
          onTap: () => onAction(code, ScanAction.open),
        ));
        break;

      case SemanticType.text:
        // No special action for plain text
        break;
    }

    return buttons;
  }
}
