import 'dart:ui';

import 'cyber_part.dart';

/// Configuration for a single year of the growth system.
///
/// Each year has a distinct theme, award, and set of modules.
class YearConfig {
  /// Year number (1, 2, or 3)
  final int year;

  /// The award emoji earned upon completing this year
  final String awardEmoji;

  /// Internal theme name for UI styling
  final String themeName;

  /// Progress display format: 'day', 'sync', or 'floor'
  final ProgressFormat progressFormat;

  /// Background gradient colors for this year
  final List<Color> backgroundColors;

  /// Accent color for glows and highlights
  final Color accentColor;

  /// All 15 modules for this year
  final List<ModuleConfig> modules;

  const YearConfig({
    required this.year,
    required this.awardEmoji,
    required this.themeName,
    required this.progressFormat,
    required this.backgroundColors,
    required this.accentColor,
    required this.modules,
  });

  /// Total number of parts in this year (sum of all module parts).
  int get totalParts => modules.fold(0, (sum, m) => sum + m.parts.length);

  /// Average days per part to fit exactly 365 days.
  double get avgDaysPerPart => 365 / totalParts;

  /// Get a specific module by index (0-14).
  ModuleConfig getModule(int index) {
    if (index < 0 || index >= modules.length) {
      throw RangeError('Module index $index out of range 0-${modules.length - 1}');
    }
    return modules[index];
  }

  /// Get a specific part by module and part index.
  CyberPart getPart(int moduleIndex, int partIndex) {
    final module = getModule(moduleIndex);
    if (partIndex < 0 || partIndex >= module.parts.length) {
      throw RangeError('Part index $partIndex out of range 0-${module.parts.length - 1}');
    }
    return module.parts[partIndex];
  }

  /// Get the global part index (0 to totalParts-1) for a module/part position.
  int getGlobalPartIndex(int moduleIndex, int partIndex) {
    int index = 0;
    for (int i = 0; i < moduleIndex; i++) {
      index += modules[i].parts.length;
    }
    return index + partIndex;
  }

  /// Get module and part indices from a global part index.
  (int moduleIndex, int partIndex) getModulePartFromGlobal(int globalIndex) {
    int remaining = globalIndex;
    for (int i = 0; i < modules.length; i++) {
      if (remaining < modules[i].parts.length) {
        return (i, remaining);
      }
      remaining -= modules[i].parts.length;
    }
    throw RangeError('Global part index $globalIndex out of range 0-${totalParts - 1}');
  }

  /// Calculate how many days a specific part should take.
  ///
  /// Distributes 365 days across all parts, with remainder days
  /// added to the first N parts to ensure exact 365-day total.
  int getDaysForPart(int globalPartIndex) {
    final base = 365 ~/ totalParts;
    final remainder = 365 % totalParts;
    return globalPartIndex < remainder ? base + 1 : base;
  }
}

/// Configuration for a single module (round) within a year.
class ModuleConfig {
  /// Module ID for localization lookup
  final String id;

  /// Module index within the year (0-14)
  final int moduleIndex;

  /// Year this module belongs to
  final int year;

  /// All parts in this module
  final List<CyberPart> parts;

  const ModuleConfig({
    required this.id,
    required this.moduleIndex,
    required this.year,
    required this.parts,
  });

  /// Number of parts in this module.
  int get partCount => parts.length;

  /// Get a part by index.
  CyberPart getPart(int index) {
    if (index < 0 || index >= parts.length) {
      throw RangeError('Part index $index out of range 0-${parts.length - 1}');
    }
    return parts[index];
  }
}

/// Progress display format for each year.
enum ProgressFormat {
  /// Year 1: "Day X / 365"
  day,

  /// Year 2: "機體同步率：85%"
  sync,

  /// Year 3: "建設層數：72F"
  floor,
}

/// Year theme identifiers.
abstract class YearTheme {
  static const String satellite = 'satellite';
  static const String mecha = 'mecha';
  static const String spire = 'spire';
}

/// Year award emoji constants.
abstract class YearAward {
  static const String year1 = '🛰️';
  static const String year2 = '🤖';
  static const String year3 = '🗼';

  static String forYear(int year) {
    return switch (year) {
      1 => year1,
      2 => year2,
      3 => year3,
      _ => '',
    };
  }
}

/// Year background color presets.
abstract class YearColors {
  /// Year 1: Deep cosmic black with blue tints
  static const year1Background = [
    Color(0xFF0a0a1a),
    Color(0xFF0d1b2a),
    Color(0xFF1b263b),
  ];

  /// Year 2: Factory/industrial with amber gold tints
  static const year2Background = [
    Color(0xFF1a1a1a),
    Color(0xFF2a2a28),
    Color(0xFF3a3520),
  ];

  /// Year 3: Neon cityscape with cyan/magenta
  static const year3Background = [
    Color(0xFF0a0a1a),
    Color(0xFF1a0a2e),
    Color(0xFF0a1a2e),
  ];

  /// Accent colors for glow effects
  static const year1Accent = Color(0xFF4da6ff); // Cosmic blue
  static const year2Accent = Color(0xFFFFBF00); // Amber gold
  static const year3Accent = Color(0xFF00ffff); // Neon cyan
}
