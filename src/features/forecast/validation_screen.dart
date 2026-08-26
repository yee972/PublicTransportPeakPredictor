import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import 'forecast_provider.dart';

class ValidationScreen extends StatelessWidget {
  const ValidationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();
    final metrics = provider.allValidation;

    return Scaffold(
      appBar: AppBar(title: const Text('Validation')),
      body: metrics.isEmpty
          ? const EmptyView(message: 'No line has enough hold-out data to score yet')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const SectionHeading(
                  label: 'How we test the model',
                  caption: 'The last 28 days are hidden from the model, then predicted '
                      'one day at a time. Each prediction only ever sees data from '
                      'before the day it forecasts.',
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Network summary',
                  icon: Icons.verified_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider.networkAccuracy.toStringAsFixed(1)}%',
                        style: AppTheme.mono(size: 34, weight: FontWeight.w700)
                            .copyWith(color: AppTheme.primary),
                      ),
                      Text('of hold-out days classified busy or quiet correctly',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 14),
                      DemandBar(
                        value: provider.networkAccuracy / 100,
                        colour: AppTheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              label: 'Mean error',
                              value:
                                  '${provider.networkMape.toStringAsFixed(1)}%',
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              label: 'Hold-out window',
                              value: '${AppConfig.validationHoldOutDays} days',
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              label: 'Series scored',
                              value: '${provider.distinctSeriesValidation.length}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Per line', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...metrics.map((item) {
                  final line = provider.network.line(item.lineId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line?.shortName ?? item.lineId,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                '${item.classificationAccuracy.toStringAsFixed(1)}%',
                                style: AppTheme.mono(
                                  size: 15,
                                  weight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DemandBar(
                            value: item.classificationAccuracy / 100,
                            colour: line?.displayColour ?? AppTheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _Stat(
                                  label: 'MAE',
                                  value: Formatters.thousands(
                                    item.meanAbsoluteError.round(),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _Stat(
                                  label: 'MAPE',
                                  value:
                                      '${item.meanAbsolutePercentageError.toStringAsFixed(1)}%',
                                ),
                              ),
                              Expanded(
                                child: _Stat(
                                  label: 'Days',
                                  value: '${item.sampleSize}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const InfoNote(
                  message: 'MAE is the average miss in riders per day. MAPE expresses '
                      'that miss as a percentage. Busy/quiet accuracy is how often the '
                      'model puts a day on the correct side of the median.',
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 3),
        Text(value, style: AppTheme.mono(size: 13, weight: FontWeight.w700)),
      ],
    );
  }
}
