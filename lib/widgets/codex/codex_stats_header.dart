// lib/widgets/codex/codex_stats_header.dart

import 'package:flutter/material.dart';
import '../../app_text.dart';
import '../../data/models/codex_stats.dart';
import '../charts/type_pie_chart.dart';
import '../charts/scan_bar_chart.dart';

class CodexStatsHeader extends StatelessWidget {
  final CodexStats stats;

  const CodexStatsHeader({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Today count
          Expanded(
            child: _StatItem(
              label: AppText.codexToday,
              value: stats.todayCount.toString(),
              icon: Icons.today,
              color: colorScheme.primary,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 36,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),

          // Total count
          Expanded(
            child: _StatItem(
              label: AppText.codexTotal,
              value: stats.totalCount.toString(),
              icon: Icons.inventory_2_outlined,
              color: colorScheme.secondary,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 36,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),

          // Most scanned type
          Expanded(
            child: _StatItem(
              label: AppText.codexTopType,
              value: stats.mostScannedType?.label ?? '-',
              icon: Icons.star_outline,
              color: Colors.amber[700]!,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 36,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),

          // Charts button
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: () => _showChartsSheet(context),
              icon: Icon(
                Icons.pie_chart_outline,
                color: colorScheme.primary,
              ),
              tooltip: AppText.chartsTitle,
            ),
          ),
        ],
      ),
    );
  }

  void _showChartsSheet(BuildContext context) {
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
                // Handle bar
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
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppText.chartsTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                // Charts
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Pie chart - Type distribution
                      SizedBox(
                        height: 250,
                        child: TypePieChart(typeCounts: stats.typeCounts),
                      ),
                      const SizedBox(height: 24),
                      // Bar chart - Weekly trend
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
