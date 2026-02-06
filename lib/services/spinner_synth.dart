import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:sound_generator/sound_generator.dart';
import 'package:sound_generator/waveTypes.dart';

/// Two-layer spinner sound: fire noise (friction feel) + synth (speed indicator).
///
/// Layer 1: Fire loop = physical friction/spinning feel ("肉")
/// Layer 2: Synth tone = speed indicator ("速度線索")
///
/// Rhythm strategy:
///   - Beat synced to rotation (1 beat per revolution)
///   - Asymmetric envelope: fast attack + slow decay = "whoosh" per revolution
///   - Pitch micro-bend on each beat for weight
///   - Max beat rate capped at ~8 Hz to avoid buzzing
class SpinnerSynth {
  static final SpinnerSynth _instance = SpinnerSynth._internal();
  factory SpinnerSynth() => _instance;
  SpinnerSynth._internal();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  // Frequency range (Hz)
  static const double _minFreq = 80.0;
  static const double _maxFreq = 450.0;

  // RPM parameters
  static const double _maxRpm = 6000.0;
  static const double _silenceThreshold = 50.0;

  // Waveform crossfade zone
  static const double _waveTransitionStart = 1500.0;
  static const double _waveTransitionEnd = 2500.0;

  // Volume limits
  static const double _maxSynthVol = 0.10;
  static const double _maxNoiseVol = 0.12;

  // Rhythm: beat rate = RPM/60, capped here to avoid buzz
  static const double _maxBeatHz = 8.0;

  // Asymmetric envelope shape
  // attackRatio < 0.5 = fast attack, slow decay = "whoosh"
  static const double _attackRatio = 0.15;

  // Pitch bend: slight downward bend per beat (in Hz)
  static const double _pitchBendRange = 15.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isInitialized = false;
  bool _isSynthPlaying = false;

  AudioPlayer? _noisePlayer;
  double _waveBlend = 0.0;

  // Rotation phase accumulator (replaces wall-clock rhythm)
  double _phase = 0.0;
  double _lastUpdateMs = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    if (_isInitialized) return;

    await SoundGenerator.init(44100);
    SoundGenerator.setWaveType(waveTypes.SINUSOIDAL);
    SoundGenerator.setVolume(0);

    _noisePlayer = AudioPlayer();
    _noisePlayer!.setReleaseMode(ReleaseMode.loop);
    await _noisePlayer!.setSource(AssetSource('sounds/fire_loop.mp3'));
    await _noisePlayer!.setVolume(0);

    _isInitialized = true;
    _lastUpdateMs = DateTime.now().millisecondsSinceEpoch.toDouble();
    _phase = 0.0;
  }

  /// Update sound based on current RPM. Call every frame during spin.
  void updateRpm(int physicsRpm) {
    if (!_isInitialized) return;

    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final dtSec = (now - _lastUpdateMs) / 1000.0;
    _lastUpdateMs = now;

    final t = (physicsRpm / _maxRpm).clamp(0.0, 1.0);

    if (physicsRpm < _silenceThreshold) {
      if (_isSynthPlaying) _fadeOutAndStop();
      return;
    }

    if (!_isSynthPlaying) {
      SoundGenerator.play();
      _noisePlayer?.resume();
      _isSynthPlaying = true;
      _phase = 0.0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ROTATION-SYNCED RHYTHM
    // ─────────────────────────────────────────────────────────────────────────
    // Beat frequency = revolutions per second, capped at _maxBeatHz
    // At low RPM: slow whoosh. At high RPM: fast but never buzzy.
    final rps = (physicsRpm / 60.0).clamp(0.0, _maxBeatHz);
    _phase += rps * dtSec;
    _phase %= 1.0; // 0→1 per revolution

    // Asymmetric envelope: fast rise in [0, _attackRatio], slow fall in [_attackRatio, 1]
    final envelope = _asymmetricEnvelope(_phase);

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 1: Fire noise
    // ─────────────────────────────────────────────────────────────────────────
    // Base volume scales with speed; envelope gives gentle pump (80-100%)
    final baseNoiseVol = 0.03 + 0.09 * math.pow(t, 0.9);
    final noiseVol = baseNoiseVol * (0.80 + 0.20 * envelope);
    _noisePlayer?.setVolume(noiseVol.clamp(0.0, _maxNoiseVol));

    // ─────────────────────────────────────────────────────────────────────────
    // LAYER 2: Synth
    // ─────────────────────────────────────────────────────────────────────────

    // Base frequency
    final baseFreq = _minFreq + (_maxFreq - _minFreq) * math.pow(t, 1.6);

    // Pitch micro-bend: slight drop at each beat's decay phase
    // envelope=1 → no bend, envelope→0 → bend down
    final bendAmount = _pitchBendRange * t; // bend scales with speed
    final freq = baseFreq - bendAmount * (1.0 - envelope);
    SoundGenerator.setFrequency(freq.clamp(_minFreq, _maxFreq + _pitchBendRange));

    // Waveform blend
    _updateWaveformBlend(physicsRpm.toDouble());

    // Synth volume: envelope drives 40-100% modulation depth
    // At low RPM: shallow modulation (more continuous)
    // At high RPM: deeper modulation (more rhythmic)
    final modDepth = 0.4 + 0.6 * math.pow(t, 0.8); // 0.4→1.0
    final modMin = 1.0 - modDepth; // 0.6→0.0
    final baseSynthVol = 0.02 + 0.08 * math.pow(t, 0.6);
    final synthVol = baseSynthVol * (modMin + modDepth * envelope);
    SoundGenerator.setVolume(synthVol.clamp(0.0, _maxSynthVol));
  }

  void stop() {
    if (!_isInitialized) return;
    _fadeOutAndStop();
  }

  void dispose() {
    if (!_isInitialized) return;
    SoundGenerator.stop();
    SoundGenerator.release();
    _noisePlayer?.stop();
    _noisePlayer?.dispose();
    _noisePlayer = null;
    _isInitialized = false;
    _isSynthPlaying = false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Asymmetric envelope: fast attack, slow exponential decay.
  ///
  /// ```
  /// 1.0 ─┐  /\
  ///       │ /  \___
  ///       │/       \___
  /// 0.0 ──┼────────────→ phase (0→1)
  ///       0  ↑_attackRatio  1.0
  /// ```
  double _asymmetricEnvelope(double phase) {
    if (phase < _attackRatio) {
      // Attack: linear rise 0→1
      return phase / _attackRatio;
    } else {
      // Decay: exponential fall 1→~0
      // Using pow for smooth curve, not linear ramp
      final decayPhase = (phase - _attackRatio) / (1.0 - _attackRatio);
      return math.pow(1.0 - decayPhase, 2.0).toDouble();
    }
  }

  void _updateWaveformBlend(double rpm) {
    double targetBlend;
    if (rpm < _waveTransitionStart) {
      targetBlend = 0.0;
    } else if (rpm > _waveTransitionEnd) {
      targetBlend = 1.0;
    } else {
      targetBlend = (rpm - _waveTransitionStart) /
          (_waveTransitionEnd - _waveTransitionStart);
    }
    _waveBlend += (targetBlend - _waveBlend) * 0.1;
    final targetType =
        _waveBlend < 0.5 ? waveTypes.SINUSOIDAL : waveTypes.TRIANGLE;
    SoundGenerator.setWaveType(targetType);
  }

  void _fadeOutAndStop() {
    SoundGenerator.setVolume(0);
    _noisePlayer?.setVolume(0);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_isSynthPlaying) {
        SoundGenerator.stop();
        _noisePlayer?.pause();
        _isSynthPlaying = false;
      }
    });
  }
}
