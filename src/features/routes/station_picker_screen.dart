import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/rail_network.dart';
import '../../models/station.dart';
import '../../widgets/band_badge.dart';
import '../../widgets/state_views.dart';

class StationPickerScreen extends StatefulWidget {
  final RailNetwork network;
  final String title;
  final String? excludeStationId;

  const StationPickerScreen({
    super.key,
    required this.network,
    required this.title,
    this.excludeStationId,
  });

  @override
  State<StationPickerScreen> createState() => _StationPickerScreenState();
}

class _StationPickerScreenState extends State<StationPickerScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.network
        .searchStations(_query)
        .where((station) => station.id != widget.excludeStationId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search stations',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? const EmptyView(
                    message: 'No station matches that search',
                    icon: Icons.search_off,
                  )
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final station = matches[index];
                      return _StationTile(
                        station: station,
                        network: widget.network,
                        onTap: () => Navigator.pop(context, station.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  final Station station;
  final RailNetwork network;
  final VoidCallback onTap;

  const _StationTile({
    required this.station,
    required this.network,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(station.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: station.lineIds.map((lineId) {
            final line = network.line(lineId);
            if (line == null) return const SizedBox.shrink();
            return StatusPill(
              label: line.code,
              colour: line.displayColour,
            );
          }).toList(),
        ),
      ),
      trailing: station.isInterchange
          ? Icon(Icons.swap_horiz, size: 18, color: AppTheme.textSecondary)
          : null,
    );
  }
}
