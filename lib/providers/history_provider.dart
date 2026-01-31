// lib/providers/history_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/database/database_helper.dart';
import '../data/models/scan_record.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db;

  List<ScanRecord> _records = [];
  bool _isLoading = false;
  String? _searchQuery;
  SemanticType? _filterType;
  bool _showFavoritesOnly = false;

  // Batch selection mode
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  HistoryProvider(this._db);

  List<ScanRecord> get records => _records;
  bool get isLoading => _isLoading;
  bool get isEmpty => _records.isEmpty;
  String? get searchQuery => _searchQuery;
  SemanticType? get filterType => _filterType;
  bool get showFavoritesOnly => _showFavoritesOnly;

  // Selection mode getters
  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedIds => _selectedIds;
  int get selectedCount => _selectedIds.length;
  bool get isAllSelected =>
      _records.isNotEmpty && _selectedIds.length == _records.length;

  /// Get selected records
  List<ScanRecord> get selectedRecords =>
      _records.where((r) => _selectedIds.contains(r.id)).toList();

  /// Load all records
  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        _records = await _db.searchScanRecords(_searchQuery!);
      } else if (_showFavoritesOnly) {
        _records = await _db.getFavoriteScanRecords();
      } else if (_filterType != null) {
        _records = await _db.getScanRecordsByType(_filterType!);
      } else {
        _records = await _db.getScanRecords();
      }
    } catch (e) {
      debugPrint('Error loading records: $e');
      _records = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new record
  Future<ScanRecord?> addRecord(ScanRecord record) async {
    try {
      final id = await _db.insertScanRecord(record);
      final newRecord = record.copyWith(id: id);
      _records.insert(0, newRecord);
      notifyListeners();
      return newRecord;
    } catch (e) {
      debugPrint('Error adding record: $e');
      return null;
    }
  }

  /// Check if rawText is duplicate of recent N records
  Future<bool> isDuplicateOfRecent(String rawText, {int limit = 10}) async {
    try {
      final recentTexts = await _db.getRecentRawTexts(limit: limit);
      return recentTexts.contains(rawText);
    } catch (e) {
      debugPrint('Error checking duplicate: $e');
      return false;
    }
  }

  /// Add record if not duplicate of recent records
  /// Returns: the new record if saved, null if duplicate or error
  Future<ScanRecord?> addRecordIfNotDuplicate(ScanRecord record, {int limit = 10}) async {
    final isDuplicate = await isDuplicateOfRecent(record.rawText, limit: limit);
    if (isDuplicate) {
      debugPrint('Skipping duplicate: ${record.rawText}');
      return null;
    }
    return await addRecord(record);
  }

  /// Update a record
  Future<bool> updateRecord(ScanRecord record) async {
    try {
      await _db.updateScanRecord(record);
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating record: $e');
      return false;
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(int id) async {
    try {
      await _db.toggleFavorite(id);
      final index = _records.indexWhere((r) => r.id == id);
      if (index != -1) {
        _records[index] = _records[index].copyWith(
          isFavorite: !_records[index].isFavorite,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  /// Delete a record and cleanup orphaned image
  Future<bool> deleteRecord(int id) async {
    try {
      // Get the image path before deleting
      final record = _records.firstWhere((r) => r.id == id, orElse: () => throw Exception('Record not found'));
      final imagePath = record.imagePath;

      await _db.deleteScanRecord(id);
      _records.removeWhere((r) => r.id == id);

      // Delete image if no other records use it
      if (imagePath != null && imagePath.isNotEmpty) {
        await _deleteImageIfOrphaned(imagePath);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting record: $e');
      return false;
    }
  }

  /// Delete image file if no other records reference it
  Future<void> _deleteImageIfOrphaned(String imagePath) async {
    try {
      final count = await _db.countRecordsByImagePath(imagePath);
      if (count == 0) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted orphaned image: $imagePath');
        }
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Clear all records and delete all images
  Future<bool> clearAll() async {
    try {
      // Get all image paths before deleting records
      final imagePaths = await _db.getAllImagePaths();

      await _db.deleteAllScanRecords();
      _records.clear();

      // Delete all image files
      for (final path in imagePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting image $path: $e');
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing records: $e');
      return false;
    }
  }

  /// Search records
  void search(String? query) {
    _searchQuery = query;
    _filterType = null;
    loadRecords();
  }

  /// Filter by type
  void filterByType(SemanticType? type) {
    _filterType = type;
    _searchQuery = null;
    _showFavoritesOnly = false;
    loadRecords();
  }

  /// Filter by favorites only
  void filterByFavorites(bool favoritesOnly) {
    _showFavoritesOnly = favoritesOnly;
    _filterType = null;
    _searchQuery = null;
    loadRecords();
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = null;
    _filterType = null;
    _showFavoritesOnly = false;
    loadRecords();
  }

  /// Trim history to limit
  Future<void> trimToLimit(int limit) async {
    try {
      await _db.trimHistory(limit);
      await loadRecords();
    } catch (e) {
      debugPrint('Error trimming history: $e');
    }
  }

  // ============ Batch Selection Mode ============

  /// Enter selection mode
  void enterSelectionMode() {
    _isSelectionMode = true;
    _selectedIds.clear();
    notifyListeners();
  }

  /// Exit selection mode
  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  /// Toggle selection for a record
  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// Check if a record is selected
  bool isSelected(int id) => _selectedIds.contains(id);

  /// Select all visible records
  void selectAll() {
    for (final record in _records) {
      if (record.id != null) {
        _selectedIds.add(record.id!);
      }
    }
    notifyListeners();
  }

  /// Deselect all
  void deselectAll() {
    _selectedIds.clear();
    notifyListeners();
  }

  /// Delete selected records and cleanup orphaned images
  Future<bool> deleteSelected() async {
    if (_selectedIds.isEmpty) return false;
    try {
      // Get image paths of selected records before deleting
      final imagePaths = await _db.getImagePathsByIds(_selectedIds.toList());

      await _db.deleteRecordsByIds(_selectedIds.toList());
      _records.removeWhere((r) => _selectedIds.contains(r.id));

      // Delete orphaned images
      for (final path in imagePaths) {
        await _deleteImageIfOrphaned(path);
      }

      _selectedIds.clear();
      _isSelectionMode = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting selected: $e');
      return false;
    }
  }

  /// Favorite selected records
  Future<bool> favoriteSelected() async {
    if (_selectedIds.isEmpty) return false;
    try {
      await _db.setFavoriteForIds(_selectedIds.toList(), true);
      for (final id in _selectedIds) {
        final index = _records.indexWhere((r) => r.id == id);
        if (index != -1) {
          _records[index] = _records[index].copyWith(isFavorite: true);
        }
      }
      _selectedIds.clear();
      _isSelectionMode = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error favoriting selected: $e');
      return false;
    }
  }
}
