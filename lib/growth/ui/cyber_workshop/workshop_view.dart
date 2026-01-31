import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_text.dart';
import '../../data/cyber_part.dart';
import '../../data/growth_state.dart';
import '../../data/year_config.dart';
import '../../logic/growth_service.dart';

/// Full-screen cyber workshop view - a hidden pomodoro timer easter egg.
///
/// Features:
/// - 15 minute forge timer
/// - Earns 0.2 CP per completion (max 1.0 CP / 5 sessions per day)
/// - Cyberpunk industrial aesthetic
/// - Floating gear/part emojis
/// - Ambient forge sounds
class CyberWorkshopView extends StatefulWidget {
  const CyberWorkshopView({super.key});

  @override
  State<CyberWorkshopView> createState() => _CyberWorkshopViewState();
}

class _CyberWorkshopViewState extends State<CyberWorkshopView>
    with TickerProviderStateMixin {
  // Timer state
  static const int forgeDurationSeconds = 15 * 60; // 15 minutes
  Timer? _timer;
  int _remainingSeconds = forgeDurationSeconds;
  bool _isForging = false;
  bool _isPaused = false;
  bool _showTime = true; // Toggle time display

  // Animation controllers
  late AnimationController _backgroundAnimController;
  late AnimationController _glowAnimController;
  late AnimationController _completeAnimController;

  // Floating emojis
  final List<_FloatingEmoji> _floatingEmojis = [];
  static const List<String> _forgeEmojis = [
    '⚙️', '🔧', '🔩', '⛓️', '🔨', '🛠️', '⚡', '🔥',
  ];

  @override
  void initState() {
    super.initState();
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _glowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _completeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initFloatingEmojis();
  }

  void _initFloatingEmojis() {
    final random = math.Random();
    for (int i = 0; i < 8; i++) {
      _floatingEmojis.add(_FloatingEmoji(
        emoji: _forgeEmojis[random.nextInt(_forgeEmojis.length)],
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 20 + random.nextDouble() * 20,
        speed: 0.0002 + random.nextDouble() * 0.0003,
        opacity: 0.15 + random.nextDouble() * 0.2,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.001,
      ));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _backgroundAnimController.dispose();
    _glowAnimController.dispose();
    _completeAnimController.dispose();
    super.dispose();
  }

  void _startForge() {
    if (_isForging) return;

    setState(() {
      _isForging = true;
      _isPaused = false;
      _remainingSeconds = forgeDurationSeconds;
    });

    HapticFeedback.mediumImpact();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          _onForgeComplete();
        }
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    HapticFeedback.lightImpact();
  }

  void _cancelForge() {
    _timer?.cancel();
    setState(() {
      _isForging = false;
      _isPaused = false;
      _remainingSeconds = forgeDurationSeconds;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _onForgeComplete() async {
    _timer?.cancel();

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Play completion animation
    _completeAnimController.forward(from: 0);

    // Earn CP
    final result = await GrowthService.instance.earnForgeCp();

    setState(() {
      _isForging = false;
      _isPaused = false;
      _remainingSeconds = forgeDurationSeconds;
    });

    // Show completion message
    if (mounted) {
      final message = result.isSuccess
          ? AppText.forgeComplete(result.cpGained)
          : AppText.forgeLimitReached;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result.isSuccess ? Colors.green[700] : Colors.orange[700],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GrowthService.instance,
      builder: (context, _) {
        final service = GrowthService.instance;
        final yearConfig = service.getCurrentYearConfig();
        final currentPart = service.getCurrentPart();

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              if (!_isForging) {
                Navigator.of(context).pop();
              }
            },
            child: Stack(
              children: [
                // Background gradient
                _buildBackground(yearConfig),

                // Animated background effects
                _buildAnimatedBackground(yearConfig),

                // Floating emojis
                _buildFloatingEmojis(),

                // Main content
                SafeArea(
                  child: Stack(
                    children: [
                      // Top left - Status info
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildStatusPanel(service, yearConfig),
                      ),

                      // Top right - Forge CP display
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildForgeCpDisplay(service, yearConfig),
                      ),

                      // Center - Main forge area
                      Center(
                        child: _buildForgeCenter(
                          currentPart,
                          yearConfig,
                          service.animationPhase,
                        ),
                      ),

                      // Bottom - Status text
                      Positioned(
                        bottom: 40,
                        left: 0,
                        right: 0,
                        child: _buildBottomStatus(yearConfig),
                      ),
                    ],
                  ),
                ),

                // Close hint (when not forging)
                if (!_isForging)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        AppText.tapToClose,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(YearConfig yearConfig) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0a0a0a),
            const Color(0xFF1a1510),
            const Color(0xFF0d0d0d),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(YearConfig yearConfig) {
    return AnimatedBuilder(
      animation: _backgroundAnimController,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _WorkshopBackgroundPainter(
            animation: _backgroundAnimController.value,
            accentColor: const Color(0xFFFFBF00), // Amber/gold for forge
          ),
        );
      },
    );
  }

  Widget _buildFloatingEmojis() {
    return AnimatedBuilder(
      animation: _backgroundAnimController,
      builder: (context, _) {
        // Update emoji positions
        for (final emoji in _floatingEmojis) {
          emoji.y -= emoji.speed;
          emoji.rotation += emoji.rotationSpeed;
          if (emoji.y < -0.1) {
            emoji.y = 1.1;
            emoji.x = math.Random().nextDouble();
          }
        }

        return Stack(
          children: _floatingEmojis.map((emoji) {
            return Positioned(
              left: emoji.x * MediaQuery.of(context).size.width,
              top: emoji.y * MediaQuery.of(context).size.height,
              child: Transform.rotate(
                angle: emoji.rotation,
                child: Opacity(
                  opacity: emoji.opacity,
                  child: Text(
                    emoji.emoji,
                    style: TextStyle(fontSize: emoji.size),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusPanel(GrowthService service, YearConfig yearConfig) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFBF00).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getModuleName(service),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: service.yearProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFBF00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                service.getProgressText(language: AppText.language),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getModuleName(GrowthService service) {
    final module = service.getCurrentModule();
    final round = service.currentRound;
    final displayName = AppText.growthModuleName(module.id);
    return '${AppText.growthRoundNumber(round)}: $displayName';
  }

  Widget _buildForgeCpDisplay(GrowthService service, YearConfig yearConfig) {
    final forgeCp = service.todayForgeCp;
    final forgeCount = service.todayForgeCpCount;
    final canEarn = service.canEarnForgeCp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFBF00).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚙️ FORGE CP',
                style: TextStyle(
                  color: const Color(0xFFFFBF00),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${forgeCp.toStringAsFixed(1)} / 1.0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 5 slot indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < forgeCount;
              return Container(
                width: 12,
                height: 12,
                margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled
                      ? const Color(0xFFFFBF00)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: const Color(0xFFFFBF00).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: filled
                    ? const Center(
                        child: Text('✓', style: TextStyle(fontSize: 8, color: Colors.black)),
                      )
                    : null,
              );
            }),
          ),
          if (!canEarn) ...[
            const SizedBox(height: 4),
            Text(
              AppText.forgeDailyMax,
              style: TextStyle(
                color: Colors.orange.withValues(alpha: 0.8),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForgeCenter(
    CyberPart currentPart,
    YearConfig yearConfig,
    PartAnimationPhase phase,
  ) {
    final progress = _isForging
        ? 1 - (_remainingSeconds / forgeDurationSeconds)
        : 0.0;

    return GestureDetector(
      onTap: () {
        if (!_isForging) {
          _startForge();
        } else {
          setState(() {
            _showTime = !_showTime;
          });
        }
      },
      onDoubleTap: _isForging ? _togglePause : null,
      onLongPress: _isForging ? _cancelForge : null,
      child: AnimatedBuilder(
        animation: _glowAnimController,
        builder: (context, _) {
          final glowIntensity = _isForging
              ? 0.4 + 0.3 * _glowAnimController.value
              : 0.2 + 0.1 * _glowAnimController.value;

          return AnimatedBuilder(
            animation: _completeAnimController,
            builder: (context, _) {
              final completeScale = 1.0 + 0.3 * _completeAnimController.value;

              return Transform.scale(
                scale: completeScale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFBF00).withValues(alpha: glowIntensity),
                        blurRadius: _isForging ? 60 : 30,
                        spreadRadius: _isForging ? 10 : 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isPaused
                                ? Colors.orange
                                : const Color(0xFFFFBF00),
                          ),
                        ),
                      ),

                      // Inner circle background
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.7),
                          border: Border.all(
                            color: const Color(0xFFFFBF00).withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                      ),

                      // Part emoji
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentPart.emoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                          if (_isForging && _showTime) ...[
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: TextStyle(
                                color: _isPaused ? Colors.orange : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                          if (_isPaused)
                            Text(
                              AppText.forgePaused,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomStatus(YearConfig yearConfig) {
    String statusText;
    if (!_isForging) {
      statusText = AppText.forgeTapToStart;
    } else if (_isPaused) {
      statusText = AppText.forgeDoubleTapResume;
    } else {
      statusText = AppText.forgeInProgress;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status text with glow effect
        Text(
          _isForging ? '⚙️ ${AppText.forgeStatus} ⚙️' : '⚙️ ${AppText.forgeReady} ⚙️',
          style: TextStyle(
            color: const Color(0xFFFFBF00),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: const Color(0xFFFFBF00).withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          statusText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        if (_isForging) ...[
          const SizedBox(height: 4),
          Text(
            AppText.forgeLongPressCancel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

/// Floating emoji data class
class _FloatingEmoji {
  final String emoji;
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  double rotation;
  final double rotationSpeed;

  _FloatingEmoji({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    this.rotation = 0,
    required this.rotationSpeed,
  });
}

/// Background painter for workshop atmosphere
class _WorkshopBackgroundPainter extends CustomPainter {
  final double animation;
  final Color accentColor;

  _WorkshopBackgroundPainter({
    required this.animation,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Grid lines (factory feel)
    paint.color = accentColor.withValues(alpha: 0.05);
    for (var x = 0.0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Animated sparks/particles
    final sparkPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final offset = (animation + i * 0.1) % 1.0;

      final x = baseX;
      final y = (baseY - offset * 100) % size.height;
      final alpha = (1 - offset) * 0.5;

      sparkPaint.color = accentColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 1.5, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WorkshopBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
