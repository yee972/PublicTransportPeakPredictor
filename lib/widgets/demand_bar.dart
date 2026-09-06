import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class DemandBar extends StatelessWidget {
  final double value;
  final Color colour;
  final String? trailingLabel;
  final Color? labelColour;
  final double height;

  const DemandBar({
    super.key,
    required this.value,
    required this.colour,
    this.trailingLabel,
    this.labelColour,
    this.height = 7,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: height,
              backgroundColor: const Color(0xFFEDF0F4),
              valueColor: AlwaysStoppedAnimation<Color>(colour),
            ),
          ),
        ),
        if (trailingLabel != null) ...[
          const SizedBox(width: 10),
          Text(
            trailingLabel!,
            style: AppTheme.mono(
                size: 11,
                color: labelColour ?? colour,
                weight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

class BarChart extends StatelessWidget {
  final List<BarChartEntry> entries;
  final double height;
  final List<String> axisLabels;

  const BarChart({
    super.key,
    required this.entries,
    this.height = 130,
    this.axisLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data to chart', style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final peak = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final safePeak = peak <= 0 ? 1.0 : peak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((entry) {
              final fraction = entry.value <= 0
                  ? 0.0
                  : (entry.value / safePeak).clamp(0.05, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.2),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: fraction <= 0 ? 0 : height * fraction,
                      decoration: BoxDecoration(
                        color: entry.outlined
                            ? entry.colour.withValues(alpha: 0.12)
                            : entry.colour,
                        border: entry.outlined
                            ? Border.all(color: entry.colour, width: 1.2)
                            : null,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (axisLabels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: axisLabels
                .map((label) => Text(label, style: AppTheme.mono(
                      size: 10,
                      color: AppTheme.textSecondary,
                    )))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class BarChartEntry {
  final double value;
  final Color colour;
  final bool outlined;

  const BarChartEntry({
    required this.value,
    required this.colour,
    this.outlined = false,
  });
}

class ChartLegend extends StatelessWidget {
  final List<ChartLegendItem> items;

  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.outlined ? Colors.transparent : item.colour,
                border: item.outlined ? Border.all(color: item.colour, width: 1.4) : null,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: AppTheme.mono(size: 10.5, color: AppTheme.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ChartLegendItem {
  final String label;
  final Color colour;
  final bool outlined;

  const ChartLegendItem({
    required this.label,
    required this.colour,
    this.outlined = false,
  });
}
