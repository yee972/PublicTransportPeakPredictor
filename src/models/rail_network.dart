import 'rail_edge.dart';
import 'rail_line.dart';
import 'station.dart';

class RailNetwork {
  final List<RailLine> lines;
  final List<Station> stations;
  final List<RailEdge> edges;
  final List<StationLink> links;
  final bool fromCache;

  final Map<String, RailLine> _linesById;
  final Map<String, Station> _stationsById;

  RailNetwork({
    required this.lines,
    required this.stations,
    required this.edges,
    required this.links,
    this.fromCache = false,
  })  : _linesById = {for (final line in lines) line.id: line},
        _stationsById = {for (final station in stations) station.id: station};

  static RailNetwork empty() => RailNetwork(
        lines: const [],
        stations: const [],
        edges: const [],
        links: const [],
      );

  bool get isEmpty => stations.isEmpty || lines.isEmpty;

  RailLine? line(String id) => _linesById[id];

  Station? station(String id) => _stationsById[id];

  String lineName(String id) => _linesById[id]?.shortName ?? id;

  String stationName(String id) => _stationsById[id]?.name ?? id;

  List<Station> stationsOnLine(String lineId) =>
      stations.where((station) => station.lineIds.contains(lineId)).toList();

  List<Station> searchStations(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return stations;
    return stations
        .where((station) => station.name.toLowerCase().contains(term))
        .toList();
  }

  Station? nearestStation(double latitude, double longitude) {
    if (stations.isEmpty) return null;
    Station? closest;
    var shortest = double.infinity;
    for (final station in stations) {
      final distance = station.metresTo(latitude, longitude);
      if (distance < shortest) {
        shortest = distance;
        closest = station;
      }
    }
    return closest;
  }

  RailNetwork asCached() => RailNetwork(
        lines: lines,
        stations: stations,
        edges: edges,
        links: links,
        fromCache: true,
      );
}
