// lib/widgets/codex/monthly_codex_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_text.dart';
import '../../providers/codex_provider.dart';
import '../../screens/scan_detail_screen.dart';
import 'codex_filter_bar.dart';
import 'codex_grid_card.dart';

class MonthlyCodexView extends StatefulWidget {
  const MonthlyCodexView({super.key});

  @override
  State<MonthlyCodexView> createState() => _MonthlyCodexViewState();
}

class _MonthlyCodexViewState extends State<MonthlyCodexView> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            // Month navigation header
            SliverToBoxAdapter(
              child: _buildMonthHeader(context, provider),
            ),

            // Filter bar
            const SliverToBoxAdapter(
              child: CodexFilterBar(),
            ),

            // Weekday labels
            SliverToBoxAdapter(
              child: _buildWeekdayLabels(context),
            ),

            // Calendar grid (heatmap)
            SliverToBoxAdapter(
              child: _buildCalendarGrid(context, provider),
            ),

            // Heatmap legend
            SliverToBoxAdapter(
              child: _buildLegend(context),
            ),

            // Selected day records
            if (_selectedDay != null)
              ..._buildSelectedDayRecordsSliver(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildMonthHeader(BuildContext context, CodexProvider provider) {
    final date = provider.selectedDate;
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
            '${date.year}/${date.month}',
            style: TextStyle(
              fontSize: 16,
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

  Widget _buildWeekdayLabels(BuildContext context) {
    final labels = ['一', '二', '三', '四', '五', '六', '日'];
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: labels
            .map((label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, CodexProvider provider) {
    final date = provider.selectedDate;
    final year = date.year;
    final month = date.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday;
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate grid size (up to 6 weeks)
    final totalCells = firstDayWeekday - 1 + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: rows * 7,
        itemBuilder: (context, index) {
          final dayOffset = index - (firstDayWeekday - 1);
          if (dayOffset < 0 || dayOffset >= daysInMonth) {
            return const SizedBox(); // Empty cell
          }

          final day = dayOffset + 1;
          final dateStr =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final count = provider.dailyCounts[dateStr] ?? 0;
          final cellDate = DateTime(year, month, day);
          final isToday = provider.isToday(cellDate);
          final isSelected = _selectedDay != null &&
              _selectedDay!.year == cellDate.year &&
              _selectedDay!.month == cellDate.month &&
              _selectedDay!.day == cellDate.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDay = null;
                } else {
                  _selectedDay = cellDate;
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: _getCellColor(colorScheme, count),
                borderRadius: BorderRadius.circular(4),
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : isToday
                        ? Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            width: 1)
                        : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        count > 0 || isToday ? FontWeight.w600 : FontWeight.normal,
                    color: _getTextColor(colorScheme, count, isToday),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCellColor(ColorScheme colorScheme, int count) {
    if (count == 0) return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final intensity = _getIntensity(count);
    return colorScheme.primary.withValues(alpha: intensity);
  }

  Color _getTextColor(ColorScheme colorScheme, int count, bool isToday) {
    if (count == 0) {
      return isToday ? colorScheme.primary : colorScheme.onSurface;
    }
    final intensity = _getIntensity(count);
    return intensity > 0.5 ? Colors.white : colorScheme.onSurface;
  }

  double _getIntensity(int count) {
    if (count == 0) return 0.0;
    if (count <= 2) return 0.2;
    if (count <= 5) return 0.4;
    if (count <= 10) return 0.6;
    return 0.8;
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppText.codexLess,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 4),
          ...List.generate(5, (i) {
            final intensity = [0.0, 0.2, 0.4, 0.6, 0.8][i];
            return Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: intensity == 0.0
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: intensity),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
          const SizedBox(width: 4),
          Text(
            AppText.codexMore,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSelectedDayRecordsSliver(
      BuildContext context, CodexProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filter records for selected day
    final dayRecords = provider.records.where((r) {
      return r.scannedAt.year == _selectedDay!.year &&
          r.scannedAt.month == _selectedDay!.month &&
          r.scannedAt.day == _selectedDay!.day;
    }).toList();

    return [
      // Selected day header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_selectedDay!.month}/${_selectedDay!.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppText.codexScansCount(dayRecords.length),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedDay = null),
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),

      // Records grid
      if (dayRecords.isEmpty)
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: Center(
              child: Text(
                AppText.codexEmpty,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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

      // Bottom padding
      const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
    ];
  }
}
