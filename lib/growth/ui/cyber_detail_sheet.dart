// Cyber Parts Growth System - Detail Sheet
// 成長系統詳情底部 Sheet

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_text.dart';
import '../../rewards/data/reward_constants.dart';
import '../../rewards/logic/reward_service.dart';
import '../data/year_config.dart';
import '../logic/growth_service.dart';
import 'cyber_parts_grid.dart';

/// 顯示成長系統詳情的底部 Sheet
class CyberDetailSheet extends StatelessWidget {
  const CyberDetailSheet({super.key});

  /// 顯示詳情 Sheet
  static void show(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CyberDetailSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GrowthService.instance,
      builder: (context, _) {
        final service = GrowthService.instance;
        if (!service.isInitialized) {
          return const SizedBox.shrink();
        }

        final yearConfig = service.getCurrentYearConfig();

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return _SheetContent(
              scrollController: scrollController,
              service: service,
              yearConfig: yearConfig,
            );
          },
        );
      },
    );
  }
}

class _SheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final GrowthService service;
  final YearConfig yearConfig;

  const _SheetContent({
    required this.scrollController,
    required this.service,
    required this.yearConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D1117),
            const Color(0xFF161B22),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: yearConfig.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: yearConfig.accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 拖曳指示器
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: yearConfig.accentColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 標題
          _buildHeader(context),

          Divider(
            height: 1,
            color: yearConfig.accentColor.withValues(alpha: 0.2),
          ),

          // 可滾動內容
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // 當前進度區塊
                _buildCurrentProgressSection(context),

                const SizedBox(height: 24),

                // 本模組收集區塊
                _buildModuleCollectionSection(context),

                const SizedBox(height: 24),

                // 年度成就區塊
                _buildYearAwardsSection(context),

                const SizedBox(height: 24),

                // 獎勵收藏區塊
                _buildRewardsSection(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = switch (yearConfig.year) {
      1 => AppText.growthYear1Title,
      2 => AppText.growthYear2Title,
      3 => AppText.growthYear3Title,
      _ => 'Cyber Parts',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: yearConfig.accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: yearConfig.accentColor.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                yearConfig.awardEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                AppText.growthDetailSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: yearConfig.accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppText.growthYearNumber(yearConfig.year),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: yearConfig.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentProgressSection(BuildContext context) {
    final currentPart = service.getCurrentPart();
    final moduleProgress = service.getModuleProgress();
    final module = service.getCurrentModule();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            yearConfig.accentColor.withValues(alpha: 0.15),
            yearConfig.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: yearConfig.accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題行
          Row(
            children: [
              Text(
                AppText.growthCurrentPart,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: yearConfig.accentColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppText.growthRoundNumber(service.currentRound),
                  style: TextStyle(
                    fontSize: 11,
                    color: yearConfig.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 當前零件顯示
          Row(
            children: [
              // 當前零件 emoji
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: yearConfig.accentColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: yearConfig.accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    currentPart.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 箭頭
              Icon(
                Icons.arrow_forward,
                color: Colors.white.withValues(alpha: 0.3),
              ),

              const SizedBox(width: 12),

              // 目標（神秘）
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Center(
                  child: Text(
                    '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 天數顯示
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppText.growthRoundDay(service.getDaysInCurrentRound()),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '/ ${service.getDaysForCurrentRound()} ${AppText.growthDaysUnit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 進度條
          _buildProgressBar(moduleProgress, yearConfig.accentColor),

          const SizedBox(height: 8),

          // 進度文字
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(moduleProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: yearConfig.accentColor,
                ),
              ),
              Text(
                AppText.growthPartProgress(
                  service.currentPartIndex + 1,
                  module.parts.length,
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCollectionSection(BuildContext context) {
    final module = service.getCurrentModule();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題行
        Row(
          children: [
            Text(
              AppText.growthModuleCollection,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            FutureBuilder<Set<String>>(
              future: service.getCollectedPartIds(yearConfig.year),
              builder: (context, snapshot) {
                final collectedIds = snapshot.data ?? {};
                final moduleCollected = module.parts
                    .where((p) => collectedIds.contains(p.id))
                    .length;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: yearConfig.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$moduleCollected / ${module.parts.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: yearConfig.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 零件網格
        FutureBuilder<Set<String>>(
          future: service.getCollectedPartIds(yearConfig.year),
          builder: (context, snapshot) {
            final collectedIds = snapshot.data ?? {};

            return CyberPartsGrid(
              parts: module.parts,
              collectedIds: collectedIds,
              accentColor: yearConfig.accentColor,
              currentRound: service.currentRound,
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearAwardsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Text(
            AppText.growthYearAwards,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),

          // 三年成就
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildYearAwardItem(1, '🛰️', service.yearAwards.contains('🛰️')),
              _buildYearAwardItem(2, '🤖', service.yearAwards.contains('🤖')),
              _buildYearAwardItem(3, '🗼', service.yearAwards.contains('🗼')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearAwardItem(int year, String emoji, bool isUnlocked) {
    final color = switch (year) {
      1 => const Color(0xFF4DA6FF), // 藍色
      2 => const Color(0xFFFF6B35), // 橘色
      3 => const Color(0xFF00FFFF), // 青色
      _ => Colors.white,
    };

    final progress = service.totalDays / (year * 365);

    return GestureDetector(
      onTap: isUnlocked ? () => _showAwardDetail(year, emoji, color) : null,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked
                    ? color.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: isUnlocked ? 2 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(emoji, style: const TextStyle(fontSize: 28))
                  : Text(
                      '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            AppText.growthYearLabel(year),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isUnlocked ? color : Colors.white.withValues(alpha: 0.5),
            ),
          ),

          // 未解鎖時顯示進度
          if (!isUnlocked) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAwardDetail(int year, String emoji, Color color) {
    HapticFeedback.lightImpact();
    // TODO: 實現成就詳情彈窗
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 獎勵收藏區塊
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRewardsSection(BuildContext context) {
    final rewardService = RewardService.instance;
    final unlockedColors = rewardService.unlockedThemeColors;
    final nextColor = rewardService.nextThemeColorToUnlock;
    final currentLimit = rewardService.currentHistoryLimit;
    final nextLimit = rewardService.nextHistoryLimitToUnlock;
    final locale = AppText.language;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                AppText.rewardsTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 主題色收藏
          _buildThemeColorRewards(
            context,
            unlockedColors,
            nextColor,
            locale,
          ),

          const SizedBox(height: 16),

          // 記錄容量
          _buildHistoryLimitReward(
            context,
            currentLimit,
            nextLimit,
            locale,
          ),

          const SizedBox(height: 16),

          // 傳奇獎勵
          _buildLegendaryRewards(context, locale),
        ],
      ),
    );
  }

  Widget _buildThemeColorRewards(
    BuildContext context,
    List unlockedColors,
    dynamic nextColor,
    String locale,
  ) {
    final totalColors = RewardConstants.totalThemeColorCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.palette, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              AppText.rewardsThemeColors,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Text(
              '${unlockedColors.length}/$totalColors',
              style: TextStyle(
                fontSize: 12,
                color: yearConfig.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 已解鎖的顏色
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...unlockedColors.map((reward) => Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: reward.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                )),
            // 下一個即將解鎖
            if (nextColor != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: nextColor.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 12,
                  color: Colors.white38,
                ),
              ),
          ],
        ),

        // 下一個解鎖提示
        if (nextColor != null) ...[
          const SizedBox(height: 8),
          Text(
            '${AppText.rewardsNextUnlock}: ${nextColor.getName(locale)} (${nextColor.unlockCondition.getShortText(locale)})',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryLimitReward(
    BuildContext context,
    int currentLimit,
    dynamic nextLimit,
    String locale,
  ) {
    final limitText = currentLimit < 0
        ? (locale == 'zh' ? '無上限' : locale == 'ja' ? '無制限' : 'Unlimited')
        : '$currentLimit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.storage, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              AppText.rewardsHistoryLimit,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: yearConfig.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                limitText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: yearConfig.accentColor,
                ),
              ),
            ),
          ],
        ),

        // 下一階段提示
        if (nextLimit != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                AppText.rewardsNextStage,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                nextLimit.limit < 0
                    ? (locale == 'zh' ? '無上限' : locale == 'ja' ? '無制限' : '∞')
                    : '${nextLimit.limit}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' (${nextLimit.unlockCondition.getShortText(locale)})',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendaryRewards(BuildContext context, String locale) {
    final legendaryColors = RewardConstants.legendaryThemeColors;
    final rewardService = RewardService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(
              AppText.rewardsLegendary,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: legendaryColors.map((reward) {
            final isUnlocked = rewardService.isThemeColorUnlocked(reward);
            return _buildLegendaryItem(reward, isUnlocked, locale);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendaryItem(dynamic reward, bool isUnlocked, String locale) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isUnlocked
                ? reward.color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked
                  ? reward.color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: isUnlocked ? 2 : 1,
            ),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: reward.color.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isUnlocked
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: reward.color,
                      shape: BoxShape.circle,
                    ),
                  )
                : Icon(
                    Icons.lock,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          reward.getName(locale),
          style: TextStyle(
            fontSize: 10,
            color: isUnlocked
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.4),
            fontWeight: isUnlocked ? FontWeight.w500 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
