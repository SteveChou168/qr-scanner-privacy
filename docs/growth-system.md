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

## Dev Tools

Settings page includes testing tools:
- Day jump buttons (+1, +10, +100, +365 days)
- Reset growth system
- Located in `lib/screens/settings_screen.dart`
