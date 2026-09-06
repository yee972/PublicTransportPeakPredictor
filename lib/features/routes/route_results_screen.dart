import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../algorithms/journey_planner.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../models/journey.dart';
import '../../models/rail_network.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../auth/auth_provider.dart';
import 'route_detail_screen.dart';
import 'route_planner_provider.dart';

class RouteResultsScreen extends StatelessWidget {
  const RouteResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutePlannerProvider>();
    final journeys = provider.results;
    final network = provider.network;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route options'),
        actions: [
          IconButton(
            tooltip: 'Save this route',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: journeys.isEmpty
                ? null
                : () => _showSaveDialog(context, provider),
          ),
        ],
      ),
      body: journeys.isEmpty
          ? const EmptyView(
              message: 'No route found between these stations',
              icon: Icons.wrong_location_outlined,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Text(
                  '${network.stationName(journeys.first.originStationId)}  →  '
                  '${network.stationName(journeys.first.destinationStationId)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Departing ${Formatters.dayMonth(provider.departureTime)} at '
                  '${Formatters.clock(provider.departureTime)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ...journeys.map((journey) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JourneyCard(journey: journey, network: network),
                    )),
                const SizedBox(height: 4),
                InfoNote(
                  message: journeys.length == 1
                      ? 'Only one route is shown because the quickest way here is '
                          'also the calmest. Searching again with more weight on '
                          'crowding returns the same journey, so there is no '
                          'trade-off worth offering.'
                      : 'All options come from one Dijkstra search. Only the '
                          'weight on predicted crowding changes: zero for Fastest, '
                          'highest for Least crowded.',
                ),
              ],
            ),
    );
  }

  static Future<void> _showSaveDialog(
    BuildContext context,
    RoutePlannerProvider provider,
  ) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId == null) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _SaveRouteDialog(
        provider: provider,
        userId: userId,
      ),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved == true
              ? 'Route saved'
              : provider.savedMessage ?? 'Route was not saved',
        ),
      ),
    );
  }
}

class _SaveRouteDialog extends StatefulWidget {
  final RoutePlannerProvider provider;
  final String userId;

  const _SaveRouteDialog({required this.provider, required this.userId});

  @override
  State<_SaveRouteDialog> createState() => _SaveRouteDialogState();
}

class _SaveRouteDialogState extends State<_SaveRouteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late JourneyPreference _preference;

  @override
  void initState() {
    super.initState();
    final network = widget.provider.network;
    _controller = TextEditingController(
      text: '${network.stationName(widget.provider.originId ?? '')} to '
          '${network.stationName(widget.provider.destinationId ?? '')}',
    );
    _preference = widget.provider.results.first.preference;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save route'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Morning commute',
              ),
              validator: Validators.routeLabel,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<JourneyPreference>(
              initialValue: _preference,
              decoration: const InputDecoration(labelText: 'Preference'),
              items: JourneyPreference.values
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _preference = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final success = await widget.provider.saveCurrentRoute(
              userId: widget.userId,
              label: _controller.text.trim(),
              preference: _preference,
            );
            if (!context.mounted) return;
            Navigator.pop(context, success);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final Journey journey;
  final RailNetwork network;

  const _JourneyCard({required this.journey, required this.network});

  @override
  Widget build(BuildContext context) {
    final crowd = JourneyFormatter.crowdLabel(journey.crowdIndex);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RouteDetailScreen(journey: journey),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(journey.preference.label,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(
                    JourneyFormatter.duration(journey.totalSeconds),
                    style: AppTheme.mono(size: 17, weight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(journey.preference.description,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var index = 0; index < journey.legs.length; index++) ...[
                    if (index > 0)
                      const Icon(Icons.chevron_right,
                          size: 15, color: AppTheme.textSecondary),
                    StatusPill(
                      label: network.lineName(journey.legs[index].lineId),
                      colour: network.line(journey.legs[index].lineId)
                              ?.displayColour ??
                          AppTheme.primary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Arrive',
                      value: Formatters.clock(journey.arrivalTime),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Changes',
                      value: '${journey.interchangeCount}',
                    ),
                  ),
                  Expanded(
                    child: _Metric(label: 'Crowding', value: crowd),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              DemandBar(
                value: JourneyFormatter.normalisedCrowd(journey.crowdIndex),
                colour: _crowdColour(journey.crowdIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _crowdColour(double index) {
    if (index >= 0.85) return DemandPalette.busy;
    if (index >= 0.60) return DemandPalette.moderate;
    if (index >= 0.35) return DemandPalette.baseline;
    return DemandPalette.quiet;
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

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
