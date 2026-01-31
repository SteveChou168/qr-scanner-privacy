// lib/providers/codex_provider.dart

import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/scan_record.dart';
import '../data/models/codex_stats.dart';

enum CodexViewMode { daily, weekly, monthly, yearly }

enum CodexSortMode { newest, oldest, byType, hasImage }

class CodexProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  CodexViewMode _viewMode = CodexViewMode.daily;
  SemanticType? _filterType;
  bool _showFavoritesOnly = false;
  CodexSortMode _sortMode = CodexSortMode.newest;
  String? _searchQuery;

  bool _isLoading = false;
  List<ScanRecord> _records = [];
  CodexStats _stats = CodexStats.empty();
  Map<String, int> _dailyCounts = {};

  // Current date for navigation
  DateTime _selectedDate = DateTime.now();

  // Selection mode state
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};

  CodexProvider(this._db);

  // Getters
  CodexViewMode get viewMode => _viewMode;
  SemanticType? get filterType => _filterType;
  bool get showFavoritesOnly => _showFavoritesOnly;
  CodexSortMode get sortMode => _sortMode;
  String? get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  List<ScanRecord> get records => _records;
  CodexStats get stats => _stats;
  Map<String, int> get dailyCounts => _dailyCounts;
  DateTime get selectedDate => _selectedDate;

  // Selection mode getters
  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedIds => _selectedIds;
  int get selectedCount => _selectedIds.length;
  bool get hasSelection => _selectedIds.isNotEmpty;

  // View mode management
  void setViewMode(CodexViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    _searchQuery = null; // Clear search when changing view
    loadData();
  }

  // Filter management
  void setFilter(SemanticType? type) {
    // When setting to null (全部), clear all filters
    if (type == null) {
      if (_filterType == null && !_showFavoritesOnly) return; // Already cleared
      _filterType = null;
      _showFavoritesOnly = false;
      loadData();
      return;
    }
    if (_filterType == type) return;
    _filterType = type;
    _showFavoritesOnly = false;
    loadData();
  }

  void setFavoritesFilter(bool favoritesOnly) {
    if (_showFavoritesOnly == favoritesOnly) return;
    _showFavoritesOnly = favoritesOnly;
    _filterType = null;
    loadData();
  }

  void setSort(CodexSortMode mode) {
    if (_sortMode == mode) return;
    _sortMode = mode;
    _sortRecords();
    notifyListeners();
  }

  void search(String? query) {
    _searchQuery = query?.isEmpty == true ? null : query;
    loadData();
  }

  void clearSearch() {
    _searchQuery = null;
    loadData();
  }

  // Date navigation
  void navigateDate(int delta) {
    switch (_viewMode) {
      case CodexViewMode.daily:
        _selectedDate = _selectedDate.add(Duration(days: delta));
        break;
      case CodexViewMode.weekly:
        _selectedDate = _selectedDate.add(Duration(days: delta * 7));
        break;
      case CodexViewMode.monthly:
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + delta,
          1,
        );
        break;
      case CodexViewMode.yearly:
        _selectedDate = DateTime(_selectedDate.year + delta, 1, 1);
        break;
    }
    loadData();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    loadData();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    loadData();
  }

  // Data loading
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadRecords(),
        _loadStats(),
        if (_viewMode == CodexViewMode.monthly ||
            _viewMode == CodexViewMode.yearly)
          _loadDailyCounts(),
      ]);
    } catch (e) {
      debugPrint('Error loading codex data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadRecords() async {
    final (start, end) = _getDateRange();

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      _records = await _db.searchWithDateRange(_searchQuery!, start, end);
    } else {
      _records = await _db.getRecordsByDateRange(
        start,
        end,
        type: _filterType,
        favoritesOnly: _showFavoritesOnly,
      );
    }

    _sortRecords();
  }

  Future<void> _loadStats() async {
    final todayCount = await _db.getTodayCount();
    final totalCount = await _db.getScanRecordCount();
    final typeCounts = await _db.getCountsByType();
    final topPlaces = await _db.getTopPlaces();

    // Load last 14 days for chart
    final chartEnd = DateTime.now().add(const Duration(days: 1));
    final chartStart = DateTime.now().subtract(const Duration(days: 13));
    final chartDailyCounts = await _db.getDailyCountsInRange(
      DateTime(chartStart.year, chartStart.month, chartStart.day),
      DateTime(chartEnd.year, chartEnd.month, chartEnd.day),
    );

    SemanticType? mostScanned;
    int maxCount = 0;
    for (final entry in typeCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostScanned = entry.key;
      }
    }

    _stats = CodexStats(
      todayCount: todayCount,
      totalCount: totalCount,
      typeCounts: typeCounts,
      mostScannedType: mostScanned,
      topPlaces: topPlaces,
      dailyCounts: chartDailyCounts,
    );
  }

  Future<void> _loadDailyCounts() async {
    final (start, end) = _getDateRange();
    _dailyCounts = await _db.getDailyCountsInRange(
      start,
      end,
      type: _filterType,
      favoritesOnly: _showFavoritesOnly,
    );
  }

  (DateTime, DateTime) _getDateRange() {
    final now = _selectedDate;
    switch (_viewMode) {
      case CodexViewMode.daily:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case CodexViewMode.weekly:
        // Start from Monday
        final weekday = now.weekday;
        final start = DateTime(now.year, now.month, now.day - weekday + 1);
        return (start, start.add(const Duration(days: 7)));
      case CodexViewMode.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return (start, end);
      case CodexViewMode.yearly:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        return (start, end);
    }
  }

  void _sortRecords() {
    switch (_sortMode) {
      case CodexSortMode.newest:
        _records.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        break;
      case CodexSortMode.oldest:
        _records.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
        break;
      case CodexSortMode.byType:
        _records.sort(
            (a, b) => a.semanticType.index.compareTo(b.semanticType.index));
        break;
      case CodexSortMode.hasImage:
        _records.sort((a, b) {
          final aHas = a.imagePath != null ? 0 : 1;
          final bHas = b.imagePath != null ? 0 : 1;
          if (aHas != bHas) return aHas.compareTo(bHas);
          return b.scannedAt.compareTo(a.scannedAt);
        });
        break;
    }
  }

  // Group records by date for weekly view
  Map<DateTime, List<ScanRecord>> get recordsByDate {
    final grouped = <DateTime, List<ScanRecord>>{};
    for (final record in _records) {
      final date = DateTime(
        record.scannedAt.year,
        record.scannedAt.month,
        record.scannedAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(record);
    }
    return grouped;
  }

  // Get week days for weekly view
  List<DateTime> get weekDays {
    final (start, _) = _getDateRange();
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  // Check if a date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Get formatted date label for current view
  String get dateLabel {
    final now = _selectedDate;
    switch (_viewMode) {
      case CodexViewMode.daily:
        if (isToday(now)) {
          return 'Today';
        }
        return '${now.year}/${now.month}/${now.day}';
      case CodexViewMode.weekly:
        final (start, end) = _getDateRange();
        return '${start.month}/${start.day} - ${end.subtract(const Duration(days: 1)).month}/${end.subtract(const Duration(days: 1)).day}';
      case CodexViewMode.monthly:
        return '${now.year}/${now.month}';
      case CodexViewMode.yearly:
        return '${now.year}';
    }
  }

  // Selection mode methods
  void enterSelectionMode(int? initialId) {
    _isSelectionMode = true;
    _selectedIds.clear();
    if (initialId != null) {
      _selectedIds.add(initialId);
    }
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  bool isSelected(int id) => _selectedIds.contains(id);

  void selectAll() {
    _selectedIds = _records.where((r) => r.id != null).map((r) => r.id!).toSet();
    notifyListeners();
  }

  void deselectAll() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Delete selected records
  Future<bool> deleteSelected() async {
    if (_selectedIds.isEmpty) return false;
    try {
      await _db.deleteRecordsByIds(_selectedIds.toList());
      _records.removeWhere((r) => _selectedIds.contains(r.id));
      _selectedIds.clear();
      _isSelectionMode = false;
      notifyListeners();
      // Reload to update stats
      loadData();
      return true;
    } catch (e) {
      debugPrint('Error deleting selected: $e');
      return false;
    }
  }

  /// Delete a single record and refresh
  Future<bool> deleteRecord(int id) async {
    try {
      await _db.deleteScanRecord(id);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
      // Reload to update stats
      loadData();
      return true;
    } catch (e) {
      debugPrint('Error deleting record: $e');
      return false;
    }
  }
}
