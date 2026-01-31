// lib/widgets/codex/weekly_codex_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_text.dart';
import '../../providers/codex_provider.dart';
import '../../screens/scan_detail_screen.dart';
import 'codex_filter_bar.dart';
import 'codex_grid_card.dart';

class WeeklyCodexView extends StatelessWidget {
  const WeeklyCodexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            // Week navigation header
            SliverToBoxAdapter(
              child: _buildWeekHeader(context, provider),
            ),

            // Filter bar
            const SliverToBoxAdapter(
              child: CodexFilterBar(),
            ),

            // Week days content
            if (provider.records.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              ..._buildWeekSlivers(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildWeekHeader(BuildContext context, CodexProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

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
          Text(
            provider.dateLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
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

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_view_week_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppText.codexEmpty,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekSlivers(BuildContext context, CodexProvider provider) {
    final recordsByDate = provider.recordsByDate;
    final weekDays = provider.weekDays;
    final colorScheme = Theme.of(context).colorScheme;

    final slivers = <Widget>[];

    for (final date in weekDays) {
      final dayRecords = recordsByDate[date] ?? [];
      final isToday = provider.isToday(date);

      // Day header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Weekday circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getWeekdayName(date.weekday),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (dayRecords.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppText.codexScansCount(dayRecords.length),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      // Day records grid or empty indicator
      if (dayRecords.isEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Text(
                  '-',
                  style: TextStyle(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final record = dayRecords[index];
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
                childCount: dayRecords.length,
              ),
            ),
          ),
        );
      }
    }

    // Bottom padding
    slivers.add(const SliverPadding(padding: EdgeInsets.only(bottom: 16)));

    return slivers;
  }

  String _getWeekdayName(int weekday) {
    const names = ['', '週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return names[weekday];
  }
}
