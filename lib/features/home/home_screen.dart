import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../algorithms/outlook_synthesis.dart';
import '../../core/app_theme.dart';
import '../../models/demand_band.dart';
import '../../models/demand_forecast.dart';
import '../../models/rail_line.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../forecast/forecast_provider.dart';
import 'service_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();

    if (provider.state == LoadState.loading || provider.state == LoadState.idle) {
      return const LoadingView(message: 'Loading today\'s outlook');
    }
    if (provider.state == LoadState.failed) {
      return ErrorView(
        message: provider.errorMessage ?? 'Could not load forecasts.',
        onRetry: () => provider.load(forceRefresh: true),
      );
    }

    final today = provider.referenceDate;
    final outlook = OutlookSynthesis.build(
      lines: provider.lines,
      forecast: provider.forecastFor,
      history: (lineId, days) =>
          provider.modelFor(lineId)?.recentActuals(days) ?? const [],
      today: today,
    );

    return RefreshIndicator(
      onRefresh: () => provider.load(forceRefresh: true),
      child: Column(
        children: [
          if (provider.usingCachedData) OfflineNotice(syncedAt: provider.syncedAt),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                _OutlookHeader(outlook: outlook, referenceDate: today),
                const SizedBox(height: 14),
                _StatusCard(outlook: outlook),
                const SizedBox(height: 22),
                Text(
                  '30-Day Daily Ridership Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _TrendCard(provider: provider, outlook: outlook),
                const SizedBox(height: 22),
                Text('Line Activity', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Bars show predicted demand as a share of the highest recorded '
                  'daily ridership for that line.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ...outlook.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LineActivityCard(
                      line: provider.network.line(line.lineId),
                      outlook: line,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlookHeader extends StatelessWidget {
  final NetworkOutlook outlook;
  final DateTime referenceDate;

  const _OutlookHeader({required this.outlook, required this.referenceDate});

  @override
  Widget build(BuildContext context) {
    final stamp = '${outlook.generatedAt.hour.toString().padLeft(2, '0')}:'
        '${outlook.generatedAt.minute.toString().padLeft(2, '0')} MYT';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TODAY'S OUTLOOK",
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Text('System Status',
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('UPDATED', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(stamp, style: AppTheme.mono(size: 13, weight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final NetworkOutlook outlook;

  const _StatusCard({required this.outlook});

  @override
  Widget build(BuildContext context) {
    final colour = DemandPalette.of(outlook.band);

    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: colour, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              outlook.headline,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const StatusPill(
                            label: 'PREDICTED',
                            colour: AppTheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Klang Valley Integrated Transit System',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              outlook.detail,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final ForecastProvider provider;
  final NetworkOutlook outlook;

  const _TrendCard({required this.provider, required this.outlook});

  @override
  Widget build(BuildContext context) {
    final scored = outlook.lines
        .where((line) => line.today.hasEnoughHistory)
        .toList();
    if (scored.isEmpty) {
      return const SectionCard(
        child: EmptyView(message: 'No ridership history available yet'),
      );
    }

    final busiest = scored.first;
    final line = provider.network.line(busiest.lineId);
    final actuals = busiest.recentTrend.length > 20
        ? busiest.recentTrend.sublist(busiest.recentTrend.length - 20)
        : busiest.recentTrend;
    final predictions = provider.sevenDayFor(busiest.lineId);

    final entries = <BarChartEntry>[
      ...actuals.map((point) => BarChartEntry(
            value: point.riders.toDouble(),
            colour: DemandPalette.of(
              DemandBands.fromRelative(
                busiest.today.baselineRiders <= 0
                    ? 1
                    : point.riders / busiest.today.baselineRiders,
              ),
            ),
          )),
      ...predictions.map((forecast) => BarChartEntry(
            value: forecast.predictedRiders.toDouble(),
            colour: AppTheme.primary,
            outlined: true,
          )),
    ];

    return SectionCard(
      trailing: line == null
          ? null
          : StatusPill(label: line.code, colour: line.displayColour),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ChartLegend(items: [
                ChartLegendItem(label: 'ACTUAL', colour: AppTheme.primary),
                ChartLegendItem(
                  label: 'EXPECTED',
                  colour: AppTheme.primary,
                  outlined: true,
                ),
              ]),
              if (line != null)
                Text(line.shortName,
                    style: AppTheme.mono(size: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          BarChart(
            entries: entries,
            axisLabels: const ['20 days ago', 'today', '+7 days'],
          ),
        ],
      ),
    );
  }
}

class _LineActivityCard extends StatelessWidget {
  final RailLine? line;
  final LineOutlook outlook;

  const _LineActivityCard({required this.line, required this.outlook});

  @override
  Widget build(BuildContext context) {
    final railLine = line;
    if (railLine == null) return const SizedBox.shrink();

    final forecast = outlook.today;
    final colour = DemandPalette.of(forecast.band);
    final percent = (forecast.percentOfMax * 100).round();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(lineId: railLine.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  LineDot(colour: railLine.displayColour, code: railLine.code),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(railLine.shortName,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              if (!forecast.hasEnoughHistory)
                Text(
                  'Not enough history yet to forecast this line',
                  style: AppTheme.mono(size: 11.5, color: DemandPalette.unknown),
                )
              else ...[
                DemandBar(
                  value: forecast.percentOfMax,
                  colour: colour,
                  trailingLabel: '$percent%',
                ),
                const SizedBox(height: 9),
                Text(
                  'Predicted: ${DemandPalette.label(forecast.band).toLowerCase()}',
                  style: AppTheme.mono(size: 11.5, color: colour),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
