// lib/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_text.dart';
import '../rewards/logic/reward_service.dart';
import '../services/language_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyVibration = 'vibration';
  static const _keySound = 'sound';
  static const _keyUrlOpenMode = 'url_open_mode';
  static const _keySaveImage = 'save_image';
  static const _keySaveLocation = 'save_location';
  static const _keyThemeMode = 'theme_mode';
  static const _keyShowGrowthCard = 'show_growth_card';
  static const _keyShowRewardPopups = 'show_reward_popups';

  final SharedPreferences _prefs;
  late final LanguageService _langService;

  SettingsProvider(this._prefs) {
    _langService = LanguageService(_prefs);
    _langService.initialize();

    // 初始化獎勵服務
    RewardService.instance.initialize(_prefs);
  }

  // ============ Scan Settings ============

  bool get vibration => _prefs.getBool(_keyVibration) ?? true;
  set vibration(bool v) {
    _prefs.setBool(_keyVibration, v);
    notifyListeners();
  }

  bool get sound => _prefs.getBool(_keySound) ?? true;
  set sound(bool v) {
    _prefs.setBool(_keySound, v);
    notifyListeners();
  }

  /// URL 開啟方式：true = 外部瀏覽器，false = 內建 WebView（預設）
  bool get useExternalBrowser => _prefs.getBool(_keyUrlOpenMode) ?? false;
  set useExternalBrowser(bool v) {
    _prefs.setBool(_keyUrlOpenMode, v);
    notifyListeners();
  }

  // ============ History Settings ============

  bool get saveImage => _prefs.getBool(_keySaveImage) ?? true;
  set saveImage(bool v) {
    _prefs.setBool(_keySaveImage, v);
    notifyListeners();
  }

  bool get saveLocation => _prefs.getBool(_keySaveLocation) ?? false;
  set saveLocation(bool v) {
    _prefs.setBool(_keySaveLocation, v);
    notifyListeners();
  }

  /// 記錄上限（由成長系統解鎖，唯讀）
  int get historyLimit => RewardService.instance.currentHistoryLimit;

  // ============ Appearance ============

  ThemeMode get themeMode {
    final v = _prefs.getString(_keyThemeMode);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  set themeMode(ThemeMode m) {
    _prefs.setString(_keyThemeMode, m.name);
    notifyListeners();
  }

  // Theme Color（由獎勵系統管理）
  Color get themeColor => RewardService.instance.selectedThemeColor.color;

  /// 設定主題色（通過 ID）
  Future<void> setThemeColorById(String colorId) async {
    await RewardService.instance.setThemeColor(colorId);
    notifyListeners();
  }

  /// 目前選擇的主題色 ID
  String get themeColorId => RewardService.instance.selectedThemeColorId;

  // Continuous Scan Mode - 功能已停用，永遠返回 false
  bool get continuousScanMode => false;

  // ============ Growth System ============

  /// Whether to show the Cyber Forge growth card in settings.
  bool get showGrowthCard => _prefs.getBool(_keyShowGrowthCard) ?? true;
  set showGrowthCard(bool v) {
    _prefs.setBool(_keyShowGrowthCard, v);
    notifyListeners();
  }

  /// Whether to show reward unlock popups.
  bool get showRewardPopups => _prefs.getBool(_keyShowRewardPopups) ?? true;
  set showRewardPopups(bool v) {
    _prefs.setBool(_keyShowRewardPopups, v);
    notifyListeners();
  }

  // ============ Language ============

  String get language => _langService.currentSetting;

  Future<void> setLanguage(String lang) async {
    await _langService.setLanguage(lang);
    notifyListeners();
  }

  // Helper to get display name for current language
  String get languageDisplayName {
    return switch (language) {
      'zh' => AppText.settingsLangZh,
      'en' => AppText.settingsLangEn,
      'ja' => AppText.settingsLangJa,
      _ => AppText.settingsLangSystem,
    };
  }
}
