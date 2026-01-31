// lib/widgets/charts/type_pie_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app_text.dart';
import '../../data/models/scan_record.dart';

class TypePieChart extends StatefulWidget {
  final Map<SemanticType, int> typeCounts;

  const TypePieChart({super.key, required this.typeCounts});

  @override
  State<TypePieChart> createState() => _TypePieChartState();
}

class _TypePieChartState extends State<TypePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.typeCounts.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return Center(
        child: Text(
          AppText.codexEmpty,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          AppText.typeDistribution,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildSections(total),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildLegend(),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(int total) {
    final entries = widget.typeCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;
      final percentage = (item.value / total * 100);

      return PieChartSectionData(
        value: item.value.toDouble(),
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        color: _getColorForType(item.key),
        radius: isTouched ? 80 : 70,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final entries = widget.typeCounts.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getColorForType(e.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getLabelForType(e.key),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 4),
              Text(
                '(${e.value})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForType(SemanticType type) {
    return switch (type) {
      SemanticType.url => Colors.blue,
      SemanticType.email => Colors.orange,
      SemanticType.wifi => Colors.purple,
      SemanticType.isbn => Colors.brown,
      SemanticType.vcard => Colors.teal,
      SemanticType.sms => Colors.pink,
      SemanticType.geo => Colors.indigo,
      SemanticType.text => Colors.grey,
    };
  }

  String _getLabelForType(SemanticType type) {
    return switch (type) {
      SemanticType.url => AppText.typeUrl,
      SemanticType.email => AppText.typeEmail,
      SemanticType.wifi => AppText.typeWifi,
      SemanticType.isbn => AppText.typeIsbn,
      SemanticType.vcard => AppText.typeVcard,
      SemanticType.sms => AppText.typeSms,
      SemanticType.geo => AppText.typeGeo,
      SemanticType.text => AppText.typeText,
    };
  }
}
