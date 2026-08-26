import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import 'forecast_provider.dart';

class DayPredictionScreen extends StatelessWidget {
  final String lineId;
  final DateTime date;

  const DayPredictionScreen({
    super.key,
    required this.lineId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();
    final isNetwork = lineId == 'network';
    final forecast = isNetwork
        ? provider.networkSevenDay(from: date).first
        : provider.forecastFor(lineId, date);
    final label = isNetwork ? 'All lines' : provider.network.lineName(lineId);

    return Scaffold(
      appBar: AppBar(title: const Text('Day prediction')),
      body: !forecast.hasEnoughHistory
          ? const EmptyView(
              message: 'This service does not have enough ridership history '
                  'for an honest forecast yet.',
              icon: Icons.hourglass_empty,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Text(Formatters.fullDate(date),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 18),
                SectionCard(
                  title: 'Prediction',
                  icon: Icons.insights_outlined,
                  trailing: BandBadge(band: forecast.band),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.thousands(forecast.predictedRiders),
                        style: AppTheme.mono(size: 30, weight: FontWeight.w700),
                      ),
                      Text('riders predicted',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 14),
                      DemandBar(
                        value: forecast.percentOfMax,
                        colour: DemandPalette.of(forecast.band),
                        trailingLabel:
                            '${(forecast.percentOfMax * 100).round()}% Max',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DemandPalette.label(forecast.band),
                        style: AppTheme.mono(
                          size: 13,
                          color: DemandPalette.of(forecast.band),
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'How this number was produced',
                  icon: Icons.calculate_outlined,
                  child: Column(
                    children: [
                      _Factor(
                        label: '${Formatters.weekdayLong(date)} baseline',
                        detail: 'Median of recent ${Formatters.weekdayLong(date)}s',
                        value: Formatters.thousands(forecast.baselineRiders),
                      ),
                      const Divider(height: 20),
                      _Factor(
                        label: 'Recent trend',
                        detail: 'Weighted average of the last 14 days',
                        value: '× ${forecast.trendFactor.toStringAsFixed(3)}',
                      ),
                      const Divider(height: 20),
                      _Factor(
                        label: 'Holiday effect',
                        detail: forecast.isHoliday
                            ? forecast.holidayName!
                            : 'Not a public holiday',
                        value: '× ${forecast.holidayFactor.toStringAsFixed(3)}',
                      ),
                      const Divider(height: 20),
                      _Factor(
                        label: 'Predicted riders',
                        detail: 'baseline × trend × holiday',
                        value: Formatters.thousands(forecast.predictedRiders),
                        emphasise: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Context',
                  icon: Icons.compare_arrows,
                  child: Column(
                    children: [
                      _Factor(
                        label: 'Versus a typical day',
                        detail: 'Across all days of the week',
                        value: Formatters.signedPercent(
                          forecast.relativeToTypical - 1,
                        ),
                      ),
                      const Divider(height: 20),
                      _Factor(
                        label: 'Versus a typical ${Formatters.weekdayLong(date)}',
                        detail: 'Trend and holiday effect only',
                        value:
                            Formatters.signedPercent(forecast.deviationFromBaseline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const InfoNote(
                  message: 'The source data is published daily, so this predicts a '
                      'whole day. For time-of-day patterns, see Busy Times.',
                ),
              ],
            ),
    );
  }
}

class _Factor extends StatelessWidget {
  final String label;
  final String detail;
  final String value;
  final bool emphasise;

  const _Factor({
    required this.label,
    required this.detail,
    required this.value,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: emphasise
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTheme.mono(
            size: emphasise ? 15 : 13,
            weight: FontWeight.w700,
            color: emphasise ? AppTheme.primary : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
