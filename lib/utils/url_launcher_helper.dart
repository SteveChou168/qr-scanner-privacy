// lib/utils/url_launcher_helper.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Unified URL launcher utility using Chrome Custom Tabs / Safari View Controller
class UrlLauncherHelper {
  UrlLauncherHelper._();

  /// Open URL based on user preference
  /// - [useExternalBrowser] = false: Chrome Custom Tabs / Safari View Controller
  /// - [useExternalBrowser] = true: System default browser (Edge, Firefox, etc.)
  static Future<bool> openUrl(
    String url, {
    required bool useExternalBrowser,
  }) async {
    final uri = Uri.tryParse(_normalizeUrl(url));
    if (uri == null) return false;

    try {
      return await launchUrl(
        uri,
        mode: useExternalBrowser
            ? LaunchMode.externalApplication
            : LaunchMode.inAppBrowserView,
      );
    } catch (e) {
      debugPrint('Error opening URL: $e');
      return false;
    }
  }

  /// Normalize URL to ensure it has a valid scheme
  static String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    // Already has scheme
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Starts with www.
    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }

    // Default to HTTPS
    return 'https://$trimmed';
  }
}
