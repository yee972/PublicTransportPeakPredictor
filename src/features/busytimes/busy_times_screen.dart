import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../forecast/forecast_provider.dart';
import 'busy_times_provider.dart';
import 'station_detail_screen.dart';

Color intensityColour(double intensity) {
  if (intensity >= 0.75) return DemandPalette.busy;
  if (intensity >= 0.5) return DemandPalette.moderate;
  if (intensity >= 0.25) return DemandPalette.baseline;
  return DemandPalette.quiet;
}

class BusyTimesScreen extends StatefulWidget {
  const BusyTimesScreen({super.key});

  @override
  State<BusyTimesScreen> createState() => _BusyTimesScreenState();
}

class _BusyTimesScreenState extends State<BusyTimesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusyTimesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusyTimesProvider>();

    if (provider.state == LoadState.loading || provider.state == LoadState.idle) {
      return const LoadingView(message: 'Loading service frequencies');
    }
    if (provider.state == LoadState.failed) {
      return ErrorView(
        message: provider.errorMessage ?? 'Could not load busy times.',
        onRetry: () => provider.load(forceRefresh: true),
      );
    }

    final ranked = provider.rankedStations();
    final message = provider.locationMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        provider.clearLocationMessage();
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        const SectionHeading(
          label: 'Typical Busy Times',
          caption: 'Typical busy periods by station, derived from published '
              'service frequencies.',
        ),
        const SizedBox(height: 12),
        const InfoNote(
          message: 'Schedule-derived, not measured crowding. More trains scheduled '
              'means more capacity and more expected demand.',
        ),
        const SizedBox(height: 14),
        _HourSelector(provider: provider),
        const SizedBox(height: 14),
        _MapCard(provider: provider),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text('Busiest stations',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: provider.locating
                  ? null
                  : () => provider.useCurrentLocation(),
              icon: provider.locating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 17),
              label: const Text('Near me'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Station % = scheduled trains at this hour, relative to the busiest '
          'station-hour on the network.',
          style: AppTheme.mono(size: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        if (ranked.isEmpty)
          const SectionCard(
            child: EmptyView(
              message: 'No trains scheduled at this hour',
              icon: Icons.bedtime_outlined,
            ),
          )
        else
          ...ranked.map((load) {
            final percent = (load.intensity * 100).round();
            final colour = intensityColour(load.intensity);
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    provider.selectStation(load.station.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StationDetailScreen(stationId: load.station.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(load.station.name,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 3),
                              Text(
                                '${load.trips} trains scheduled · '
                                '${load.station.lineIds.length} line'
                                '${load.station.lineIds.length == 1 ? '' : 's'}',
                                style: AppTheme.mono(
                                  size: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 9),
                              DemandBar(value: load.intensity, colour: colour),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$percent%',
                            style: AppTheme.mono(
                              size: 14,
                              weight: FontWeight.w700,
                              color: colour,
                            )),
                        const Icon(Icons.chevron_right,
                            size: 20, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

}

class _HourSelector extends StatelessWidget {
  final BusyTimesProvider provider;

  const _HourSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.hourRange(provider.selectedHour),
                  style: AppTheme.mono(size: 15, weight: FontWeight.w700),
                ),
              ),
              Text(
                Formatters.dayTypeLabel(provider.dayType),
                style: AppTheme.mono(size: 11.5, color: AppTheme.textSecondary),
              ),
            ],
          ),
          Slider(
            value: provider.selectedHour.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            label: Formatters.hourLabel(provider.selectedHour),
            onChanged: (value) => provider.selectHour(value.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12am', style: Theme.of(context).textTheme.labelSmall),
              Text('12pm', style: Theme.of(context).textTheme.labelSmall),
              Text('11pm', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final BusyTimesProvider provider;

  const _MapCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final loads = provider.stationsForMap();
    if (loads.isEmpty) {
      return const SectionCard(
        child: EmptyView(message: 'No service to map at this hour'),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(3.130, 101.686),
            initialZoom: 10.6,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConfig.openStreetMapTileUrl,
              userAgentPackageName: AppConfig.tileUserAgent,
            ),
            MarkerLayer(
              markers: loads.map((load) {
                final colour =
                    intensityColour(load.intensity);
                final selected = load.station.id == provider.selectedStationId;
                final size = 10.0 + load.intensity * 12.0;
                return Marker(
                  point: LatLng(load.station.latitude, load.station.longitude),
                  width: size + 8,
                  height: size + 8,
                  child: GestureDetector(
                    onTap: () => provider.selectStation(load.station.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colour.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black87 : Colors.white,
                          width: selected ? 2.4 : 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
