// lib/widgets/history/scan_history_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import '../../utils/date_format_helper.dart';
import '../../utils/semantic_type_extension.dart';

class ScanHistoryCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onActionTap; // For URL open, phone call, etc.
  final VoidCallback? onShare;
  final bool isSelectionMode;
  final bool isSelected;

  const ScanHistoryCard({
    super.key,
    required this.record,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onDelete,
    this.onActionTap,
    this.onShare,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isSelected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection checkbox
              if (isSelectionMode) ...[
                SizedBox(
                  width: 24,
                  height: 60,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // QR Code thumbnail
              _buildThumbnail(colorScheme),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + share + favorite
                    Row(
                      children: [
                        _buildTypeBadge(colorScheme),
                        const Spacer(),
                        // Favorite toggle
                        GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Icon(
                            record.isFavorite ? Icons.star : Icons.star_border,
                            size: 20,
                            color: record.isFavorite ? Colors.amber[600] : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Main content text
                    Text(
                      record.rawText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // Parsed value (if different)
                    if (record.displayText != null &&
                        record.displayText != record.rawText) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.displayText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Bottom row: time + location + action button
                    Row(
                      children: [
                        // Time
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(record.scannedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),

                        // Location
                        if (record.placeName != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              record.placeName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),

                        // Action button
                        _buildActionButton(context, colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    Widget child;

    if (record.imagePath != null) {
      final file = File(record.imagePath!);
      if (file.existsSync()) {
        child = Image.file(
          file,
          fit: BoxFit.cover,
          // 限制解碼解析度，避免大量圖片佔用記憶體
          cacheWidth: 120, // 2x display size for retina
          cacheHeight: 120,
          errorBuilder: (_, _, _) => _buildPlaceholderIcon(colorScheme),
        );
      } else {
        child = _buildPlaceholderIcon(colorScheme);
      }
    } else {
      child = _buildPlaceholderIcon(colorScheme);
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        _getFormatIcon(),
        size: 28,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  IconData _getFormatIcon() {
    return switch (record.barcodeFormat) {
      BarcodeFormat.qrCode => Icons.qr_code_2,
      BarcodeFormat.dataMatrix => Icons.grid_view,
      BarcodeFormat.aztec => Icons.blur_circular,
      BarcodeFormat.pdf417 => Icons.view_week,
      BarcodeFormat.ean13 ||
      BarcodeFormat.ean8 ||
      BarcodeFormat.upcA ||
      BarcodeFormat.upcE =>
        Icons.shopping_cart_outlined,
      BarcodeFormat.code39 ||
      BarcodeFormat.code128 ||
      BarcodeFormat.codabar ||
      BarcodeFormat.itf =>
        Icons.view_column,
      _ => Icons.qr_code,
    };
  }

  Widget _buildTypeBadge(ColorScheme colorScheme) {
    final typeLabel = record.semanticType == SemanticType.isbn
        ? AppText.typeIsbn
        : record.semanticType.label;
    final color = record.semanticType.color;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 類型標籤 (ISBN)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            typeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, ColorScheme colorScheme) {
    final (icon, label) = _getActionInfo();

    return SizedBox(
      height: 28,
      child: TextButton.icon(
        onPressed: onActionTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  (IconData, String) _getActionInfo() {
    return (record.semanticType.actionIcon, record.semanticType.actionLabel);
  }

  String _formatTime(DateTime time) {
    return DateFormatHelper.formatRelative(time);
  }
}
