// lib/widgets/scan/scan_bottom_toolbar.dart

import 'package:flutter/material.dart';
import '../../app_text.dart';

/// Bottom toolbar for the scan screen with camera controls
class ScanBottomToolbar extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onTorchTap;
  final VoidCallback onArModeTap;
  final bool isTorchOn;
  final bool isArModeActive;

  const ScanBottomToolbar({
    super.key,
    required this.onGalleryTap,
    required this.onTorchTap,
    required this.onArModeTap,
    this.isTorchOn = false,
    this.isArModeActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withAlpha(230)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolButton(
                icon: Icons.photo_library,
                label: AppText.toolGallery,
                onTap: onGalleryTap,
              ),
              _ToolButton(
                icon: isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                label: AppText.toolFlash,
                onTap: onTorchTap,
                isActive: isTorchOn,
              ),
              _ToolButton(
                icon: Icons.grid_view_rounded,
                label: AppText.arMode,
                onTap: onArModeTap,
                isActive: isArModeActive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual tool button in the bottom toolbar
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withAlpha(51)
                      : Colors.white.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.amber : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
