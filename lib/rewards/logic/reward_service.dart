// lib/rewards/logic/reward_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/reward_constants.dart';
import '../data/reward_models.dart';
import '../../growth/logic/growth_service.dart';

/// 獎勵系統服務
///
/// 管理主題色和記錄上限的解鎖邏輯。
/// 與 GrowthService 整合，根據成長進度解鎖獎勵。
class RewardService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // SINGLETON
  // ═══════════════════════════════════════════════════════════════════════════

  static RewardService? _instance;

  static RewardService get instance {
    _instance ??= RewardService._();
    return _instance!;
  }

  RewardService._();

  factory RewardService() => instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  static const _keySelectedThemeColorId = 'selected_theme_color_id';
  static const _keyHasSeenGrowthIntro = 'has_seen_growth_intro';

  bool get isInitialized => _isInitialized;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// 初始化服務
  Future<void> initialize(SharedPreferences prefs) async {
    if (_isInitialized) return;

    _prefs = prefs;
    _isInitialized = true;
    notifyListeners();
  }

  /// 刷新獎勵狀態（當 GrowthService 狀態變更時調用）
  void refresh() {
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROWTH INTRO (SETUP)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 是否已看過成長系統介紹
  bool get hasSeenGrowthIntro => _prefs?.getBool(_keyHasSeenGrowthIntro) ?? false;

  /// 標記已看過成長系統介紹
  Future<void> markGrowthIntroSeen() async {
    await _prefs?.setBool(_keyHasSeenGrowthIntro, true);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME COLOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// 目前選擇的主題色 ID
  String get selectedThemeColorId =>
      _prefs?.getString(_keySelectedThemeColorId) ?? 'classic_blue';

  /// 目前選擇的主題色
  ThemeColorReward get selectedThemeColor {
    final reward = RewardConstants.findThemeColorById(selectedThemeColorId);
    return reward ?? RewardConstants.allThemeColors.first;
  }

  /// 設定主題色
  Future<void> setThemeColor(String colorId) async {
    // 檢查是否已解鎖
    final reward = RewardConstants.findThemeColorById(colorId);
    if (reward == null) return;
    if (!isThemeColorUnlocked(reward)) return;

    await _prefs?.setString(_keySelectedThemeColorId, colorId);
    notifyListeners();
  }

  /// 檢查主題色是否已解鎖
  bool isThemeColorUnlocked(ThemeColorReward reward) {
    return _isConditionMet(reward.unlockCondition);
  }

  /// 獲取所有已解鎖的主題色
  List<ThemeColorReward> get unlockedThemeColors {
    return RewardConstants.allThemeColors
        .where((c) => isThemeColorUnlocked(c))
        .toList();
  }

  /// 獲取已解鎖的主題色數量
  int get unlockedThemeColorCount => unlockedThemeColors.length;

  /// 獲取下一個即將解鎖的主題色（如果有）
  ThemeColorReward? get nextThemeColorToUnlock {
    try {
      return RewardConstants.allThemeColors
          .firstWhere((c) => !isThemeColorUnlocked(c));
    } catch (_) {
      return null; // 全部已解鎖
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HISTORY LIMIT
  // ═══════════════════════════════════════════════════════════════════════════

  /// 獲取目前已解鎖的記錄上限
  int get currentHistoryLimit {
    final unlocked = unlockedHistoryLimits;
    if (unlocked.isEmpty) return 500;

    // 取最後一個（最高的）
    return unlocked.last.limit;
  }

  /// 檢查記錄上限是否已解鎖
  bool isHistoryLimitUnlocked(HistoryLimitReward reward) {
    return _isConditionMet(reward.unlockCondition);
  }

  /// 獲取所有已解鎖的記錄上限
  List<HistoryLimitReward> get unlockedHistoryLimits {
    return RewardConstants.allHistoryLimits
        .where((l) => isHistoryLimitUnlocked(l))
        .toList();
  }

  /// 獲取下一個即將解鎖的記錄上限（如果有）
  HistoryLimitReward? get nextHistoryLimitToUnlock {
    try {
      return RewardConstants.allHistoryLimits
          .firstWhere((l) => !isHistoryLimitUnlocked(l));
    } catch (_) {
      return null; // 全部已解鎖
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNLOCK CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  /// 檢查模組完成時新解鎖的獎勵
  ///
  /// [completedYear] 完成的年份 (1-3)
  /// [completedModuleIndex] 完成的模組索引 (0-14)
  RewardUnlockResult checkModuleCompleteRewards(
    int completedYear,
    int completedModuleIndex,
  ) {
    final newColors = <ThemeColorReward>[];
    HistoryLimitReward? newLimit;

    // 檢查主題色
    for (final color in RewardConstants.allThemeColors) {
      final condition = color.unlockCondition;
      if (condition.type == UnlockConditionType.moduleComplete &&
          condition.year == completedYear &&
          condition.moduleIndex == completedModuleIndex) {
        newColors.add(color);
      }
    }

    // 檢查記錄上限
    for (final limit in RewardConstants.allHistoryLimits) {
      final condition = limit.unlockCondition;
      if (condition.type == UnlockConditionType.moduleComplete &&
          condition.year == completedYear &&
          condition.moduleIndex == completedModuleIndex) {
        newLimit = limit;
        break;
      }
    }

    return RewardUnlockResult(
      unlockedColors: newColors,
      unlockedHistoryLimit: newLimit,
    );
  }

  /// 檢查年度完成時新解鎖的獎勵
  ///
  /// [completedYear] 完成的年份 (1-3)
  RewardUnlockResult checkYearCompleteRewards(int completedYear) {
    final newColors = <ThemeColorReward>[];
    HistoryLimitReward? newLimit;

    // 檢查傳奇主題色
    for (final color in RewardConstants.allThemeColors) {
      final condition = color.unlockCondition;
      if (condition.type == UnlockConditionType.yearComplete &&
          condition.year == completedYear) {
        newColors.add(color);
      }
    }

    // 檢查記錄上限
    for (final limit in RewardConstants.allHistoryLimits) {
      final condition = limit.unlockCondition;
      if (condition.type == UnlockConditionType.yearComplete &&
          condition.year == completedYear) {
        newLimit = limit;
        break;
      }
    }

    return RewardUnlockResult(
      unlockedColors: newColors,
      unlockedHistoryLimit: newLimit,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 檢查解鎖條件是否滿足
  bool _isConditionMet(UnlockCondition condition) {
    final growth = GrowthService.instance;
    if (!growth.isInitialized) return condition.type == UnlockConditionType.initial;

    switch (condition.type) {
      case UnlockConditionType.initial:
        return true;

      case UnlockConditionType.moduleComplete:
        final requiredYear = condition.year ?? 1;
        final requiredModule = condition.moduleIndex ?? 0;

        // 如果已經過了這一年，肯定已解鎖
        if (growth.currentYear > requiredYear) return true;

        // 如果在同一年，檢查模組進度
        if (growth.currentYear == requiredYear) {
          // currentRound 是 1-based，moduleIndex 是 0-based
          // currentRound - 1 = 已完成的模組數（不含當前）
          // 所以如果 currentRound > requiredModule + 1，表示已完成
          return growth.currentRound > requiredModule + 1;
        }

        return false;

      case UnlockConditionType.yearComplete:
        final requiredYear = condition.year ?? 1;
        // 檢查是否有該年的獎勵
        final awardEmojis = ['🛰️', '🤖', '🗼'];
        if (requiredYear >= 1 && requiredYear <= 3) {
          return growth.yearAwards.contains(awardEmojis[requiredYear - 1]);
        }
        return false;
    }
  }
}
