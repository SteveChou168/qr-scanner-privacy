// lib/widgets/charts/scan_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app_text.dart';

class ScanBarChart extends StatelessWidget {
  final Map<String, int> dailyCounts;
  final String title;

  const ScanBarChart({
    super.key,
    required this.dailyCounts,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (dailyCounts.isEmpty) {
      return Center(
        child: Text(
          AppText.codexEmpty,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final sortedEntries = dailyCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxValue = sortedEntries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final entry = sortedEntries[group.x.toInt()];
                    return BarTooltipItem(
                      '${_formatDate(entry.key)}\n${entry.value} ${AppText.scannedCount}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedEntries.length) {
                        return const SizedBox.shrink();
                      }
                      // Show every 2nd or 3rd label to avoid crowding
                      if (sortedEntries.length > 7 && index % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _formatShortDate(sortedEntries[index].key),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: sortedEntries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: colorScheme.primary,
                      width: sortedEntries.length > 14 ? 8 : 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    // dateStr is in format YYYY-MM-DD
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[1]}/${parts[2]}';
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatShortDate(String dateStr) {
    // dateStr is in format YYYY-MM-DD
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${int.parse(parts[1])}/${int.parse(parts[2])}';
      }
    } catch (_) {}
    return dateStr;
  }
}
