// lib/rewards/data/reward_models.dart

import 'package:flutter/material.dart';

/// 解鎖條件類型
enum UnlockConditionType {
  /// 初始解鎖（免費）
  initial,

  /// 完成指定模組
  moduleComplete,

  /// 完成指定年份
  yearComplete,
}

/// 解鎖條件
class UnlockCondition {
  final UnlockConditionType type;

  /// 需要完成的年份 (1, 2, 3)
  final int? year;

  /// 需要完成的模組索引 (0-14)
  final int? moduleIndex;

  const UnlockCondition.initial()
      : type = UnlockConditionType.initial,
        year = null,
        moduleIndex = null;

  const UnlockCondition.module(int y, int m)
      : type = UnlockConditionType.moduleComplete,
        year = y,
        moduleIndex = m;

  const UnlockCondition.yearComplete(int y)
      : type = UnlockConditionType.yearComplete,
        year = y,
        moduleIndex = null;

  /// 取得模組顯示編號 (1-15)
  int get moduleDisplayNumber => (moduleIndex ?? 0) + 1;

  /// 取得解鎖條件的顯示文字
  String getDisplayText(String locale) {
    return switch (type) {
      UnlockConditionType.initial => _localize(
          locale,
          zh: '初始解鎖',
          en: 'Initially Unlocked',
          ja: '初期解放',
        ),
      UnlockConditionType.moduleComplete => _localize(
          locale,
          zh: '完成 Y$year 模組 $moduleDisplayNumber',
          en: 'Complete Y$year Module $moduleDisplayNumber',
          ja: 'Y$year モジュール $moduleDisplayNumber 完了',
        ),
      UnlockConditionType.yearComplete => _localize(
          locale,
          zh: '完成第 $year 年',
          en: 'Complete Year $year',
          ja: '第 $year 年完了',
        ),
    };
  }

  /// 簡短顯示文字（用於選擇器）
  String getShortText(String locale) {
    return switch (type) {
      UnlockConditionType.initial => '',
      UnlockConditionType.moduleComplete => _localize(
          locale,
          zh: '模組 $moduleDisplayNumber',
          en: 'Module $moduleDisplayNumber',
          ja: 'M$moduleDisplayNumber',
        ),
      UnlockConditionType.yearComplete => _localize(
          locale,
          zh: 'Year $year',
          en: 'Year $year',
          ja: 'Year $year',
        ),
    };
  }

  static String _localize(
    String locale, {
    required String zh,
    required String en,
    required String ja,
  }) {
    return switch (locale) {
      'zh' => zh,
      'ja' => ja,
      _ => en,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 主題色獎勵
// ═══════════════════════════════════════════════════════════════════════════

/// 主題色獎勵
class ThemeColorReward {
  final String id;
  final Color color;
  final UnlockCondition unlockCondition;

  /// 是否為傳奇主題（年度完成獎勵）
  final bool isLegendary;

  /// 多語言名稱
  final Map<String, String> name;

  const ThemeColorReward({
    required this.id,
    required this.color,
    required this.unlockCondition,
    this.isLegendary = false,
    required this.name,
  });

  String getName(String locale) => name[locale] ?? name['en'] ?? id;
}

// ═══════════════════════════════════════════════════════════════════════════
// 記錄上限獎勵
// ═══════════════════════════════════════════════════════════════════════════

/// 記錄上限獎勵
class HistoryLimitReward {
  final String id;
  final int limit;
  final UnlockCondition unlockCondition;

  const HistoryLimitReward({
    required this.id,
    required this.limit,
    required this.unlockCondition,
  });

  /// 是否為無限制
  bool get isUnlimited => limit < 0;

  /// 獲取顯示文字
  String getDisplayText(String locale) {
    if (isUnlimited) {
      return switch (locale) {
        'zh' => '無上限',
        'ja' => '無制限',
        _ => 'Unlimited',
      };
    }
    return '$limit';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 獎勵解鎖結果
// ═══════════════════════════════════════════════════════════════════════════

/// 獎勵解鎖結果（用於 POP 通知）
class RewardUnlockResult {
  /// 新解鎖的主題色
  final List<ThemeColorReward> unlockedColors;

  /// 新解鎖的記錄上限
  final HistoryLimitReward? unlockedHistoryLimit;

  const RewardUnlockResult({
    this.unlockedColors = const [],
    this.unlockedHistoryLimit,
  });

  /// 是否有新獎勵
  bool get hasNewRewards =>
      unlockedColors.isNotEmpty || unlockedHistoryLimit != null;
}
