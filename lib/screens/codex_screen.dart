// lib/screens/codex_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_text.dart';
import '../data/models/scan_record.dart';
import '../providers/codex_provider.dart';
import '../widgets/codex/codex_grid_card.dart';
import '../widgets/codex/daily_codex_view.dart';
import '../widgets/codex/weekly_codex_view.dart';
import '../widgets/codex/monthly_codex_view.dart';
import '../widgets/codex/yearly_codex_view.dart';
import '../widgets/charts/type_pie_chart.dart';
import '../widgets/charts/scan_bar_chart.dart';
import 'scan_detail_screen.dart';

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CodexProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final mode = CodexViewMode.values[_tabController.index];
    context.read<CodexProvider>().setViewMode(mode);
  }

  void _goToToday() {
    context.read<CodexProvider>().goToToday();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        // Selection mode AppBar
        if (provider.isSelectionMode) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => provider.exitSelectionMode(),
              ),
              title: Text(AppText.selectedCount(provider.selectedCount)),
              centerTitle: false,
              actions: [
                // Select all button
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () => provider.selectAll(),
                  tooltip: AppText.selectAll,
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: provider.hasSelection
                      ? () => _confirmDeleteSelected(context, provider)
                      : null,
                  tooltip: AppText.actionDelete,
                ),
              ],
            ),
            body: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                DailyCodexView(),
                WeeklyCodexView(),
                MonthlyCodexView(),
                YearlyCodexView(),
              ],
            ),
          );
        }

        // Normal AppBar
        return Scaffold(
          appBar: AppBar(
            title: Text(AppText.codexTitle),
            centerTitle: false,
            actions: [
              // Today button
              TextButton.icon(
                onPressed: _goToToday,
                icon: Icon(Icons.today, size: 18, color: colorScheme.primary),
                label: Text(
                  AppText.codexGoToToday,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearch(context),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: () => _showChartsSheet(context),
                tooltip: AppText.chartsTitle,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(text: AppText.codexDaily),
                Tab(text: AppText.codexWeekly),
                Tab(text: AppText.codexMonthly),
                Tab(text: AppText.codexYearly),
              ],
            ),
          ),
          body: _buildBody(provider),
        );
      },
    );
  }

  Widget _buildBody(CodexProvider provider) {
    // Sync tab with provider state
    if (_tabController.index != provider.viewMode.index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(provider.viewMode.index);
        }
      });
    }

    if (provider.isLoading && provider.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        DailyCodexView(),
        WeeklyCodexView(),
        MonthlyCodexView(),
        YearlyCodexView(),
      ],
    );
  }

  void _confirmDeleteSelected(BuildContext context, CodexProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppText.deleteConfirmTitle),
        content: Text(AppText.deleteSelectedMessage(provider.selectedCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppText.dialogCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await provider.deleteSelected();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppText.actionDelete),
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _CodexSearchDelegate(),
    );
  }

  void _showChartsSheet(BuildContext context) {
    final stats = context.read<CodexProvider>().stats;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppText.chartsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(
                        height: 250,
                        child: TypePieChart(typeCounts: stats.typeCounts),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: ScanBarChart(
                          dailyCounts: stats.dailyCounts,
                          title: AppText.scanTrend,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CodexSearchDelegate extends SearchDelegate<ScanRecord?> {
  @override
  String get searchFieldLabel => AppText.codexSearchHint;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    context.read<CodexProvider>().search(query);
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          AppText.codexSearchHint,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    context.read<CodexProvider>().search(query);
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.records.isEmpty) {
          return Center(child: Text(AppText.historyNoResults));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: provider.records.length,
          itemBuilder: (context, index) {
            final record = provider.records[index];
            return CodexGridCard(
              record: record,
              onTap: () {
                close(context, record);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanDetailScreen(record: record),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
