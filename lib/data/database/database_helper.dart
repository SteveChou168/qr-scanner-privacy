// lib/data/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_record.dart';
import '../../growth/data/growth_repository.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _version = 4; // v4: Added code_letter for multi-code scan labeling

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'qr_scanner.db');

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Scan history table
    await db.execute('''
      CREATE TABLE scan_history (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        raw_text        TEXT NOT NULL,
        display_text    TEXT,
        barcode_format  TEXT NOT NULL,
        semantic_type   TEXT NOT NULL,
        scanned_at      TEXT NOT NULL,
        place_name      TEXT,
        place_source    TEXT DEFAULT 'none',
        image_path      TEXT,
        code_letter     TEXT,
        tags            TEXT,
        note            TEXT,
        is_favorite     INTEGER DEFAULT 0,
        created_at      TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_history_scanned_at ON scan_history(scanned_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_semantic_type ON scan_history(semantic_type)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_is_favorite ON scan_history(is_favorite)
    ''');

    await db.execute('''
      CREATE INDEX idx_history_raw_text ON scan_history(raw_text)
    ''');

    // Growth system tables
    await _createGrowthTables(db);
  }

  /// Create growth system tables (shared between onCreate and onUpgrade)
  Future<void> _createGrowthTables(Database db) async {
    await db.execute(GrowthRepository.createStateTableSql);
    await db.execute(GrowthRepository.createCollectedTableSql);
    for (final sql in GrowthRepository.createIndexesSql) {
      await db.execute(sql);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2: Add growth system tables
    if (oldVersion < 2) {
      await _createGrowthTables(db);
    }
    // Migration from version 2 to 3: Add raw_text index for search performance
    if (oldVersion < 3) {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_history_raw_text ON scan_history(raw_text)
      ''');
    }
    // Migration from version 3 to 4: Add code_letter for multi-code scan labeling
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE scan_history ADD COLUMN code_letter TEXT
      ''');
    }
  }

  // ============ Helper Methods ============

  /// Escape special characters for SQL LIKE queries
  /// Escapes %, _, and \ to prevent unexpected pattern matching
  String _escapeLikeQuery(String query) {
    return query
        .replaceAll('\\', '\\\\')  // Escape backslash first
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  // ============ CRUD Operations ============

  /// Insert a new scan record
  Future<int> insertScanRecord(ScanRecord record) async {
    final db = await database;
    return await db.insert('scan_history', record.toMap());
  }

  /// Get all scan records (newest first)
  Future<List<ScanRecord>> getScanRecords({int? limit, int? offset}) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      orderBy: 'scanned_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Get scan record by ID
  Future<ScanRecord?> getScanRecordById(int id) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ScanRecord.fromMap(maps.first);
  }

  /// Get scan records by semantic type
  Future<List<ScanRecord>> getScanRecordsByType(SemanticType type) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'semantic_type = ?',
      whereArgs: [type.name],
      orderBy: 'scanned_at DESC',
    );
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Get favorite scan records
  Future<List<ScanRecord>> getFavoriteScanRecords() async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'is_favorite = 1',
      orderBy: 'scanned_at DESC',
    );
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Search scan records
  Future<List<ScanRecord>> searchScanRecords(String query) async {
    final db = await database;
    final escaped = _escapeLikeQuery(query);
    final pattern = '%$escaped%';
    final maps = await db.rawQuery(
      '''
      SELECT * FROM scan_history
      WHERE raw_text LIKE ? ESCAPE '\\'
         OR display_text LIKE ? ESCAPE '\\'
         OR note LIKE ? ESCAPE '\\'
      ORDER BY scanned_at DESC
      ''',
      [pattern, pattern, pattern],
    );
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Update a scan record
  Future<int> updateScanRecord(ScanRecord record) async {
    if (record.id == null) return 0;
    final db = await database;
    return await db.update(
      'scan_history',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// Toggle favorite status
  Future<int> toggleFavorite(int id) async {
    final db = await database;
    return await db.rawUpdate('''
      UPDATE scan_history
      SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END
      WHERE id = ?
    ''', [id]);
  }

  /// Delete a scan record
  Future<int> deleteScanRecord(int id) async {
    final db = await database;
    return await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all scan records
  Future<int> deleteAllScanRecords() async {
    final db = await database;
    return await db.delete('scan_history');
  }

  /// Delete multiple records by IDs
  Future<int> deleteRecordsByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    return await db.delete(
      'scan_history',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Set favorite status for multiple records
  Future<int> setFavoriteForIds(List<int> ids, bool isFavorite) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    return await db.rawUpdate(
      'UPDATE scan_history SET is_favorite = ? WHERE id IN ($placeholders)',
      [isFavorite ? 1 : 0, ...ids],
    );
  }

  /// Get total count of scan records
  Future<int> getScanRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM scan_history');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Trim history to keep only the most recent records
  Future<void> trimHistory(int maxRecords) async {
    final db = await database;
    await db.execute('''
      DELETE FROM scan_history
      WHERE id NOT IN (
        SELECT id FROM scan_history
        ORDER BY scanned_at DESC
        LIMIT ?
      )
    ''', [maxRecords]);
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ============ Codex-specific Queries ============

  /// Get records for a specific date range
  Future<List<ScanRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end, {
    SemanticType? type,
    bool favoritesOnly = false,
  }) async {
    final db = await database;
    final conditions = <String>['scanned_at >= ? AND scanned_at < ?'];
    final args = <dynamic>[start.toIso8601String(), end.toIso8601String()];

    if (type != null) {
      conditions.add('semantic_type = ?');
      args.add(type.name);
    }
    if (favoritesOnly) {
      conditions.add('is_favorite = 1');
    }

    final maps = await db.query(
      'scan_history',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'scanned_at DESC',
    );
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Get daily scan counts for a date range (for heatmap)
  Future<Map<String, int>> getDailyCountsInRange(
    DateTime start,
    DateTime end, {
    SemanticType? type,
    bool favoritesOnly = false,
  }) async {
    final db = await database;
    final conditions = <String>['scanned_at >= ? AND scanned_at < ?'];
    final args = <dynamic>[start.toIso8601String(), end.toIso8601String()];

    if (type != null) {
      conditions.add('semantic_type = ?');
      args.add(type.name);
    }
    if (favoritesOnly) {
      conditions.add('is_favorite = 1');
    }

    final result = await db.rawQuery('''
      SELECT DATE(scanned_at) as date, COUNT(*) as count
      FROM scan_history
      WHERE ${conditions.join(' AND ')}
      GROUP BY DATE(scanned_at)
    ''', args);

    return Map.fromEntries(
      result.map((r) => MapEntry(r['date'] as String, r['count'] as int)),
    );
  }

  /// Get counts grouped by semantic type
  Future<Map<SemanticType, int>> getCountsByType() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT semantic_type, COUNT(*) as count
      FROM scan_history
      GROUP BY semantic_type
    ''');

    return Map.fromEntries(result.map((r) {
      final typeStr = r['semantic_type'] as String?;
      final type = SemanticType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => SemanticType.text,
      );
      return MapEntry(type, r['count'] as int);
    }));
  }

  /// Get today's scan count
  Future<int> getTodayCount() async {
    final db = await database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM scan_history
      WHERE scanned_at >= ? AND scanned_at < ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get monthly counts for a year (for yearly view)
  Future<Map<int, int>> getMonthlyCounts(int year) async {
    final db = await database;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final result = await db.rawQuery('''
      SELECT strftime('%m', scanned_at) as month, COUNT(*) as count
      FROM scan_history
      WHERE scanned_at >= ? AND scanned_at < ?
      GROUP BY strftime('%m', scanned_at)
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return Map.fromEntries(result.map((r) => MapEntry(
          int.parse(r['month'] as String),
          r['count'] as int,
        )));
  }

  /// Get recent N records' raw_text values for duplicate check
  Future<List<String>> getRecentRawTexts({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      columns: ['raw_text'],
      orderBy: 'scanned_at DESC',
      limit: limit,
    );
    return maps.map((m) => m['raw_text'] as String).toList();
  }

  /// Get most scanned place names
  Future<List<MapEntry<String, int>>> getTopPlaces({int limit = 5}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT place_name, COUNT(*) as count
      FROM scan_history
      WHERE place_name IS NOT NULL AND place_name != ''
      GROUP BY place_name
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);

    return result
        .map((r) => MapEntry(
              r['place_name'] as String,
              r['count'] as int,
            ))
        .toList();
  }

  /// Get records with images only
  Future<List<ScanRecord>> getRecordsWithImages({int? limit}) async {
    final db = await database;
    final maps = await db.query(
      'scan_history',
      where: 'image_path IS NOT NULL AND image_path != ""',
      orderBy: 'scanned_at DESC',
      limit: limit,
    );
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Count how many records use a specific image path
  Future<int> countRecordsByImagePath(String imagePath) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM scan_history WHERE image_path = ?',
      [imagePath],
    );
    return result.first['count'] as int;
  }

  /// Get all unique image paths
  Future<List<String>> getAllImagePaths() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT image_path FROM scan_history WHERE image_path IS NOT NULL AND image_path != ""',
    );
    return result.map((r) => r['image_path'] as String).toList();
  }

  /// Get image paths for specific record IDs
  Future<List<String>> getImagePathsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    final result = await db.rawQuery(
      'SELECT DISTINCT image_path FROM scan_history WHERE id IN ($placeholders) AND image_path IS NOT NULL AND image_path != ""',
      ids,
    );
    return result.map((r) => r['image_path'] as String).toList();
  }

  /// Search with date range filter
  Future<List<ScanRecord>> searchWithDateRange(
    String query,
    DateTime? start,
    DateTime? end,
  ) async {
    final db = await database;
    final escaped = _escapeLikeQuery(query);
    final pattern = '%$escaped%';

    var sql = '''
      SELECT * FROM scan_history
      WHERE (raw_text LIKE ? ESCAPE '\\'
         OR display_text LIKE ? ESCAPE '\\'
         OR place_name LIKE ? ESCAPE '\\')
    ''';
    final args = <dynamic>[pattern, pattern, pattern];

    if (start != null) {
      sql += ' AND scanned_at >= ?';
      args.add(start.toIso8601String());
    }
    if (end != null) {
      sql += ' AND scanned_at < ?';
      args.add(end.toIso8601String());
    }
    sql += ' ORDER BY scanned_at DESC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => ScanRecord.fromMap(m)).toList();
  }

  /// Get monthly statistics with type breakdown
  Future<Map<int, Map<SemanticType, int>>> getMonthlyTypeStats(int year) async {
    final db = await database;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year + 1, 1, 1);

    final result = await db.rawQuery('''
      SELECT
        CAST(strftime('%m', scanned_at) AS INTEGER) as month,
        semantic_type,
        COUNT(*) as count
      FROM scan_history
      WHERE scanned_at >= ? AND scanned_at < ?
      GROUP BY strftime('%m', scanned_at), semantic_type
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final stats = <int, Map<SemanticType, int>>{};
    for (final row in result) {
      final month = row['month'] as int;
      final typeStr = row['semantic_type'] as String?;
      final type = SemanticType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => SemanticType.text,
      );
      final count = row['count'] as int;

      stats.putIfAbsent(month, () => {});
      stats[month]![type] = count;
    }
    return stats;
  }
}
