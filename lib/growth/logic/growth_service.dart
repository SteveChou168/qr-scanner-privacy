import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/cyber_part.dart';
import '../data/growth_constants.dart';
import '../data/growth_repository.dart';
import '../data/growth_state.dart';
import '../data/year_config.dart';

/// Singleton service for managing the Cyber Parts growth system.
///
/// Tracks daily logins, part collection, and year progression.
/// Uses [ChangeNotifier] for reactive UI updates.
class GrowthService extends ChangeNotifier {
  // ═══════════════════════════════════════════════════════════════════════════
  // SINGLETON
  // ═══════════════════════════════════════════════════════════════════════════

  static GrowthService? _instance;

  /// Get the singleton instance.
  static GrowthService get instance {
    _instance ??= GrowthService._();
    return _instance!;
  }

  GrowthService._();

  /// Factory constructor returns singleton.
  factory GrowthService() => instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════

  GrowthRepository? _repository;
  GrowthState _state = GrowthState.initial();
  bool _isInitialized = false;

  /// 待處理的登入結果（用於顯示獎勵彈窗）
  GrowthUpdateResult? _pendingResult;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// 獲取並清除待處理的登入結果
  GrowthUpdateResult? consumePendingResult() {
    final result = _pendingResult;
    _pendingResult = null;
    return result;
  }

  /// Current growth state.
  GrowthState get state => _state;

  /// Total cumulative days logged in.
  int get totalDays => _state.totalDays;

  /// Current year (1, 2, or 3).
  int get currentYear => _state.currentYear;

  /// Current round/module within the year (1-15).
  int get currentRound => _state.currentRound;

  /// Current part index within the round.
  int get currentPartIndex => _state.currentPartIndex;

  /// Animation day within current part (1-4).
  int get dayInPart => _state.dayInPart;

  /// Animation phase for current part.
  PartAnimationPhase get animationPhase => _state.animationPhase;

  /// Year awards earned.
  List<String> get yearAwards => _state.yearAwards;

  /// Progress through current year (0.0-1.0).
  double get yearProgress => _state.yearProgress;

  /// Days in current year (1-365).
  int get daysInCurrentYear => _state.daysInCurrentYear;

  // ─────────────────────────────────────────────────────────────────────────
  // CP (Computing Power) Getters
  // ─────────────────────────────────────────────────────────────────────────

  /// Current CP balance (0.0 ~ 0.99).
  double get cpBalance => _state.cpBalance;

  /// Today's scan count that earned CP.
  int get todayScanCpCount => _state.todayScanCpCount;

  /// Today's ad watch count.
  int get todayAdCpCount => _state.todayAdCpCount;

  /// Today's forge completion count.
  int get todayForgeCpCount => _state.todayForgeCpCount;

  /// Today's forge CP earned (0.0 ~ 1.0).
  double get todayForgeCp => _state.todayForgeCp;

  /// Whether more forge CP can be earned today.
  bool get canEarnForgeCp => _state.canEarnForgeCp;

  /// Maximum scans per day for CP.
  static const int maxDailyScanCp = 20;

  /// Maximum ads per day for CP.
  static const int maxDailyAdCp = 2;

  /// Maximum forge sessions per day for CP.
  static const int maxDailyForgeCp = 5;

  /// CP gained per scan batch (20 scans = 2.0 CP).
  static const double cpPerScanBatch = 2.0;

  /// CP gained per ad batch (2 ads = 1.0 CP).
  static const double cpPerAdBatch = 1.0;

  /// CP gained per forge session (15 min timer).
  static const double cpPerForge = 0.2;

  /// Whether scan injection is ready (20/20).
  bool get canInjectScanCp => _state.todayScanCpCount >= maxDailyScanCp;

  /// Whether ad/energy injection is ready (2/2).
  bool get canInjectAdCp => _state.todayAdCpCount >= maxDailyAdCp;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialize the service with a database instance.
  Future<void> initialize(Database db) async {
    if (_isInitialized) return;

    _repository = GrowthRepository(db);
    await _repository!.ensureTables();
    _state = await _repository!.loadState();
    _isInitialized = true;
    notifyListeners();
  }

  /// Reset the growth system (use with caution).
  /// Used for testing and dev tools.
  Future<void> reset() async {
    if (_repository != null) {
      await _repository!.resetAll();
      _state = GrowthState.initial();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY LOGIN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a daily login. Idempotent (safe to call multiple times per day).
  ///
  /// Returns a [GrowthUpdateResult] describing any significant events
  /// (part completion, module completion, year completion).
  Future<GrowthUpdateResult> recordDailyLogin() async {
    if (!_isInitialized || _repository == null) {
      return GrowthUpdateResult(newState: _state);
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);

    // Already recorded today - idempotent return
    if (_state.lastLoginDate == today) {
      return GrowthUpdateResult(newState: _state);
    }

    // Increment day counters
    var newTotalDays = _state.totalDays + 1;
    var newDayInPart = _state.dayInPart + 1;
    var newYear = _state.currentYear;
    var newRound = _state.currentRound;
    var newPartIndex = _state.currentPartIndex;
    var newAwards = List<String>.from(_state.yearAwards);

    String? completedPartEmoji;
    int? completedModuleIndex;
    int? completedModuleYear;
    int? completedYear;
    String? yearAwardEmoji;

    // Get current year config
    final yearConfig = GrowthConstants.getYearConfig(newYear);
    final globalPartIndex = yearConfig.getGlobalPartIndex(newRound - 1, newPartIndex);
    final daysForPart = yearConfig.getDaysForPart(globalPartIndex);

    // Check if part is complete
    if (newDayInPart > daysForPart) {
      // Collect the current part
      final currentPart = getCurrentPart();
      completedPartEmoji = currentPart.emoji;

      await _collectPart(currentPart, newTotalDays);

      // Advance to next part
      newDayInPart = 1;
      newPartIndex++;

      // Check if module is complete
      final moduleConfig = yearConfig.getModule(newRound - 1);
      if (newPartIndex >= moduleConfig.parts.length) {
        completedModuleIndex = newRound - 1;
        completedModuleYear = newYear; // Capture year before potential advancement
        newPartIndex = 0;
        newRound++;

        // Check if year is complete
        if (newRound > 15) {
          completedYear = newYear;
          yearAwardEmoji = yearConfig.awardEmoji;
          newAwards = [...newAwards, yearAwardEmoji];

          // Move to next year (or stay at year 3)
          if (newYear < 3) {
            newYear++;
            newRound = 1;
          } else {
            // Stay at year 3, round 15, but mark as complete
            newRound = 15;
            newPartIndex = yearConfig.getModule(14).parts.length - 1;
          }
        }
      }
    }

    // Determine new CP balance (reset if year completed)
    final newCpBalance = completedYear != null ? 0.0 : _state.cpBalance;

    // Replenish challenge quota to 5 if below
    final newChallengeQuota = _state.challengeQuota < 5 ? 5 : _state.challengeQuota;

    // Update state (reset daily CP counters for new day)
    _state = _state.copyWith(
      totalDays: newTotalDays,
      currentYear: newYear,
      currentRound: newRound,
      currentPartIndex: newPartIndex,
      dayInPart: newDayInPart,
      yearAwards: newAwards,
      lastLoginDate: today,
      cpBalance: newCpBalance,
      todayScanCpCount: 0,
      todayAdCpCount: 0,
      todayScannedCodesJson: '[]',
      todayForgeCpCount: 0,
      challengeQuota: newChallengeQuota,
    );

    await _repository!.saveState(_state);
    notifyListeners();

    final result = GrowthUpdateResult(
      newState: _state,
      completedPartEmoji: completedPartEmoji,
      completedModuleIndex: completedModuleIndex,
      completedModuleYear: completedModuleYear,
      completedYear: completedYear,
      yearAwardEmoji: yearAwardEmoji,
    );

    // 如果有模組或年度完成，存儲待處理結果
    if (completedModuleIndex != null || completedYear != null) {
      _pendingResult = result;
    }

    return result;
  }

  /// Collect a part and save to database.
  Future<void> _collectPart(CyberPart part, int totalDays) async {
    final collected = CollectedPart.fromCyberPart(part, totalDays);
    await _repository!.recordCollectedPart(collected);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CP (COMPUTING POWER) SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reset daily CP counters if date has changed (app open past midnight).
  /// Auto-injects any accumulated CP before resetting.
  Future<void> _resetIfNewDay() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_state.lastLoginDate != today) {
      // Auto-inject accumulated CP before resetting (midnight auto-inject)
      var newCpBalance = _state.cpBalance;
      var bonusDays = 0;

      // Inject scan CP if full (20/20)
      if (_state.todayScanCpCount >= maxDailyScanCp) {
        newCpBalance += cpPerScanBatch;
      }

      // Inject ad CP if full (2/2)
      if (_state.todayAdCpCount >= maxDailyAdCp) {
        newCpBalance += cpPerAdBatch;
      }

      // Convert CP to days if >= 1.0
      while (newCpBalance >= 1.0) {
        newCpBalance -= 1.0;
        bonusDays += 1;
      }

      // Apply bonus days if any
      if (bonusDays > 0) {
        await _applyBonusDays(bonusDays);
      }

      // Reset for new day
      _state = _state.copyWith(
        lastLoginDate: today,
        cpBalance: newCpBalance,
        todayScanCpCount: 0,
        todayAdCpCount: 0,
        todayScannedCodesJson: '[]',
        todayForgeCpCount: 0,
      );
      await _repository!.saveState(_state);
      notifyListeners();
    }
  }

  /// Record a scan for CP accumulation (does NOT add CP immediately).
  ///
  /// Returns [CpResult] indicating success/failure.
  /// - Each unique scan increments count (max 20/day)
  /// - Same code only counts once per day
  /// - CP is added when user manually injects (or auto-inject at midnight)
  Future<CpResult> earnScanCp(String rawText) async {
    if (!_isInitialized || _repository == null) {
      return CpResult.limitReached();
    }

    // Check if date changed (app open past midnight)
    await _resetIfNewDay();

    // Check daily limit
    if (_state.todayScanCpCount >= maxDailyScanCp) {
      return CpResult.limitReached();
    }

    // Check for duplicate code today
    final scannedCodes = _state.todayScannedCodes;
    if (scannedCodes.contains(rawText)) {
      return CpResult.duplicate();
    }

    // Only increment count, don't add CP yet
    final newScannedCodes = {...scannedCodes, rawText};

    _state = _state.copyWith(
      todayScanCpCount: _state.todayScanCpCount + 1,
      todayScannedCodesJson: _encodeCodes(newScannedCodes),
    );

    await _repository!.saveState(_state);
    notifyListeners();

    return CpResult.success(
      cpGained: 0.0, // No immediate CP
      bonusDays: 0,
      newCpBalance: _state.cpBalance,
    );
  }

  /// Inject accumulated scan CP (when 20/20 is reached).
  ///
  /// Returns [CpResult] with bonus days from the 2.0 CP injection.
  Future<CpResult> injectScanCp() async {
    if (!_isInitialized || _repository == null) {
      return CpResult.limitReached();
    }

    // Must have full 20 scans to inject
    if (_state.todayScanCpCount < maxDailyScanCp) {
      return CpResult.limitReached();
    }

    // Add 2.0 CP (20 scans * 0.1 each)
    var newCpBalance = _state.cpBalance + cpPerScanBatch;
    var bonusDays = 0;

    // Convert CP to days if >= 1.0
    while (newCpBalance >= 1.0) {
      newCpBalance -= 1.0;
      bonusDays += 1;
    }

    // Apply bonus days through the normal day progression
    if (bonusDays > 0) {
      await _applyBonusDays(bonusDays);
    }

    // Reset scan count after injection
    _state = _state.copyWith(
      cpBalance: newCpBalance,
      todayScanCpCount: 0,
      todayScannedCodesJson: '[]',
    );

    await _repository!.saveState(_state);
    notifyListeners();

    return CpResult.success(
      cpGained: cpPerScanBatch,
      bonusDays: bonusDays,
      newCpBalance: newCpBalance,
    );
  }

  /// Record an ad watch for CP accumulation (does NOT add CP immediately).
  ///
  /// Returns [CpResult] indicating success/failure.
  /// - Each ad increments count (max 2/day)
  /// - CP is added when user manually injects (or auto-inject at midnight)
  Future<CpResult> earnAdCp() async {
    if (!_isInitialized || _repository == null) {
      return CpResult.limitReached();
    }

    // Check if date changed (app open past midnight)
    await _resetIfNewDay();

    // Check daily limit
    if (_state.todayAdCpCount >= maxDailyAdCp) {
      return CpResult.limitReached();
    }

    // Only increment count, don't add CP yet
    _state = _state.copyWith(
      todayAdCpCount: _state.todayAdCpCount + 1,
    );

    await _repository!.saveState(_state);
    notifyListeners();

    return CpResult.success(
      cpGained: 0.0, // No immediate CP
      bonusDays: 0,
      newCpBalance: _state.cpBalance,
    );
  }

  /// Inject accumulated ad/energy CP (when 2/2 is reached).
  ///
  /// Returns [CpResult] with bonus days from the 1.0 CP injection.
  Future<CpResult> injectAdCp() async {
    if (!_isInitialized || _repository == null) {
      return CpResult.limitReached();
    }

    // Must have full 2 ads to inject
    if (_state.todayAdCpCount < maxDailyAdCp) {
      return CpResult.limitReached();
    }

    // Add 1.0 CP (2 ads * 0.5 each)
    var newCpBalance = _state.cpBalance + cpPerAdBatch;
    var bonusDays = 0;

    // Convert CP to days if >= 1.0
    while (newCpBalance >= 1.0) {
      newCpBalance -= 1.0;
      bonusDays += 1;
    }

    // Apply bonus days through the normal day progression
    if (bonusDays > 0) {
      await _applyBonusDays(bonusDays);
    }

    // Reset ad count after injection
    _state = _state.copyWith(
      cpBalance: newCpBalance,
      todayAdCpCount: 0,
    );

    await _repository!.saveState(_state);
    notifyListeners();

    return CpResult.success(
      cpGained: cpPerAdBatch,
      bonusDays: bonusDays,
      newCpBalance: newCpBalance,
    );
  }

  /// Earn CP from completing a forge session (15 min timer).
  ///
  /// Returns [CpResult] indicating success/failure and any bonus days.
  /// - Each forge = +0.2 CP (max 5/day = 1.0 CP)
  Future<CpResult> earnForgeCp() async {
    if (!_isInitialized || _repository == null) {
      return CpResult.limitReached();
    }

    // Check if date changed (app open past midnight)
    await _resetIfNewDay();

    // Check daily limit
    if (_state.todayForgeCpCount >= maxDailyForgeCp) {
      return CpResult.limitReached();
    }

    // Add CP
    var newCpBalance = _state.cpBalance + cpPerForge;
    var bonusDays = 0;

    // Convert CP to days if >= 1.0
    while (newCpBalance >= 1.0) {
      newCpBalance -= 1.0;
      bonusDays += 1;
    }

    // Apply bonus days through the normal day progression
    if (bonusDays > 0) {
      await _applyBonusDays(bonusDays);
    }

    // Update CP state
    _state = _state.copyWith(
      cpBalance: newCpBalance,
      todayForgeCpCount: _state.todayForgeCpCount + 1,
    );

    await _repository!.saveState(_state);
    notifyListeners();

    return CpResult.success(
      cpGained: cpPerForge,
      bonusDays: bonusDays,
      newCpBalance: newCpBalance,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fidget Spinner System
  // ─────────────────────────────────────────────────────────────────────────

  /// All-time high RPM record
  int get spinnerHighRpm => _state.spinnerHighRpm;

  /// Update spinner high RPM if new record
  Future<void> updateSpinnerHighRpm(int rpm) async {
    if (!_isInitialized || _repository == null) return;
    if (rpm <= _state.spinnerHighRpm) return;

    _state = _state.copyWith(spinnerHighRpm: rpm);
    await _repository!.saveState(_state);
    notifyListeners();
  }

  /// All-time high score for challenge mode (legacy)
  int get spinnerHighScore => _state.spinnerHighScore;

  /// Update spinner challenge high score if new record (legacy)
  Future<void> updateSpinnerHighScore(int score) async {
    if (!_isInitialized || _repository == null) return;
    if (score <= _state.spinnerHighScore) return;

    _state = _state.copyWith(spinnerHighScore: score);
    await _repository!.saveState(_state);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Challenge Mode System (TOP 5 + Quota)
  // ─────────────────────────────────────────────────────────────────────────

  /// Current challenge quota
  int get challengeQuota => _state.challengeQuota;

  /// Whether user can start a challenge
  bool get canChallenge => _state.canChallenge;

  /// TOP 5 challenge scores
  List<ChallengeScoreRecord> get challengeScores => _state.challengeScores;

  /// Use one challenge quota (call when starting challenge)
  Future<bool> useChallengeQuota() async {
    if (!_isInitialized || _repository == null) return false;
    if (_state.challengeQuota <= 0) return false;

    _state = _state.copyWith(challengeQuota: _state.challengeQuota - 1);
    await _repository!.saveState(_state);
    notifyListeners();
    return true;
  }

  /// Add challenge quota from watching ad (+5)
  Future<void> addChallengeQuotaFromAd() async {
    if (!_isInitialized || _repository == null) return;

    _state = _state.copyWith(challengeQuota: _state.challengeQuota + 5);
    await _repository!.saveState(_state);
    notifyListeners();
  }

  /// Submit a challenge score, updates TOP 5 if qualified
  /// Returns the rank (1-5) if made it to TOP 5, null otherwise
  Future<int?> submitChallengeScore(int score) async {
    if (!_isInitialized || _repository == null) return null;

    final currentScores = List<ChallengeScoreRecord>.from(_state.challengeScores);
    final newRecord = ChallengeScoreRecord(
      score: score,
      timestamp: DateTime.now(),
    );

    // Add new score and sort descending
    currentScores.add(newRecord);
    currentScores.sort((a, b) => b.score.compareTo(a.score));

    // Keep only TOP 5
    if (currentScores.length > 5) {
      currentScores.removeRange(5, currentScores.length);
    }

    // Check if new score made it to TOP 5
    final rank = currentScores.indexWhere((r) =>
        r.score == newRecord.score &&
        r.timestamp == newRecord.timestamp);
    final madeTop5 = rank >= 0 && rank < 5;

    // Encode and save
    final scoresJson = jsonEncode(currentScores.map((r) => r.toJson()).toList());
    _state = _state.copyWith(
      challengeScoresJson: scoresJson,
      // Also update legacy high score for backwards compatibility
      spinnerHighScore: currentScores.isNotEmpty ? currentScores.first.score : 0,
    );
    await _repository!.saveState(_state);
    notifyListeners();

    return madeTop5 ? rank + 1 : null; // Return 1-based rank
  }

  /// Apply bonus days from CP conversion.
  /// Similar to recordDailyLogin but doesn't update lastLoginDate.
  /// Sets _pendingResult if any module or year is completed.
  Future<void> _applyBonusDays(int days) async {
    // Track the most significant completion across all bonus days
    int? mostSignificantModuleIndex;
    int? mostSignificantModuleYear;
    int? mostSignificantYear;
    String? mostSignificantYearAward;

    for (var i = 0; i < days; i++) {
      final result = await _advanceOneDay();

      // Year completion is more significant than module completion
      if (result.completedYear != null) {
        mostSignificantYear = result.completedYear;
        mostSignificantYearAward = result.yearAwardEmoji;
        // Also track the module (last module of the year)
        mostSignificantModuleIndex = result.completedModuleIndex;
        mostSignificantModuleYear = result.completedModuleYear;
      } else if (result.completedModuleIndex != null && mostSignificantYear == null) {
        // Only update module if no year completion yet
        mostSignificantModuleIndex = result.completedModuleIndex;
        mostSignificantModuleYear = result.completedModuleYear;
      }
    }

    // Set pending result if any completion occurred
    if (mostSignificantModuleIndex != null || mostSignificantYear != null) {
      _pendingResult = GrowthUpdateResult(
        newState: _state,
        completedModuleIndex: mostSignificantModuleIndex,
        completedModuleYear: mostSignificantModuleYear,
        completedYear: mostSignificantYear,
        yearAwardEmoji: mostSignificantYearAward,
      );
    }
  }

  /// Advance the growth state by one day (for CP conversion).
  /// Returns completion information for tracking rewards.
  Future<_DayAdvanceResult> _advanceOneDay() async {
    var newTotalDays = _state.totalDays + 1;
    var newDayInPart = _state.dayInPart + 1;
    var newYear = _state.currentYear;
    var newRound = _state.currentRound;
    var newPartIndex = _state.currentPartIndex;
    var newAwards = List<String>.from(_state.yearAwards);
    var newCpBalance = _state.cpBalance;

    int? completedModuleIndex;
    int? completedModuleYear;
    int? completedYear;
    String? yearAwardEmoji;

    // Get current year config
    final yearConfig = GrowthConstants.getYearConfig(newYear);
    final globalPartIndex = yearConfig.getGlobalPartIndex(newRound - 1, newPartIndex);
    final daysForPart = yearConfig.getDaysForPart(globalPartIndex);

    // Check if part is complete
    if (newDayInPart > daysForPart) {
      final currentPart = getCurrentPart();
      await _collectPart(currentPart, newTotalDays);

      newDayInPart = 1;
      newPartIndex++;

      final moduleConfig = yearConfig.getModule(newRound - 1);
      if (newPartIndex >= moduleConfig.parts.length) {
        completedModuleIndex = newRound - 1;
        completedModuleYear = newYear; // Capture year before potential advancement
        newPartIndex = 0;
        newRound++;

        if (newRound > 15) {
          completedYear = newYear;
          yearAwardEmoji = yearConfig.awardEmoji;
          newAwards = [...newAwards, yearAwardEmoji];
          newCpBalance = 0.0; // Reset CP on year completion

          if (newYear < 3) {
            newYear++;
            newRound = 1;
          } else {
            newRound = 15;
            newPartIndex = yearConfig.getModule(14).parts.length - 1;
          }
        }
      }
    }

    _state = _state.copyWith(
      totalDays: newTotalDays,
      currentYear: newYear,
      currentRound: newRound,
      currentPartIndex: newPartIndex,
      dayInPart: newDayInPart,
      yearAwards: newAwards,
      cpBalance: newCpBalance,
    );

    return _DayAdvanceResult(
      completedModuleIndex: completedModuleIndex,
      completedModuleYear: completedModuleYear,
      completedYear: completedYear,
      yearAwardEmoji: yearAwardEmoji,
    );
  }

  /// Encode a set of codes to JSON string.
  String _encodeCodes(Set<String> codes) {
    return jsonEncode(codes.toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the current part being worked on.
  CyberPart getCurrentPart() {
    final yearConfig = GrowthConstants.getYearConfig(_state.currentYear);
    return yearConfig.getPart(_state.currentRound - 1, _state.currentPartIndex);
  }

  /// Get the current year configuration.
  YearConfig getCurrentYearConfig() {
    return GrowthConstants.getYearConfig(_state.currentYear);
  }

  /// Get the current module configuration.
  ModuleConfig getCurrentModule() {
    final yearConfig = getCurrentYearConfig();
    return yearConfig.getModule(_state.currentRound - 1);
  }

  /// Get progress through the current module (0.0-1.0).
  double getModuleProgress() {
    final module = getCurrentModule();
    final partsComplete = _state.currentPartIndex;
    final totalParts = module.parts.length;

    // Add partial progress for current part
    final yearConfig = getCurrentYearConfig();
    final globalIndex = yearConfig.getGlobalPartIndex(
        _state.currentRound - 1, _state.currentPartIndex);
    final daysForPart = yearConfig.getDaysForPart(globalIndex);
    final partProgress = (_state.dayInPart - 1) / daysForPart;

    return (partsComplete + partProgress) / totalParts;
  }

  /// Get total days for the current round/module.
  int getDaysForCurrentRound() {
    final yearConfig = getCurrentYearConfig();
    final moduleIndex = _state.currentRound - 1;
    final module = yearConfig.getModule(moduleIndex);

    int totalDays = 0;
    for (int i = 0; i < module.parts.length; i++) {
      final globalIndex = yearConfig.getGlobalPartIndex(moduleIndex, i);
      totalDays += yearConfig.getDaysForPart(globalIndex);
    }
    return totalDays;
  }

  /// Get days elapsed in the current round.
  int getDaysInCurrentRound() {
    final yearConfig = getCurrentYearConfig();
    final moduleIndex = _state.currentRound - 1;

    // Days from completed parts in this round
    int days = 0;
    for (int i = 0; i < _state.currentPartIndex; i++) {
      final globalIndex = yearConfig.getGlobalPartIndex(moduleIndex, i);
      days += yearConfig.getDaysForPart(globalIndex);
    }

    // Add days in current part
    days += _state.dayInPart;
    return days;
  }

  /// Get year-specific progress text.
  String getProgressText({String language = 'zh'}) {
    return _state.getProgressText(language: language);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLECTION QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get collected parts for a specific year.
  Future<List<CollectedPart>> getCollectedParts(int year) async {
    if (_repository == null) return [];
    return _repository!.getCollectedByYear(year);
  }

  /// Get collected parts for a specific module.
  Future<List<CollectedPart>> getCollectedByModule(int year, int moduleIndex) async {
    if (_repository == null) return [];
    return _repository!.getCollectedByModule(year, moduleIndex);
  }

  /// Check if a specific part has been collected.
  Future<bool> isPartCollected(String partId) async {
    if (_repository == null) return false;
    return _repository!.isPartCollected(partId);
  }

  /// Get the set of collected part IDs for a year.
  Future<Set<String>> getCollectedPartIds(int year) async {
    if (_repository == null) return {};
    return _repository!.getCollectedPartIds(year);
  }

  /// Get collection count for a year.
  Future<int> getCollectedCount(int year) async {
    if (_repository == null) return 0;
    return _repository!.getCollectedCount(year);
  }

  /// Get total collection count across all years.
  Future<int> getTotalCollectedCount() async {
    if (_repository == null) return 0;
    return _repository!.getTotalCollectedCount();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERITAGE SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if the current part triggers a heritage animation.
  ///
  /// Returns [HeritageAnimationData] if the current part is a reuse part
  /// and the original has been collected, null otherwise.
  Future<HeritageAnimationData?> checkHeritageAnimation() async {
    final currentPart = getCurrentPart();
    if (!currentPart.isReuse || currentPart.reuseSourceId == null) {
      return null;
    }

    // Check if original part was collected
    if (_repository == null) return null;
    final isCollected = await _repository!.isPartCollected(currentPart.reuseSourceId!);
    if (!isCollected) return null;

    // Find original part definition
    final originalPart = GrowthConstants.findPartById(currentPart.reuseSourceId!);
    if (originalPart == null) return null;

    return HeritageAnimationData(
      originalPartId: originalPart.id,
      originalEmoji: originalPart.emoji,
      sourceYear: originalPart.year,
      currentPartId: currentPart.id,
      currentEmoji: currentPart.emoji,
      sourceYearAward: YearAward.forYear(originalPart.year),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUG / TESTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get debug statistics.
  Future<Map<String, dynamic>> getStats() async {
    if (_repository == null) return {'error': 'Not initialized'};
    return _repository!.getStats();
  }

  /// Manually advance to a specific day.
  /// Used for testing and dev tools.
  Future<void> setTotalDays(int days) async {
    if (_repository == null) return;

    // Recalculate position from total days
    var year = 1;
    var remainingDays = days;

    // Determine which year we're in
    while (remainingDays > 365 && year < 3) {
      remainingDays -= 365;
      year++;
    }

    // Find position within the year
    final yearConfig = GrowthConstants.getYearConfig(year);
    var round = 1;
    var partIndex = 0;
    var dayInPart = 1;
    var dayCounter = 0;

    outer:
    for (var r = 0; r < 15; r++) {
      final module = yearConfig.getModule(r);
      for (var p = 0; p < module.parts.length; p++) {
        final globalIdx = yearConfig.getGlobalPartIndex(r, p);
        final daysForPart = yearConfig.getDaysForPart(globalIdx);

        if (dayCounter + daysForPart >= remainingDays) {
          round = r + 1;
          partIndex = p;
          dayInPart = remainingDays - dayCounter;
          if (dayInPart < 1) dayInPart = 1;
          break outer;
        }
        dayCounter += daysForPart;
      }
    }

    // Calculate year awards based on completed years
    final newAwards = <String>[];
    if (days > 365) newAwards.add('🛰️'); // Completed Year 1
    if (days > 730) newAwards.add('🤖'); // Completed Year 2
    if (days > 1095) newAwards.add('🗼'); // Completed Year 3

    _state = _state.copyWith(
      totalDays: days,
      currentYear: year,
      currentRound: round,
      currentPartIndex: partIndex,
      dayInPart: dayInPart,
      yearAwards: newAwards,
    );

    await _repository!.saveState(_state);
    notifyListeners();
  }
}

/// Internal result class for tracking day advancement completions.
class _DayAdvanceResult {
  final int? completedModuleIndex;
  final int? completedModuleYear;
  final int? completedYear;
  final String? yearAwardEmoji;

  const _DayAdvanceResult({
    this.completedModuleIndex,
    this.completedModuleYear,
    this.completedYear,
    this.yearAwardEmoji,
  });
}
