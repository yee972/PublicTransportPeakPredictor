import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/demand_forecast.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import 'day_prediction_screen.dart';
import 'forecast_provider.dart';
import 'validation_screen.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  bool _isTomorrow(DateTime date) {
    final target = DateTime.now().add(const Duration(days: 1));
    return date.year == target.year &&
        date.month == target.month &&
        date.day == target.day;
  }

  String _selectedLineId = 'network';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();

    if (provider.state == LoadState.loading || provider.state == LoadState.idle) {
      return const LoadingView(message: 'Building forecasts');
    }
    if (provider.state == LoadState.failed) {
      return ErrorView(
        message: provider.errorMessage ?? 'Could not build forecasts.',
        onRetry: () => provider.load(forceRefresh: true),
      );
    }

    final isNetwork = _selectedLineId == 'network';
    final forecasts = isNetwork
        ? provider.networkSevenDay()
        : provider.sevenDayFor(_selectedLineId);
    final accuracy = isNetwork
        ? provider.networkAccuracy
        : provider.validationFor(_selectedLineId)?.classificationAccuracy ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const SectionHeading(
          label: '7-Day Forecast',
          caption: 'Predicted demand from historical daily ridership on data.gov.my.',
        ),
        const SizedBox(height: 12),
        InfoNote(
          message: 'Predictions for the next 7 days, modelled from ridership '
              'published on data.gov.my up to '
              '${Formatters.dayMonthYear(provider.latestDataDate)}.',
          icon: Icons.event_note_outlined,
        ),
        const SizedBox(height: 14),
        _LineSelector(
          value: _selectedLineId,
          provider: provider,
          onChanged: (value) => setState(() => _selectedLineId = value),
        ),
        const SizedBox(height: 14),
        _WeeklyTrendCard(forecasts: forecasts, accuracy: accuracy),
        const SizedBox(height: 22),
        Text('Daily Predictions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '% Max = predicted demand relative to the highest recorded day',
          style: AppTheme.mono(size: 11.5, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        ...forecasts.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DayCard(
              forecast: entry.value,
              isTomorrow: _isTomorrow(entry.value.date),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DayPredictionScreen(
                    lineId: _selectedLineId,
                    date: entry.value.date,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ValidationScreen()),
          ),
          icon: const Icon(Icons.fact_check_outlined, size: 18),
          label: const Text('View detailed validation metrics'),
        ),
      ],
    );
  }
}

class _LineSelector extends StatelessWidget {
  final String value;
  final ForecastProvider provider;
  final ValueChanged<String> onChanged;

  const _LineSelector({
    required this.value,
    required this.provider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Service',
        prefixIcon: Icon(Icons.train_outlined),
      ),
      items: [
        const DropdownMenuItem(value: 'network', child: Text('All lines')),
        ...provider.lines.map(
          (line) => DropdownMenuItem(value: line.id, child: Text(line.shortName)),
        ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  final List<DemandForecast> forecasts;
  final double accuracy;

  const _WeeklyTrendCard({required this.forecasts, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final scored = forecasts.where((f) => f.hasEnoughHistory).toList();
    if (scored.isEmpty) {
      return const SectionCard(
        title: 'Weekly Trend',
        child: EmptyView(message: 'Not enough history to forecast this service'),
      );
    }

    final peak = scored.reduce(
      (a, b) => a.relativeToTypical >= b.relativeToTypical ? a : b,
    );

    return SectionCard(
      title: 'Weekly Trend',
      trailing: BandBadge(band: peak.band),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            accuracy <= 0
                ? 'Hold-out validation not available for this service'
                : 'Busy/quiet prediction correct on '
                    '${accuracy.toStringAsFixed(0)}% of hold-out days',
            style: AppTheme.mono(size: 12),
          ),
          const SizedBox(height: 16),
          BarChart(
            entries: forecasts
                .map((forecast) => BarChartEntry(
                      value: forecast.hasEnoughHistory
                          ? forecast.relativeToTypical
                          : 0,
                      colour: DemandPalette.of(forecast.band),
                    ))
                .toList(),
            height: 92,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: forecasts
                .map((forecast) => Text(
                      Formatters.weekdayShort(forecast.date),
                      style: AppTheme.mono(
                        size: 10.5,
                        color: AppTheme.textSecondary,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DemandForecast forecast;
  final bool isTomorrow;
  final VoidCallback onTap;

  const _DayCard({
    required this.forecast,
    required this.isTomorrow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colour = DemandPalette.of(forecast.band);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.canvas,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      Formatters.weekdayShort(forecast.date),
                      style: AppTheme.mono(
                        size: 10,
                        color: AppTheme.textSecondary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${forecast.date.day}',
                      style: AppTheme.mono(size: 16, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTomorrow
                          ? 'Tomorrow'
                          : '${Formatters.weekdayLong(forecast.date)}, '
                              '${Formatters.dayMonth(forecast.date)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      forecast.hasEnoughHistory
                          ? DemandPalette.shortLabel(forecast.band)
                          : 'INSUFFICIENT HISTORY',
                      style: AppTheme.mono(
                        size: 11,
                        color: colour,
                        weight: FontWeight.w700,
                      ),
                    ),
                    if (forecast.isHoliday) ...[
                      const SizedBox(height: 4),
                      Text(
                        forecast.holidayName!,
                        style: AppTheme.mono(
                          size: 10.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (forecast.hasEnoughHistory) ...[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: colour.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(forecast.percentOfMax * 100).round()}% Max',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.mono(
                        size: 11,
                        color: colour,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const Icon(Icons.chevron_right,
                  size: 20, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
