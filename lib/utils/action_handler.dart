// lib/utils/action_handler.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_text.dart';
import '../data/models/scan_record.dart';
import '../providers/settings_provider.dart';
import '../services/barcode_parser.dart';
import 'clipboard_helper.dart';
import 'snackbar_helper.dart';
import 'url_launcher_helper.dart';

/// Centralized handler for semantic type actions
class ActionHandler {
  ActionHandler._();

  /// Handle action based on semantic type
  static Future<void> handle(
    BuildContext context,
    ScanRecord record, {
    VoidCallback? onWifiTap,
  }) async {
    switch (record.semanticType) {
      case SemanticType.url:
        await _handleUrl(context, record.rawText, record.displayText);
        break;
      case SemanticType.email:
        await _handleEmail(context, record.displayText ?? record.rawText);
        break;
      case SemanticType.sms:
        await _handleSms(context, record.displayText ?? record.rawText);
        break;
      case SemanticType.isbn:
        await _handleIsbn(context, record.displayText ?? record.rawText);
        break;
      case SemanticType.wifi:
        if (onWifiTap != null) {
          onWifiTap();
        } else {
          _showWifiDialog(context, record.rawText);
        }
        break;
      case SemanticType.vcard:
        ClipboardHelper.copy(context, record.rawText);
        break;
      case SemanticType.geo:
        await _handleGeo(context, record.rawText);
        break;
      case SemanticType.text:
        await _handleTextSearch(context, record.rawText);
        break;
    }
  }

  /// Handle URL - open in Chrome Custom Tabs or external browser
  static Future<void> _handleUrl(
    BuildContext context,
    String url,
    String? title,
  ) async {
    if (!context.mounted) return;

    final settings = context.read<SettingsProvider>();
    final success = await UrlLauncherHelper.openUrl(
      url,
      useExternalBrowser: settings.useExternalBrowser,
    );

    if (!success && context.mounted) {
      SnackbarHelper.showError(context, AppText.urlOpenFailed);
    }
  }

  /// Handle email - open mail client
  static Future<void> _handleEmail(BuildContext context, String email) async {
    // Extract email if it has mailto: prefix
    final cleanEmail = email.toLowerCase().startsWith('mailto:')
        ? email.substring(7).split('?').first
        : email;

    final uri = Uri(scheme: 'mailto', path: cleanEmail);
    final success = await _launchUri(uri);

    if (!success && context.mounted) {
      SnackbarHelper.showError(context, AppText.emailOpenFailed);
    }
  }

  /// Handle SMS - open messaging app
  static Future<void> _handleSms(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    final success = await _launchUri(uri);

    if (!success && context.mounted) {
      SnackbarHelper.showError(context, AppText.smsOpenFailed);
    }
  }

  /// Handle ISBN - search on Google
  static Future<void> _handleIsbn(BuildContext context, String isbn) async {
    if (!context.mounted) return;

    final searchUrl = 'https://www.google.com/search?q=ISBN+$isbn';
    await _openSearchUrl(context, searchUrl, 'ISBN: $isbn');
  }

  /// Handle text - search on Google
  static Future<void> _handleTextSearch(BuildContext context, String text) async {
    if (!context.mounted) return;

    final encoded = Uri.encodeComponent(text);
    final searchUrl = 'https://www.google.com/search?q=$encoded';
    await _openSearchUrl(context, searchUrl, text);
  }

  /// Open search URL based on user settings
  static Future<void> _openSearchUrl(BuildContext context, String url, String title) async {
    if (!context.mounted) return;

    final settings = context.read<SettingsProvider>();
    await UrlLauncherHelper.openUrl(
      url,
      useExternalBrowser: settings.useExternalBrowser,
    );
  }

  /// Handle Geo - open in maps
  static Future<void> _handleGeo(BuildContext context, String geoUri) async {
    final uri = Uri.parse(geoUri);
    final success = await _launchUri(uri);

    if (!success && context.mounted) {
      SnackbarHelper.showError(context, AppText.mapOpenFailed);
    }
  }

  /// Show WiFi details dialog
  static void _showWifiDialog(BuildContext context, String wifiString) {
    final wifi = BarcodeParser.parseWifiString(wifiString);
    final ssid = wifi['ssid'] ?? '-';
    final password = wifi['password'] ?? '-';
    final security = wifi['type'] ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppText.typeWifi),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _wifiInfoRow('SSID', ssid),
            _wifiInfoRow(AppText.wifiSecurity, security),
            _wifiInfoRow(AppText.wifiPassword, password),
          ],
        ),
        actions: [
          if (password != '-')
            TextButton(
              onPressed: () {
                ClipboardHelper.copy(ctx, password);
                Navigator.pop(ctx);
              },
              child: Text(AppText.wifiCopyPassword),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppText.dialogClose),
          ),
        ],
      ),
    );
  }

  static Widget _wifiInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Helper to launch URI with error handling
  static Future<bool> _launchUri(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching URI: $e');
      return false;
    }
  }
}
