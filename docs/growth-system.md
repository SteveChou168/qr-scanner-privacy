# Growth System (Cyber Parts)

A 3-year gamification system where users "forge" cyber parts by daily app usage.

## Overview

| Year | Theme | Award | Parts | Progress Display |
|------|-------|-------|-------|------------------|
| 1 (2026) | Satellite Assembly | satellite | 99 | "Day X / 365" |
| 2 (2027) | Mecha Warrior | robot | 68 | "sync rate: X%" |
| 3 (2028) | Data Spire | tower | 60 | "floor: XF" |

**Total: 227 parts across 45 modules (15 per year)**

## Key Files

| File | Purpose |
|------|---------|
| `lib/growth/data/cyber_part.dart` | Part model with year/module/reuse tracking |
| `lib/growth/data/growth_state.dart` | User state (totalDays, currentYear, awards) |
| `lib/growth/data/growth_constants.dart` | All 227 parts data for 3 years |
| `lib/growth/data/growth_repository.dart` | SQLite persistence |
| `lib/growth/logic/growth_service.dart` | Singleton service with ChangeNotifier |
| `lib/growth/ui/cyber_forge_card.dart` | Main UI card in Settings |

## Architecture

```
UI (cyber_forge_card) -> Service (growth_service) -> Repository (growth_repository) -> SQLite
```

## Daily Login Flow

```dart
// In main.dart - called on app startup
await GrowthService.instance.initialize(database);
await GrowthService.instance.recordDailyLogin();  // Idempotent
```

**Idempotency**: Uses `lastLoginDate` (YYYY-MM-DD) to prevent duplicate recordings on same day.

## Animation Phases

Each part goes through 4 animation phases over ~3-6 days:

| Day | Phase | Animation |
|-----|-------|-----------|
| 1 | Spawn | Scale 0->1.2->1.0 bounce |
| 2 | Polish | +/-15 degree rotation wobble |
| 3 | Charge | BoxShadow glow pulse |
| 4+ | Settle | Shrink to 0.5x, move to background |

## Part Duration Calculation

Parts are distributed to fit exactly 365 days per year:
```dart
// Year 1: 99 parts -> ~3.69 days/part
// Year 2: 68 parts -> ~5.37 days/part
// Year 3: 60 parts -> ~6.08 days/part
int daysForPart = 365 ~/ totalParts + (partIndex < remainder ? 1 : 0);
```

## Heritage System (Part Reuse)

Parts marked with `(reuse)` reuse parts from earlier modules/years:
- `isReuse: true` - Indicates this is a reused part
- `reuseSourceId` - Original part's ID
- `reuseFromYear` - Which year the original came from

## Year-Specific Theming

| Year | Background | Accent Color |
|------|------------|--------------|
| 1 | Cosmic black + stars | Blue (#4da6ff) |
| 2 | Factory grid + sparks | Orange (#ff6b35) |
| 3 | Neon cityscape | Cyan (#00ffff) |

## Database Tables

```sql
-- State (singleton, id=1)
cyber_growth_state: total_days, current_year, current_round,
                    current_part_index, day_in_part, year_awards_json, last_login_date

-- Collection log
cyber_collected_parts: part_id, emoji, year, module_index, is_reuse,
                       reuse_source_id, collected_at, total_days_at_collection
```

## Settings Toggle

- `SettingsProvider.showGrowthCard` - Enable/disable growth card display
- Toggle in Settings -> Appearance

## State Initialization

- `dayInPart` starts at 0 (not 1) for new users
- First login increments to 1, matching `daysInCurrentYear` calculation
- `animationPhase` treats both 0 and 1 as `spawn` phase

---

# Reward System

Growth system progression unlocks theme colors and increases history record limits.

## Key Files

| File | Purpose |
|------|---------|
| `lib/rewards/data/reward_models.dart` | UnlockCondition, ThemeColorReward, HistoryLimitReward |
| `lib/rewards/data/reward_constants.dart` | All rewards data (15 colors, 11 limit stages) |
| `lib/rewards/logic/reward_service.dart` | Singleton service managing unlock state |
| `lib/rewards/ui/reward_popup.dart` | Unlock celebration popups |

## Theme Colors (15 total)

| Stage | Colors | Unlock Condition |
|-------|--------|------------------|
| Initial | Classic Blue, Forest Green, Deep Purple | Day 1 |
| Year 1 | Amber Orange, Rose Red, Titanium Grey, Teal | Module completion |
| Year 2 | Indigo, Deep Orange, Pink | Module completion |
| Year 3 | Light Blue, Lime Green | Module completion |
| Legendary | Satellite Gold, Mecha Orange, Spire Cyan | Year completion |

## History Limits Progression

| Stage | Limit | Unlock |
|-------|-------|--------|
| Initial | 1,000 | Day 1 |
| Y1 M3 | 2,000 | Module 3 |
| Y1 M6 | 4,000 | Module 6 |
| Y1 M10 | 7,000 | Module 10 |
| Y1 Complete | **10,000** | Year 1 done |
| Y2 M5 | 15,000 | Module 5 |
| Y2 M10 | 22,000 | Module 10 |
| Y2 Complete | **30,000** | Year 2 done |
| Y3 M5 | 37,000 | Module 5 |
| Y3 M10 | 44,000 | Module 10 |
| Y3 Complete | **50,000** | Year 3 done |

---

# Cyber Workshop (Easter Egg)

A hidden full-screen pomodoro timer accessible from the Growth Card.

## Key File

| File | Purpose |
|------|---------|
| `lib/growth/ui/cyber_workshop/workshop_view.dart` | Full-screen forge timer with gravity lock |

## Access

Long-press the current part emoji in CyberForgeCard to enter the workshop.

## Features

### Forge Timer (15 min Pomodoro)
- Tap center emoji to start 15-minute timer
- Double-tap to pause/resume
- Long-press to cancel
- Tap time display to toggle visibility
- Earns **0.2 CP per completion** (max 1.0 CP / 5 sessions per day)

### Screen Rotation
- **Only this screen** allows landscape mode (rest of app is portrait-locked)
- Uses `SystemChrome.setPreferredOrientations` in `initState`/`dispose`
- Adaptive layouts for portrait and landscape

### Gravity Lock (Easter Egg within Easter Egg)
The center emoji can act like a compass, always pointing down regardless of device rotation.

| State | Button | Behavior |
|-------|--------|----------|
| Unlocked | `🔓 LOCK` | Emoji static |
| Locked | `🔒 LOCKED` | Emoji rotates to stay "down" via accelerometer |

**Implementation:**
```dart
// Uses sensors_plus package
accelerometerEventStream(samplingPeriod: Duration(milliseconds: 50))
  .listen((event) {
    final angle = math.atan2(event.x, event.y);
    setState(() => _deviceAngle = angle);
  });

// Applied to emoji
Transform.rotate(
  angle: _isGravityLocked ? _deviceAngle : 0.0,
  child: Text(emoji),
)
```

**Battery Optimization:**
- Only active when user explicitly enables (tap LOCK button)
- Auto-unlocks when:
  - App goes to background (`AppLifecycleState.paused/inactive`)
  - User leaves the screen (`dispose`)
- Sampling rate: 20Hz (balanced smoothness vs battery)

### Fire Ambience Sound (Another Easter Egg)
Fireplace/forge crackling loop for immersive focus sessions.

| State | Button | Behavior |
|-------|--------|----------|
| Off | `🔥` (dim) | No sound |
| On | `🔥 FORGE` (animated glow) | Looping fire sound at 30% volume |

**Visual Effects when On:**
- Fire emoji scales/pulses (0.95x ~ 1.05x)
- Button border color flickers (orange ↔ yellow)
- Dual glow shadow (orange outer + yellow inner)
- Flicker intensity varies with animation

**Implementation:**
```dart
// Uses audioplayers package
await _firePlayer!.setReleaseMode(ReleaseMode.loop);
await _firePlayer!.setVolume(0.3);  // Default: not too loud
await _firePlayer!.play(AssetSource('sounds/fire_loop.mp3'));
```

**Auto-pause/resume:**
- Pauses when app goes to background
- Resumes when app returns to foreground (if was playing)
- Stops completely when leaving screen

**Required Asset:**
- `assets/sounds/fire_loop.mp3` - Fireplace/forge crackling loop

## UI Layout

| Orientation | Layout |
|-------------|--------|
| Portrait | Status (top-left), CP display (top-right), Forge center, Lock (bottom-left), Fire (bottom-right) |
| Landscape | Row: [Status + CP + Lock + Fire] - [Forge] - [Status text] |

## Dependencies

- `sensors_plus: ^6.1.1` - Accelerometer access for gravity lock
- `audioplayers: ^6.5.0` - Fire ambience loop playback (already in project)

---

## Dev Tools

Settings page includes testing tools:
- Day jump buttons (+1, +10, +100, +365 days)
- Reset growth system
- Located in `lib/screens/settings_screen.dart`
