// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_text.dart';
import '../data/models/scan_record.dart';
import '../providers/history_provider.dart';
import '../services/export_service.dart';
import '../utils/action_handler.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/history/scan_history_card.dart';
import 'scan_detail_screen.dart';
import 'package:share_plus/share_plus.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: provider.isSelectionMode
              ? _buildSelectionAppBar(provider)
              : _buildAppBar(),
          body: _buildBody(),
          bottomNavigationBar: provider.isSelectionMode
              ? _buildSelectionBottomBar(provider)
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(HistoryProvider provider) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => provider.exitSelectionMode(),
      ),
      title: Text(AppText.selectedCount(provider.selectedCount)),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(provider.isAllSelected
              ? Icons.deselect
              : Icons.select_all),
          tooltip: provider.isAllSelected
              ? AppText.deselectAll
              : AppText.selectAll,
          onPressed: () {
            if (provider.isAllSelected) {
              provider.deselectAll();
            } else {
              provider.selectAll();
            }
          },
        ),
      ],
    );
  }

  Widget _buildSelectionBottomBar(HistoryProvider provider) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomAction(
              icon: Icons.share,
              label: AppText.exportShare,
              onTap: provider.selectedCount > 0
                  ? () {
                      final records = provider.selectedRecords.toList();
                      provider.exitSelectionMode();
                      _shareRecords(records);
                    }
                  : null,
            ),
            _buildBottomAction(
              icon: Icons.file_download,
              label: AppText.exportSelected,
              onTap: provider.selectedCount > 0
                  ? () {
                      final records = provider.selectedRecords.toList();
                      provider.exitSelectionMode();
                      _showExportDialog('csv', records);
                    }
                  : null,
            ),
            _buildBottomAction(
              icon: Icons.delete,
              label: AppText.deleteSelected,
              color: Colors.red,
              onTap: provider.selectedCount > 0
                  ? () => _confirmDeleteSelected(provider)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled
                  ? effectiveColor
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled
                    ? effectiveColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSelected(HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppText.deleteConfirmTitle),
        content: Text(AppText.selectedCount(provider.selectedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppText.dialogCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteSelected();
              HapticFeedback.lightImpact();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppText.actionDelete),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            context.read<HistoryProvider>().clearFilters();
          },
        ),
        centerTitle: false,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppText.historySearchHint,
            border: InputBorder.none,
          ),
          onChanged: (value) {
            context.read<HistoryProvider>().search(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<HistoryProvider>().search(null);
            },
          ),
        ],
      );
    }

    return AppBar(
      title: Text(AppText.historyTitle),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) {
            final provider = context.read<HistoryProvider>();
            if (value == 'favorites') {
              // Toggle: 如果已經是最愛過濾，就取消
              provider.filterByFavorites(!provider.showFavoritesOnly);
            } else {
              final type = SemanticType.values.firstWhere((t) => t.name == value);
              // Toggle: 如果已經選中該類型，就取消
              if (provider.filterType == type) {
                provider.filterByType(null);
              } else {
                provider.filterByType(type);
              }
            }
          },
          itemBuilder: (context) {
            final provider = context.read<HistoryProvider>();
            return [
              PopupMenuItem(
                value: 'favorites',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20,
                      color: provider.showFavoritesOnly ? Colors.amber : Colors.grey),
                    const SizedBox(width: 8),
                    Text(AppText.filterFavoritesOnly),
                    if (provider.showFavoritesOnly) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 18),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: SemanticType.url.name,
                child: _buildFilterItem(AppText.typeUrl, provider.filterType == SemanticType.url),
              ),
              PopupMenuItem(
                value: SemanticType.email.name,
                child: _buildFilterItem(AppText.typeEmail, provider.filterType == SemanticType.email),
              ),
              PopupMenuItem(
                value: SemanticType.wifi.name,
                child: _buildFilterItem(AppText.typeWifi, provider.filterType == SemanticType.wifi),
              ),
              PopupMenuItem(
                value: SemanticType.isbn.name,
                child: _buildFilterItem(AppText.typeIsbn, provider.filterType == SemanticType.isbn),
              ),
              PopupMenuItem(
                value: SemanticType.vcard.name,
                child: _buildFilterItem(AppText.typeVcard, provider.filterType == SemanticType.vcard),
              ),
              PopupMenuItem(
                value: SemanticType.text.name,
                child: _buildFilterItem(AppText.typeText, provider.filterType == SemanticType.text),
              ),
            ];
          },
        ),
        PopupMenuButton<String>(
          onSelected: (action) => _handleMenuAction(action),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export_csv',
              child: Row(
                children: [
                  const Icon(Icons.file_download, size: 20),
                  const SizedBox(width: 12),
                  Text(AppText.exportCsv),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export_json',
              child: Row(
                children: [
                  const Icon(Icons.code, size: 20),
                  const SizedBox(width: 12),
                  Text(AppText.exportJson),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(AppText.historyClearAll, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<HistoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadRecords(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.records.length,
            itemBuilder: (context, index) {
              final record = provider.records[index];
              final isSelected = provider.isSelected(record.id ?? -1);

              return ScanHistoryCard(
                record: record,
                isSelectionMode: provider.isSelectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (provider.isSelectionMode) {
                    provider.toggleSelection(record.id!);
                  } else {
                    _showRecordDetail(record);
                  }
                },
                onLongPress: () {
                  if (!provider.isSelectionMode) {
                    HapticFeedback.lightImpact();
                    provider.enterSelectionMode();
                    provider.toggleSelection(record.id!);
                  }
                },
                onFavoriteToggle: () => provider.toggleFavorite(record.id!),
                onActionTap: () => _handleAction(record),
                onShare: () => _shareRecord(record),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterItem(String label, bool isSelected) {
    return Row(
      children: [
        Text(label),
        if (isSelected) ...[
          const Spacer(),
          const Icon(Icons.check, size: 18),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final provider = context.read<HistoryProvider>();
    final hasFilter =
        provider.searchQuery != null || provider.filterType != null || provider.showFavoritesOnly;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? AppText.historyNoResults : AppText.historyEmpty,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => provider.clearFilters(),
              child: Text(AppText.historyClearFilter),
            ),
          ],
        ],
      ),
    );
  }

  void _showRecordDetail(ScanRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanDetailScreen(record: record),
      ),
    );
  }

  Future<void> _handleAction(ScanRecord record) async {
    await ActionHandler.handle(context, record);
  }

  Future<void> _shareRecord(ScanRecord record) async {
    final note = await _showShareNoteDialog();
    if (note == null) return; // user cancelled
    final text = note.isEmpty ? record.rawText : '${record.rawText}\n\n$note';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _shareRecords(List<ScanRecord> records) async {
    final note = await _showShareNoteDialog();
    if (note == null) return; // user cancelled
    final content = records.map((r) => r.rawText).join('\n');
    final text = note.isEmpty ? content : '$content\n\n$note';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<String?> _showShareNoteDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppText.scanShare),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppText.shareNoteHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(AppText.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(AppText.scanShare),
            ),
          ],
        );
      },
    );
  }

  void _handleMenuAction(String action) async {
    final provider = context.read<HistoryProvider>();

    switch (action) {
      case 'export_csv':
        if (provider.records.isEmpty) {
          SnackbarHelper.show(context,AppText.historyEmpty);
          return;
        }
        _showExportDialog('csv', provider.records);
        break;

      case 'export_json':
        if (provider.records.isEmpty) {
          SnackbarHelper.show(context,AppText.historyEmpty);
          return;
        }
        _showExportDialog('json', provider.records);
        break;

      case 'clear_all':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppText.clearAllTitle),
            content: Text(AppText.clearAllMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppText.dialogCancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<HistoryProvider>().clearAll();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppText.dialogConfirm),
              ),
            ],
          ),
        );
        break;
    }
  }


  void _showExportDialog(String format, List<ScanRecord> records) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppText.exportChooseAction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: Text(AppText.exportSaveToDevice),
              onTap: () async {
                Navigator.pop(ctx);
                await _performExport(format, records, ExportAction.saveToDevice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppText.exportShare),
              onTap: () async {
                Navigator.pop(ctx);
                await _performExport(format, records, ExportAction.share);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _performExport(
    String format,
    List<ScanRecord> records,
    ExportAction action,
  ) async {
    final result = format == 'csv'
        ? await ExportService.exportToCsv(records, action)
        : await ExportService.exportToJson(records, action);

    if (result.success) {
      if (action == ExportAction.saveToDevice && result.filePath != null) {
        // Show only filename, not full path
        final fileName = result.filePath!.split('/').last;
        SnackbarHelper.show(context,'${AppText.exportSavedTo} Download/$fileName');
      } else {
        SnackbarHelper.show(context,AppText.exportSuccess);
      }
    } else {
      SnackbarHelper.show(context,AppText.exportFailed);
    }
  }
}
