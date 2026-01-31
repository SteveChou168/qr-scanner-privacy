// lib/widgets/codex/yearly_codex_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_text.dart';
import '../../data/models/scan_record.dart';
import '../../providers/codex_provider.dart';
import 'codex_filter_bar.dart';

class YearlyCodexView extends StatelessWidget {
  const YearlyCodexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CodexProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            // Year navigation header
            SliverToBoxAdapter(
              child: _buildYearHeader(context, provider),
            ),

            // Filter bar
            const SliverToBoxAdapter(
              child: CodexFilterBar(),
            ),

            // Monthly grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _buildMonthlyGridSliver(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearHeader(BuildContext context, CodexProvider provider) {
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
            '${provider.selectedDate.year}',
            style: TextStyle(
              fontSize: 18,
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

  Widget _buildMonthlyGridSliver(BuildContext context, CodexProvider provider) {
    // Group records by month
    final monthCounts = <int, int>{};
    final monthTypeCounts = <int, Map<SemanticType, int>>{};

    for (final record in provider.records) {
      final month = record.scannedAt.month;
      monthCounts[month] = (monthCounts[month] ?? 0) + 1;
      monthTypeCounts.putIfAbsent(month, () => {});
      monthTypeCounts[month]![record.semanticType] =
          (monthTypeCounts[month]![record.semanticType] ?? 0) + 1;
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final month = index + 1;
          final count = monthCounts[month] ?? 0;
          final types = monthTypeCounts[month] ?? {};

          // Find dominant type
          SemanticType? dominantType;
          int maxTypeCount = 0;
          for (final entry in types.entries) {
            if (entry.value > maxTypeCount) {
              maxTypeCount = entry.value;
              dominantType = entry.key;
            }
          }

          return _MonthCard(
            month: month,
            count: count,
            dominantType: dominantType,
            onTap: () {
              // Switch to monthly view for this month
              provider.selectDate(
                  DateTime(provider.selectedDate.year, month, 1));
              provider.setViewMode(CodexViewMode.monthly);
            },
          );
        },
        childCount: 12,
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final int month;
  final int count;
  final SemanticType? dominantType;
  final VoidCallback? onTap;

  const _MonthCard({
    required this.month,
    required this.count,
    this.dominantType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isCurrentMonth =
        now.month == month && now.year == DateTime.now().year;

    return Card(
      elevation: count > 0 ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentMonth
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppText.codexMonthLabel(month),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentMonth
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              if (count > 0) ...[
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                if (dominantType != null)
                  Text(
                    dominantType!.icon,
                    style: const TextStyle(fontSize: 12),
                  ),
              ] else
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
