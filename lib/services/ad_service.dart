// lib/services/ad_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Ad Unit IDs - 測試模式用 Google 官方測試 ID
  static String get _bannerAdUnitId {
    if (kDebugMode) {
      // Google 官方測試 ID (所有平台通用)
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-1511081955473690/6470549628';
    } else if (Platform.isIOS) {
      // TODO: 申請 iOS 正式 Ad Unit ID 後替換
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get _rewardedAdUnitId {
    if (kDebugMode) {
      // Google 官方測試 ID (所有平台通用)
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    if (Platform.isAndroid) {
      return 'ca-app-pub-1511081955473690/2938498720';
    } else if (Platform.isIOS) {
      // TODO: 申請 iOS 正式 Ad Unit ID 後替換
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  // GDPR / UMP 同意狀態
  bool _canShowAds = false;

  // Banner Ad - single instance for History & Codex pages
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Rewarded Ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Daily quota system
  static const String _quotaDateKey = 'ad_quota_date';
  static const String _quotaCountKey = 'ad_quota_count';
  static const int _dailyFreeQuota = 3;

  // Daily ad watch limit (for proactive ad watching)
  static const String _dailyAdWatchCountKey = 'ad_daily_watch_count';
  static const int _maxDailyAdWatches = 20;

  // Retry configuration
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 30);
  int _bannerRetryAttempts = 0;
  int _rewardedRetryAttempts = 0;

  // Reward system: 3 quota (90%), 5 quota bonus (10%)
  static const int _normalReward = 3;
  static const int _bonusReward = 5;
  static const int _bonusChancePercent = 10;
  final Random _random = Random();

  // Callbacks
  VoidCallback? onBannerAdLoaded;
  VoidCallback? onRewardedAdLoaded;

  // Getters
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  /// Initialize the Mobile Ads SDK with UMP consent handling
  /// UMP 會自動偵測歐盟用戶並顯示同意表單，非歐盟用戶不會被打擾
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    debugPrint('AdService: MobileAds SDK initialized');

    // 使用 UMP 處理 GDPR 同意（只會對歐盟用戶顯示）
    await _handleConsent();
  }

  /// 使用 Google UMP 處理同意流程
  /// - 自動偵測用戶是否在歐盟
  /// - 歐盟用戶：顯示 Google 官方同意表單
  /// - 非歐盟用戶：直接通過，不顯示任何東西
  Future<void> _handleConsent() async {
    final completer = Completer<void>();

    // 請求同意資訊更新
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // 檢查是否可以顯示廣告
        if (await ConsentInformation.instance.canRequestAds()) {
          _canShowAds = true;
          debugPrint('AdService: Consent already obtained, can show ads');
        } else {
          // 需要顯示同意表單（歐盟用戶）
          await _showConsentFormIfRequired();
        }
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        debugPrint('AdService: Consent info update failed: ${error.message}');
        // 錯誤時預設允許廣告（非歐盟地區通常不需要同意）
        _canShowAds = true;
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// 顯示同意表單（如果需要）
  Future<void> _showConsentFormIfRequired() async {
    final completer = Completer<void>();

    ConsentForm.loadAndShowConsentFormIfRequired(
      (FormError? error) async {
        if (error != null) {
          debugPrint('AdService: Consent form error: ${error.message}');
        }
        // 檢查最終狀態
        _canShowAds = await ConsentInformation.instance.canRequestAds();
        debugPrint('AdService: Consent form completed, canShowAds: $_canShowAds');
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// 檢查是否可以顯示廣告
  bool get canShowAds => _canShowAds;

  /// 取得廣告請求
  AdRequest _getAdRequest() {
    return const AdRequest();
  }

  /// Load Banner Ad (called once, shared between History & Codex)
  void loadBannerAd() {
    if (!_canShowAds) {
      debugPrint('AdService: Cannot show ads (no consent)');
      return;
    }
    if (_bannerAd != null) {
      debugPrint('AdService: Banner ad already exists');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: _getAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner ad loaded');
          _isBannerAdLoaded = true;
          _bannerRetryAttempts = 0; // 重設重試次數
          onBannerAdLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner ad failed to load: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;

          // 重試邏輯
          if (_bannerRetryAttempts < _maxRetryAttempts) {
            _bannerRetryAttempts++;
            debugPrint('AdService: Retrying banner ad in ${_retryDelay.inSeconds}s (attempt $_bannerRetryAttempts/$_maxRetryAttempts)');
            Future.delayed(_retryDelay, loadBannerAd);
          } else {
            debugPrint('AdService: Banner ad max retries reached');
          }
        },
        onAdOpened: (ad) => debugPrint('AdService: Banner ad opened'),
        onAdClosed: (ad) => debugPrint('AdService: Banner ad closed'),
      ),
    );

    _bannerAd!.load();
    debugPrint('AdService: Loading banner ad...');
  }

  /// Load Rewarded Ad
  void loadRewardedAd() {
    if (!_canShowAds) {
      debugPrint('AdService: Cannot show ads (no consent)');
      return;
    }
    if (_isRewardedAdLoaded) {
      debugPrint('AdService: Rewarded ad already loaded');
      return;
    }

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: _getAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdService: Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _rewardedRetryAttempts = 0; // 重設重試次數
          onRewardedAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Rewarded ad failed to load: ${error.message}');
          _isRewardedAdLoaded = false;

          // 重試邏輯
          if (_rewardedRetryAttempts < _maxRetryAttempts) {
            _rewardedRetryAttempts++;
            debugPrint('AdService: Retrying rewarded ad in ${_retryDelay.inSeconds}s (attempt $_rewardedRetryAttempts/$_maxRetryAttempts)');
            Future.delayed(_retryDelay, loadRewardedAd);
          } else {
            debugPrint('AdService: Rewarded ad max retries reached');
          }
        },
      ),
    );
    debugPrint('AdService: Loading rewarded ad...');
  }

  /// Show Rewarded Ad and return the reward amount (0 if not earned)
  Future<int> showRewardedAd() async {
    if (_rewardedAd == null) {
      debugPrint('AdService: Rewarded ad not ready');
      return 0;
    }

    final completer = Completer<int>();
    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdService: Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        // Pre-load next rewarded ad
        loadRewardedAd();

        // Complete with reward amount when ad is dismissed
        if (!completer.isCompleted) {
          if (rewardEarned) {
            final isBonus = _random.nextInt(100) < _bonusChancePercent;
            final reward = isBonus ? _bonusReward : _normalReward;
            debugPrint('AdService: Reward granted: $reward (bonus: $isBonus)');
            completer.complete(reward);
          } else {
            completer.complete(0);
          }
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        loadRewardedAd();

        if (!completer.isCompleted) {
          completer.complete(0);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('AdService: User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );

    return completer.future;
  }

  /// Get remaining quota for today
  Future<int> getRemainingQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_quotaDateKey);

    if (savedDate != today) {
      // New day, reset quota
      await prefs.setString(_quotaDateKey, today);
      await prefs.setInt(_quotaCountKey, _dailyFreeQuota);
      return _dailyFreeQuota;
    }

    return prefs.getInt(_quotaCountKey) ?? _dailyFreeQuota;
  }

  /// Use one quota, returns true if successful (had quota available)
  Future<bool> useQuota() async {
    final remaining = await getRemainingQuota();
    if (remaining <= 0) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quotaCountKey, remaining - 1);
    return true;
  }

  /// Add reward quota after watching ad
  Future<void> addRewardQuota(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_quotaDateKey);

    if (savedDate != today) {
      await prefs.setString(_quotaDateKey, today);
      await prefs.setInt(_quotaCountKey, _dailyFreeQuota + amount);
    } else {
      final current = prefs.getInt(_quotaCountKey) ?? 0;
      await prefs.setInt(_quotaCountKey, current + amount);
    }
  }

  /// Check if user needs to watch ad (quota exhausted)
  Future<bool> needsToWatchAd() async {
    final remaining = await getRemainingQuota();
    return remaining <= 0;
  }

  /// Get today's ad watch count (for proactive ad watching)
  Future<int> getDailyAdWatchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_quotaDateKey);

    if (savedDate != today) {
      // New day, reset count
      return 0;
    }

    return prefs.getInt(_dailyAdWatchCountKey) ?? 0;
  }

  /// Check if user can still watch ads proactively today
  Future<bool> canWatchAdProactively() async {
    final count = await getDailyAdWatchCount();
    return count < _maxDailyAdWatches;
  }

  /// Increment daily ad watch count, returns true if successful
  Future<bool> incrementAdWatchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_quotaDateKey);

    int currentCount = 0;
    if (savedDate == today) {
      currentCount = prefs.getInt(_dailyAdWatchCountKey) ?? 0;
    } else {
      // New day, ensure date is set
      await prefs.setString(_quotaDateKey, today);
    }

    if (currentCount >= _maxDailyAdWatches) {
      return false;
    }

    await prefs.setInt(_dailyAdWatchCountKey, currentCount + 1);
    return true;
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 重設重試次數（App 從背景恢復時呼叫）
  void resetRetryAttempts() {
    _bannerRetryAttempts = 0;
    _rewardedRetryAttempts = 0;
  }

  /// Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;

    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }
}
