import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../forecast/forecast_provider.dart';
import '../forecast/validation_screen.dart';
import 'data_citations_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForecastProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('About & data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text('About & Data', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Peak Predictor forecasts congestion on Klang Valley rail from '
            'published government open data, so commuters can plan around the '
            'busiest days and hours.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Sources and Methods',
            icon: Icons.science_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily predictions use a day-of-week baseline with a recent-trend '
                  'adjustment and a holiday factor, fitted to historical daily '
                  'ridership from data.gov.my.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                const _Spec(
                  label: 'MODEL ARCHITECTURE',
                  value: 'Day-of-week median baseline × exponentially weighted '
                      'trend × learned holiday factor',
                ),
                const SizedBox(height: 10),
                const _Spec(
                  label: 'HOURLY LAYER',
                  value: 'Scheduled trains per hour, normalised against the '
                      'busiest station-hour on the network',
                ),
                const SizedBox(height: 10),
                const _Spec(
                  label: 'ROUTE PLANNING',
                  value: 'Dijkstra over a station-line graph, cost = travel time '
                      '+ interchange penalty + weighted crowd index',
                ),
                const SizedBox(height: 10),
                const _Spec(
                  label: 'UPDATE FREQUENCY',
                  value: 'Daily, matching the publication cadence of the source',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionCard(
            title: 'Honest limits',
            icon: Icons.balance_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Limit(
                  text: 'The open data is daily, not hourly. Busy Times is derived '
                      'from published timetables, not measured crowding.',
                ),
                _Limit(
                  text: 'The Ampang and Sri Petaling lines are reported as one '
                      'combined ridership figure, so they share a forecast.',
                ),
                _Limit(
                  text: 'Lines with too little history are marked "insufficient '
                      'history" rather than given an unreliable number.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Data Citations',
            icon: Icons.verified_outlined,
            trailing: const StatusPill(
              label: 'OFFICIAL SOURCE',
              colour: AppTheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppTheme.primary, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('data.gov.my',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('Malaysian Open Data Portal',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Daily rail ridership is sourced directly from the Malaysian '
                  'government open data initiative. Station coordinates and line '
                  'sequences come from OpenStreetMap.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataCitationsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.list_alt_outlined, size: 18),
                  label: const Text('View all citations'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Validation Metrics',
            icon: Icons.bar_chart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.networkAccuracy <= 0
                      ? 'Not yet validated'
                      : 'Busy/quiet correct on '
                          '${provider.networkAccuracy.toStringAsFixed(1)}% of '
                          'hold-out days across ${provider.distinctSeriesValidation.length} lines',
                  style: AppTheme.mono(size: 12),
                ),
                const SizedBox(height: 10),
                DemandBar(
                  value: provider.networkAccuracy / 100,
                  colour: AppTheme.primary,
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ValidationScreen(),
                    ),
                  ),
                  child: const Text('View Detailed Metrics'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Team & Credits',
            icon: Icons.groups_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Built for BMIT2073 Mobile Application, Group 3, in support of '
                  'UN Sustainable Development Goal 9: Industry, Innovation and '
                  'Infrastructure.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Text('Version 1.0.0', style: AppTheme.mono(size: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  final String label;
  final String value;

  const _Spec({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 5),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Limit extends StatelessWidget {
  final String text;

  const _Limit({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
