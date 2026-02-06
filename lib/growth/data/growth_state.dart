import 'dart:convert';

/// Represents the user's complete growth state across all years.
///
/// Tracks cumulative login days, current position in the growth system,
/// collected parts, and completed year awards.
class GrowthState {
  /// Total cumulative login days across all years
  final int totalDays;

  /// Current year (1, 2, or 3)
  final int currentYear;

  /// Current round/module within the year (1-15)
  final int currentRound;

  /// Current part index within the round (0-based)
  final int currentPartIndex;

  /// Day within the current part's animation cycle (1-4)
  final int dayInPart;

  /// Year awards earned (e.g., ['🛰️', '🤖'] if Y1 and Y2 complete)
  final List<String> yearAwards;

  /// Last login date (YYYY-MM-DD format) for idempotency
  final String? lastLoginDate;

  /// Database row update timestamp
  final DateTime? updatedAt;

  // ─────────────────────────────────────────────────────────────────────────
  // CP (Computing Power) System
  // ─────────────────────────────────────────────────────────────────────────

  /// Current CP balance (0.0 ~ 0.99). When >= 1.0, converts to +1 day.
  final double cpBalance;

  /// Today's scan count that earned CP (max 20/day)
  final int todayScanCpCount;

  /// Today's ad watch count (max 2/day)
  final int todayAdCpCount;

  /// JSON-encoded Set of code contents already counted today (for dedup)
  final String todayScannedCodesJson;

  // ─────────────────────────────────────────────────────────────────────────
  // Forge System (Hidden Pomodoro Timer)
  // ─────────────────────────────────────────────────────────────────────────

  /// Today's forge completion count (max 5/day = 1.0 CP)
  final int todayForgeCpCount;

  // ─────────────────────────────────────────────────────────────────────────
  // Fidget Spinner (Easter Egg)
  // ─────────────────────────────────────────────────────────────────────────

  /// All-time high RPM record for fidget spinner
  final int spinnerHighRpm;

  /// All-time high score for spinner challenge mode (legacy, use challengeScoresJson for TOP 5)
  final int spinnerHighScore;

  /// TOP 5 challenge scores JSON: [{"score": 12345, "timestamp": "2026-02-06T14:32:00"}, ...]
  final String challengeScoresJson;

  /// Current challenge quota (accumulates, daily replenish to 5 if below)
  final int challengeQuota;

  const GrowthState({
    this.totalDays = 0,
    this.currentYear = 1,
    this.currentRound = 1,
    this.currentPartIndex = 0,
    this.dayInPart = 0,
    this.yearAwards = const [],
    this.lastLoginDate,
    this.updatedAt,
    this.cpBalance = 0.0,
    this.todayScanCpCount = 0,
    this.todayAdCpCount = 0,
    this.todayScannedCodesJson = '[]',
    this.todayForgeCpCount = 0,
    this.spinnerHighRpm = 0,
    this.spinnerHighScore = 0,
    this.challengeScoresJson = '[]',
    this.challengeQuota = 5,
  });

  /// Creates initial state for a new user.
  factory GrowthState.initial() {
    return const GrowthState();
  }

  /// Creates from database JSON row.
  factory GrowthState.fromJson(Map<String, dynamic> json) {
    List<String> awards = [];
    final awardsJson = json['year_awards_json'] as String?;
    if (awardsJson != null && awardsJson.isNotEmpty) {
      try {
        awards = (jsonDecode(awardsJson) as List).cast<String>();
      } catch (_) {
        awards = [];
      }
    }

    return GrowthState(
      totalDays: json['total_days'] as int? ?? 0,
      currentYear: json['current_year'] as int? ?? 1,
      currentRound: json['current_round'] as int? ?? 1,
      currentPartIndex: json['current_part_index'] as int? ?? 0,
      dayInPart: json['day_in_part'] as int? ?? 0,
      yearAwards: awards,
      lastLoginDate: json['last_login_date'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      cpBalance: (json['cp_balance'] as num?)?.toDouble() ?? 0.0,
      todayScanCpCount: json['today_scan_cp_count'] as int? ?? 0,
      todayAdCpCount: json['today_ad_cp_count'] as int? ?? 0,
      todayScannedCodesJson: json['today_scanned_codes_json'] as String? ?? '[]',
      todayForgeCpCount: json['today_forge_cp_count'] as int? ?? 0,
      spinnerHighRpm: json['spinner_high_rpm'] as int? ?? 0,
      spinnerHighScore: json['spinner_high_score'] as int? ?? 0,
      challengeScoresJson: json['challenge_scores_json'] as String? ?? '[]',
      challengeQuota: json['challenge_quota'] as int? ?? 5,
    );
  }

  /// Converts to JSON for database storage.
  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'current_year': currentYear,
      'current_round': currentRound,
      'current_part_index': currentPartIndex,
      'day_in_part': dayInPart,
      'year_awards_json': jsonEncode(yearAwards),
      'last_login_date': lastLoginDate,
      'updated_at': DateTime.now().toIso8601String(),
      'cp_balance': cpBalance,
      'today_scan_cp_count': todayScanCpCount,
      'today_ad_cp_count': todayAdCpCount,
      'today_scanned_codes_json': todayScannedCodesJson,
      'today_forge_cp_count': todayForgeCpCount,
      'spinner_high_rpm': spinnerHighRpm,
      'spinner_high_score': spinnerHighScore,
      'challenge_scores_json': challengeScoresJson,
      'challenge_quota': challengeQuota,
    };
  }

  /// Creates a copy with optional field overrides.
  GrowthState copyWith({
    int? totalDays,
    int? currentYear,
    int? currentRound,
    int? currentPartIndex,
    int? dayInPart,
    List<String>? yearAwards,
    String? lastLoginDate,
    DateTime? updatedAt,
    double? cpBalance,
    int? todayScanCpCount,
    int? todayAdCpCount,
    String? todayScannedCodesJson,
    int? todayForgeCpCount,
    int? spinnerHighRpm,
    int? spinnerHighScore,
    String? challengeScoresJson,
    int? challengeQuota,
  }) {
    return GrowthState(
      totalDays: totalDays ?? this.totalDays,
      currentYear: currentYear ?? this.currentYear,
      currentRound: currentRound ?? this.currentRound,
      currentPartIndex: currentPartIndex ?? this.currentPartIndex,
      dayInPart: dayInPart ?? this.dayInPart,
      yearAwards: yearAwards ?? this.yearAwards,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      updatedAt: updatedAt ?? this.updatedAt,
      cpBalance: cpBalance ?? this.cpBalance,
      todayScanCpCount: todayScanCpCount ?? this.todayScanCpCount,
      todayAdCpCount: todayAdCpCount ?? this.todayAdCpCount,
      todayScannedCodesJson: todayScannedCodesJson ?? this.todayScannedCodesJson,
      todayForgeCpCount: todayForgeCpCount ?? this.todayForgeCpCount,
      spinnerHighRpm: spinnerHighRpm ?? this.spinnerHighRpm,
      spinnerHighScore: spinnerHighScore ?? this.spinnerHighScore,
      challengeScoresJson: challengeScoresJson ?? this.challengeScoresJson,
      challengeQuota: challengeQuota ?? this.challengeQuota,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Days elapsed in the current year (0-364).
  int get daysInCurrentYear {
    if (totalDays == 0) return 0;
    return ((totalDays - 1) % 365) + 1;
  }

  /// Progress through current year as 0.0 to 1.0.
  double get yearProgress => daysInCurrentYear / 365;

  /// Whether Year 1 is complete (365+ days).
  bool get isYear1Complete => totalDays >= 365;

  /// Whether Year 2 is complete (730+ days).
  bool get isYear2Complete => totalDays >= 730;

  /// Whether Year 3 is complete (1095+ days).
  bool get isYear3Complete => totalDays >= 1095;

  /// Whether all three years are complete.
  bool get isFullyComplete => isYear3Complete;

  /// Animation phase based on dayInPart (1-4).
  /// dayInPart = 0 means user hasn't logged in yet, defaults to spawn.
  PartAnimationPhase get animationPhase {
    return switch (dayInPart) {
      0 || 1 => PartAnimationPhase.spawn,
      2 => PartAnimationPhase.polish,
      3 => PartAnimationPhase.charge,
      _ => PartAnimationPhase.settle,
    };
  }

  /// Year-specific progress text (without /365 suffix).
  ///
  /// - Year 1: "Day 42"
  /// - Year 2: "機體同步率：85%"
  /// - Year 3: "建設層數：72F"
  String getProgressText({String language = 'zh'}) {
    final progress = (yearProgress * 100).toInt();
    return switch (currentYear) {
      1 => switch (language) {
          'en' => 'Day $daysInCurrentYear',
          'ja' => '$daysInCurrentYear日目',
          'es' => 'Día $daysInCurrentYear',
          'pt' => 'Dia $daysInCurrentYear',
          'ko' => '$daysInCurrentYear일째',
          'vi' => 'Ngày $daysInCurrentYear',
          _ => '第 $daysInCurrentYear 天',
        },
      2 => switch (language) {
          'en' => 'Sync Rate: $progress%',
          'ja' => '同期率：$progress%',
          'es' => 'Sincronización: $progress%',
          'pt' => 'Sincronização: $progress%',
          'ko' => '동기화율: $progress%',
          'vi' => 'Đồng bộ: $progress%',
          _ => '機體同步率：$progress%',
        },
      3 => switch (language) {
          'en' => 'Floor: ${progress}F',
          'ja' => '建設階：${progress}F',
          'es' => 'Piso: ${progress}F',
          'pt' => 'Andar: ${progress}F',
          'ko' => '층수: ${progress}F',
          'vi' => 'Tầng: ${progress}F',
          _ => '建設層數：${progress}F',
        },
      _ => 'Day $totalDays',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Forge System Computed Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Today's forge CP earned (0.0 ~ 1.0)
  double get todayForgeCp => todayForgeCpCount * 0.2;

  /// Whether more forge CP can be earned today
  bool get canEarnForgeCp => todayForgeCpCount < 5;

  /// Remaining forge sessions today
  int get remainingForgeSessions => 5 - todayForgeCpCount;

  /// Get today's scanned codes as a Set.
  Set<String> get todayScannedCodes {
    try {
      final list = jsonDecode(todayScannedCodesJson) as List;
      return list.cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Challenge Mode Computed Properties
  // ─────────────────────────────────────────────────────────────────────────

  /// Get TOP 5 challenge scores as list of records
  List<ChallengeScoreRecord> get challengeScores {
    try {
      final list = jsonDecode(challengeScoresJson) as List;
      return list
          .map((e) => ChallengeScoreRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Whether user has challenge quota remaining
  bool get canChallenge => challengeQuota > 0;

  /// Get the highest challenge score (TOP 1)
  int get topChallengeScore {
    final scores = challengeScores;
    return scores.isEmpty ? 0 : scores.first.score;
  }

  @override
  String toString() => 'GrowthState('
      'totalDays: $totalDays, '
      'year: $currentYear, '
      'round: $currentRound, '
      'partIndex: $currentPartIndex, '
      'dayInPart: $dayInPart, '
      'awards: $yearAwards, '
      'cpBalance: $cpBalance'
      ')';
}

/// Animation phases for the current part.
///
/// Each part goes through 4 phases over ~3-6 days:
/// - Day 1: [spawn] - Scale bounce animation
/// - Day 2: [polish] - Rotation wobble
/// - Day 3: [charge] - Glow effect
/// - Day 4+: [settle] - Shrink and move to background
enum PartAnimationPhase {
  /// Day 1: Part spawns with scale 0→1.2→1.0 bounce
  spawn,

  /// Day 2: Part wobbles ±15° rotation (alignment)
  polish,

  /// Day 3: Part glows with BoxShadow pulse
  charge,

  /// Day 4+: Part shrinks to 0.5x and moves to background
  settle,
}

/// Result from recording a daily login.
class GrowthUpdateResult {
  /// The updated state after login.
  final GrowthState newState;

  /// If a part was completed, the part's emoji.
  final String? completedPartEmoji;

  /// If a module was completed, the module index (0-based).
  final int? completedModuleIndex;

  /// The year in which the module was completed (1-3).
  /// This is needed because newState.currentYear may have advanced.
  final int? completedModuleYear;

  /// If a year was completed, the year number.
  final int? completedYear;

  /// If a year was completed, the award emoji.
  final String? yearAwardEmoji;

  const GrowthUpdateResult({
    required this.newState,
    this.completedPartEmoji,
    this.completedModuleIndex,
    this.completedModuleYear,
    this.completedYear,
    this.yearAwardEmoji,
  });

  /// Whether any significant event occurred (part/module/year completion).
  bool get hasEvent =>
      completedPartEmoji != null ||
      completedModuleIndex != null ||
      completedYear != null;
}

/// Data for heritage (cross-year reuse) animations.
class HeritageAnimationData {
  /// The original part being reused
  final String originalPartId;
  final String originalEmoji;
  final int sourceYear;

  /// The current part that's reusing the original
  final String currentPartId;
  final String currentEmoji;

  /// The source year's award emoji (🛰️, 🤖, 🗼)
  final String sourceYearAward;

  const HeritageAnimationData({
    required this.originalPartId,
    required this.originalEmoji,
    required this.sourceYear,
    required this.currentPartId,
    required this.currentEmoji,
    required this.sourceYearAward,
  });
}

/// Result status for CP operations.
enum CpResultStatus {
  /// CP successfully added
  success,

  /// Daily limit reached (20 scans or 2 ads)
  limitReached,

  /// Code already scanned today (duplicate)
  duplicate,
}

/// Result from a CP earning operation (scan or ad).
class CpResult {
  /// The result status
  final CpResultStatus status;

  /// Amount of CP gained (0.0 if not success)
  final double cpGained;

  /// Bonus days converted from CP (0 if < 1.0 CP accumulated)
  final int bonusDays;

  /// New CP balance after operation
  final double newCpBalance;

  const CpResult({
    required this.status,
    this.cpGained = 0.0,
    this.bonusDays = 0,
    this.newCpBalance = 0.0,
  });

  /// Create a success result
  factory CpResult.success({
    required double cpGained,
    required int bonusDays,
    required double newCpBalance,
  }) {
    return CpResult(
      status: CpResultStatus.success,
      cpGained: cpGained,
      bonusDays: bonusDays,
      newCpBalance: newCpBalance,
    );
  }

  /// Create a limit reached result
  factory CpResult.limitReached() {
    return const CpResult(status: CpResultStatus.limitReached);
  }

  /// Create a duplicate result
  factory CpResult.duplicate() {
    return const CpResult(status: CpResultStatus.duplicate);
  }

  /// Whether the operation was successful
  bool get isSuccess => status == CpResultStatus.success;
}

/// A single challenge score record with timestamp.
class ChallengeScoreRecord {
  final int score;
  final DateTime timestamp;

  const ChallengeScoreRecord({
    required this.score,
    required this.timestamp,
  });

  factory ChallengeScoreRecord.fromJson(Map<String, dynamic> json) {
    return ChallengeScoreRecord(
      score: json['score'] as int? ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
