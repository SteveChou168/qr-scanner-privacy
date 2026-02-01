import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  // 30fps optimization for background/emojis (saves ~50% battery)
  Timer? _backgroundTimer;
  double _backgroundAnimValue = 0.0;
  static const _backgroundFrameInterval = 33; // ~30fps in ms

  // Floating emojis
  final List<_FloatingEmoji> _floatingEmojis = [];
  static const List<String> _forgeEmojis = [
    '⚙️', '🔧', '🔩', '⛓️', '🔨', '🛠️', '⚡', '🔥',
  ];

  // Gravity lock (easter egg within easter egg)
  bool _isGravityLocked = false;
  double _deviceAngle = 0.0;
  double _lastDeviceAngle = 0.0; // For haptic feedback calculation
  int _gravityHapticCounter = 0; // Throttle haptic feedback
  Orientation? _lockedOrientation; // Remember orientation when locked
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  // Fire ambience sound
  bool _isFireOn = false;
  AudioPlayer? _firePlayer;
  late AnimationController _fireAnimController;

  // Fidget Spinner (easter egg within easter egg)
  double _spinnerAngle = 0.0; // Current rotation angle
  double _spinnerVelocity = 0.0; // Angular velocity (rad/s)
  double _lastTouchAngle = 0.0; // Last touch angle for delta calculation
  bool _isTouching = false; // Whether user is touching
  Offset? _spinnerCenter; // Center point for angle calculation
  int _hapticCounter = 0; // Counter for periodic haptic feedback
  final List<int> _rpmHistory = []; // History for ghost number effect
  double _spinDuration = 0.0; // How long user has been spinning (seconds)
  int _sessionHighRpm = 0; // Highest RPM in current session
  int _currentRpm = 0; // Current live RPM (0 when stopped)
  static const int _rpmHistoryLength = 5; // Number of ghost frames
  static const double _maxVelocity = 50.0; // Max angular velocity
  static const int _baseMaxRpm = 6000; // Base max RPM
  static const double _phase1Duration = 20.0; // Seconds to reach 3000 RPM
  static const double _phase2Duration = 20.0; // Additional seconds to reach max (total 40s)
  static const double _friction = 0.95; // Friction coefficient (faster deceleration)
  static const double _velocityThreshold = 0.1; // Stop threshold

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Allow rotation in this screen (easter egg feature)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Background animation - but we'll use 30fps Timer instead of 60fps vsync
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    ); // Don't repeat - we use _backgroundTimer at 30fps instead

    // Start 30fps timer for background/emoji animations (battery optimization)
    _start30fpsTimer();

    _glowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _completeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fireAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initFloatingEmojis();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause everything when app goes to background (save battery)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopGravityLock();
      _firePlayer?.pause();
      _timer?.cancel(); // Stop timer to prevent background completion
      // Pause animations
      _stop30fpsTimer();
      _glowAnimController.stop();
      _fireAnimController.stop();
    } else if (state == AppLifecycleState.resumed) {
      // Resume fire sound if it was on
      if (_isFireOn) {
        _firePlayer?.resume();
        _fireAnimController.repeat(reverse: true);
      }
      // Resume timer if forging and not paused
      if (_isForging && !_isPaused) {
        _startTimer();
      }
      // Resume animations
      _start30fpsTimer();
      _glowAnimController.repeat(reverse: true);
    }
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

  // 30fps timer for background animations (saves ~50% battery vs 60fps)
  void _start30fpsTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(
      const Duration(milliseconds: _backgroundFrameInterval),
      (_) {
        if (mounted) {
          setState(() {
            // Update animation value (10 second cycle)
            _backgroundAnimValue =
                (_backgroundAnimValue + _backgroundFrameInterval / 10000) % 1.0;

            // Update fidget spinner physics (only when not touching and has velocity)
            if (!_isTouching && _spinnerVelocity.abs() > _velocityThreshold) {
              _spinnerAngle += _spinnerVelocity * (_backgroundFrameInterval / 1000);
              _spinnerVelocity *= _friction;
            } else if (!_isTouching) {
              _spinnerVelocity = 0.0; // Stop completely below threshold
            }

            // Periodic haptic feedback while spinning (frequency based on speed)
            final absVelocity = _spinnerVelocity.abs();
            if (absVelocity > _velocityThreshold) {
              _hapticCounter++;
              // Higher speed = more frequent haptics
              final hapticInterval = absVelocity > _maxVelocity * 0.7
                  ? 2  // Every 2 frames (~66ms) at high speed
                  : absVelocity > _maxVelocity * 0.4
                      ? 4  // Every 4 frames (~132ms) at medium speed
                      : 8; // Every 8 frames (~264ms) at low speed

              if (_hapticCounter >= hapticInterval) {
                _hapticCounter = 0;
                if (absVelocity > _maxVelocity * 0.7) {
                  HapticFeedback.mediumImpact();
                } else {
                  HapticFeedback.lightImpact();
                }
              }

              // Track spin duration
              _spinDuration += _backgroundFrameInterval / 1000;

              // Dynamic max RPM based on login days (6000 + totalDays)
              final totalDays = GrowthService.instance.totalDays;
              final dynamicMaxRpm = _baseMaxRpm + totalDays;

              // Two-phase RPM progression:
              // Phase 1 (0-20s): 0-3000 RPM based on velocity + time
              // Phase 2 (20-40s): 3001-max RPM with continued spinning

              int currentRpm;

              if (_spinDuration < _phase1Duration) {
                // Phase 1: velocity-based with time scaling (0-3000)
                final velocityFactor = absVelocity / _maxVelocity; // 0.0 ~ 1.0
                final timeFactor = _spinDuration / _phase1Duration; // 0.0 ~ 1.0
                // Combine: faster spin + longer time = higher RPM
                final combinedFactor = (velocityFactor * 0.6 + timeFactor * 0.4).clamp(0.0, 1.0);
                currentRpm = (combinedFactor * 3000).toInt();
              } else {
                // Phase 2: 3000 + bonus towards max (over next 20s)
                final phase2Time = _spinDuration - _phase1Duration;
                final phase2Factor = (phase2Time / _phase2Duration).clamp(0.0, 1.0);
                final bonusRpm = phase2Factor * (dynamicMaxRpm - 3000);
                currentRpm = 3000 + bonusRpm.toInt();

                // When near max, use random range (maxRpm - 50) to (maxRpm - 1)
                if (currentRpm >= dynamicMaxRpm - 60) {
                  final minRange = dynamicMaxRpm - 50;
                  final maxRange = dynamicMaxRpm - 1;
                  currentRpm = minRange + math.Random().nextInt(maxRange - minRange + 1);
                }
              }

              // Clamp to dynamic max
              currentRpm = currentRpm.clamp(0, dynamicMaxRpm - 1);

              // Track session high and history high
              if (currentRpm > _sessionHighRpm) {
                _sessionHighRpm = currentRpm;
                // Update history high if new record
                GrowthService.instance.updateSpinnerHighRpm(currentRpm);
              }

              _currentRpm = currentRpm;
              _rpmHistory.insert(0, currentRpm);
              if (_rpmHistory.length > _rpmHistoryLength) {
                _rpmHistory.removeLast();
              }
            } else {
              // Stopped spinning - reset to 0
              _currentRpm = 0;
              _rpmHistory.clear();
              _spinDuration = 0.0;
            }
          });
        }
      },
    );
  }

  void _stop30fpsTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  @override
  void dispose() {
    // Restore portrait-only when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Restore system UI (status bar, navigation bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    WidgetsBinding.instance.removeObserver(this);
    _accelSubscription?.cancel();
    _firePlayer?.dispose();
    _timer?.cancel();
    _stop30fpsTimer();
    _backgroundAnimController.dispose();
    _glowAnimController.dispose();
    _completeAnimController.dispose();
    _fireAnimController.dispose();
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

  // Gravity lock methods
  void _toggleGravityLock() {
    if (_isGravityLocked) {
      _stopGravityLock();
    } else {
      _startGravityLock();
    }
    HapticFeedback.mediumImpact();
  }

  void _startGravityLock() {
    // Lock screen orientation to current orientation
    final currentOrientation = MediaQuery.of(context).orientation;
    _lockedOrientation = currentOrientation;

    if (currentOrientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    _accelSubscription?.cancel();
    _lastDeviceAngle = _deviceAngle;
    _gravityHapticCounter = 0;

    _accelSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20Hz for smoothness
    ).listen((event) {
      // Calculate angle from accelerometer
      // Adjust axes based on locked orientation
      double newAngle;
      if (_lockedOrientation == Orientation.landscape) {
        // In landscape: swap axes and flip 180°
        newAngle = math.atan2(event.y, -event.x);
      } else {
        // In portrait: standard calculation
        newAngle = math.atan2(event.x, event.y);
      }

      // Smooth the angle with low-pass filter to reduce jitter
      const smoothingFactor = 0.18;
      const threshold = 0.015; // Ignore very small changes

      if (mounted) {
        final diff = newAngle - _deviceAngle;
        // Handle angle wrapping around ±π
        final wrappedDiff = math.atan2(math.sin(diff), math.cos(diff));

        if (wrappedDiff.abs() > threshold) {
          setState(() {
            _deviceAngle += wrappedDiff * smoothingFactor;
          });

          // Haptic feedback for gravity lock rotation
          // Skip if spinner is actively spinning (to avoid conflict)
          if (_spinnerVelocity.abs() < _velocityThreshold) {
            _gravityHapticCounter++;

            // Calculate rotation delta from last haptic check
            final rotationDelta = (_deviceAngle - _lastDeviceAngle).abs();

            // Trigger haptic based on rotation amount (throttled)
            if (_gravityHapticCounter >= 3) { // Every ~150ms
              _gravityHapticCounter = 0;

              if (rotationDelta > 0.3) {
                // Large rotation - medium impact
                HapticFeedback.mediumImpact();
                _lastDeviceAngle = _deviceAngle;
              } else if (rotationDelta > 0.1) {
                // Small rotation - light impact
                HapticFeedback.lightImpact();
                _lastDeviceAngle = _deviceAngle;
              }
            }
          }
        }
      }
    });
    setState(() => _isGravityLocked = true);
  }

  void _stopGravityLock() {
    _accelSubscription?.cancel();
    _accelSubscription = null;

    // Restore free rotation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (mounted) {
      setState(() {
        _isGravityLocked = false;
        _deviceAngle = 0.0;
        _lockedOrientation = null;
      });
    }
  }

  // Fire ambience methods
  Future<void> _toggleFire() async {
    if (_isFireOn) {
      _stopFire();
    } else {
      await _startFire();
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _startFire() async {
    _firePlayer ??= AudioPlayer();
    await _firePlayer!.setReleaseMode(ReleaseMode.loop);
    await _firePlayer!.setVolume(0.3); // Default: not too loud
    await _firePlayer!.play(AssetSource('sounds/fire_loop.mp3'));
    _fireAnimController.repeat(reverse: true);
    setState(() => _isFireOn = true);
  }

  void _stopFire() {
    _firePlayer?.stop();
    _fireAnimController.stop();
    _fireAnimController.value = 0;
    setState(() => _isFireOn = false);
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
              // Can't exit while spinner is still spinning
              if (!_isForging && _spinnerVelocity.abs() < _velocityThreshold) {
                Navigator.of(context).pop();
              }
            },
            child: OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;

                return Stack(
                  children: [
                    // Background gradient
                    _buildBackground(yearConfig),

                    // Animated background effects
                    _buildAnimatedBackground(yearConfig),

                    // Floating emojis
                    _buildFloatingEmojis(),

                    // Main content - adaptive layout
                    SafeArea(
                      child: isLandscape
                          ? _buildLandscapeLayout(service, yearConfig, currentPart)
                          : _buildPortraitLayout(service, yearConfig, currentPart),
                    ),

                    // Close hint (when not forging and not spinning fast)
                    if (!_isForging && _spinnerVelocity.abs() / _maxVelocity < 0.7)
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Portrait layout - original vertical stacked design
  Widget _buildPortraitLayout(
    GrowthService service,
    YearConfig yearConfig,
    CyberPart currentPart,
  ) {
    return Stack(
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

        // Bottom left - Gravity lock button
        Positioned(
          bottom: 100,
          left: 16,
          child: _buildGravityLockButton(yearConfig),
        ),

        // Bottom right - Fire ambience button
        Positioned(
          bottom: 100,
          right: 16,
          child: _buildFireButton(yearConfig),
        ),

        // Bottom - Status text
        Positioned(
          bottom: 56,
          left: 0,
          right: 0,
          child: _buildBottomStatus(yearConfig),
        ),
      ],
    );
  }

  /// Landscape layout - horizontal arrangement for wide screens
  Widget _buildLandscapeLayout(
    GrowthService service,
    YearConfig yearConfig,
    CyberPart currentPart,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // Scale factor based on available height (target ~300 for comfortable display)
        final heightScale = (availableHeight / 300).clamp(0.6, 1.2);

        // Calculate forge size based on available space
        final forgeSize = (availableHeight * 0.55).clamp(100.0, 180.0);

        return Row(
          children: [
            // Left panel - Status info panels
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8 * heightScale,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusPanel(service, yearConfig, scale: heightScale),
                      SizedBox(height: 12 * heightScale),
                      _buildForgeCpDisplay(service, yearConfig, scale: heightScale),
                      SizedBox(height: 12 * heightScale),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGravityLockButton(yearConfig, scale: heightScale),
                          SizedBox(width: 8 * heightScale),
                          _buildFireButton(yearConfig, scale: heightScale),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center - Main forge area (flex 3 to give more space)
            Expanded(
              flex: 3,
              child: Center(
                child: _buildForgeCenter(
                  currentPart,
                  yearConfig,
                  service.animationPhase,
                  isLandscape: true,
                  customSize: forgeSize,
                ),
              ),
            ),

            // Right panel - Status text
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8 * heightScale,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBottomStatus(yearConfig, scale: heightScale),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    // Uses 30fps _backgroundAnimValue instead of 60fps AnimationController
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WorkshopBackgroundPainter(
          animation: _backgroundAnimValue,
          accentColor: yearConfig.accentColor,
        ),
      ),
    );
  }

  Widget _buildFloatingEmojis() {
    // Update emoji positions (called at 30fps via _backgroundTimer)
    for (final emoji in _floatingEmojis) {
      emoji.y -= emoji.speed;
      emoji.rotation += emoji.rotationSpeed;
      if (emoji.y < -0.1) {
        emoji.y = 1.1;
        emoji.x = math.Random().nextDouble();
      }
    }

    final screenSize = MediaQuery.of(context).size;

    // RepaintBoundary isolates this from other repaints
    return RepaintBoundary(
      child: Stack(
        children: _floatingEmojis.map((emoji) {
          return Positioned(
            left: emoji.x * screenSize.width,
            top: emoji.y * screenSize.height,
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
      ),
    );
  }

  Widget _buildStatusPanel(GrowthService service, YearConfig yearConfig, {double scale = 1.0}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: yearConfig.accentColor.withValues(alpha: 0.3),
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
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4 * scale),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: service.yearProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: yearConfig.accentColor,
                      borderRadius: BorderRadius.circular(2 * scale),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              Text(
                service.getProgressText(language: AppText.language),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11 * scale,
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

  Widget _buildForgeCpDisplay(GrowthService service, YearConfig yearConfig, {double scale = 1.0}) {
    final forgeCp = service.todayForgeCp;
    final forgeCount = service.todayForgeCpCount;
    final canEarn = service.canEarnForgeCp;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: yearConfig.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppText.forgeCpLabel,
                style: TextStyle(
                  color: yearConfig.accentColor,
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          Text(
            '${forgeCp.toStringAsFixed(1)} / 1.0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4 * scale),
          // 5 slot indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < forgeCount;
              return Container(
                width: 12 * scale,
                height: 12 * scale,
                margin: EdgeInsets.only(left: i > 0 ? 4 * scale : 0),
                decoration: BoxDecoration(
                  color: filled
                      ? yearConfig.accentColor
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2 * scale),
                  border: Border.all(
                    color: yearConfig.accentColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: filled
                    ? Center(
                        child: Text('✓', style: TextStyle(fontSize: 8 * scale, color: Colors.black)),
                      )
                    : null,
              );
            }),
          ),
          if (!canEarn) ...[
            SizedBox(height: 4 * scale),
            Text(
              AppText.forgeDailyMax,
              style: TextStyle(
                color: Colors.orange.withValues(alpha: 0.8),
                fontSize: 9 * scale,
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
    PartAnimationPhase phase, {
    bool isLandscape = false,
    double? customSize,
  }) {
    final progress = _isForging
        ? 1 - (_remainingSeconds / forgeDurationSeconds)
        : 0.0;

    // Adjust sizes for landscape mode (smaller to fit better)
    // Use customSize if provided (for dynamic landscape sizing)
    final baseSize = customSize ?? (isLandscape ? 160.0 : 200.0);
    final outerSize = baseSize;
    final ringSize = baseSize * 0.9;
    final innerSize = baseSize * 0.8;
    final emojiSize = baseSize * 0.32;
    final timeSize = baseSize * 0.1;

    // Forge amber color for that hot metal / furnace feel
    const forgeAmber = Color(0xFFFF9800); // Amber/orange for forging
    const forgePausedColor = Color(0xFFFF5722); // Deep orange when paused

    // Use amber when forging, year accent when idle
    final activeColor = _isForging
        ? (_isPaused ? forgePausedColor : forgeAmber)
        : yearConfig.accentColor;

    // Fixed height for time area to prevent layout jump
    final timeAreaHeight = baseSize * 0.35;

    return GestureDetector(
      onTap: () {
        // Can't start forge while spinner is still spinning
        if (!_isForging && _spinnerVelocity.abs() < _velocityThreshold) {
          _startForge();
        } else if (_isForging) {
          setState(() {
            _showTime = !_showTime;
          });
        }
      },
      onDoubleTap: _isForging ? _togglePause : null,
      onLongPress: _isForging ? _cancelForge : null,
      // Fidget spinner: circular swipe gesture (only when not forging)
      onPanStart: !_isForging ? (details) {
        _isTouching = true;
        _spinnerCenter = Offset(outerSize / 2, outerSize / 2);
        final localPos = details.localPosition;
        _lastTouchAngle = math.atan2(
          localPos.dy - _spinnerCenter!.dy,
          localPos.dx - _spinnerCenter!.dx,
        );
        // Clear any lingering state when starting new spin
        _rpmHistory.clear();
      } : null,
      onPanUpdate: !_isForging ? (details) {
        if (_spinnerCenter == null) return;
        final localPos = details.localPosition;
        final currentAngle = math.atan2(
          localPos.dy - _spinnerCenter!.dy,
          localPos.dx - _spinnerCenter!.dx,
        );

        // Calculate angle delta (handle wrap-around)
        var delta = currentAngle - _lastTouchAngle;
        if (delta > math.pi) delta -= 2 * math.pi;
        if (delta < -math.pi) delta += 2 * math.pi;

        // Accumulate velocity gradually (for acceleration feel)
        setState(() {
          _spinnerAngle += delta;
          _spinnerVelocity = (_spinnerVelocity + delta * 30).clamp(-_maxVelocity, _maxVelocity);
          _lastTouchAngle = currentAngle;
        });

        // Light haptic while spinning
        if (delta.abs() > 0.05) {
          HapticFeedback.selectionClick();
        }
      } : null,
      onPanEnd: !_isForging ? (_) {
        _isTouching = false;
      } : null,
      child: AnimatedBuilder(
        animation: _glowAnimController,
        builder: (context, _) {
          final glowIntensity = _isForging
              ? 0.5 + 0.4 * _glowAnimController.value  // Stronger glow when forging
              : 0.2 + 0.1 * _glowAnimController.value;

          return AnimatedBuilder(
            animation: _completeAnimController,
            builder: (context, _) {
              final completeScale = 1.0 + 0.3 * _completeAnimController.value;

              // Fidget spinner: calculate visual effects based on velocity
              final spinnerSpeed = _spinnerVelocity.abs() / _maxVelocity; // 0.0 ~ 1.0
              final isSpinning = !_isForging && spinnerSpeed > 0.01;

              // Dynamic glow based on spinner speed (only when not forging)
              final spinnerGlowIntensity = isSpinning
                  ? 0.3 + spinnerSpeed * 0.7 // 0.3 ~ 1.0
                  : glowIntensity;
              final spinnerBlurRadius = isSpinning
                  ? baseSize * (0.2 + spinnerSpeed * 0.5) // Bigger blur at high speed
                  : (_isForging ? baseSize * 0.35 : baseSize * 0.15);
              final spinnerSpreadRadius = isSpinning
                  ? baseSize * (0.03 + spinnerSpeed * 0.15)
                  : (_isForging ? baseSize * 0.06 : baseSize * 0.025);

              // Color shifts from accent (blue) → amber gold at max speed
              const amberGold = Color(0xFFFFB300);
              final spinnerColor = isSpinning
                  ? Color.lerp(
                      yearConfig.accentColor, // Blue at low speed
                      amberGold, // Amber gold at high speed
                      spinnerSpeed,
                    )!
                  : activeColor;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circle (slightly raised by the time area below)
                  Transform.scale(
                    scale: completeScale,
                    child: Container(
                      width: outerSize,
                      height: outerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: spinnerColor.withValues(alpha: spinnerGlowIntensity),
                            blurRadius: spinnerBlurRadius,
                            spreadRadius: spinnerSpreadRadius,
                          ),
                          // Extra glow layers at high speed
                          if (isSpinning && spinnerSpeed > 0.5)
                            BoxShadow(
                              color: Colors.cyan.withValues(alpha: spinnerSpeed * 0.4),
                              blurRadius: baseSize * 0.4,
                              spreadRadius: baseSize * 0.08,
                            ),
                          if (isSpinning && spinnerSpeed > 0.8)
                            BoxShadow(
                              color: Colors.white.withValues(alpha: spinnerSpeed * 0.3),
                              blurRadius: baseSize * 0.6,
                              spreadRadius: baseSize * 0.1,
                            ),
                          // Extra inner glow when forging for more fire-like effect
                          if (_isForging)
                            BoxShadow(
                              color: Colors.yellow.withValues(alpha: glowIntensity * 0.3),
                              blurRadius: baseSize * 0.2,
                              spreadRadius: baseSize * 0.02,
                            ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Spinning ring (rotates with fidget spinner)
                          Transform.rotate(
                            angle: _spinnerAngle,
                            child: SizedBox(
                              width: ringSize,
                              height: ringSize,
                              child: CustomPaint(
                                painter: _SpinnerRingPainter(
                                  color: spinnerColor,
                                  speed: spinnerSpeed,
                                  progress: progress,
                                  isForging: _isForging,
                                ),
                              ),
                            ),
                          ),

                          // Lightning arcs (when spinning fast)
                          if (_currentRpm > 500)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _LightningPainter(
                                  arcCount: _currentRpm < 3000
                                      ? (_currentRpm / 750).floor().clamp(0, 4)
                                      : 5 + ((_currentRpm - 3000) / 750).floor().clamp(0, 3),
                                  intensity: spinnerSpeed,
                                  ringRadius: ringSize / 2,
                                  innerRadius: innerSize / 2,
                                  seed: DateTime.now().millisecondsSinceEpoch,
                                ),
                              ),
                            ),

                          // Inner circle background
                          Container(
                            width: innerSize,
                            height: innerSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.7),
                              border: Border.all(
                                color: spinnerColor.withValues(alpha: 0.5),
                                width: baseSize * 0.01,
                              ),
                            ),
                          ),

                          // Part emoji only (centered, fixed position)
                          // When gravity locked, rotate to always point down
                          Transform.rotate(
                            angle: _isGravityLocked ? _deviceAngle : 0.0,
                            child: Text(
                              currentPart.emoji,
                              style: TextStyle(fontSize: emojiSize),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Time display area (fixed height to prevent jumping)
                  SizedBox(
                    height: timeAreaHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: baseSize * 0.08),
                        if (_isForging && _showTime)
                          Text(
                            _formatTime(_remainingSeconds),
                            style: TextStyle(
                              color: _isPaused ? Colors.orange : activeColor,
                              fontSize: timeSize * 1.2,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              shadows: [
                                Shadow(
                                  color: activeColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          )
                        else if (_isForging)
                          // Placeholder to maintain height
                          SizedBox(height: timeSize * 1.2),
                        if (_isPaused)
                          Padding(
                            padding: EdgeInsets.only(top: baseSize * 0.02),
                            child: Text(
                              AppText.forgePaused,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: baseSize * 0.07,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // RPM HUD Display (only when spinning)
                  if (!_isForging && _currentRpm > 0)
                    _buildRpmDisplay(baseSize, yearConfig),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Build the RPM HUD display with ghost numbers and glitch effect
  Widget _buildRpmDisplay(double baseSize, YearConfig yearConfig) {
    // Constant font size (no scaling)
    final fontSize = baseSize * 0.12;

    // Color: cyan throughout
    Color getRpmColor(int rpm) {
      if (rpm < 1000) {
        return Colors.cyan;
      } else if (rpm < 3000) {
        final t = (rpm - 1000) / 2000;
        return Color.lerp(Colors.cyan, const Color(0xFF00E5FF), t)!;
      } else {
        final t = ((rpm - 3000) / 3000).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFF00E5FF), const Color(0xFF80FFFF), t)!;
      }
    }

    final rpmColor = getRpmColor(_currentRpm);
    final isHighSpeed = _currentRpm >= 4000;

    // Glitch effect for high speed
    final glitchOffset = isHighSpeed
        ? Offset(
            (math.Random().nextDouble() - 0.5) * 4,
            (math.Random().nextDouble() - 0.5) * 2,
          )
        : Offset.zero;

    return GestureDetector(
      onTap: _showRpmRecord,
      child: Padding(
      padding: EdgeInsets.only(top: baseSize * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ghost numbers (older RPM values fading out)
          SizedBox(
            height: baseSize * 0.15,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ghost trail (older values)
                for (int i = 1; i < _rpmHistory.length && i < _rpmHistoryLength; i++)
                  Transform.translate(
                    offset: Offset(0, -i * 3.0), // Stack upward
                    child: Opacity(
                      opacity: (1.0 - i / _rpmHistoryLength) * 0.3,
                      child: Text(
                        _rpmHistory[i].toString().padLeft(4, '0'),
                        style: TextStyle(
                          color: getRpmColor(_rpmHistory[i]).withValues(alpha: 0.3),
                          fontSize: fontSize * 0.85,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                // Current RPM (main display)
                Transform.translate(
                  offset: glitchOffset,
                  child: Stack(
                    children: [
                      // Glitch layer (offset cyan shades when high speed)
                      if (isHighSpeed) ...[
                        Transform.translate(
                          offset: const Offset(-2, 0),
                          child: Text(
                            _currentRpm.toString().padLeft(4, '0'),
                            style: TextStyle(
                              color: const Color(0xFF00FFFF).withValues(alpha: 0.4),
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(2, 0),
                          child: Text(
                            _currentRpm.toString().padLeft(4, '0'),
                            style: TextStyle(
                              color: const Color(0xFF80FFFF).withValues(alpha: 0.4),
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],

                      // Main number
                      Text(
                        _currentRpm.toString().padLeft(4, '0'),
                        style: TextStyle(
                          color: rpmColor,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          shadows: [
                            Shadow(
                              color: rpmColor.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                            if (isHighSpeed)
                              Shadow(
                                color: rpmColor.withValues(alpha: 0.8),
                                blurRadius: 16,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // RPM label
          Text(
            'RPM',
            style: TextStyle(
              color: rpmColor.withValues(alpha: 0.6),
              fontSize: baseSize * 0.05,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Show RPM record dialog
  void _showRpmRecord() {
    final historyHigh = GrowthService.instance.spinnerHighRpm;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withValues(alpha: 0.5)),
        ),
        title: Text(
          '⚡ RPM RECORD ⚡',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.cyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(color: Colors.cyan.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // History high (all-time)
            Text(
              'HISTORY HIGH',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              historyHigh.toString().padLeft(4, '0'),
              style: TextStyle(
                color: const Color(0xFFFFD700), // Gold for history high
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: [
                  Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.6), blurRadius: 10),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Session high
            Text(
              'SESSION HIGH',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _sessionHighRpm.toString().padLeft(4, '0'),
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStatus(YearConfig yearConfig, {double scale = 1.0}) {
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
            color: yearConfig.accentColor,
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: yearConfig.accentColor.withValues(alpha: 0.5),
                blurRadius: 10 * scale,
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * scale),
        Text(
          statusText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12 * scale,
          ),
        ),
        if (!_isForging) ...[
          SizedBox(height: 4 * scale),
          Text(
            AppText.forgeHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10 * scale,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGravityLockButton(YearConfig yearConfig, {double scale = 1.0}) {
    final buttonSize = 44 * scale;

    return GestureDetector(
      onTap: _toggleGravityLock,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: _isGravityLocked
              ? yearConfig.accentColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: _isGravityLocked
                ? yearConfig.accentColor
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: _isGravityLocked
              ? [
                  BoxShadow(
                    color: yearConfig.accentColor.withValues(alpha: 0.4),
                    blurRadius: 8 * scale,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.explore,
            color: _isGravityLocked
                ? yearConfig.accentColor
                : Colors.white.withValues(alpha: 0.3),
            size: 22 * scale,
          ),
        ),
      ),
    );
  }

  Widget _buildFireButton(YearConfig yearConfig, {double scale = 1.0}) {
    final buttonSize = 44 * scale;
    const fireOrange = Color(0xFFFF6B00);

    return GestureDetector(
      onTap: _toggleFire,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: _isFireOn
              ? fireOrange.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: _isFireOn
                ? fireOrange
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: _isFireOn
              ? [
                  BoxShadow(
                    color: fireOrange.withValues(alpha: 0.4),
                    blurRadius: 8 * scale,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          // Grayscale filter when fire is off
          child: _isFireOn
              ? Text('🔥', style: TextStyle(fontSize: 22 * scale))
              : ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0, 0, 0, 0.5, 0,
                  ]),
                  child: Text('🔥', style: TextStyle(fontSize: 22 * scale)),
                ),
        ),
      ),
    );
  }
}

/// Custom painter for the spinning ring with visible rotation markers
class _SpinnerRingPainter extends CustomPainter {
  final Color color;
  final double speed; // 0.0 ~ 1.0
  final double progress; // Forge progress (0.0 ~ 1.0)
  final bool isForging;

  _SpinnerRingPainter({
    required this.color,
    required this.speed,
    required this.progress,
    required this.isForging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.03;

    // Base ring (background)
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, basePaint);

    // Progress arc (when forging)
    if (isForging && progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        progressPaint,
      );
    }

    // Spinner markers (visible rotation) - only when not forging
    if (!isForging) {
      final markerCount = 8;
      final markerLength = size.width * 0.08;
      final markerWidth = 2.0 + speed * 3.0; // Thicker at high speed

      for (int i = 0; i < markerCount; i++) {
        final angle = (i / markerCount) * 2 * math.pi;
        final startRadius = radius - strokeWidth * 1.5;
        final endRadius = startRadius - markerLength;

        // Gradient opacity: primary marker is brightest
        final opacity = i == 0
            ? 0.4 + speed * 0.6 // Primary marker: 0.4 ~ 1.0
            : 0.1 + speed * 0.3; // Others: 0.1 ~ 0.4

        final markerPaint = Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = markerWidth
          ..strokeCap = StrokeCap.round;

        final start = Offset(
          center.dx + startRadius * math.cos(angle),
          center.dy + startRadius * math.sin(angle),
        );
        final end = Offset(
          center.dx + endRadius * math.cos(angle),
          center.dy + endRadius * math.sin(angle),
        );

        canvas.drawLine(start, end, markerPaint);
      }

      // Speed trail effect at high speed (motion blur simulation)
      if (speed > 0.5) {
        final trailPaint = Paint()
          ..color = color.withValues(alpha: speed * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5;

        final sweepAngle = speed * math.pi * 0.5; // Up to 90 degrees trail
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
          0,
          sweepAngle,
          false,
          trailPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpinnerRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.speed != speed ||
        oldDelegate.progress != progress ||
        oldDelegate.isForging != isForging;
  }
}

/// Painter for lightning arcs radiating from ring
class _LightningPainter extends CustomPainter {
  final int arcCount;
  final double intensity;
  final double ringRadius;
  final double innerRadius;
  final int seed;

  _LightningPainter({
    required this.arcCount,
    required this.intensity,
    required this.ringRadius,
    required this.innerRadius,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (arcCount <= 0) return;

    // Calculate center from actual canvas size
    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(seed);

    // Protect inner circle - clip out the center
    canvas.save();
    canvas.clipPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: center, radius: innerRadius))
        ..fillType = PathFillType.evenOdd,
    );

    // Draw arcs radiating outward from ring
    for (int i = 0; i < arcCount; i++) {
      final startAngle = (i / arcCount) * 2 * math.pi + random.nextDouble() * 0.5;
      final arcLength = ringRadius * (0.8 + intensity * 1.5);
      _drawArc(canvas, size, center, startAngle, arcLength, random);
    }

    canvas.restore();
  }

  void _drawArc(Canvas canvas, Size size, Offset center, double startAngle, double maxLength, math.Random random) {
    final path = Path();

    // Start from ring edge
    var current = Offset(
      center.dx + ringRadius * math.cos(startAngle),
      center.dy + ringRadius * math.sin(startAngle),
    );
    path.moveTo(current.dx, current.dy);

    final segments = 3 + random.nextInt(3);
    final segmentLength = maxLength / segments;
    var currentAngle = startAngle;

    for (int i = 0; i < segments; i++) {
      currentAngle += (random.nextDouble() - 0.5) * 0.5;
      final length = segmentLength * (0.7 + random.nextDouble() * 0.6);

      current = Offset(
        (current.dx + length * math.cos(currentAngle)).clamp(0, size.width),
        (current.dy + length * math.sin(currentAngle)).clamp(0, size.height),
      );
      path.lineTo(current.dx, current.dy);
    }

    // Glow layer
    final glowPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: intensity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 + intensity * 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(path, glowPaint);

    // Core
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 + intensity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + intensity * 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) {
    return oldDelegate.arcCount != arcCount ||
        oldDelegate.intensity != intensity ||
        oldDelegate.seed != seed;
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
    required this.rotationSpeed,
  }) : rotation = 0;
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
