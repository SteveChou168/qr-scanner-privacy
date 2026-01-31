// lib/utils/app_constants.dart

/// App-wide constants
class AppConstants {
  AppConstants._();

  // ============ Timeouts ============
  /// Location service timeout
  static const Duration locationTimeout = Duration(seconds: 8);

  /// Generic async operation timeout
  static const Duration operationTimeout = Duration(seconds: 30);

  // ============ Scanner Settings ============
  /// Multi-frame accumulation window for AR mode
  static const Duration accumulationWindow = Duration(milliseconds: 800);

  // ============ UI Constants ============
  /// Default snackbar duration
  static const Duration snackbarDuration = Duration(seconds: 2);

  /// Generator text field height limits
  static const double minTextFieldHeight = 56.0;
  static const double maxTextFieldHeight = 200.0;

  // ============ Validation ============
  /// Maximum WiFi password length (WPA2 spec)
  static const int maxWifiPasswordLength = 63;

  /// Maximum QR code data length (reasonable limit for readability)
  static const int maxQrDataLength = 2000;

  // ============ Image Settings ============
  /// Screenshot compression target width
  static const int screenshotWidth = 800;

  /// Screenshot compression target height
  static const int screenshotHeight = 600;

  /// Screenshot compression quality (0-100)
  static const int screenshotQuality = 75;

  /// Thumbnail cache size multiplier (for retina displays)
  static const int thumbnailCacheMultiplier = 2;

  /// History card thumbnail size
  static const int historyThumbnailSize = 60;

  /// Codex grid thumbnail size
  static const int codexThumbnailSize = 100;
}
