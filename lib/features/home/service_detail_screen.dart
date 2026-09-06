import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/demand_forecast.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../forecast/forecast_provider.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String lineId;

  const ServiceDetailScreen({super.key, required this.lineId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();
    final line = provider.network.line(lineId);
    final model = provider.modelFor(lineId);

    if (line == null || model == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service detail')),
        body: const EmptyView(message: 'This line is not available'),
      );
    }

    final today = provider.today;
    final forecast = provider.forecastFor(lineId, today);
    final metrics = provider.validationFor(lineId);
    final history = model.recentActuals(30);
    final stations = provider.network.stationsOnLine(lineId);

    return Scaffold(
      appBar: AppBar(title: Text(line.shortName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Row(
            children: [
              LineDot(colour: line.displayColour, code: line.code),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.name, style: Theme.of(context).textTheme.titleLarge),
                    Text('Operated by ${line.operator}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Today',
            icon: Icons.today_outlined,
            trailing: BandBadge(band: forecast.band),
            child: forecast.hasEnoughHistory
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.thousands(forecast.predictedRiders)} riders predicted',
                  style: AppTheme.mono(size: 18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                _buildComparisonIndicator(forecast),
                const SizedBox(height: 10),
                DemandBar(
                  value: forecast.percentOfMax,
                  colour: DemandPalette.of(forecast.band),
                  trailingLabel:
                  '${(forecast.percentOfMax * 100).round()}% max',
                ),
                const SizedBox(height: 10),
                Text(
                  DemandPalette.label(forecast.band),
                  style: AppTheme.mono(
                    size: 12,
                    color: DemandPalette.of(forecast.band),
                  ),
                ),
              ],
            )
                : const Text('Not enough ridership history to forecast this line yet.'),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Last 30 days',
            icon: Icons.show_chart,
            child: BarChart(
              entries: history
                  .map((point) => BarChartEntry(
                value: point.riders.toDouble(),
                colour: line.displayColour,
              ))
                  .toList(),
              axisLabels: const ['30 days ago', 'latest'],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Model accuracy for this line',
            icon: Icons.verified_outlined,
            child: metrics == null || !metrics.isReliable
                ? const Text('Not enough hold-out data to score this line yet.')
                : Column(
              children: [
                _MetricRow(
                  label: 'Mean absolute error',
                  value: '${Formatters.thousands(metrics.meanAbsoluteError.round())} riders/day',
                ),
                _MetricRow(
                  label: 'Mean absolute percentage error',
                  value: '${metrics.meanAbsolutePercentageError.toStringAsFixed(1)}%',
                ),
                _MetricRow(
                  label: 'Busy/quiet correct',
                  value: '${metrics.classificationAccuracy.toStringAsFixed(1)}%',
                ),
                _MetricRow(
                  label: 'Hold-out sample',
                  value: '${metrics.sampleSize} days',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (line.sharesSeries)
            const InfoNote(
              message: 'data.gov.my reports the Ampang and Sri Petaling lines as one '
                  'combined ridership figure, so both lines share this forecast.',
            ),
          if (line.sharesSeries) const SizedBox(height: 14),
          SectionCard(
            title: '${stations.length} stations',
            icon: Icons.location_on_outlined,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stations
                  .map((station) => Chip(
                label: Text(
                  station.name,
                  style: AppTheme.mono(size: 11),
                ),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: AppTheme.outline),
                backgroundColor: Colors.white,
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonIndicator(DemandForecast forecast) {
    final diffPercent = ((forecast.relativeToTypical - 1) * 100).round();

    if (diffPercent.abs() <= 2) {
      return Text(
        '~ In line with a typical day',
        style: AppTheme.mono(size: 12, color: AppTheme.textSecondary),
      );
    }

    final isAbove = diffPercent > 0;
    final color = isAbove ? DemandPalette.busy : DemandPalette.quiet;

    return Row(
      children: [
        Icon(
          isAbove ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${isAbove ? '+' : ''}$diffPercent% ${isAbove ? 'above' : 'below'} a typical day',
          style: AppTheme.mono(
            size: 12,
            weight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: AppTheme.mono(size: 12, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}