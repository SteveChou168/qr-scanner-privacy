// lib/widgets/scan/scan_indicators.dart

import 'package:flutter/material.dart';
import '../../app_text.dart';

/// Counter showing number of items scanned in continuous mode
class ContinuousScanCounter extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const ContinuousScanCounter({
    super.key,
    required this.count,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            AppText.scannedItems(count),
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result bar when paused
class SingleModeResultBar extends StatelessWidget {
  final int count;
  final VoidCallback onViewResults;
  final VoidCallback onRescan;

  const SingleModeResultBar({
    super.key,
    required this.count,
    required this.onViewResults,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
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
            child: GestureDetector(
              onTap: onViewResults,
              child: Text(
                AppText.foundCodes(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRescan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppText.btnRescan,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onViewResults,
            child: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
