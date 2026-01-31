// lib/utils/snackbar_helper.dart

import 'package:flutter/material.dart';
import 'app_constants.dart';

/// Helper for showing snackbars safely
class SnackbarHelper {
  SnackbarHelper._();

  /// Show snackbar only if the context is still mounted
  static void show(
    BuildContext context,
    String message, {
    Duration duration = AppConstants.snackbarDuration,
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  /// Show success snackbar (green)
  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.green.shade700,
    );
  }

  /// Show error snackbar (red)
  static void showError(BuildContext context, String message) {
    show(
      context,
      message,
      backgroundColor: Colors.red.shade700,
    );
  }
}
