/// Represents a single cyber part in the growth system.
///
/// Each part belongs to a specific year (1-3) and module (0-14).
/// Parts can be "reused" from previous years, indicated by [isReuse].
class CyberPart {
  /// Unique identifier, e.g., 'screw_y1_m0_p0' (year 1, module 0, part 0)
  final String id;

  /// The emoji representing this part, e.g., '🔩', '🔋'
  final String emoji;

  /// Which year this part belongs to (1, 2, or 3)
  final int year;

  /// Module index within the year (0-14)
  final int moduleIndex;

  /// Part index within the module
  final int partIndex;

  /// True if this is a reused part from a previous module/year
  final bool isReuse;

  /// If [isReuse] is true, the original part's ID
  final String? reuseSourceId;

  /// If [isReuse] is true, which year the original came from
  final int? reuseFromYear;

  const CyberPart({
    required this.id,
    required this.emoji,
    required this.year,
    required this.moduleIndex,
    required this.partIndex,
    this.isReuse = false,
    this.reuseSourceId,
    this.reuseFromYear,
  });

  /// Creates a CyberPart from a JSON map (database row).
  factory CyberPart.fromJson(Map<String, dynamic> json) {
    return CyberPart(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      year: json['year'] as int,
      moduleIndex: json['module_index'] as int,
      partIndex: json['part_index'] as int,
      isReuse: (json['is_reuse'] as int?) == 1,
      reuseSourceId: json['reuse_source_id'] as String?,
      reuseFromYear: json['reuse_from_year'] as int?,
    );
  }

  /// Converts to a JSON map for database storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emoji': emoji,
      'year': year,
      'module_index': moduleIndex,
      'part_index': partIndex,
      'is_reuse': isReuse ? 1 : 0,
      'reuse_source_id': reuseSourceId,
      'reuse_from_year': reuseFromYear,
    };
  }

  /// Creates a copy with optional field overrides.
  CyberPart copyWith({
    String? id,
    String? emoji,
    int? year,
    int? moduleIndex,
    int? partIndex,
    bool? isReuse,
    String? reuseSourceId,
    int? reuseFromYear,
  }) {
    return CyberPart(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      year: year ?? this.year,
      moduleIndex: moduleIndex ?? this.moduleIndex,
      partIndex: partIndex ?? this.partIndex,
      isReuse: isReuse ?? this.isReuse,
      reuseSourceId: reuseSourceId ?? this.reuseSourceId,
      reuseFromYear: reuseFromYear ?? this.reuseFromYear,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CyberPart &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CyberPart(id: $id, emoji: $emoji, year: $year, module: $moduleIndex, part: $partIndex, isReuse: $isReuse)';
}

/// Record of a collected part stored in the database.
class CollectedPart {
  final int? dbId;
  final String partId;
  final String emoji;
  final int year;
  final int moduleIndex;
  final bool isReuse;
  final String? reuseSourceId;
  final DateTime collectedAt;
  final int totalDaysAtCollection;

  const CollectedPart({
    this.dbId,
    required this.partId,
    required this.emoji,
    required this.year,
    required this.moduleIndex,
    this.isReuse = false,
    this.reuseSourceId,
    required this.collectedAt,
    required this.totalDaysAtCollection,
  });

  factory CollectedPart.fromJson(Map<String, dynamic> json) {
    return CollectedPart(
      dbId: json['id'] as int?,
      partId: json['part_id'] as String,
      emoji: json['emoji'] as String,
      year: json['year'] as int,
      moduleIndex: json['module_index'] as int,
      isReuse: (json['is_reuse'] as int?) == 1,
      reuseSourceId: json['reuse_source_id'] as String?,
      collectedAt: DateTime.parse(json['collected_at'] as String),
      totalDaysAtCollection: json['total_days_at_collection'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (dbId != null) 'id': dbId,
      'part_id': partId,
      'emoji': emoji,
      'year': year,
      'module_index': moduleIndex,
      'is_reuse': isReuse ? 1 : 0,
      'reuse_source_id': reuseSourceId,
      'collected_at': collectedAt.toIso8601String(),
      'total_days_at_collection': totalDaysAtCollection,
    };
  }

  /// Creates a CollectedPart from a CyberPart when it's collected.
  factory CollectedPart.fromCyberPart(CyberPart part, int totalDays) {
    return CollectedPart(
      partId: part.id,
      emoji: part.emoji,
      year: part.year,
      moduleIndex: part.moduleIndex,
      isReuse: part.isReuse,
      reuseSourceId: part.reuseSourceId,
      collectedAt: DateTime.now(),
      totalDaysAtCollection: totalDays,
    );
  }
}
