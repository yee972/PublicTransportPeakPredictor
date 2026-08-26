import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/validators.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../forecast/forecast_provider.dart';
import 'route_planner_provider.dart';
import 'route_results_screen.dart';
import 'saved_routes_screen.dart';
import 'station_picker_screen.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  String? _endpointError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutePlannerProvider>().load();
    });
  }

  Future<void> _pickStation({required bool isOrigin}) async {
    final provider = context.read<RoutePlannerProvider>();
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => StationPickerScreen(
          network: provider.network,
          title: isOrigin ? 'Select origin' : 'Select destination',
          excludeStationId:
              isOrigin ? provider.destinationId : provider.originId,
        ),
      ),
    );
    if (selected == null) return;
    if (isOrigin) {
      provider.setOrigin(selected);
    } else {
      provider.setDestination(selected);
    }
    setState(() => _endpointError = null);
  }

  Future<void> _pickDepartureTime() async {
    final provider = context.read<RoutePlannerProvider>();
    final current = provider.departureTime;

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    provider.setDepartureTime(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  void _findRoutes() {
    final provider = context.read<RoutePlannerProvider>();
    final forecast = context.read<ForecastProvider>();

    final originError =
        Validators.requiredStation(provider.originId, 'starting');
    final destinationError =
        Validators.requiredStation(provider.destinationId, 'destination');
    final distinctError = Validators.distinctStations(
      provider.originId,
      provider.destinationId,
    );
    final error = originError ?? destinationError ?? distinctError;
    if (error != null) {
      setState(() => _endpointError = error);
      return;
    }

    setState(() => _endpointError = null);
    final departure = provider.departureTime;
    provider.plan(
      crowdIndex: ({
        required String lineId,
        required String stationId,
        required int hour,
      }) =>
          forecast.crowdIndexFor(
        lineId: lineId,
        stationId: stationId,
        hour: hour,
        date: departure,
      ),
    );

    if (provider.results.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RouteResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutePlannerProvider>();

    if (provider.state == LoadState.loading || provider.state == LoadState.idle) {
      return const LoadingView(message: 'Building the rail graph');
    }
    if (provider.state == LoadState.failed) {
      return ErrorView(
        message: provider.errorMessage ?? 'Could not load the rail network.',
        onRetry: () => provider.load(forceRefresh: true),
      );
    }

    final planner = provider.planner;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const SectionHeading(
          label: 'Route Planner',
          caption: 'Finds the cheapest path through the rail network, weighing '
              'travel time against predicted crowding.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            children: [
              _EndpointRow(
                label: 'FROM',
                icon: Icons.trip_origin,
                stationName: provider.origin?.name,
                placeholder: 'Select origin',
                onTap: () => _pickStation(isOrigin: true),
                trailing: IconButton(
                  tooltip: 'Use my location',
                  icon: provider.locating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 20),
                  onPressed: provider.locating
                      ? null
                      : () => provider.useCurrentLocationAsOrigin(),
                ),
              ),
              const Divider(height: 20),
              _EndpointRow(
                label: 'TO',
                icon: Icons.place_outlined,
                stationName: provider.destination?.name,
                placeholder: 'Select destination',
                onTap: () => _pickStation(isOrigin: false),
                trailing: IconButton(
                  tooltip: 'Swap origin and destination',
                  icon: const Icon(Icons.swap_vert, size: 20),
                  onPressed: provider.swapEndpoints,
                ),
              ),
            ],
          ),
        ),
        if (_endpointError != null) ...[
          const SizedBox(height: 8),
          Text(
            _endpointError!,
            style: AppTheme.mono(size: 12, color: DemandPalette.busy),
          ),
        ],
        const SizedBox(height: 12),
        SectionCard(
          child: InkWell(
            onTap: _pickDepartureTime,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 19, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEPARTING',
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 3),
                        Text(
                          '${Formatters.dayMonth(provider.departureTime)} at '
                          '${Formatters.clock(provider.departureTime)}',
                          style: AppTheme.mono(size: 14, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_calendar_outlined,
                      size: 19, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: provider.planning ? null : _findRoutes,
          icon: provider.planning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.search, size: 20),
          label: const Text('Find routes'),
        ),
        if (provider.planMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            provider.planMessage!,
            textAlign: TextAlign.center,
            style: AppTheme.mono(size: 12, color: DemandPalette.busy),
          ),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavedRoutesScreen()),
          ),
          icon: const Icon(Icons.bookmark_outline, size: 19),
          label: const Text('Saved routes'),
        ),
        const SizedBox(height: 22),
        if (planner != null)
          SectionCard(
            title: 'Network loaded',
            icon: Icons.hub_outlined,
            child: Text(
              '${provider.network.stations.length} stations across '
              '${provider.network.lines.length} lines, modelled as '
              '${planner.nodeCount} graph nodes and ${planner.arcCount} arcs. '
              'Interchanges are separate nodes, so changing lines carries its own cost.',
              style: AppTheme.mono(size: 11.5, color: AppTheme.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? stationName;
  final String placeholder;
  final VoidCallback onTap;
  final Widget trailing;

  const _EndpointRow({
    required this.label,
    required this.icon,
    required this.stationName,
    required this.placeholder,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final selected = stationName != null;
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 3),
                  Text(
                    stationName ?? placeholder,
                    style: selected
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}
