import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_text.dart';
import '../../services/ad_service.dart';
import '../data/growth_state.dart';
import '../data/year_config.dart';
import '../logic/growth_service.dart';

/// Main display card for the Cyber Parts growth system.
///
/// Shows:
/// - Current part emoji with day-based animation
/// - Year-specific background gradient
/// - Progress text (day/sync%/floor)
/// - Module name
/// - Tap to open detail sheet
class CyberForgeCard extends StatefulWidget {
  /// Whether this card is currently visible/active.
  /// When false, animations are paused to save battery.
  final bool isActive;

  /// Callback when card is tapped.
  final VoidCallback? onTap;

  /// Callback when card is long-pressed (e.g., for debug menu).
  final VoidCallback? onLongPress;

  const CyberForgeCard({
    super.key,
    this.isActive = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<CyberForgeCard> createState() => _CyberForgeCardState();
}

class _CyberForgeCardState extends State<CyberForgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Only start animation if card is active
    if (widget.isActive) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CyberForgeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start/stop animation when isActive changes
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GrowthService.instance,
      builder: (context, _) {
        final service = GrowthService.instance;
        if (!service.isInitialized) {
          return _buildLoadingCard(context);
        }

        final yearConfig = service.getCurrentYearConfig();
        final currentPart = service.getCurrentPart();
        final animPhase = service.animationPhase;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onLongPress?.call();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: yearConfig.backgroundColors,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: yearConfig.accentColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background stars/particles (Year 1)
                  if (yearConfig.year == 1) _buildCosmicBackground(),
                  // Factory grid (Year 2)
                  if (yearConfig.year == 2) _buildFactoryBackground(),
                  // Neon lines (Year 3)
                  if (yearConfig.year == 3) _buildNeonBackground(),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        // Award preview - top right
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Text(
                            yearConfig.awardEmoji,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        // Main content row
                        Row(
                          children: [
                            // Part emoji with animation
                            _buildPartEmoji(
                              currentPart.emoji,
                              animPhase,
                              yearConfig.accentColor,
                            ),
                            const SizedBox(width: 16),

                            // Info column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Year title
                                  _buildYearTitle(yearConfig),
                                  const SizedBox(height: 4),

                                  // Progress text + Round progress (same line)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        service.getProgressText(language: AppText.language),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${AppText.growthRoundDay(service.getDaysInCurrentRound())}/${service.getDaysForCurrentRound()}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Module name
                                  Text(
                                    _getModuleName(service),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Progress bar
                                  _buildProgressBar(service, yearConfig),

                                  // CP section
                                  const SizedBox(height: 10),
                                  _buildCpSection(service, yearConfig),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCpSection(GrowthService service, YearConfig yearConfig) {
    final cpBalance = service.cpBalance;
    final scanCount = service.todayScanCpCount;
    final adCount = service.todayAdCpCount;
    final canInjectScan = service.canInjectScanCp;
    final canInjectAd = service.canInjectAdCp;
    final canWatchAd = adCount < GrowthService.maxDailyAdCp;

    // Amber gold color for injection buttons
    const amberGold = Color(0xFFFFB300);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 8),

        // CP progress row
        Row(
          children: [
            // CP label and bar
            Expanded(
              child: Row(
                children: [
                  Text(
                    'CP',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildCpProgressBar(cpBalance, yearConfig),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cpBalance.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Stats row with injection buttons
        Row(
          children: [
            // Scan stat or injection button
            canInjectScan
                ? GestureDetector(
                    onTap: () => _onScanInjectTap(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: amberGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: amberGold,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '⚡ ${AppText.cpScanInject}',
                        style: const TextStyle(
                          color: amberGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '${AppText.cpScanCount}: $scanCount/${GrowthService.maxDailyScanCp}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
            const SizedBox(width: 12),

            // Energy stat or injection button
            canInjectAd
                ? GestureDetector(
                    onTap: () => _onEnergyInjectTap(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: amberGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: amberGold,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '⚡ ${AppText.cpEnergyInject}',
                        style: const TextStyle(
                          color: amberGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '${AppText.cpEnergyCount}: $adCount/${GrowthService.maxDailyAdCp}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
            const Spacer(),

            // Energy boost button (only show if not full)
            if (canWatchAd && !canInjectAd)
              GestureDetector(
                onTap: () => _onEnergyBoostTap(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: yearConfig.accentColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: yearConfig.accentColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 12,
                        color: yearConfig.accentColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '+0.5',
                        style: TextStyle(
                          color: yearConfig.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _onScanInjectTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    _showInjectDialog(context, isScan: true);
  }

  void _onEnergyInjectTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    _showInjectDialog(context, isScan: false);
  }

  Future<void> _showInjectDialog(BuildContext context, {required bool isScan}) async {
    final service = GrowthService.instance;

    // Perform injection
    final result = isScan
        ? await service.injectScanCp()
        : await service.injectAdCp();

    if (!result.isSuccess || !context.mounted) return;

    // Amber gold color
    const amberGold = Color(0xFFFFB300);

    // Show reward dialog
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: amberGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          isScan ? AppText.cpInjectDialogScanTitle : AppText.cpInjectDialogEnergyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: amberGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚡',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              isScan ? AppText.cpInjectDialogScanMessage : AppText.cpInjectDialogEnergyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppText.cpInjectDialogReward(result.bonusDays),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: amberGold,
              ),
              child: Text(
                AppText.cpInjectDialogConfirm,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCpProgressBar(double cpBalance, YearConfig yearConfig) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: cpBalance.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: yearConfig.accentColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  void _onEnergyBoostTap(BuildContext context) {
    HapticFeedback.lightImpact();
    _showEnergyBoostDialog(context);
  }

  Future<void> _showEnergyBoostDialog(BuildContext context) async {
    final adService = AdService();
    final service = GrowthService.instance;
    final remaining = GrowthService.maxDailyAdCp - service.todayAdCpCount;

    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppText.cpEnergyBoostTitle),
        content: Text(AppText.cpEnergyBoostMessage(
          remaining,
          GrowthService.maxDailyAdCp,
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppText.cpEnergyBoostCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppText.cpEnergyBoostConfirm),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    // Show rewarded ad
    final rewardAmount = await adService.showRewardedAd();
    if (rewardAmount > 0) {
      // Ad watched successfully, earn CP
      final cpResult = await GrowthService.instance.earnAdCp();
      if (cpResult.isSuccess && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppText.cpEnergyBoostSuccess(cpResult.cpGained)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPartEmoji(
    String emoji,
    PartAnimationPhase phase,
    Color accentColor,
  ) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        double scale = 1.0;
        double rotation = 0.0;
        double glowOpacity = 0.0;

        switch (phase) {
          case PartAnimationPhase.spawn:
            // Bounce effect
            scale = 1.0 + 0.15 * math.sin(_animController.value * math.pi);
            break;

          case PartAnimationPhase.polish:
            // Rotation wobble
            rotation = 0.1 * math.sin(_animController.value * math.pi * 2);
            break;

          case PartAnimationPhase.charge:
            // Glow pulse
            glowOpacity = 0.3 + 0.4 * _animController.value;
            break;

          case PartAnimationPhase.settle:
            // Subtle pulse, ready to move
            scale = 0.95 + 0.05 * _animController.value;
            break;
        }

        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.3),
            boxShadow: glowOpacity > 0
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: glowOpacity),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotation,
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearTitle(YearConfig yearConfig) {
    final title = switch (yearConfig.year) {
      1 => AppText.growthYear1Title,
      2 => AppText.growthYear2Title,
      3 => AppText.growthYear3Title,
      _ => 'Growth',
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            AppText.growthYearNumber(yearConfig.year),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getModuleName(GrowthService service) {
    final module = service.getCurrentModule();
    final round = service.currentRound;
    final displayName = AppText.growthModuleName(module.id);
    final currentPart = service.getCurrentPart();
    final partName = AppText.growthPartName(currentPart.id);

    return '${AppText.growthRoundNumber(round)}: $displayName - $partName';
  }

  Widget _buildProgressBar(GrowthService service, YearConfig yearConfig) {
    final progress = service.yearProgress;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                yearConfig.accentColor,
                yearConfig.accentColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildCosmicBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _StarsPainter(animation: _animController),
      ),
    );
  }

  Widget _buildFactoryBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildNeonBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _NeonLinesPainter(animation: _animController),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _StarsPainter extends CustomPainter {
  final Animation<double> animation;

  _StarsPainter({required this.animation}) : super(repaint: animation);

  static final List<Offset> _starPositions = List.generate(
    15,
    (i) => Offset(
      (i * 17 + 7) % 100 / 100,
      (i * 23 + 13) % 100 / 100,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var i = 0; i < _starPositions.length; i++) {
      final pos = _starPositions[i];
      final x = pos.dx * size.width;
      final y = pos.dy * size.height;

      // Twinkle effect
      final twinkle = 0.3 + 0.7 * math.sin(animation.value * math.pi * 2 + i);
      paint.color = Colors.white.withValues(alpha: twinkle * 0.6);

      final radius = (i % 3 + 1) * 0.8;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFBF00).withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // Vertical lines
    for (var x = 0.0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeonLinesPainter extends CustomPainter {
  final Animation<double> animation;

  _NeonLinesPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Animated horizontal lines
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.3 + i * 0.2);
      final progress = (animation.value + i * 0.3) % 1.0;

      paint.color = Colors.cyan.withValues(alpha: 0.3);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width * progress, y),
        paint,
      );
    }

    // Vertical accent
    paint.color = const Color(0xFFFF00FF).withValues(alpha: 0.2); // Magenta
    final x = size.width * 0.85;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height * animation.value),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _NeonLinesPainter oldDelegate) => false;
}
