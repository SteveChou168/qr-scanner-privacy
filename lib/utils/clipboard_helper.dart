// lib/utils/clipboard_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_text.dart';
import 'snackbar_helper.dart';

/// Helper for clipboard operations
class ClipboardHelper {
  ClipboardHelper._();

  /// Copy text to clipboard and show feedback
  static void copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    SnackbarHelper.show(context, AppText.copiedToClipboard);
  }

  /// Copy text to clipboard without feedback (silent)
  static void copySilent(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}
