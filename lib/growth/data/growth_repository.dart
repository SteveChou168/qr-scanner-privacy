import 'package:sqflite/sqflite.dart';

import 'cyber_part.dart';
import 'growth_state.dart';

/// Repository for persisting growth system data to SQLite.
///
/// Uses two tables:
/// - `cyber_growth_state`: Singleton state record (id=1)
/// - `cyber_collected_parts`: Log of collected parts
class GrowthRepository {
  final Database _db;

  GrowthRepository(this._db);

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLE DEFINITIONS (for use in database migrations)
  // ═══════════════════════════════════════════════════════════════════════════

  /// SQL to create the growth state table.
  static const String createStateTableSql = '''
    CREATE TABLE IF NOT EXISTS cyber_growth_state (
      id INTEGER PRIMARY KEY DEFAULT 1,
      total_days INTEGER DEFAULT 0,
      current_year INTEGER DEFAULT 1,
      current_round INTEGER DEFAULT 1,
      current_part_index INTEGER DEFAULT 0,
      day_in_part INTEGER DEFAULT 1,
      year_awards_json TEXT DEFAULT '[]',
      last_login_date TEXT,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      cp_balance REAL DEFAULT 0.0,
      today_scan_cp_count INTEGER DEFAULT 0,
      today_ad_cp_count INTEGER DEFAULT 0,
      today_scanned_codes_json TEXT DEFAULT '[]'
    )
  ''';

  /// SQL to create the collected parts table.
  static const String createCollectedTableSql = '''
    CREATE TABLE IF NOT EXISTS cyber_collected_parts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      part_id TEXT NOT NULL UNIQUE,
      emoji TEXT NOT NULL,
      year INTEGER NOT NULL,
      module_index INTEGER NOT NULL,
      is_reuse INTEGER DEFAULT 0,
      reuse_source_id TEXT,
      collected_at TEXT DEFAULT CURRENT_TIMESTAMP,
      total_days_at_collection INTEGER NOT NULL
    )
  ''';

  /// SQL to create indexes.
  static const List<String> createIndexesSql = [
    'CREATE INDEX IF NOT EXISTS idx_collected_year ON cyber_collected_parts(year)',
    'CREATE INDEX IF NOT EXISTS idx_collected_module ON cyber_collected_parts(year, module_index)',
    'CREATE INDEX IF NOT EXISTS idx_collected_reuse ON cyber_collected_parts(reuse_source_id)',
  ];

  /// Initialize tables if they don't exist.
  Future<void> ensureTables() async {
    await _db.execute(createStateTableSql);
    await _db.execute(createCollectedTableSql);
    for (final sql in createIndexesSql) {
      await _db.execute(sql);
    }
    // Migrate existing tables to add CP columns if missing
    await _migrateCpColumns();
  }

  /// Add CP columns to existing cyber_growth_state table.
  Future<void> _migrateCpColumns() async {
    // Check if columns exist by querying table info
    final tableInfo = await _db.rawQuery(
      "PRAGMA table_info(cyber_growth_state)",
    );
    final columns = tableInfo.map((r) => r['name'] as String).toSet();

    // Add missing CP columns
    if (!columns.contains('cp_balance')) {
      await _db.execute(
        'ALTER TABLE cyber_growth_state ADD COLUMN cp_balance REAL DEFAULT 0.0',
      );
    }
    if (!columns.contains('today_scan_cp_count')) {
      await _db.execute(
        'ALTER TABLE cyber_growth_state ADD COLUMN today_scan_cp_count INTEGER DEFAULT 0',
      );
    }
    if (!columns.contains('today_ad_cp_count')) {
      await _db.execute(
        'ALTER TABLE cyber_growth_state ADD COLUMN today_ad_cp_count INTEGER DEFAULT 0',
      );
    }
    if (!columns.contains('today_scanned_codes_json')) {
      await _db.execute(
        "ALTER TABLE cyber_growth_state ADD COLUMN today_scanned_codes_json TEXT DEFAULT '[]'",
      );
    }
    if (!columns.contains('today_forge_cp_count')) {
      await _db.execute(
        'ALTER TABLE cyber_growth_state ADD COLUMN today_forge_cp_count INTEGER DEFAULT 0',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load the current growth state. Returns initial state if none exists.
  Future<GrowthState> loadState() async {
    final rows = await _db.query(
      'cyber_growth_state',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return GrowthState.initial();
    }

    return GrowthState.fromJson(rows.first);
  }

  /// Save the growth state (upsert pattern).
  Future<void> saveState(GrowthState state) async {
    final json = state.toJson();
    json['id'] = 1; // Ensure singleton ID

    await _db.insert(
      'cyber_growth_state',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update only the last login date (optimization for daily check).
  Future<void> updateLastLoginDate(String date) async {
    await _db.update(
      'cyber_growth_state',
      {
        'last_login_date': date,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLECTED PARTS OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a newly collected part.
  Future<void> recordCollectedPart(CollectedPart part) async {
    await _db.insert(
      'cyber_collected_parts',
      part.toJson(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // Skip if already exists
    );
  }

  /// Get a collected part by its ID. Returns null if not collected.
  Future<CollectedPart?> getCollectedPart(String partId) async {
    final rows = await _db.query(
      'cyber_collected_parts',
      where: 'part_id = ?',
      whereArgs: [partId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return CollectedPart.fromJson(rows.first);
  }

  /// Check if a part has been collected.
  Future<bool> isPartCollected(String partId) async {
    final count = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT COUNT(*) FROM cyber_collected_parts WHERE part_id = ?',
      [partId],
    ));
    return (count ?? 0) > 0;
  }

  /// Get all collected parts for a specific year.
  Future<List<CollectedPart>> getCollectedByYear(int year) async {
    final rows = await _db.query(
      'cyber_collected_parts',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'total_days_at_collection ASC',
    );

    return rows.map((r) => CollectedPart.fromJson(r)).toList();
  }

  /// Get all collected parts for a specific year and module.
  Future<List<CollectedPart>> getCollectedByModule(int year, int moduleIndex) async {
    final rows = await _db.query(
      'cyber_collected_parts',
      where: 'year = ? AND module_index = ?',
      whereArgs: [year, moduleIndex],
      orderBy: 'total_days_at_collection ASC',
    );

    return rows.map((r) => CollectedPart.fromJson(r)).toList();
  }

  /// Get all collected parts across all years.
  Future<List<CollectedPart>> getAllCollected() async {
    final rows = await _db.query(
      'cyber_collected_parts',
      orderBy: 'total_days_at_collection ASC',
    );

    return rows.map((r) => CollectedPart.fromJson(r)).toList();
  }

  /// Get the set of collected part IDs for a year.
  Future<Set<String>> getCollectedPartIds(int year) async {
    final rows = await _db.query(
      'cyber_collected_parts',
      columns: ['part_id'],
      where: 'year = ?',
      whereArgs: [year],
    );

    return rows.map((r) => r['part_id'] as String).toSet();
  }

  /// Get the count of collected parts for a year.
  Future<int> getCollectedCount(int year) async {
    final count = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT COUNT(*) FROM cyber_collected_parts WHERE year = ?',
      [year],
    ));
    return count ?? 0;
  }

  /// Get the total count of collected parts across all years.
  Future<int> getTotalCollectedCount() async {
    final count = Sqflite.firstIntValue(await _db.rawQuery(
      'SELECT COUNT(*) FROM cyber_collected_parts',
    ));
    return count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // YEAR COMPLETION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record that a year was completed.
  /// This is handled in GrowthState.yearAwards, but we can log it here too.
  Future<void> recordYearComplete(int year) async {
    // Currently just a hook for potential future logging/analytics
    // The award is stored in GrowthState.yearAwards
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESET / DEBUG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reset all growth data (for testing/debug).
  Future<void> resetAll() async {
    await _db.delete('cyber_growth_state');
    await _db.delete('cyber_collected_parts');
  }

  /// Get statistics for debugging.
  Future<Map<String, dynamic>> getStats() async {
    final state = await loadState();
    final totalCollected = await getTotalCollectedCount();
    final y1Count = await getCollectedCount(1);
    final y2Count = await getCollectedCount(2);
    final y3Count = await getCollectedCount(3);

    return {
      'totalDays': state.totalDays,
      'currentYear': state.currentYear,
      'currentRound': state.currentRound,
      'currentPartIndex': state.currentPartIndex,
      'dayInPart': state.dayInPart,
      'yearAwards': state.yearAwards,
      'totalCollected': totalCollected,
      'year1Collected': y1Count,
      'year2Collected': y2Count,
      'year3Collected': y3Count,
    };
  }
}
