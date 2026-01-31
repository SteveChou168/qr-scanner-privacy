import '../data/cyber_part.dart';
import '../data/growth_constants.dart';
import '../data/year_config.dart';

/// Utility class for generating and validating part sequences.
///
/// Provides methods to:
/// - Validate that year configurations produce exactly 365 days
/// - Calculate part schedules
/// - Find parts by day number
class YearGenerator {
  /// Validate that a year config produces exactly 365 days.
  static bool validateYear(YearConfig yearConfig) {
    int totalDays = 0;
    for (var i = 0; i < yearConfig.totalParts; i++) {
      totalDays += yearConfig.getDaysForPart(i);
    }
    return totalDays == 365;
  }

  /// Validate all year configurations.
  static Map<int, bool> validateAllYears() {
    return {
      1: validateYear(GrowthConstants.year1Config),
      2: validateYear(GrowthConstants.year2Config),
      3: validateYear(GrowthConstants.year3Config),
    };
  }

  /// Get detailed schedule for a year.
  ///
  /// Returns a list of [PartSchedule] objects showing the exact day range
  /// for each part in the year.
  static List<PartSchedule> getYearSchedule(int year) {
    final yearConfig = GrowthConstants.getYearConfig(year);
    final schedule = <PartSchedule>[];
    var dayCounter = 1;

    for (var moduleIdx = 0; moduleIdx < yearConfig.modules.length; moduleIdx++) {
      final module = yearConfig.modules[moduleIdx];
      for (var partIdx = 0; partIdx < module.parts.length; partIdx++) {
        final part = module.parts[partIdx];
        final globalIdx = yearConfig.getGlobalPartIndex(moduleIdx, partIdx);
        final days = yearConfig.getDaysForPart(globalIdx);

        schedule.add(PartSchedule(
          part: part,
          moduleIndex: moduleIdx,
          partIndex: partIdx,
          globalIndex: globalIdx,
          startDay: dayCounter,
          endDay: dayCounter + days - 1,
          totalDays: days,
        ));

        dayCounter += days;
      }
    }

    return schedule;
  }

  /// Find which part is active on a specific day of the year.
  ///
  /// [dayInYear] should be 1-365.
  /// Returns the [PartSchedule] for that day, or null if out of range.
  static PartSchedule? findPartForDay(int year, int dayInYear) {
    if (dayInYear < 1 || dayInYear > 365) return null;

    final schedule = getYearSchedule(year);
    for (final item in schedule) {
      if (dayInYear >= item.startDay && dayInYear <= item.endDay) {
        return item;
      }
    }
    return null;
  }

  /// Calculate the animation day (1-4) for a specific day in the year.
  static int getAnimationDay(int year, int dayInYear) {
    final partSchedule = findPartForDay(year, dayInYear);
    if (partSchedule == null) return 1;

    final dayWithinPart = dayInYear - partSchedule.startDay + 1;
    // Clamp to 1-4 range
    return dayWithinPart.clamp(1, 4);
  }

  /// Get statistics for a year.
  static YearStats getYearStats(int year) {
    final yearConfig = GrowthConstants.getYearConfig(year);
    final schedule = getYearSchedule(year);

    int minDaysPerPart = 999;
    int maxDaysPerPart = 0;
    int totalReuseParts = 0;

    for (final item in schedule) {
      if (item.totalDays < minDaysPerPart) minDaysPerPart = item.totalDays;
      if (item.totalDays > maxDaysPerPart) maxDaysPerPart = item.totalDays;
      if (item.part.isReuse) totalReuseParts++;
    }

    final moduleSizes = <int>[];
    for (final module in yearConfig.modules) {
      moduleSizes.add(module.parts.length);
    }

    return YearStats(
      year: year,
      totalParts: yearConfig.totalParts,
      totalDays: 365,
      avgDaysPerPart: 365 / yearConfig.totalParts,
      minDaysPerPart: minDaysPerPart,
      maxDaysPerPart: maxDaysPerPart,
      totalReuseParts: totalReuseParts,
      uniqueParts: yearConfig.totalParts - totalReuseParts,
      moduleSizes: moduleSizes,
    );
  }

  /// Print a visual calendar for a year (for debugging).
  static String generateCalendar(int year) {
    final buffer = StringBuffer();
    final yearConfig = GrowthConstants.getYearConfig(year);
    final schedule = getYearSchedule(year);

    buffer.writeln('=== Year $year: ${yearConfig.awardEmoji} ===');
    buffer.writeln('Total Parts: ${yearConfig.totalParts}');
    buffer.writeln('');

    var currentModule = -1;
    for (final item in schedule) {
      if (item.moduleIndex != currentModule) {
        currentModule = item.moduleIndex;
        final module = yearConfig.modules[item.moduleIndex];
        buffer.writeln('\nModule ${item.moduleIndex + 1}: ${module.id}');
        buffer.writeln('-' * 40);
      }

      final reuseMarker = item.part.isReuse ? ' (復)' : '';
      buffer.writeln(
        '  ${item.part.emoji} Days ${item.startDay}-${item.endDay} '
        '(${item.totalDays}d)$reuseMarker',
      );
    }

    return buffer.toString();
  }
}

/// Schedule information for a single part.
class PartSchedule {
  final CyberPart part;
  final int moduleIndex;
  final int partIndex;
  final int globalIndex;
  final int startDay;
  final int endDay;
  final int totalDays;

  const PartSchedule({
    required this.part,
    required this.moduleIndex,
    required this.partIndex,
    required this.globalIndex,
    required this.startDay,
    required this.endDay,
    required this.totalDays,
  });

  /// Which animation day (1-4) for a given day in year.
  int animationDayFor(int dayInYear) {
    if (dayInYear < startDay || dayInYear > endDay) return 1;
    return (dayInYear - startDay + 1).clamp(1, 4);
  }
}

/// Statistics for a year.
class YearStats {
  final int year;
  final int totalParts;
  final int totalDays;
  final double avgDaysPerPart;
  final int minDaysPerPart;
  final int maxDaysPerPart;
  final int totalReuseParts;
  final int uniqueParts;
  final List<int> moduleSizes;

  const YearStats({
    required this.year,
    required this.totalParts,
    required this.totalDays,
    required this.avgDaysPerPart,
    required this.minDaysPerPart,
    required this.maxDaysPerPart,
    required this.totalReuseParts,
    required this.uniqueParts,
    required this.moduleSizes,
  });

  @override
  String toString() {
    return '''
YearStats(year: $year)
  Total Parts: $totalParts
  Total Days: $totalDays
  Avg Days/Part: ${avgDaysPerPart.toStringAsFixed(2)}
  Min Days/Part: $minDaysPerPart
  Max Days/Part: $maxDaysPerPart
  Reuse Parts: $totalReuseParts
  Unique Parts: $uniqueParts
  Module Sizes: $moduleSizes
''';
  }
}
