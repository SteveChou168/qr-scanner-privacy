// lib/services/language_service.dart

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_text.dart';

class LanguageService {
  static const _keyLanguage = 'app_language';

  final SharedPreferences _prefs;

  LanguageService(this._prefs);

  /// Initialize language on app start
  void initialize() {
    final saved = _prefs.getString(_keyLanguage);

    if (saved != null && saved != 'system') {
      // User manually set a language
      AppText.language = saved;
    } else {
      // Follow system
      AppText.language = _getSystemLanguage();
    }
  }

  /// Get current setting
  /// Returns 'system' | 'zh' | 'en' | 'ja' | 'es' | 'pt' | 'ko' | 'vi'
  String get currentSetting => _prefs.getString(_keyLanguage) ?? 'system';

  /// Set language
  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_keyLanguage, lang);

    if (lang == 'system') {
      AppText.language = _getSystemLanguage();
    } else {
      AppText.language = lang;
    }
  }

  /// Get system language
  String _getSystemLanguage() {
    try {
      final locale = Platform.localeName; // e.g., "zh_TW", "en_US", "ja_JP"
      final langCode = locale.split('_').first.toLowerCase();

      return switch (langCode) {
        'zh' => 'zh',
        'en' => 'en',
        'ja' => 'ja',
        'es' => 'es',
        'pt' => 'pt',
        'ko' => 'ko',
        'vi' => 'vi',
        _ => 'en', // Default to English for global users
      };
    } catch (_) {
      return 'en';
    }
  }
}
