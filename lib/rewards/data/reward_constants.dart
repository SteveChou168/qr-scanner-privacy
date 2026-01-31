// lib/rewards/data/reward_constants.dart

import 'package:flutter/material.dart';
import 'reward_models.dart';

/// 完整三年獎勵常數
///
/// 主題色：15 個（初始 3 + Year1 4 + Year2 3 + Year3 2 + 傳奇 3）
/// 記錄上限：11 階（1,000 → 2,000 → 4,000 → 7,000 → 10,000 → 15,000 → 22,000 → 30,000 → 37,000 → 44,000 → 50,000）
abstract class RewardConstants {
  // ═══════════════════════════════════════════════════════════════════════════
  // 主題色獎勵
  // ═══════════════════════════════════════════════════════════════════════════

  /// 所有主題色獎勵（按解鎖順序）
  static const List<ThemeColorReward> allThemeColors = [
    // ─── 初始解鎖 (3) ───
    ThemeColorReward(
      id: 'classic_blue',
      color: Colors.blue,
      unlockCondition: UnlockCondition.initial(),
      name: {'zh': '經典藍', 'en': 'Classic Blue', 'ja': 'クラシックブルー'},
    ),
    ThemeColorReward(
      id: 'forest_green',
      color: Color(0xFF388E3C), // Colors.green[700]
      unlockCondition: UnlockCondition.initial(),
      name: {'zh': '森林綠', 'en': 'Forest Green', 'ja': 'フォレストグリーン'},
    ),
    ThemeColorReward(
      id: 'deep_purple',
      color: Colors.deepPurple,
      unlockCondition: UnlockCondition.initial(),
      name: {'zh': '深紫', 'en': 'Deep Purple', 'ja': 'ディープパープル'},
    ),

    // ─── Year 1 解鎖 (4) ───
    ThemeColorReward(
      id: 'amber_orange',
      color: Color(0xFFFFA000), // Colors.amber[700]
      unlockCondition: UnlockCondition.module(1, 1), // M2
      name: {'zh': '琥珀橙', 'en': 'Amber Orange', 'ja': 'アンバーオレンジ'},
    ),
    ThemeColorReward(
      id: 'rose_red',
      color: Color(0xFFEF5350), // Colors.red[400]
      unlockCondition: UnlockCondition.module(1, 4), // M5
      name: {'zh': '玫瑰紅', 'en': 'Rose Red', 'ja': 'ローズレッド'},
    ),
    ThemeColorReward(
      id: 'titanium_grey',
      color: Color(0xFF455A64), // Colors.blueGrey[700]
      unlockCondition: UnlockCondition.module(1, 7), // M8
      name: {'zh': '鈦金灰', 'en': 'Titanium Grey', 'ja': 'チタングレー'},
    ),
    ThemeColorReward(
      id: 'teal',
      color: Colors.teal,
      unlockCondition: UnlockCondition.module(1, 11), // M12
      name: {'zh': '青色', 'en': 'Teal', 'ja': 'ティール'},
    ),

    // ─── Year 2 解鎖 (3) ───
    ThemeColorReward(
      id: 'indigo',
      color: Colors.indigo,
      unlockCondition: UnlockCondition.module(2, 2), // M3
      name: {'zh': '靛藍', 'en': 'Indigo', 'ja': 'インディゴ'},
    ),
    ThemeColorReward(
      id: 'deep_orange',
      color: Colors.deepOrange,
      unlockCondition: UnlockCondition.module(2, 7), // M8
      name: {'zh': '深橙', 'en': 'Deep Orange', 'ja': 'ディープオレンジ'},
    ),
    ThemeColorReward(
      id: 'pink',
      color: Color(0xFFF06292), // Colors.pink[300]
      unlockCondition: UnlockCondition.module(2, 12), // M13
      name: {'zh': '粉紅', 'en': 'Pink', 'ja': 'ピンク'},
    ),

    // ─── Year 3 解鎖 (2) ───
    ThemeColorReward(
      id: 'light_blue',
      color: Colors.lightBlue,
      unlockCondition: UnlockCondition.module(3, 2), // M3
      name: {'zh': '淺藍', 'en': 'Light Blue', 'ja': 'ライトブルー'},
    ),
    ThemeColorReward(
      id: 'lime_green',
      color: Color(0xFFC0CA33), // Colors.lime[600]
      unlockCondition: UnlockCondition.module(3, 7), // M8
      name: {'zh': '萊姆綠', 'en': 'Lime Green', 'ja': 'ライムグリーン'},
    ),

    // ─── 傳奇獎勵 (3) ───
    ThemeColorReward(
      id: 'satellite_gold',
      color: Color(0xFFFFB300), // Colors.amber[600]
      unlockCondition: UnlockCondition.yearComplete(1),
      isLegendary: true,
      name: {'zh': '🛰️ 衛星金', 'en': '🛰️ Satellite Gold', 'ja': '🛰️ サテライトゴールド'},
    ),
    ThemeColorReward(
      id: 'mecha_orange',
      color: Color(0xFFFF7043), // Colors.deepOrange[400]
      unlockCondition: UnlockCondition.yearComplete(2),
      isLegendary: true,
      name: {'zh': '🤖 機甲橙', 'en': '🤖 Mecha Orange', 'ja': '🤖 メカオレンジ'},
    ),
    ThemeColorReward(
      id: 'spire_cyan',
      color: Color(0xFF26C6DA), // Colors.cyan[400]
      unlockCondition: UnlockCondition.yearComplete(3),
      isLegendary: true,
      name: {'zh': '🗼 尖塔青', 'en': '🗼 Spire Cyan', 'ja': '🗼 スパイアシアン'},
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 記錄上限獎勵
  // ═══════════════════════════════════════════════════════════════════════════

  /// 所有記錄上限獎勵（按解鎖順序）
  /// 目標：Year 1 = 10,000 / Year 2 = 30,000 / Year 3 = 50,000
  static const List<HistoryLimitReward> allHistoryLimits = [
    // 初始
    HistoryLimitReward(
      id: 'limit_1000',
      limit: 1000,
      unlockCondition: UnlockCondition.initial(),
    ),

    // Year 1 → 10,000
    HistoryLimitReward(
      id: 'limit_2000',
      limit: 2000,
      unlockCondition: UnlockCondition.module(1, 2), // M3
    ),
    HistoryLimitReward(
      id: 'limit_4000',
      limit: 4000,
      unlockCondition: UnlockCondition.module(1, 5), // M6
    ),
    HistoryLimitReward(
      id: 'limit_7000',
      limit: 7000,
      unlockCondition: UnlockCondition.module(1, 9), // M10
    ),
    HistoryLimitReward(
      id: 'limit_10000',
      limit: 10000,
      unlockCondition: UnlockCondition.yearComplete(1), // Year 1 完成
    ),

    // Year 2 → 30,000
    HistoryLimitReward(
      id: 'limit_15000',
      limit: 15000,
      unlockCondition: UnlockCondition.module(2, 4), // M5
    ),
    HistoryLimitReward(
      id: 'limit_22000',
      limit: 22000,
      unlockCondition: UnlockCondition.module(2, 9), // M10
    ),
    HistoryLimitReward(
      id: 'limit_30000',
      limit: 30000,
      unlockCondition: UnlockCondition.yearComplete(2), // Year 2 完成
    ),

    // Year 3 → 50,000
    HistoryLimitReward(
      id: 'limit_37000',
      limit: 37000,
      unlockCondition: UnlockCondition.module(3, 4), // M5
    ),
    HistoryLimitReward(
      id: 'limit_44000',
      limit: 44000,
      unlockCondition: UnlockCondition.module(3, 9), // M10
    ),
    HistoryLimitReward(
      id: 'limit_50000',
      limit: 50000,
      unlockCondition: UnlockCondition.yearComplete(3), // Year 3 完成
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // 輔助方法
  // ═══════════════════════════════════════════════════════════════════════════

  /// 根據 ID 找主題色
  static ThemeColorReward? findThemeColorById(String id) {
    try {
      return allThemeColors.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根據 ID 找記錄上限
  static HistoryLimitReward? findHistoryLimitById(String id) {
    try {
      return allHistoryLimits.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 獲取初始解鎖的主題色
  static List<ThemeColorReward> get initialThemeColors {
    return allThemeColors
        .where((c) => c.unlockCondition.type == UnlockConditionType.initial)
        .toList();
  }

  /// 獲取傳奇主題色
  static List<ThemeColorReward> get legendaryThemeColors {
    return allThemeColors.where((c) => c.isLegendary).toList();
  }

  /// 獲取指定年份的主題色（不含傳奇）
  static List<ThemeColorReward> getThemeColorsForYear(int year) {
    return allThemeColors.where((c) {
      if (c.isLegendary) return false;
      final condition = c.unlockCondition;
      return condition.type == UnlockConditionType.moduleComplete &&
          condition.year == year;
    }).toList();
  }

  /// 主題色總數
  static int get totalThemeColorCount => allThemeColors.length;

  /// 記錄上限階段數
  static int get totalHistoryLimitStages => allHistoryLimits.length;
}
