// lib/rewards/ui/reward_popup.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_text.dart';
import '../data/reward_models.dart';

/// 獎勵解鎖彈窗
class RewardUnlockPopup {
  /// 顯示模組完成獎勵彈窗
  static Future<void> show(
    BuildContext context, {
    required RewardUnlockResult result,
    required String moduleName,
    bool isYearComplete = false,
  }) async {
    if (!result.hasNewRewards) return;

    HapticFeedback.heavyImpact();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RewardPopupDialog(
        result: result,
        moduleName: moduleName,
        isYearComplete: isYearComplete,
      ),
    );
  }

  /// 顯示首次成長系統介紹彈窗
  static Future<void> showIntro(
    BuildContext context, {
    required List<ThemeColorReward> initialColors,
    required int initialHistoryLimit,
  }) async {
    HapticFeedback.mediumImpact();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _IntroPopupDialog(
        initialColors: initialColors,
        initialHistoryLimit: initialHistoryLimit,
      ),
    );
  }
}

/// 獎勵解鎖彈窗內容
class _RewardPopupDialog extends StatelessWidget {
  final RewardUnlockResult result;
  final String moduleName;
  final bool isYearComplete;

  const _RewardPopupDialog({
    required this.result,
    required this.moduleName,
    required this.isYearComplete,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppText.language;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isYearComplete
                ? [const Color(0xFF1a1a2e), const Color(0xFF0f0f1a)]
                : [const Color(0xFF1e1e2e), const Color(0xFF141420)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isYearComplete
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: isYearComplete ? 2 : 1,
          ),
          boxShadow: isYearComplete
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 標題
              Text(
                isYearComplete
                    ? AppText.rewardLegendaryUnlock
                    : AppText.rewardUnlockTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isYearComplete ? Colors.amber : Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // 模組名稱
              Text(
                moduleName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 24),

              // 主題色獎勵
              if (result.unlockedColors.isNotEmpty) ...[
                _buildColorRewards(context, locale),
                const SizedBox(height: 16),
              ],

              // 記錄上限獎勵
              if (result.unlockedHistoryLimit != null) ...[
                _buildHistoryLimitReward(context, locale),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // 確認按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isYearComplete
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: isYearComplete ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppText.rewardContinue,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorRewards(BuildContext context, String locale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            AppText.rewardNewThemeColor,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: result.unlockedColors.map((reward) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: reward.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: reward.color.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: reward.isLegendary
                        ? const Icon(Icons.star, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reward.getName(locale),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLimitReward(BuildContext context, String locale) {
    final limit = result.unlockedHistoryLimit!;
    final limitText = limit.limit < 0
        ? (locale == 'zh' ? '無上限' : locale == 'ja' ? '無制限' : 'Unlimited')
        : '${limit.limit}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            AppText.rewardHistoryLimitUp,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              limitText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 首次成長系統介紹彈窗
class _IntroPopupDialog extends StatelessWidget {
  final List<ThemeColorReward> initialColors;
  final int initialHistoryLimit;

  const _IntroPopupDialog({
    required this.initialColors,
    required this.initialHistoryLimit,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppText.language;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1e1e2e), Color(0xFF141420)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 歡迎圖示
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.blue,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              // 標題
              Text(
                AppText.growthIntroTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // 說明
              Text(
                AppText.growthIntroDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 初始獎勵區塊
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      AppText.growthIntroInitialRewards,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 初始主題色
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: initialColors.map((reward) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: reward.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reward.getName(locale),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 12),

                    // 初始記錄上限
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.storage,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${AppText.rewardsHistoryLimit}：$initialHistoryLimit',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 開始按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppText.growthIntroStart,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
