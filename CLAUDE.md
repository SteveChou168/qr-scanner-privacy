# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Offline-First QR/Barcode Scanner - A Flutter app supporting QR codes, barcodes, and semantic type detection (URL, Email, Phone, WiFi, ISBN, vCard, SMS). Multi-language UI (Traditional Chinese, English, Japanese, Spanish, Portuguese, Korean, Vietnamese).

## Build & Development Commands

```bash
flutter pub get      # Get dependencies
flutter run          # Run app (debug)
flutter analyze      # Analyze code
flutter test         # Run tests
flutter build apk    # Build APK
flutter build ios    # Build iOS
```

## Architecture

### Layer Structure
```
UI (screens/) -> Widgets (widgets/) -> Providers (providers/) -> Services (services/) -> Data (data/)
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, Provider setup, language initialization |
| `lib/app_text.dart` | Multi-language dictionary using static `_v(zh, en, ja)` pattern |
| `lib/data/models/scan_record.dart` | Core model with `BarcodeFormat` and `SemanticType` enums |
| `lib/services/barcode_parser.dart` | Parses barcodes and determines semantic type |
| `lib/screens/scan_screen.dart` | Main scanner with AR Mode support via `mobile_scanner` |
| `lib/widgets/scan/scan_widgets.dart` | Barrel file for all scan-related widgets (see below) |
| `lib/growth/ui/cyber_workshop/workshop_view.dart` | Easter egg: full-screen pomodoro timer with gravity lock |

### Scan Widgets Structure

The scanner functionality is modularized into `lib/widgets/scan/`:

| File | Purpose |
|------|---------|
| `scan_models.dart` | `DetectedCode`, `AccumulatedCode`, `ScanAction` enum |
| `scan_action_buttons.dart` | `ScanActionButton`, `ScanIconButton` |
| `scan_result_sheets.dart` | `ScanResultSheet`, `MultiCodeSheet` (bottom sheets) |
| `scan_bottom_toolbar.dart` | `ScanBottomToolbar` (gallery, torch, focus, AR mode) |
| `scan_ar_overlay.dart` | `ScanArOverlay`, `ScanArResultCard`, `scaleRect()`, `getTypeColor()` |
| `scan_indicators.dart` | `ContinuousScanCounter`, `MultiCodeModeIndicator`, `MultiCodeConfirmBar`, `SingleModeResultBar` |
| `scan_gallery_mode.dart` | `ScanGalleryMode` (photo/gallery scanning with ML Kit) |

Import all via: `import '../widgets/scan/scan_widgets.dart';`

> For detailed scanner implementation (AR mode, multi-frame accumulation, lifecycle), see `docs/scanner.md`

### State Management (Provider)

- `SettingsProvider` - App preferences (theme, language, scan settings)
- `HistoryProvider` - Scan history CRUD operations
- `CodexProvider` - Calendar view data, search, selection mode

### Database

SQLite via `sqflite`. Single table `scan_history`:
- Fields: `raw_text`, `display_text`, `barcode_format`, `semantic_type`, `scanned_at`, `place_name`, `image_path`, `is_favorite`

## Navigation Structure

Uses `PageView` in `HomeScreen` with 5 tabs:
```
Index 0: ScanScreen (isActive controlled)
Index 1: GeneratorScreen
Index 2: HistoryScreen
Index 3: CodexScreen
Index 4: SettingsScreen (isActive controlled)
```

**Important**: PageView keeps all children mounted. Use `isActive` parameter to pause expensive operations (camera, animations) when tab is not visible.

## Key Patterns

### isActive Pattern
Screens with continuous resource usage (camera, animations) must accept `isActive` parameter to start/stop when tab visibility changes.

### Multi-Language System
Static class `AppText` with `_v(zh, en, ja)` pattern. Usage: `Text(AppText.scanTitle)`

### Mobile Scanner
Uses `mobile_scanner` v7.x with `ms.` prefix. **v7.x breaking change**: `autoStart` removed, must manually call `start()`.

## Platform Configuration

- **Android**: Camera, location, internet permissions in `AndroidManifest.xml`
- **iOS**: Camera, location, photo library descriptions in `Info.plist`

## Design Principles

- **Offline-first**: All scanning/parsing is local, no cloud sync
- **Privacy-friendly**: Location only saves city/district (no coordinates)

## Advertising (Google AdMob)

- Scan page: No ads (core functionality)
- Generator: Banner + Rewarded ads (quota system: 3 free, +3 per ad)
- History/Codex/Settings: Banner ads
- Key file: `lib/services/ad_service.dart`

---

## Detailed Documentation

For implementation details, algorithms, and code examples, see:

| Topic | File |
|-------|------|
| Scanner (AR mode, multi-frame accumulation, lifecycle) | `docs/scanner.md` |
| Growth System + Rewards | `docs/growth-system.md` |
| Android adaptive icon generation | `docs/android-icon.md` |
| Image optimization (thumbnail, compression) | `docs/image-optimization.md` |
