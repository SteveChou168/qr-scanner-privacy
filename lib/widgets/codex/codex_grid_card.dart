// lib/widgets/codex/codex_grid_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/scan_record.dart';

class CodexGridCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? size;
  final bool isSelectionMode;
  final bool isSelected;

  const CodexGridCard({
    super.key,
    required this.record,
    this.onTap,
    this.onLongPress,
    this.size,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = _getTypeColor();

    return Card(
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail area (60% height)
                Expanded(
                  flex: 6,
                  child: _buildThumbnail(colorScheme, typeColor),
                ),

                // Info area (40% height)
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time
                        Text(
                          _formatTime(record.scannedAt),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),

                        // Location + Type indicator
                        Row(
                          children: [
                            if (record.placeName != null &&
                                record.placeName!.isNotEmpty) ...[
                              Icon(
                                Icons.location_on,
                                size: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  record.placeName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ] else
                              const Spacer(),

                            // Type color dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Selection indicator
            if (isSelectionMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme, Color typeColor) {
    // Try to load image if available
    if (record.imagePath != null && record.imagePath!.isNotEmpty) {
      final file = File(record.imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          // 限制解碼解析度，避免大量圖片佔用記憶體
          cacheWidth: 200, // Grid card is ~100px, use 2x for retina
          cacheHeight: 200,
          errorBuilder: (_, _, _) =>
              _buildPlaceholder(colorScheme, typeColor),
        );
      }
    }
    return _buildPlaceholder(colorScheme, typeColor);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme, Color typeColor) {
    return Container(
      color: typeColor.withValues(alpha: 0.15),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(),
              size: 28,
              color: typeColor,
            ),
            const SizedBox(height: 4),
            Text(
              record.semanticType.icon,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor() {
    return switch (record.semanticType) {
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

  IconData _getTypeIcon() {
    return switch (record.semanticType) {
      SemanticType.url => Icons.link,
      SemanticType.email => Icons.email_outlined,
      SemanticType.wifi => Icons.wifi,
      SemanticType.isbn => Icons.menu_book_outlined,
      SemanticType.vcard => Icons.person_outline,
      SemanticType.sms => Icons.sms_outlined,
      SemanticType.geo => Icons.location_on_outlined,
      SemanticType.text => Icons.text_fields,
    };
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
