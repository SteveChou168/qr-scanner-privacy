// lib/widgets/codex/daily_codex_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_text.dart';
import '../../providers/codex_provider.dart';
import '../../screens/scan_detail_screen.dart';
import 'codex_filter_bar.dart';
import 'codex_grid_card.dart';

class DailyCodexView extends StatelessWidget {
  const DailyCodexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            // Date navigation header
            SliverToBoxAdapter(
              child: _buildDateHeader(context, provider),
            ),

            // Filter bar
            const SliverToBoxAdapter(
              child: CodexFilterBar(),
            ),

            // Grid content
            if (provider.records.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, provider),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = provider.records[index];
                      final isSelected = provider.isSelected(record.id!);
                      return CodexGridCard(
                        record: record,
                        isSelectionMode: provider.isSelectionMode,
                        isSelected: isSelected,
                        onTap: () {
                          if (provider.isSelectionMode) {
                            provider.toggleSelection(record.id!);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScanDetailScreen(record: record),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          if (!provider.isSelectionMode) {
                            provider.enterSelectionMode(record.id!);
                          }
                        },
                      );
                    },
                    childCount: provider.records.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, CodexProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = provider.isToday(provider.selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => provider.navigateDate(-1),
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),
          GestureDetector(
            onTap: () => _showDatePicker(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isToday) ...[
                    Icon(
                      Icons.today,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _formatDate(provider.selectedDate, isToday),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => provider.navigateDate(1),
            icon: const Icon(Icons.chevron_right),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, bool isToday) {
    if (isToday) {
      return AppText.codexToday;
    }
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _showDatePicker(
      BuildContext context, CodexProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      provider.selectDate(picked);
    }
  }

  Widget _buildEmptyState(BuildContext context, CodexProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = provider.isToday(provider.selectedDate);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_mosaic_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isToday ? AppText.codexEmptyToday : AppText.codexEmpty,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

}
