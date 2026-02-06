# Power Management Analysis

> Analysis Date: 2026-02-02

This document analyzes the power management design of ScanScreen and CyberWorkshopView to ensure battery efficiency.

---

## Summary

| Module | Rating | Background Issues |
|--------|--------|-------------------|
| ScanScreen | ⭐⭐⭐⭐⭐ | **None** |
| CyberWorkshopView | ⭐⭐⭐⭐⭐ | **None** |
| HomeScreen | ⭐⭐⭐⭐⭐ | **None** |

**Conclusion: Excellent power management design. No "running in background" issues found.**

---

## ScanScreen Analysis

**File:** `lib/screens/scan_screen.dart`

### Camera Control Timing ✅

| Scenario | Action | Location |
|----------|--------|----------|
| App goes to background | `controller.stop()` | L146-150 |
| App resumes | `controller.start()` | L151-157 |
| Tab switches away | `controller.stop()` | L182-184 |
| Tab switches back | `controller.start()` | L168-179 |

**Implementation:**
```dart
// didChangeAppLifecycleState (L142-158)
if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
  controller.stop();
  _clearAllDetectionStates();
} else if (state == AppLifecycleState.resumed && widget.isActive) {
  controller.start();
}

// didUpdateWidget (L161-186)
if (oldWidget.isActive != widget.isActive) {
  if (widget.isActive) {
    controller.start();
  } else {
    controller.stop();
    _clearAllDetectionStates();
  }
}
```

### Timer Management ✅

All timers are properly cancelled:

| Timer | Cancelled In |
|-------|--------------|
| `_debounceTimer` | `dispose()` |
| `_recentlyClearTimer` | `dispose()` |
| `_accumulationTimer` | `dispose()`, `_clearAllDetectionStates()` |
| `_detectionTimer` | `dispose()`, `_clearAllDetectionStates()` |
| `_fallbackTimer` | `dispose()`, `_clearAllDetectionStates()` |

**Key method - `_clearAllDetectionStates()` (L200-209):**
```dart
void _clearAllDetectionStates() {
  setState(() {
    _detectedCodes = [];
    _frameAccumulator.clear();
    _accumulationTimer?.cancel();
    _detectionTimer?.cancel();
    _fallbackTimer?.cancel();
    _multiCodeBuffer.clear();
  });
}
```

### AudioPlayer ✅

- Disposed in `dispose()` method (L221)

---

## CyberWorkshopView Analysis

**File:** `lib/growth/ui/cyber_workshop/workshop_view.dart`

### 30fps Battery Optimization ✅ (Best Practice)

Instead of using 60fps vsync animation, uses 30fps Timer for ~50% battery savings:

```dart
// L46-48
// 30fps optimization for background/emojis (saves ~50% battery)
Timer? _backgroundTimer;
static const _backgroundFrameInterval = 33; // ~30fps in ms
```

**Timer control methods:**
- `_start30fpsTimer()` - Start background animation
- `_stop30fpsTimer()` - Stop background animation

### App Lifecycle Handling ✅

**`didChangeAppLifecycleState` (L134-158):**

| State | Actions |
|-------|---------|
| `paused` / `inactive` | Stop gravity lock, pause audio, cancel timer, stop animations |
| `resumed` | Resume audio (if was on), resume timer (if forging), resume animations |

```dart
if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
  _stopGravityLock();           // Stop accelerometer subscription
  _firePlayer?.pause();         // Pause audio
  _timer?.cancel();             // Stop pomodoro timer
  _stop30fpsTimer();            // Stop background animation
  _glowAnimController.stop();
  _fireAnimController.stop();
} else if (state == AppLifecycleState.resumed) {
  if (_isFireOn) {
    _firePlayer?.resume();
    _fireAnimController.repeat(reverse: true);
  }
  if (_isForging && !_isPaused) {
    _startTimer();
  }
  _start30fpsTimer();
  _glowAnimController.repeat(reverse: true);
}
```

### Sensor Management ✅

| Aspect | Implementation |
|--------|----------------|
| Sampling rate | 50ms (20Hz) instead of default 60Hz |
| Subscription cleanup | `_accelSubscription?.cancel()` in `_stopGravityLock()` |
| Background handling | Auto-stop when app goes to background |

### Audio Management ✅

| State | Action |
|-------|--------|
| Background | `_firePlayer?.pause()` |
| Resume | `_firePlayer?.resume()` |
| Dispose | `_firePlayer?.dispose()` |

### Resource Disposal ✅

**`dispose()` method (L265-285):**
```dart
void dispose() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
```

---

## HomeScreen Analysis

**File:** `lib/screens/home_screen.dart`

### isActive Parameter Passing ✅

```dart
// L184-191
PageView(
  children: [
    ScanScreen(isActive: _currentIndex == 0, ...),  // ✅
    const GeneratorScreen(),
    const HistoryScreen(),
    const CodexScreen(),
    SettingsScreen(isActive: _currentIndex == 4),   // ✅
  ],
)
```

**Design Pattern:**
- PageView keeps all children mounted
- `isActive` parameter controls resource usage
- Only active tab consumes heavy resources (camera, animations)

---

## SettingsScreen Analysis

**File:** `lib/screens/settings_screen.dart`

### isActive Propagation ✅

```dart
// L88
CyberForgeCard(
  isActive: widget.isActive && settings.showGrowthCard,
  ...
)
```

---

## GeneratorScreen Analysis

**File:** `lib/screens/generator_screen.dart`

### Resource Usage ✅

- No camera, animations, or sensors
- Only TextControllers (lightweight)
- `didChangeAppLifecycleState` only for quota refresh on day change

---

## Best Practices Implemented

1. **WidgetsBindingObserver** - All screens with heavy resources implement lifecycle observer
2. **isActive Pattern** - Resource-heavy screens accept `isActive` parameter
3. **30fps Animation** - Workshop uses 30fps instead of 60fps for battery savings
4. **Proper Disposal** - All resources disposed in `dispose()` method
5. **State Clearing** - Detection states cleared when leaving scan screen
6. **Sensor Optimization** - Accelerometer uses 20Hz instead of 60Hz

---

## Checklist for Future Development

When adding new features with heavy resources:

- [ ] Implement `WidgetsBindingObserver` for lifecycle handling
- [ ] Accept `isActive` parameter if used in PageView
- [ ] Cancel all timers in `dispose()`
- [ ] Pause resources when app goes to background
- [ ] Resume resources only when app is active AND widget is active
- [ ] Consider 30fps for non-critical animations
- [ ] Use lower sampling rates for sensors when possible
