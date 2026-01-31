// lib/data/models/codex_stats.dart

import 'scan_record.dart';

class CodexStats {
  final int todayCount;
  final int totalCount;
  final Map<SemanticType, int> typeCounts;
  final SemanticType? mostScannedType;
  final List<MapEntry<String, int>> topPlaces;
  final Map<String, int> dailyCounts; // For chart - date -> count

  const CodexStats({
    required this.todayCount,
    required this.totalCount,
    required this.typeCounts,
    this.mostScannedType,
    required this.topPlaces,
    this.dailyCounts = const {},
  });

  factory CodexStats.empty() => const CodexStats(
        todayCount: 0,
        totalCount: 0,
        typeCounts: {},
        mostScannedType: null,
        topPlaces: [],
        dailyCounts: {},
      );

  /// Get count for a specific type
  int countForType(SemanticType type) => typeCounts[type] ?? 0;

  /// Get the most common place
  String? get topPlace => topPlaces.isNotEmpty ? topPlaces.first.key : null;
}

class DayData {
  final DateTime date;
  final int count;
  final List<ScanRecord> records;

  const DayData({
    required this.date,
    required this.count,
    required this.records,
  });

  bool get isEmpty => records.isEmpty;
  bool get isNotEmpty => records.isNotEmpty;

  /// Format date as YYYY-MM-DD
  String get dateKey {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class MonthData {
  final int year;
  final int month;
  final int count;
  final Map<SemanticType, int> typeCounts;

  const MonthData({
    required this.year,
    required this.month,
    required this.count,
    required this.typeCounts,
  });

  /// Get the dominant type for this month
  SemanticType? get dominantType {
    if (typeCounts.isEmpty) return null;
    return typeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
