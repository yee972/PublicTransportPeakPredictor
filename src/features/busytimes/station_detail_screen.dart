import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import '../../widgets/state_views.dart';
import '../routes/route_planner_provider.dart';
import 'busy_times_provider.dart';
import 'busy_times_screen.dart';

class StationDetailScreen extends StatelessWidget {
  final String stationId;

  const StationDetailScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusyTimesProvider>();
    final station = provider.network.station(stationId);
    final resolver = provider.intensity;

    if (station == null || resolver == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Station')),
        body: const EmptyView(message: 'This station is not available'),
      );
    }

    final profile = resolver.stationProfile(stationId, provider.dayType);
    final peaks = resolver.peakHours(stationId, provider.dayType);
    final serviceHours = profile.where((slot) => slot.isServiceHour).toList();
    final busiest = serviceHours.isEmpty
        ? null
        : serviceHours.reduce((a, b) => a.trips >= b.trips ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(station.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Text(station.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: station.lineIds.map((lineId) {
              final line = provider.network.line(lineId);
              if (line == null) return const SizedBox.shrink();
              return StatusPill(
                label: line.shortName.toUpperCase(),
                colour: line.displayColour,
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'Typical ${Formatters.dayTypeLabel(provider.dayType)} pattern',
            icon: Icons.schedule,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (busiest != null)
                  Text(
                    'Busiest around ${Formatters.hourRange(busiest.hour)} '
                    'with ${busiest.trips} scheduled trains',
                    style: AppTheme.mono(size: 12),
                  ),
                const SizedBox(height: 16),
                BarChart(
                  entries: profile
                      .map((slot) => BarChartEntry(
                            value: slot.trips.toDouble(),
                            colour: intensityColour(slot.intensity),
                          ))
                      .toList(),
                  height: 110,
                  axisLabels: const ['12am', '12pm', '11pm'],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Typical busy periods',
            icon: Icons.trending_up,
            child: peaks.isEmpty
                ? const Text('No scheduled service recorded for this day type.')
                : Column(
                    children: peaks.map((hour) {
                      final slot = profile[hour];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 108,
                              child: Text(
                                Formatters.hourRange(hour),
                                style: AppTheme.mono(size: 12, weight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              child: DemandBar(
                                value: slot.intensity,
                                colour: intensityColour(slot.intensity),
                                trailingLabel: '${slot.trips} trains',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          if (station.isInterchange)
            SectionCard(
              title: 'Interchange',
              icon: Icons.swap_horiz,
              child: Text(
                'Allow about ${(station.transferSeconds / 60).round()} minutes to '
                'change lines here. The route planner already includes this.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (station.isInterchange) const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              context.read<RoutePlannerProvider>().setOrigin(stationId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Route planner will start from ${station.name}'),
                ),
              );
            },
            icon: const Icon(Icons.alt_route, size: 19),
            label: const Text('Plan a route from here'),
          ),
        ],
      ),
    );
  }
}
