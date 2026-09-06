import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../algorithms/journey_planner.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/journey.dart';
import '../../models/rail_network.dart';
import '../../services/notification_service.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/demand_bar.dart';
import '../../widgets/section_card.dart';
import 'route_planner_provider.dart';

class RouteDetailScreen extends StatelessWidget {
  final Journey journey;

  const RouteDetailScreen({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final network = context.watch<RoutePlannerProvider>().network;
    var runningTime = journey.departureTime;

    return Scaffold(
      appBar: AppBar(title: Text(journey.preference.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        JourneyFormatter.duration(journey.totalSeconds),
                        style: AppTheme.mono(size: 26, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${Formatters.clock(journey.departureTime)} → '
                        '${Formatters.clock(journey.arrivalTime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${journey.interchangeCount} change'
                        '${journey.interchangeCount == 1 ? '' : 's'}',
                        style: AppTheme.mono(size: 12)),
                    const SizedBox(height: 5),
                    Text(
                      JourneyFormatter.crowdLabel(journey.crowdIndex),
                      style: AppTheme.mono(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Journey', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...() {
            final tiles = <Widget>[];
            for (var index = 0; index < journey.legs.length; index++) {
              final leg = journey.legs[index];
              final boardTime = runningTime;
              runningTime = runningTime.add(Duration(seconds: leg.travelSeconds));
              tiles.add(_LegCard(
                leg: leg,
                network: network,
                boardTime: boardTime,
                alightTime: runningTime,
              ));
              if (index < journey.transfers.length) {
                final transfer = journey.transfers[index];
                runningTime =
                    runningTime.add(Duration(seconds: transfer.transferSeconds));
                tiles.add(_TransferCard(transfer: transfer, network: network));
              }
            }
            return tiles;
          }(),
          const SizedBox(height: 12),
          SectionCard(
            title: 'How this route was chosen',
            icon: Icons.route_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cost = travel time × (1 + '
                  '${journey.preference.crowdWeight} × crowd index) '
                  '+ interchange penalty',
                  style: AppTheme.mono(size: 11.5),
                ),
                const SizedBox(height: 10),
                Text(
                  'Riding time ${JourneyFormatter.duration(journey.travelSeconds)}, '
                  'interchange time '
                  '${JourneyFormatter.duration(journey.transferSeconds)}. '
                  'The crowd index blends the line\'s scheduled frequency at each '
                  'hour with the predicted demand for that day.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _scheduleReminder(context, network),
            icon: const Icon(Icons.notifications_active_outlined, size: 19),
            label: const Text('Remind me before I leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleReminder(
    BuildContext context,
    RailNetwork network,
  ) async {
    final service = context.read<NotificationService>();
    final granted = await service.requestPermission();
    final departAt = journey.departureTime.subtract(const Duration(minutes: 15));
    final origin = network.stationName(journey.originStationId);
    final destination = network.stationName(journey.destinationStationId);

    if (departAt.isAfter(DateTime.now())) {
      await service.scheduleDepartureReminder(
        departAt: departAt,
        title: 'Leave soon for $destination',
        body: 'Your ${journey.preference.label.toLowerCase()} route from $origin '
            'departs at ${Formatters.clock(journey.departureTime)}.',
      );
    } else {
      await service.showNow(
        title: 'Route to $destination',
        body: '${JourneyFormatter.duration(journey.totalSeconds)} via '
            '${journey.legs.map((leg) => network.lineName(leg.lineId)).join(' → ')}.',
      );
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? departAt.isAfter(DateTime.now())
                  ? 'Reminder set for ${Formatters.clock(departAt)}'
                  : 'Route sent to your notifications'
              : 'Notifications are turned off for this app',
        ),
      ),
    );
  }
}

class _LegCard extends StatelessWidget {
  final JourneyLeg leg;
  final RailNetwork network;
  final DateTime boardTime;
  final DateTime alightTime;

  const _LegCard({
    required this.leg,
    required this.network,
    required this.boardTime,
    required this.alightTime,
  });

  @override
  Widget build(BuildContext context) {
    final line = network.line(leg.lineId);
    final colour = line?.displayColour ?? AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LineDot(colour: colour, code: line?.code ?? '?'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line?.shortName ?? leg.lineId,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${leg.stopCount} stop${leg.stopCount == 1 ? '' : 's'} · '
                        '${JourneyFormatter.duration(leg.travelSeconds)}',
                        style: AppTheme.mono(
                          size: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Stop(
              time: Formatters.clock(boardTime),
              name: network.stationName(leg.boardStationId),
              label: 'Board',
              colour: colour,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 6, bottom: 6),
              child: Text(
                leg.stopCount > 1
                    ? '${leg.stopCount - 1} intermediate stop'
                        '${leg.stopCount - 1 == 1 ? '' : 's'}'
                    : 'Direct',
                style: AppTheme.mono(size: 10.5, color: AppTheme.textSecondary),
              ),
            ),
            _Stop(
              time: Formatters.clock(alightTime),
              name: network.stationName(leg.alightStationId),
              label: 'Alight',
              colour: colour,
            ),
            const SizedBox(height: 12),
            DemandBar(
              value: JourneyFormatter.normalisedCrowd(leg.averageCrowdIndex),
              colour: colour,
              trailingLabel: JourneyFormatter.crowdLabel(leg.averageCrowdIndex),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  final String time;
  final String name;
  final String label;
  final Color colour;

  const _Stop({
    required this.time,
    required this.name,
    required this.label,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(time, style: AppTheme.mono(size: 12, weight: FontWeight.w700)),
        ),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: colour, width: 2.4),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TransferCard extends StatelessWidget {
  final TransferStep transfer;
  final RailNetwork network;

  const _TransferCard({required this.transfer, required this.network});

  @override
  Widget build(BuildContext context) {
    final destination = transfer.isWalkingLink && transfer.toStationId != null
        ? network.stationName(transfer.toStationId!)
        : network.stationName(transfer.stationId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 26),
      child: Row(
        children: [
          Icon(
            transfer.isWalkingLink ? Icons.directions_walk : Icons.swap_horiz,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              transfer.isWalkingLink
                  ? 'Walk to $destination '
                      '(${JourneyFormatter.duration(transfer.transferSeconds)})'
                  : 'Change at $destination '
                      '(${JourneyFormatter.duration(transfer.transferSeconds)})',
              style: AppTheme.mono(size: 11.5, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
