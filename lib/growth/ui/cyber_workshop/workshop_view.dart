import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../app_text.dart';
import '../../../services/ad_service.dart';
import '../../../services/spinner_synth.dart';
import '../../data/cyber_part.dart';
import '../../data/growth_state.dart';
import '../../data/year_config.dart';
import '../../logic/growth_service.dart';

/// Challenge mode states
enum _ChallengeState { idle, countdown, playing, result }

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

  // Shared Random instance (avoid creating new instances every frame)
  final _random = math.Random();

  // Floating emojis
  final List<_FloatingEmoji> _floatingEmojis = [];
  static const List<String> _forgeEmojis = [
    '⚙️', '🔧', '🔩', '⛓️', '🔨', '🛠️', '⚡', '🔥',
  ];

  // Compass lock (指南針鎖定 - emoji always points to North)
  bool _isGravityLocked = false; // Keep name for compatibility
  double _deviceAngle = 0.0; // Angle to North
  double _lastDeviceAngle = 0.0; // For haptic feedback calculation
  int _gravityHapticCounter = 0; // Throttle haptic feedback
  Orientation? _lockedOrientation; // Remember orientation when locked
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

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
  int _sessionHighRpm = 0; // Highest RPM in current session
  int _currentRpm = 0; // Current live RPM (0 when stopped)
  bool _wasSpinning = false; // Track spinning state for save trigger
  static const int _rpmHistoryLength = 5; // Number of ghost frames
  static const double _maxVelocity = 50.0; // Max angular velocity (rad/s)
  static const int _baseMaxRpm = 6000; // Base max RPM
  // RPM = velocity × scale (50 rad/s → 6000 RPM)
  static const double _rpmScale = 120.0;
  // Friction: high speed = fast decay, low speed = slow tail
  static const double _frictionHighSpeed = 0.92; // Fast decay at high RPM
  static const double _frictionLowSpeed = 0.985; // Slow tail at low RPM
  static const double _velocityThreshold = 0.05; // Stop threshold (lowered for smoother fade)

  // Cyber visual effects
  double _shakeOffset = 0.0; // Core shake offset for high-speed effect

  // Particle burst system (Comet Trail style - no blur)
  final List<_ParticleBurst> _particles = [];
  int _burstCooldown = 0; // Cooldown counter for burst effect

  // Challenge Mode: Time-limited scoring game
  _ChallengeState _challengeState = _ChallengeState.idle;
  double _challengeTimeLeft = 30.0; // Seconds remaining
  double _challengeScore = 0.0; // Current score
  int _challengeHighScore = 0; // Session high score (loaded from storage)
  int _countdownValue = 3; // 3-2-1 countdown
  static const double _challengeDuration = 30.0; // Total challenge time in seconds

  // Challenge result overlay
  bool _isNewHighScore = false; // Flag for celebration

  // Challenge mode toggle (shows challenge cards when true, forge cards when false)
  bool _isChallengeMode = false;

  // Prevent immediate long press trigger when workshop opens
  bool _canInteract = false;

  /// Whether challenge mode is active (countdown or playing)
  bool get _isChallengeActive =>
      _challengeState == _ChallengeState.countdown ||
      _challengeState == _ChallengeState.playing;

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

    // Load challenge high score from persistence
    _challengeHighScore = GrowthService.instance.spinnerHighScore;

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

    // Delay interaction to prevent long press carry-over from entry gesture
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _canInteract = true);
      }
    });

    // Initialize spinner synth for rotation sound effects
    SpinnerSynth().init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause everything when app goes to background (save battery)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopGravityLock();
      _firePlayer?.pause();
      SpinnerSynth().stop(); // Stop spinner sound
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
    for (int i = 0; i < 8; i++) {
      _floatingEmojis.add(_FloatingEmoji(
        emoji: _forgeEmojis[_random.nextInt(_forgeEmojis.length)],
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 20 + _random.nextDouble() * 20,
        speed: 0.0002 + _random.nextDouble() * 0.0003,
        opacity: 0.15 + _random.nextDouble() * 0.2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.001,
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
              // Normalize angle to prevent overflow (keep within 0-2π)
              _spinnerAngle = _spinnerAngle % (2 * math.pi);

              // Variable friction: fast decay at high speed, slow tail at low speed
              final speedRatio = (_spinnerVelocity.abs() / _maxVelocity).clamp(0.0, 1.0);
              final friction = _frictionLowSpeed + (_frictionHighSpeed - _frictionLowSpeed) * speedRatio;
              _spinnerVelocity *= friction;
            } else if (!_isTouching) {
              _spinnerVelocity = 0.0; // Stop completely below threshold
            }

            // Calculate RPM from velocity (both while touching and coasting)
            final absVelocity = _spinnerVelocity.abs();

            // Dynamic max RPM based on login days
            final totalDays = GrowthService.instance.totalDays;
            final dynamicMaxRpm = _baseMaxRpm + totalDays;

            // RPM = velocity × scale factor (purely physics-based)
            int currentRpm = (absVelocity * _rpmScale).toInt().clamp(0, dynamicMaxRpm);

            _currentRpm = currentRpm;

            // Update spinner synth sound based on RPM
            SpinnerSynth().updateRpm(_currentRpm);

            // Cyber visual effects: core shake at high RPM
            if (_currentRpm > 4000) {
              _shakeOffset = (_random.nextDouble() - 0.5) * 5;
              // Occasional heavy impact at extreme speed
              if (_currentRpm > 5000 && _random.nextInt(30) == 0) {
                HapticFeedback.heavyImpact();
              }
            } else if (_currentRpm > 2000) {
              _shakeOffset = (_random.nextDouble() - 0.5) * 2;
            } else {
              _shakeOffset = 0;
            }

            // Periodic haptic feedback while spinning (frequency based on speed)
            final isSpinning = absVelocity > _velocityThreshold;

            if (isSpinning) {
              _wasSpinning = true;
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

              // Track session high (only update history high when spinning stops)
              if (currentRpm > _sessionHighRpm) {
                _sessionHighRpm = currentRpm;
              }

              // Update RPM history for ghost effect
              _rpmHistory.insert(0, currentRpm);
              if (_rpmHistory.length > _rpmHistoryLength) {
                _rpmHistory.removeLast();
              }

              // Particle burst system (Comet Trail style - no blur)
              if (_currentRpm > 3000) {
                _burstCooldown--;
                if (_burstCooldown <= 0) {
                  // Trigger burst! Random interval: 2-6 seconds (60-180 frames at 30fps)
                  _burstCooldown = 60 + math.Random().nextInt(120);
                  _triggerParticleBurst();
                  HapticFeedback.heavyImpact(); // Strong haptic for burst
                }
              }

              // Challenge Mode: Accumulate score based on RPM (only when spinning)
              if (_challengeState == _ChallengeState.playing) {
                const deltaTime = 1.0 / 30.0; // 30fps
                _challengeScore += _currentRpm * deltaTime;
              }
            } else {
              // Just stopped spinning - save history high once
              if (_wasSpinning && _sessionHighRpm > 0) {
                GrowthService.instance.updateSpinnerHighRpm(_sessionHighRpm);
                _wasSpinning = false;
              }
              _rpmHistory.clear();
              _burstCooldown = 0; // Reset cooldown when stopped
            }

            // Challenge Mode: Timer always counts down (regardless of spinning)
            if (_challengeState == _ChallengeState.playing) {
              const deltaTime = 1.0 / 30.0; // 30fps
              _challengeTimeLeft -= deltaTime;

              // Time's up!
              if (_challengeTimeLeft <= 0) {
                _challengeTimeLeft = 0;
                // Force release touch but keep momentum (spinner continues with inertia)
                _isTouching = false;
                _endChallenge();
              }
            }

            // Update existing particles
            _particles.removeWhere((p) => p.isDead);
            for (var particle in _particles) {
              particle.update();
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
    _magnetometerSubscription?.cancel();
    _firePlayer?.dispose();
    _timer?.cancel();
    _stop30fpsTimer();
    _backgroundAnimController.dispose();
    _glowAnimController.dispose();
    _completeAnimController.dispose();
    _fireAnimController.dispose();
    SpinnerSynth().dispose();
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

  // Compass lock methods (emoji points to North)
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

    _magnetometerSubscription?.cancel();
    _lastDeviceAngle = _deviceAngle;
    _gravityHapticCounter = 0;

    // Use magnetometer (compass) to point emoji to North
    _magnetometerSubscription = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20Hz for more responsive compass
    ).listen((MagnetometerEvent event) {
      // Calculate angle to magnetic North
      // event.x: right, event.y: top of screen, event.z: out of screen
      double newAngle;
      if (_lockedOrientation == Orientation.landscape) {
        // In landscape: Y axis points to right, X points down
        newAngle = math.atan2(-event.x, event.y);
      } else {
        // In portrait: X axis points to right, Y points up
        // Angle to North = atan2(-x, y) where North is screen top
        newAngle = math.atan2(-event.x, event.y);
      }

      // Smooth the angle with low-pass filter to reduce jitter
      const smoothingFactor = 0.35; // More responsive (was 0.15)
      const threshold = 0.01; // More sensitive (was 0.02)

      if (mounted) {
        final diff = newAngle - _deviceAngle;
        // Handle angle wrapping around ±π
        final wrappedDiff = math.atan2(math.sin(diff), math.cos(diff));

        if (wrappedDiff.abs() > threshold) {
          setState(() {
            _deviceAngle += wrappedDiff * smoothingFactor;
          });

          // Haptic feedback for compass rotation
          // Skip if spinner is actively spinning (to avoid conflict)
          if (_spinnerVelocity.abs() < _velocityThreshold) {
            _gravityHapticCounter++;

            // Calculate rotation delta from last haptic check
            final rotationDelta = (_deviceAngle - _lastDeviceAngle).abs();

            // Trigger haptic based on rotation amount (throttled)
            if (_gravityHapticCounter >= 5) { // Every ~500ms (less frequent for compass)
              _gravityHapticCounter = 0;

              if (rotationDelta > 0.5) {
                // Large rotation - medium impact
                HapticFeedback.mediumImpact();
                _lastDeviceAngle = _deviceAngle;
              } else if (rotationDelta > 0.2) {
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
    _magnetometerSubscription?.cancel();
    _magnetometerSubscription = null;

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
                    // Background gradient (must fill entire screen)
                    Positioned.fill(
                      child: _buildBackground(yearConfig),
                    ),

                    // Animated background effects
                    Positioned.fill(
                      child: _buildAnimatedBackground(yearConfig),
                    ),

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

                    // Challenge Mode UI overlay
                    if (_challengeState != _ChallengeState.idle)
                      _buildChallengeOverlay(),

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
        // Top left - Forge StatusPanel OR Challenge Left Card
        Positioned(
          top: 16,
          left: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.3, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _isChallengeMode
                ? _buildChallengeLeftCard(yearConfig, key: const ValueKey('challenge_left'))
                : _buildStatusPanel(service, yearConfig, key: const ValueKey('status')),
          ),
        ),

        // Top right - Forge CpDisplay OR Challenge Right Card
        Positioned(
          top: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _isChallengeMode
                ? _buildChallengeRightCard(yearConfig, key: const ValueKey('challenge_right'))
                : _buildForgeCpDisplay(service, yearConfig, key: const ValueKey('forge_cp')),
          ),
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

        // Bottom center - Challenge toggle button (only when not playing)
        if (_challengeState != _ChallengeState.playing)
          Positioned(
            bottom: 132,
            left: 0,
            right: 0,
            child: Center(child: _buildChallengeToggleButton(yearConfig)),
          ),

        // Bottom center - STOP button (only during playing)
        if (_challengeState == _ChallengeState.playing)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(child: _buildStopButton(yearConfig)),
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

        // Result overlay (only during result state)
        if (_challengeState == _ChallengeState.result)
          _buildChallengeOverlay(),
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

        return Stack(
          children: [
            Row(
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
                          // Forge StatusPanel OR Challenge Left Card with animation
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(-0.3, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: _isChallengeMode
                                ? _buildChallengeLeftCard(yearConfig, scale: heightScale, key: const ValueKey('challenge_left'))
                                : _buildStatusPanel(service, yearConfig, scale: heightScale, key: const ValueKey('status')),
                          ),
                          SizedBox(height: 12 * heightScale),
                          // Forge CpDisplay OR Challenge Right Card with animation
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(-0.3, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: _isChallengeMode
                                ? _buildChallengeRightCard(yearConfig, scale: heightScale, key: const ValueKey('challenge_right'))
                                : _buildForgeCpDisplay(service, yearConfig, scale: heightScale, key: const ValueKey('forge_cp')),
                          ),
                          SizedBox(height: 12 * heightScale),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGravityLockButton(yearConfig, scale: heightScale),
                              SizedBox(width: 8 * heightScale),
                              // Challenge toggle button (when not playing)
                              if (_challengeState != _ChallengeState.playing)
                                _buildChallengeToggleButton(yearConfig, scale: heightScale),
                              // Stop button (when playing)
                              if (_challengeState == _ChallengeState.playing)
                                _buildStopButton(yearConfig, scale: heightScale),
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
            ),

            // Result overlay (only during result state)
            if (_challengeState == _ChallengeState.result)
              _buildChallengeOverlay(),
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
        emoji.x = _random.nextDouble();
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

  // ============ FORGE MODE CARDS ============

  /// Status panel showing module name and progress (for Forge mode)
  Widget _buildStatusPanel(GrowthService service, YearConfig yearConfig, {double scale = 1.0, Key? key}) {
    return Container(
      key: key,
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

  /// Forge CP display showing today's progress (for Forge mode)
  Widget _buildForgeCpDisplay(GrowthService service, YearConfig yearConfig, {double scale = 1.0, Key? key}) {
    final forgeCp = service.todayForgeCp;
    final forgeCount = service.todayForgeCpCount;
    final canEarn = service.canEarnForgeCp;

    return Container(
      key: key,
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

  // ============ CHALLENGE MODE CARDS ============

  /// Left-top card: Time + Quota (for Challenge mode)
  Widget _buildChallengeLeftCard(YearConfig yearConfig, {double scale = 1.0, Key? key}) {
    final quota = GrowthService.instance.challengeQuota;
    final hasQuota = quota > 0;
    final isPlaying = _challengeState == _ChallengeState.playing;
    final timeLeft = _challengeTimeLeft.ceil();
    final isUrgent = timeLeft <= 10 && isPlaying;

    return GestureDetector(
      onTap: isPlaying ? null : _showChallengeConfirmDialog,
      child: Container(
        key: key,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: isUrgent
                ? Colors.redAccent.withValues(alpha: 0.6)
                : (isPlaying ? Colors.cyan.withValues(alpha: 0.5) : yearConfig.accentColor.withValues(alpha: 0.3)),
            width: isUrgent ? 2 : 1,
          ),
          boxShadow: isUrgent
              ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time display (large, matching right card score size)
            Text(
              isPlaying ? '${_challengeTimeLeft.toStringAsFixed(1)} sec' : '${_challengeDuration.toInt()}.0 sec',
              style: TextStyle(
                color: isUrgent ? Colors.redAccent : Colors.white,
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            // Divider line (matching right card)
            Container(
              margin: EdgeInsets.symmetric(vertical: 4 * scale),
              width: 80 * scale,
              height: 1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            // Quota display
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppText.challengeQuotaLabel}: ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10 * scale,
                  ),
                ),
                Text(
                  '×$quota',
                  style: TextStyle(
                    color: hasQuota ? Colors.cyan : Colors.red,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (!isPlaying && hasQuota) ...[
              SizedBox(height: 2 * scale),
              Text(
                AppText.tapToStart,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 8 * scale,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Right-top card: Score + High Score (for Challenge mode)
  Widget _buildChallengeRightCard(YearConfig yearConfig, {double scale = 1.0, Key? key}) {
    final isPlaying = _challengeState == _ChallengeState.playing;
    final score = _challengeScore.round();
    final topScore = GrowthService.instance.challengeScores.isNotEmpty
        ? GrowthService.instance.challengeScores.first.score
        : 0;

    // Score color based on value (cyan → amber → red like RPM)
    Color getScoreColor(int s) {
      if (s < 10000) {
        return Colors.cyan;
      } else if (s < 50000) {
        final t = (s - 10000) / 40000;
        return Color.lerp(Colors.cyan, Colors.amberAccent, t)!;
      } else {
        final t = ((s - 50000) / 50000).clamp(0.0, 1.0);
        return Color.lerp(Colors.amberAccent, Colors.redAccent, t)!;
      }
    }

    final scoreColor = getScoreColor(score);
    final isHighScore = score > 30000;

    return GestureDetector(
      onTap: isPlaying ? null : _showScoreRecord,
      child: Container(
        key: key,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 8 * scale),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(
            color: isPlaying && isHighScore
                ? scoreColor.withValues(alpha: 0.5)
                : yearConfig.accentColor.withValues(alpha: 0.3),
            width: isPlaying && isHighScore ? 2 : 1,
          ),
          boxShadow: isPlaying && isHighScore
              ? [BoxShadow(color: scoreColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current score (large with glow effect)
            Text(
              _formatScore(isPlaying ? score : 0),
              style: TextStyle(
                color: isPlaying ? scoreColor : Colors.white,
                fontSize: 26 * scale,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                shadows: isPlaying ? [
                  Shadow(
                    color: scoreColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                  if (isHighScore)
                    Shadow(
                      color: scoreColor.withValues(alpha: 0.8),
                      blurRadius: 16,
                    ),
                ] : null,
              ),
            ),
            // Divider line (matching left card)
            Container(
              margin: EdgeInsets.symmetric(vertical: 4 * scale),
              width: 80 * scale,
              height: 1,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            // High score display (larger to match left card quota)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏆 ', style: TextStyle(fontSize: 12 * scale)),
                Text(
                  _formatScore(topScore),
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
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

    // Cyber three-stage color system (cyan → amber → red)
    const forgeAmber = Color(0xFFFF9800); // Amber/orange for forging
    const forgePausedColor = Color(0xFFFF5722); // Deep orange when paused

    // Determine color based on state and RPM
    Color activeColor;
    if (_isForging) {
      activeColor = _isPaused ? forgePausedColor : forgeAmber;
    } else {
      // Spinner color: cyan → amber → red based on RPM
      if (_currentRpm > 4000) {
        activeColor = Colors.redAccent; // Red at extreme speed
      } else if (_currentRpm > 2000) {
        activeColor = Colors.amberAccent; // Amber at high speed
      } else if (_currentRpm > 100) {
        // Gradient cyan → amber (2000-4000 RPM range)
        final t = ((_currentRpm - 2000) / 2000).clamp(0.0, 1.0);
        activeColor = Color.lerp(Colors.cyanAccent, Colors.amberAccent, t)!;
      } else {
        activeColor = Colors.cyanAccent; // Cyan at low/idle speed
      }
    }

    // Fixed height for time area to prevent layout jump
    final timeAreaHeight = baseSize * 0.35;

    return GestureDetector(
      onTap: () {
        // Ignore taps during challenge mode
        if (_isChallengeActive) return;

        // Toggle time display when forging
        if (_isForging) {
          setState(() {
            _showTime = !_showTime;
          });
        }
      },
      onDoubleTap: _isForging ? _togglePause : null,
      onLongPress: () {
        // Ignore if interaction not yet allowed (prevents carry-over from entry gesture)
        if (!_canInteract) return;
        // Ignore during challenge mode
        if (_isChallengeActive) return;

        // Long press to toggle forge mode
        if (_isForging) {
          _cancelForge();
        } else if (_spinnerVelocity.abs() < _velocityThreshold) {
          // Can't start forge while spinner is still spinning
          _startForge();
        }
      },
      // Fidget spinner: circular swipe gesture (only when not forging)
      onPanStart: !_isForging ? (details) {
        _isTouching = true;
        _spinnerCenter = Offset(outerSize / 2, outerSize / 2);
        final localPos = details.localPosition;
        _lastTouchAngle = math.atan2(
          localPos.dy - _spinnerCenter!.dy,
          localPos.dx - _spinnerCenter!.dx,
        );
        // If spinner was essentially stopped, reset velocity
        // If still spinning, keep momentum for acceleration
        if (_spinnerVelocity.abs() < _velocityThreshold * 2) {
          _spinnerVelocity = 0.0;
          _rpmHistory.clear();
        }
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

        // Update state WITHOUT setState - let 30fps timer handle UI updates
        _spinnerAngle = (_spinnerAngle + delta) % (2 * math.pi);

        // Only add velocity if there's meaningful movement (ignore sensor noise)
        // This fixes the bug where holding finger still keeps max velocity
        if (delta.abs() > 0.01) {
          _spinnerVelocity = (_spinnerVelocity + delta * 30).clamp(-_maxVelocity, _maxVelocity);
        } else {
          // Finger is stationary - apply friction to slow down
          _spinnerVelocity *= 0.95;
        }
        _lastTouchAngle = currentAngle;

        // Light haptic while spinning (throttled by delta check)
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
              // Only consider "spinning" when RPM is significant (> 500)
              final isSpinning = !_isForging && _currentRpm > 500;

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
                  // Circle - fixed size to prevent layout jumping
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
                        clipBehavior: Clip.none, // Allow lightning to extend beyond bounds
                        children: [
                          // Layer 0: Outer neon wheel segments (testing if this causes crashes)
                          if (!_isForging && isSpinning)
                            Transform.rotate(
                              angle: _spinnerAngle,
                              child: SizedBox(
                                width: ringSize * 1.3,
                                height: ringSize * 1.3,
                                child: CustomPaint(
                                  painter: _NeonWheelSegmentsPainter(
                                    rpm: _currentRpm,
                                    color: _getNeonWheelColor(_currentRpm),
                                    segmentCount: _getSegmentCountByRpm(_currentRpm),
                                  ),
                                ),
                              ),
                            ),

                          // Layer 1: SweepGradient trail effect (only when spinning)
                          if (isSpinning)
                            Transform.rotate(
                              angle: _spinnerAngle,
                              child: Container(
                                width: ringSize * 1.15,
                                height: ringSize * 1.15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      Colors.transparent,
                                      spinnerColor.withValues(alpha: 0.1),
                                      spinnerColor.withValues(alpha: 0.6 * spinnerSpeed),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    transform: const GradientRotation(math.pi / 2),
                                  ),
                                ),
                              ),
                            ),

                          // Layer 1.5: Persistence patterns (no blur - pure lines)
                          if (!_isForging && _currentRpm > 1500)
                            Transform.rotate(
                              angle: _spinnerAngle * 0.5, // Rotates at half speed for moiré effect
                              child: SizedBox(
                                width: ringSize * 1.1,
                                height: ringSize * 1.1,
                                child: CustomPaint(
                                  painter: _PersistencePatternPainter(
                                    rpm: _currentRpm,
                                    patternType: _getPatternTypeByRpm(_currentRpm),
                                  ),
                                ),
                              ),
                            ),

                          // Layer 2: Inner energy ring (⚡) - DISABLED (testing for crashes)
                          // if (!_isForging && isSpinning)
                          //   Transform.rotate(
                          //     angle: _spinnerAngle * 1.2,
                          //     child: _buildEvenEmojiRing(
                          //       count: 8,
                          //       emoji: '⚡',
                          //       radius: ringSize * 0.38,
                          //       scale: 1.1,
                          //       opacity: 1.0,
                          //     ),
                          //   ),

                          // Layer 4: Spinning ring markers (rotates with fidget spinner)
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

                          // Layer 5: Lightning arcs (DISABLED - testing for crashes)
                          // if (isSpinning && _currentRpm > 750)
                          //   Positioned.fill(
                          //     child: CustomPaint(
                          //       painter: _LightningPainter(
                          //         arcCount: _currentRpm < 3000
                          //             ? (_currentRpm ~/ 750).clamp(1, 4)  // 1-4 arcs
                          //             : (5 + (_currentRpm - 3000) ~/ 1000).clamp(5, 8),  // 5-8 arcs
                          //         intensity: spinnerSpeed,
                          //         ringRadius: ringSize / 2,
                          //         innerRadius: innerSize / 2,
                          //         seed: DateTime.now().millisecondsSinceEpoch ~/ 150, // Change every 150ms
                          //       ),
                          //     ),
                          //   ),

                          // Layer 5.5: Particle burst effect (occasional explosive particles)
                          if (_particles.isNotEmpty)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ParticleBurstPainter(
                                  particles: _particles,
                                ),
                              ),
                            ),

                          // Layer 6: Inner circle background
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

                          // Layer 7: Center emoji with shake and heat color
                          Transform.translate(
                            offset: Offset(_shakeOffset, _shakeOffset * 0.5),
                            child: Transform.rotate(
                              angle: _isGravityLocked ? _deviceAngle : 0.0,
                              child: _currentRpm > 4000
                                  // Hot mode: red/orange tint
                                  ? ColorFiltered(
                                      colorFilter: ColorFilter.matrix(<double>[
                                        1.2, 0.3, 0, 0, 30,   // R: boost red
                                        0, 0.8, 0, 0, -10,    // G: reduce green
                                        0, 0, 0.6, 0, -20,    // B: reduce blue
                                        0, 0, 0, 1, 0,
                                      ]),
                                      child: Text(
                                        currentPart.emoji,
                                        style: TextStyle(fontSize: emojiSize),
                                      ),
                                    )
                                  : _currentRpm > 2000
                                      // Warm mode: amber tint
                                      ? ColorFiltered(
                                          colorFilter: ColorFilter.matrix(<double>[
                                            1.1, 0.1, 0, 0, 10,   // R: slight boost
                                            0, 1.0, 0, 0, 0,      // G: normal
                                            0, 0, 0.85, 0, -5,    // B: slight reduce
                                            0, 0, 0, 1, 0,
                                          ]),
                                          child: Text(
                                            currentPart.emoji,
                                            style: TextStyle(fontSize: emojiSize),
                                          ),
                                        )
                                      // Normal mode: no filter
                                      : Text(
                                          currentPart.emoji,
                                          style: TextStyle(fontSize: emojiSize),
                                        ),
                            ),
                          ),

                          // Layer 8: Countdown overlay (covers spinner during countdown)
                          if (_challengeState == _ChallengeState.countdown)
                            _buildCountdownOverlay(innerSize),
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

                  // RPM HUD Display area (fixed height to prevent layout jumping)
                  SizedBox(
                    height: baseSize * 0.35, // Fixed height for RPM display area
                    child: !_isForging && _sessionHighRpm > 0
                        ? _buildRpmDisplay(baseSize, yearConfig)
                        : const SizedBox(), // Empty space when not showing
                  ),
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
            (_random.nextDouble() - 0.5) * 4,
            (_random.nextDouble() - 0.5) * 2,
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

  /// Trigger particle burst effect (shoot particles from ring)
  void _triggerParticleBurst() {
    final particleCount = 12 + _random.nextInt(8); // 12-20 particles per burst

    // Determine color based on RPM
    final color = _currentRpm > 4000
        ? Colors.redAccent
        : _currentRpm > 3500
            ? Colors.amberAccent
            : Colors.cyanAccent;

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * math.pi * i / particleCount) + _random.nextDouble() * 0.3;
      final speed = 3.0 + _random.nextDouble() * 4.0; // Random speed variation

      // Randomly assign particle type (50/50 mix)
      final type = _random.nextBool() ? _ParticleType.comet : _ParticleType.diamond;

      // Diamonds get varied sizes for visual interest
      final size = type == _ParticleType.diamond
          ? 4.0 + _random.nextDouble() * 5.0  // 4-9 size range
          : 6.0;

      _particles.add(_ParticleBurst(
        angle: angle,
        speed: speed,
        startRadius: 100.0, // Start from ring edge
        color: color,
        type: type,
        size: size,
      ));
    }
  }

  /// Show challenge confirm dialog (called from left-top quota card)
  Future<void> _showChallengeConfirmDialog() async {
    if (_challengeState != _ChallengeState.idle) return;
    if (_isForging) return;

    final quota = GrowthService.instance.challengeQuota;
    final hasQuota = quota > 0;

    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            // Glass morphism effect
            color: const Color(0xFF0a1520).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.cyan.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row: Title + Quota
                Row(
                  children: [
                    // Rocket icon + Title
                    Expanded(
                      child: Row(
                        children: [
                          const Text('🚀', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppText.challengeTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Spin Challenge',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quota badge (right side)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${AppText.challengeQuotaLabel} $quota ${AppText.challengeQuotaUnit}',
                        style: TextStyle(
                          color: hasQuota ? Colors.cyan : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Description
                Text(
                  AppText.challengeDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons row
                Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, 'cancel'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            AppText.cancel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Start button
                    Expanded(
                      flex: hasQuota ? 1 : 0,
                      child: hasQuota
                          ? GestureDetector(
                              onTap: () => Navigator.pop(ctx, 'start'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyan.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  AppText.challengeGo,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Watch ad row (bottom left style)
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, 'watch_ad'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ondemand_video,
                        color: Colors.amber.withValues(alpha: 0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${AppText.watchAd} +5 ${AppText.challengeQuotaUnit}',
                        style: TextStyle(
                          color: Colors.amber.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Handle result
    switch (result) {
      case 'start':
        await _beginCountdown();
        break;
      case 'watch_ad':
        await _watchAdForQuota();
        break;
      case 'cancel':
      default:
        // Do nothing
        break;
    }
  }

  /// Watch ad to get more quota (integrated with AdService)
  Future<void> _watchAdForQuota() async {
    final adService = AdService();

    // Check if can watch ad today
    final canWatch = await adService.canWatchAdProactively();
    if (!canWatch) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppText.adDailyLimitReachedMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show rewarded ad
    final rewardAmount = await adService.showRewardedAd();

    if (rewardAmount > 0) {
      await adService.incrementAdWatchCount();
      await GrowthService.instance.addChallengeQuotaFromAd();

      if (!mounted) return;
      setState(() {});
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 +5 ${AppText.challengeQuotaAdded}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Begin countdown after user confirms (deducts quota here)
  Future<void> _beginCountdown() async {
    // Check quota first
    final quota = GrowthService.instance.challengeQuota;
    if (quota <= 0) return;

    // Set state FIRST to show countdown immediately
    HapticFeedback.mediumImpact();
    setState(() {
      _challengeState = _ChallengeState.countdown;
      _countdownValue = 3;
      _challengeScore = 0;
      _challengeTimeLeft = _challengeDuration;
      _isNewHighScore = false;
      // Force stop spinner during countdown
      _spinnerVelocity = 0;
      _spinnerAngle = 0;
      _currentRpm = 0;
      _isTouching = false;
    });

    // Start countdown timer IMMEDIATELY (don't wait for async quota deduction)
    _runCountdown();

    // Deduct quota in background (non-blocking)
    GrowthService.instance.useChallengeQuota();
  }

  void _runCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _challengeState != _ChallengeState.countdown) return;

      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
        HapticFeedback.lightImpact();
        _runCountdown();
      } else if (_countdownValue == 1) {
        setState(() {
          _countdownValue = 0; // Show "GO!"
        });
        HapticFeedback.heavyImpact();

        // Show GO! for 500ms before entering playing state
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _challengeState = _ChallengeState.playing;
          });
        });
      }
    });
  }

  /// End challenge and show result
  void _endChallenge() async {
    if (_challengeState != _ChallengeState.playing) return;

    // IMMEDIATELY change state to stop scoring
    final finalScore = _challengeScore.toInt();
    setState(() {
      _challengeState = _ChallengeState.result;
    });

    // Submit to TOP 5 (background)
    final rank = await GrowthService.instance.submitChallengeScore(finalScore);
    _isNewHighScore = rank == 1; // New #1 record

    // Update local high score cache
    _challengeHighScore = GrowthService.instance.challengeScores.isNotEmpty
        ? GrowthService.instance.challengeScores.first.score
        : finalScore;

    if (_isNewHighScore) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
      _triggerCelebrationParticles();
    } else if (rank != null) {
      // Made it to TOP 5
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Refresh UI with final results
    if (mounted) setState(() {});
  }

  /// Reset to idle state
  void _resetChallenge() {
    setState(() {
      _challengeState = _ChallengeState.idle;
      _challengeScore = 0;
      _challengeTimeLeft = _challengeDuration;
      _isNewHighScore = false;
    });
  }

  /// Build countdown overlay (covers spinner center)
  Widget _buildCountdownOverlay(double size) {
    final text = _countdownValue > 0 ? '$_countdownValue' : AppText.countdownGo;
    final isGo = _countdownValue <= 0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.75),
      ),
      child: Center(
        child: AnimatedScale(
          scale: isGo ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            text,
            style: TextStyle(
              color: isGo ? Colors.amber : Colors.white.withValues(alpha: 0.7),
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
              shadows: isGo ? [
                Shadow(
                  color: Colors.amber.withValues(alpha: 0.6),
                  blurRadius: 16,
                ),
              ] : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Trigger celebration particles for new high score
  void _triggerCelebrationParticles() {
    const particleCount = 40;
    const color = Color(0xFFFFD700); // Gold

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * math.pi * i / particleCount) + _random.nextDouble() * 0.5;
      final speed = 4.0 + _random.nextDouble() * 6.0;

      final type = _random.nextBool() ? _ParticleType.comet : _ParticleType.diamond;
      final size = type == _ParticleType.diamond
          ? 5.0 + _random.nextDouble() * 6.0
          : 6.0;

      _particles.add(_ParticleBurst(
        angle: angle,
        speed: speed,
        startRadius: 100.0,
        color: color,
        type: type,
        size: size,
      ));
    }
  }

  /// Build STOP button for challenge mode
  Widget _buildStopButton(YearConfig yearConfig, {double scale = 1.0}) {
    return GestureDetector(
      onTap: _endChallenge,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24 * scale),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 12 * scale,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stop_rounded,
              color: Colors.red,
              size: 24 * scale,
            ),
            SizedBox(width: 8 * scale),
            Text(
              AppText.stopButton,
              style: TextStyle(
                color: Colors.red,
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
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
              AppText.historyHigh,
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
              AppText.sessionHigh,
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
              AppText.ok,
              style: TextStyle(color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Show challenge score record dialog
  void _showScoreRecord() {
    final scores = GrowthService.instance.challengeScores;
    const challengeAmber = Color(0xFFFFB300);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: challengeAmber.withValues(alpha: 0.5)),
        ),
        title: Text(
          '🏆 ${AppText.challengeTopScores} 🏆',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: challengeAmber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(color: challengeAmber.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TOP 5 list
            if (scores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppText.challengeNoScores,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...scores.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final record = entry.value;
                final isTop1 = rank == 1;
                final color = isTop1 ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.8);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(
                        width: 24,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            color: color.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Score
                      Expanded(
                        child: Text(
                          _formatScore(record.score),
                          style: TextStyle(
                            color: color,
                            fontSize: isTop1 ? 20 : 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            shadows: isTop1 ? [
                              Shadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
                            ] : null,
                          ),
                        ),
                      ),
                      // Timestamp
                      Text(
                        _formatTimestamp(record.timestamp),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),

          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppText.ok,
              style: TextStyle(color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  /// Format timestamp for display (MM/DD HH:mm)
  String _formatTimestamp(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Get segment count based on RPM (different patterns at different speeds)
  int _getSegmentCountByRpm(int rpm) {
    if (rpm < 1000) return 8;        // 8-petal flower
    if (rpm < 2000) return 12;       // 12-petal flower
    if (rpm < 3000) return 16;       // 16-petal flower
    if (rpm < 4000) return 6;        // 6-petal flower (creates visual impact)
    if (rpm < 5000) return 24;       // Dense pattern
    return 32;                       // Ultra-high speed ring
  }

  /// Get persistence pattern type based on RPM
  _PersistencePattern _getPatternTypeByRpm(int rpm) {
    if (rpm < 1500) return _PersistencePattern.none;
    if (rpm < 2500) return _PersistencePattern.spiralArms;
    if (rpm < 4000) return _PersistencePattern.moireRings;
    // starBurst removed
    return _PersistencePattern.hypnotic;
  }

  /// Get neon wheel color based on RPM (yellow base with intensity variation)
  Color _getNeonWheelColor(int rpm) {
    if (rpm < 2000) {
      return const Color(0xFFFFD700); // Gold
    } else if (rpm < 4000) {
      final t = (rpm - 2000) / 2000;
      return Color.lerp(const Color(0xFFFFD700), const Color(0xFFFFB300), t)!; // Gold → Amber
    } else {
      final t = ((rpm - 4000) / 2000).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFFFFB300), const Color(0xFFFF6B00), t)!; // Amber → Orange
    }
  }

  Widget _buildBottomStatus(YearConfig yearConfig, {double scale = 1.0}) {
    // Determine main status based on mode
    String mainStatus;
    String emoji;
    Color statusColor;

    if (_isChallengeActive || _isChallengeMode) {
      // Challenge mode selected or active
      mainStatus = AppText.challengeStatus;
      emoji = '💫';
      statusColor = Colors.cyanAccent;
    } else if (_isForging) {
      // Forging mode active
      mainStatus = AppText.forgeStatus;
      emoji = '⚙️';
      statusColor = yearConfig.accentColor;
    } else {
      // Idle state
      mainStatus = AppText.challengeReady;
      emoji = '⚙️';
      statusColor = yearConfig.accentColor;
    }

    // Determine sub-status text
    String statusText;
    if (_isChallengeActive) {
      // No sub-status during challenge
      statusText = '';
    } else if (!_isForging) {
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
          '$emoji $mainStatus $emoji',
          style: TextStyle(
            color: statusColor,
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: statusColor.withValues(alpha: 0.5),
                blurRadius: 10 * scale,
              ),
            ],
          ),
        ),
        if (statusText.isNotEmpty) ...[
          SizedBox(height: 8 * scale),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12 * scale,
            ),
          ),
        ],
        if (!_isForging && !_isChallengeActive) ...[
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

  /// Challenge mode toggle button (bottom center)
  Widget _buildChallengeToggleButton(YearConfig yearConfig, {double scale = 1.0}) {
    final buttonSize = 44 * scale; // Same size as gravity lock and fire buttons
    const challengeAmber = Color(0xFFFFB300); // Amber yellow, distinct from fire orange

    return GestureDetector(
      onTap: _toggleChallengeMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: _isChallengeMode
              ? challengeAmber.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12 * scale), // Same as other buttons
          border: Border.all(
            color: _isChallengeMode
                ? challengeAmber
                : Colors.white.withValues(alpha: 0.2),
            width: _isChallengeMode ? 2 : 1,
          ),
          boxShadow: _isChallengeMode
              ? [
                  BoxShadow(
                    color: challengeAmber.withValues(alpha: 0.4),
                    blurRadius: 8 * scale,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Opacity(
            opacity: _isChallengeMode ? 1.0 : 0.4,
            child: Text(
              '💫',
              style: TextStyle(fontSize: 22 * scale),
            ),
          ),
        ),
      ),
    );
  }

  /// Toggle challenge mode on/off
  void _toggleChallengeMode() {
    // Can't toggle while challenge is active
    if (_isChallengeActive) return;
    // Can't toggle while result is showing
    if (_challengeState == _ChallengeState.result) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isChallengeMode = !_isChallengeMode;
    });
  }

  /// Challenge mode overlay (only for result screen now)
  /// Countdown is handled by _buildCountdownOverlay in spinner
  /// Playing state uses top cards
  Widget _buildChallengeOverlay() {
    // Only show overlay during result state
    if (_challengeState != _ChallengeState.result) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: _buildResultDisplay(),
      ),
    );
  }

  /// Result display (final score, high score, retry/exit buttons)
  /// Card-style container matching app design
  Widget _buildResultDisplay() {
    return SafeArea(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isNewHighScore
                  ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isNewHighScore) ...[
                // Celebration banner with glow effect
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.2),
                        const Color(0xFFFF8C00).withValues(alpha: 0.2),
                        const Color(0xFFFFD700).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    '🎉 新紀錄！ 🎉',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                AppText.challengeScore,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              // Score with FittedBox for large numbers
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatScore(_challengeScore.toInt()),
                  style: TextStyle(
                    color: _isNewHighScore ? const Color(0xFFFFD700) : Colors.cyan,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(
                        color: (_isNewHighScore ? const Color(0xFFFFD700) : Colors.cyan).withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                      Shadow(
                        color: (_isNewHighScore ? const Color(0xFFFFD700) : Colors.cyan).withValues(alpha: 0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppText.challengeHighScore}: ${_formatScore(_challengeHighScore)}',
                style: TextStyle(
                  color: Colors.cyan.withValues(alpha: 0.7),
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRetryButton(),
                  const SizedBox(width: 16),
                  _buildResultButton(AppText.challengeExit, Colors.white54, _resetChallenge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultButton(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  /// Retry button with quota display
  /// Shows "RETRY ×N" when has quota, or "📺 +5" when no quota
  Widget _buildRetryButton() {
    final quota = GrowthService.instance.challengeQuota;
    final hasQuota = quota > 0;

    return GestureDetector(
      onTap: () {
        _resetChallenge();
        if (hasQuota) {
          _showChallengeConfirmDialog();
        } else {
          _watchAdForQuota();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasQuota
                ? Colors.cyan.withValues(alpha: 0.3)
                : Colors.amber.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: hasQuota
            ? Text(
                AppText.challengeRetry,
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.ondemand_video,
                    color: Colors.amber.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '+5',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Format score with commas (e.g., 123456 -> "123,456")
  String _formatScore(int score) {
    final str = score.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
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
    final ringWidth = size.width * 0.02; // For progress arc and markers

    // Calculate neon intensity based on speed
    final neonIntensity = speed.clamp(0.0, 1.0);

    // === NEON RING (multi-layer, no blur) ===
    // The brighter it spins, the more layers and intensity

    // Layer 1: Outermost glow (widest, most transparent)
    final glow1Paint = Paint()
      ..color = color.withValues(alpha: 0.08 + neonIntensity * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20 + neonIntensity * 10;
    canvas.drawCircle(center, radius * 0.85, glow1Paint);

    // Layer 2: Middle glow
    final glow2Paint = Paint()
      ..color = color.withValues(alpha: 0.15 + neonIntensity * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 + neonIntensity * 6;
    canvas.drawCircle(center, radius * 0.85, glow2Paint);

    // Layer 3: Inner glow
    final glow3Paint = Paint()
      ..color = color.withValues(alpha: 0.3 + neonIntensity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 + neonIntensity * 3;
    canvas.drawCircle(center, radius * 0.85, glow3Paint);

    // Layer 4: Core line (brightest, thinnest)
    final corePaint = Paint()
      ..color = color.withValues(alpha: 0.7 + neonIntensity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius * 0.85, corePaint);

    // Layer 5: White hot center (only at high speed)
    if (neonIntensity > 0.5) {
      final whitePaint = Paint()
        ..color = Colors.white.withValues(alpha: (neonIntensity - 0.5) * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius * 0.85, whitePaint);
    }

    // === INNER RING (decorative) ===
    final innerGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.1 + neonIntensity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius * 0.65, innerGlowPaint);

    final innerCorePaint = Paint()
      ..color = color.withValues(alpha: 0.25 + neonIntensity * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.65, innerCorePaint);

    // Progress arc (when forging)
    if (isForging && progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - ringWidth / 2),
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
        final startRadius = radius - ringWidth * 1.5;
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
          ..strokeWidth = ringWidth * 0.5;

        final sweepAngle = speed * math.pi * 0.5; // Up to 90 degrees trail
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - ringWidth / 2),
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

/// Particle type for visual variety
enum _ParticleType { comet, diamond }

/// Particle burst data class (for explosive shooting effect)
class _ParticleBurst {
  double angle; // Direction angle
  double speed; // Outward speed
  double radius; // Current distance from center
  final double startRadius; // Starting radius
  final Color color; // Particle color
  double life; // Remaining life (1.0 = just born, 0.0 = dead)
  double rotation; // Rotation for star particles
  final _ParticleType type; // Particle visual type
  final double size; // Size for diamond particles
  static const double maxLife = 60.0; // Lifespan in frames (~2 seconds at 30fps)

  _ParticleBurst({
    required this.angle,
    required this.speed,
    required this.startRadius,
    required this.color,
    this.type = _ParticleType.comet,
    this.size = 6.0,
  })  : radius = startRadius,
        life = maxLife,
        rotation = 0.0;

  void update() {
    radius += speed; // Move outward
    speed *= 0.96; // Decelerate (air resistance)
    life -= 1.0; // Age
    rotation += 0.15; // Rotate for visual interest (faster for diamonds)
  }

  bool get isDead => life <= 0;

  double get opacity => (life / maxLife).clamp(0.0, 1.0);
  double get length => 15.0 + speed * 2.0; // Longer trail when faster
}

/// Painter for particle burst effect (Comet Trail + Diamond styles)
class _ParticleBurstPainter extends CustomPainter {
  final List<_ParticleBurst> particles;

  _ParticleBurstPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var particle in particles) {
      final x = center.dx + particle.radius * math.cos(particle.angle);
      final y = center.dy + particle.radius * math.sin(particle.angle);
      final pos = Offset(x, y);

      if (particle.type == _ParticleType.diamond) {
        // Diamond/Star dust style - rotating diamond shape
        _drawDiamond(canvas, pos, particle);
      } else {
        // Comet trail style - gradient line
        _drawComet(canvas, center, particle);
      }
    }
  }

  void _drawComet(Canvas canvas, Offset center, _ParticleBurst particle) {
    // Current position (head of comet)
    final headX = center.dx + particle.radius * math.cos(particle.angle);
    final headY = center.dy + particle.radius * math.sin(particle.angle);
    final headPos = Offset(headX, headY);

    // Trail position (tail of comet - closer to center)
    final tailRadius = particle.radius - particle.length;
    final tailX = center.dx + tailRadius * math.cos(particle.angle);
    final tailY = center.dy + tailRadius * math.sin(particle.angle);
    final tailPos = Offset(tailX, tailY);

    // Draw gradient trail line
    final trailPaint = Paint()
      ..shader = ui.Gradient.linear(
        tailPos,
        headPos,
        [
          particle.color.withValues(alpha: 0), // Transparent tail
          particle.color.withValues(alpha: particle.opacity * 0.8), // Bright head
        ],
      )
      ..strokeWidth = 2.5 + particle.speed * 0.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(tailPos, headPos, trailPaint);

    // Draw bright core at head
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: particle.opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headPos, 2.0, corePaint);
  }

  void _drawDiamond(Canvas canvas, Offset pos, _ParticleBurst particle) {
    final size = particle.size * (0.5 + particle.opacity * 0.5); // Shrink as it fades

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(particle.rotation);

    // Diamond shape path
    final path = Path()
      ..moveTo(0, -size) // Top
      ..lineTo(size * 0.6, 0) // Right
      ..lineTo(0, size) // Bottom
      ..lineTo(-size * 0.6, 0) // Left
      ..close();

    // Outer glow (gradient fill, no blur)
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset.zero,
        size,
        [
          particle.color.withValues(alpha: particle.opacity * 0.8),
          particle.color.withValues(alpha: particle.opacity * 0.2),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glowPaint);

    // Inner bright core
    final innerPath = Path()
      ..moveTo(0, -size * 0.4)
      ..lineTo(size * 0.25, 0)
      ..lineTo(0, size * 0.4)
      ..lineTo(-size * 0.25, 0)
      ..close();

    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: particle.opacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, corePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParticleBurstPainter oldDelegate) {
    return true; // Always repaint when particles are active
  }
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

/// Neon wheel segments painter - creates segmented ring with glow effect
class _NeonWheelSegmentsPainter extends CustomPainter {
  final int rpm;
  final Color color;
  final int segmentCount;

  _NeonWheelSegmentsPainter({
    required this.rpm,
    required this.color,
    required this.segmentCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segmentCount;

    // Calculate glow intensity based on RPM
    final intensity = (rpm / 6000).clamp(0.3, 1.0);

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = i * segmentAngle - math.pi / 2;
      final sweepAngle = segmentAngle * 0.85; // Leave 15% gap

      // Multi-layer glow effect (NO MaskFilter.blur - lightweight approach)
      // Layer 1: Outermost glow (widest, most transparent)
      final glow1Paint = Paint()
        ..color = color.withValues(alpha: intensity * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glow1Paint,
      );

      // Layer 2: Middle glow
      final glow2Paint = Paint()
        ..color = color.withValues(alpha: intensity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glow2Paint,
      );

      // Layer 3: Inner glow
      final glow3Paint = Paint()
        ..color = color.withValues(alpha: intensity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glow3Paint,
      );

      // Layer 4: Main arc body (brightest, thinnest)
      final arcPaint = Paint()
        ..color = color.withValues(alpha: intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeonWheelSegmentsPainter oldDelegate) {
    return oldDelegate.rpm != rpm ||
        oldDelegate.color != color ||
        oldDelegate.segmentCount != segmentCount;
  }
}

/// Persistence of vision pattern types
enum _PersistencePattern {
  none,           // No pattern
  spiralArms,     // Spiral arms
  moireRings,     // Moiré rings
  starBurst,      // Star burst
  hypnotic,       // Hypnotic spiral
}

/// Persistence pattern painter - creates visual patterns at different speeds
class _PersistencePatternPainter extends CustomPainter {
  final int rpm;
  final _PersistencePattern patternType;

  _PersistencePatternPainter({
    required this.rpm,
    required this.patternType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final intensity = (rpm / 6000).clamp(0.0, 1.0);

    switch (patternType) {
      case _PersistencePattern.spiralArms:
        _drawSpiralArms(canvas, center, size.width / 2, intensity);
        break;
      case _PersistencePattern.moireRings:
        _drawMoireRings(canvas, center, size.width / 2, intensity);
        break;
      case _PersistencePattern.starBurst:
        _drawStarBurst(canvas, center, size.width / 2, intensity);
        break;
      case _PersistencePattern.hypnotic:
        _drawHypnoticSpiral(canvas, center, size.width / 2, intensity);
        break;
      default:
        break;
    }
  }

  void _drawSpiralArms(Canvas canvas, Offset center, double radius, double intensity) {
    const armCount = 3;
    const color = Color(0xFFFFD700); // Unified gold color

    for (int i = 0; i < armCount; i++) {
      final angle = (i / armCount) * 2 * math.pi;

      // Build spiral path
      final path = Path();
      path.moveTo(center.dx, center.dy);
      for (double r = 0; r < radius; r += 3) {
        final spiralAngle = angle + (r / radius) * math.pi * 1.2;
        final x = center.dx + r * math.cos(spiralAngle);
        final y = center.dy + r * math.sin(spiralAngle);
        path.lineTo(x, y);
      }

      // Multi-layer neon effect (no blur)
      // Layer 1: Outer glow (widest)
      final glow1 = Paint()
        ..color = color.withValues(alpha: intensity * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow1);

      // Layer 2: Middle glow
      final glow2 = Paint()
        ..color = color.withValues(alpha: intensity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow2);

      // Layer 3: Inner glow
      final glow3 = Paint()
        ..color = color.withValues(alpha: intensity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow3);

      // Layer 4: Core (brightest)
      final core = Paint()
        ..color = color.withValues(alpha: intensity * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, core);

      // Layer 5: White hot center
      if (intensity > 0.6) {
        final white = Paint()
          ..color = Colors.white.withValues(alpha: (intensity - 0.6) * 1.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, white);
      }
    }
  }

  void _drawMoireRings(Canvas canvas, Offset center, double radius, double intensity) {
    const ringCount = 6;
    for (int i = 0; i < ringCount; i++) {
      final r = radius * (i + 1) / ringCount;

      // Multi-layer neon ring (no blur)
      // Layer 1: Outer glow
      final glow1 = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: intensity * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      canvas.drawCircle(center, r, glow1);

      // Layer 2: Middle glow
      final glow2 = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: intensity * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(center, r, glow2);

      // Layer 3: Core (brightest)
      final core = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: intensity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, r, core);

      // Layer 4: White hot center
      if (intensity > 0.5) {
        final white = Paint()
          ..color = Colors.white.withValues(alpha: (intensity - 0.5) * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(center, r, white);
      }
    }
  }

  void _drawStarBurst(Canvas canvas, Offset center, double radius, double intensity) {
    const rayCount = 16;
    const color = Colors.cyanAccent;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi;
      final innerRadius = radius * 0.25;
      final outerRadius = radius * 1.15;

      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      // Multi-layer neon rays (no blur)
      // Layer 1: Outer glow
      final glow1 = Paint()
        ..color = color.withValues(alpha: intensity * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(innerPoint, outerPoint, glow1);

      // Layer 2: Middle glow
      final glow2 = Paint()
        ..color = color.withValues(alpha: intensity * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(innerPoint, outerPoint, glow2);

      // Layer 3: Inner glow
      final glow3 = Paint()
        ..color = color.withValues(alpha: intensity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(innerPoint, outerPoint, glow3);

      // Layer 4: Core
      final core = Paint()
        ..color = color.withValues(alpha: intensity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(innerPoint, outerPoint, core);

      // Layer 5: White hot center
      if (intensity > 0.5) {
        final white = Paint()
          ..color = Colors.white.withValues(alpha: (intensity - 0.5) * 1.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(innerPoint, outerPoint, white);
      }
    }
  }

  void _drawHypnoticSpiral(Canvas canvas, Offset center, double radius, double intensity) {
    // Hypnotic spiral - unified red neon
    const color = Color(0xFFFF1744); // Red

    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final turns = 3 + layer;

      for (double t = 0; t < turns; t += 0.03) {
        final r = radius * (t / turns);
        final angle = t * 2 * math.pi + (layer * math.pi / 3);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);

        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Multi-layer neon effect (no blur)
      // Layer 1: Outer glow
      final glow1 = Paint()
        ..color = color.withValues(alpha: intensity * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow1);

      // Layer 2: Middle glow
      final glow2 = Paint()
        ..color = color.withValues(alpha: intensity * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow2);

      // Layer 3: Inner glow
      final glow3 = Paint()
        ..color = color.withValues(alpha: intensity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow3);

      // Layer 4: Core
      final core = Paint()
        ..color = color.withValues(alpha: intensity * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, core);

      // Layer 5: White hot center
      if (intensity > 0.6) {
        final white = Paint()
          ..color = Colors.white.withValues(alpha: (intensity - 0.6) * 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PersistencePatternPainter oldDelegate) {
    return oldDelegate.rpm != rpm || oldDelegate.patternType != patternType;
  }
}

