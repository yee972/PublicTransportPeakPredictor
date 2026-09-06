import 'dart:math' as math;

import '../models/journey.dart';
import '../models/rail_edge.dart';
import '../models/station.dart';

typedef CrowdIndexResolver = double Function({
  required String lineId,
  required String stationId,
  required int hour,
});

double _noCrowd({
  required String lineId,
  required String stationId,
  required int hour,
}) =>
    0;

enum _ArcKind { ride, transfer, walk }

class _Arc {
  final int target;
  final int seconds;
  final _ArcKind kind;

  const _Arc(this.target, this.seconds, this.kind);
}

class JourneyPlanner {
  final Map<String, Station> _stations;
  final List<String> _nodeStation = [];
  final List<String> _nodeLine = [];
  final Map<String, int> _nodeIndex = {};
  final List<List<_Arc>> _adjacency = [];

  JourneyPlanner({
    required List<Station> stations,
    required List<RailEdge> edges,
    required List<StationLink> links,
  }) : _stations = {for (final station in stations) station.id: station} {
    for (final station in stations) {
      for (final lineId in station.lineIds) {
        _createNode(station.id, lineId);
      }
    }

    for (final edge in edges) {
      final from = _nodeIndex['${edge.fromStationId}|${edge.lineId}'];
      final to = _nodeIndex['${edge.toStationId}|${edge.lineId}'];
      if (from == null || to == null) continue;
      _adjacency[from].add(_Arc(to, edge.travelSeconds, _ArcKind.ride));
      _adjacency[to].add(_Arc(from, edge.travelSeconds, _ArcKind.ride));
    }

    for (final station in stations) {
      if (station.lineIds.length < 2) continue;
      for (final first in station.lineIds) {
        for (final second in station.lineIds) {
          if (first == second) continue;
          final from = _nodeIndex['${station.id}|$first'];
          final to = _nodeIndex['${station.id}|$second'];
          if (from == null || to == null) continue;
          final seconds = station.transferSeconds > 0 ? station.transferSeconds : 180;
          _adjacency[from].add(_Arc(to, seconds, _ArcKind.transfer));
        }
      }
    }

    for (final link in links) {
      final origin = _stations[link.fromStationId];
      final target = _stations[link.toStationId];
      if (origin == null || target == null) continue;
      for (final fromLine in origin.lineIds) {
        for (final toLine in target.lineIds) {
          final from = _nodeIndex['${origin.id}|$fromLine'];
          final to = _nodeIndex['${target.id}|$toLine'];
          if (from == null || to == null) continue;
          _adjacency[from].add(_Arc(to, link.walkSeconds, _ArcKind.walk));
          _adjacency[to].add(_Arc(from, link.walkSeconds, _ArcKind.walk));
        }
      }
    }
  }

  int get nodeCount => _nodeStation.length;

  int get arcCount => _adjacency.fold(0, (sum, arcs) => sum + arcs.length);

  bool knowsStation(String stationId) => _stations.containsKey(stationId);

  void _createNode(String stationId, String lineId) {
    final key = '$stationId|$lineId';
    if (_nodeIndex.containsKey(key)) return;
    _nodeIndex[key] = _nodeStation.length;
    _nodeStation.add(stationId);
    _nodeLine.add(lineId);
    _adjacency.add([]);
  }

  List<Journey> planAlternatives({
    required String originId,
    required String destinationId,
    required DateTime departureTime,
    CrowdIndexResolver crowdIndex = _noCrowd,
  }) {
    final results = <Journey>[];
    final seen = <String>{};
    for (final preference in JourneyPreference.values) {
      final journey = plan(
        originId: originId,
        destinationId: destinationId,
        departureTime: departureTime,
        preference: preference,
        crowdIndex: crowdIndex,
      );
      if (journey == null) continue;
      if (seen.add(journey.signature())) {
        results.add(journey);
      }
    }
    return results;
  }

  Journey? plan({
    required String originId,
    required String destinationId,
    required DateTime departureTime,
    required JourneyPreference preference,
    CrowdIndexResolver crowdIndex = _noCrowd,
  }) {
    if (originId == destinationId) return null;
    final origin = _stations[originId];
    final destination = _stations[destinationId];
    if (origin == null || destination == null) return null;
    if (origin.lineIds.isEmpty || destination.lineIds.isEmpty) return null;

    final weight = preference.crowdWeight;
    final total = _nodeStation.length;
    final cost = List<double>.filled(total, double.infinity);
    final elapsed = List<int>.filled(total, 0);
    final parent = List<int>.filled(total, -1);
    final settled = List<bool>.filled(total, false);
    final queue = _MinHeap();

    for (final lineId in origin.lineIds) {
      final start = _nodeIndex['$originId|$lineId'];
      if (start == null) continue;
      cost[start] = 0;
      elapsed[start] = 0;
      queue.push(start, 0);
    }

    var goal = -1;
    while (!queue.isEmpty) {
      final current = queue.pop();
      if (settled[current]) continue;
      settled[current] = true;

      if (_nodeStation[current] == destinationId) {
        goal = current;
        break;
      }

      final hour = departureTime.add(Duration(seconds: elapsed[current])).hour;
      for (final arc in _adjacency[current]) {
        if (settled[arc.target]) continue;
        var penalty = 0.0;
        if (arc.kind == _ArcKind.ride && weight > 0) {
          penalty = arc.seconds *
              weight *
              crowdIndex(
                lineId: _nodeLine[arc.target],
                stationId: _nodeStation[arc.target],
                hour: hour,
              );
        }
        final candidate = cost[current] + arc.seconds + penalty;
        if (candidate < cost[arc.target]) {
          cost[arc.target] = candidate;
          elapsed[arc.target] = elapsed[current] + arc.seconds;
          parent[arc.target] = current;
          queue.push(arc.target, candidate);
        }
      }
    }

    if (goal < 0) return null;
    return _reconstruct(goal, parent, departureTime, preference, crowdIndex);
  }

  Journey _reconstruct(
    int goal,
    List<int> parent,
    DateTime departureTime,
    JourneyPreference preference,
    CrowdIndexResolver crowdIndex,
  ) {
    final path = <int>[];
    for (var node = goal; node >= 0; node = parent[node]) {
      path.add(node);
    }
    final ordered = path.reversed.toList();

    final legs = <JourneyLeg>[];
    final transfers = <TransferStep>[];
    var travelSeconds = 0;
    var transferSeconds = 0;
    var elapsed = 0;

    var legStations = <String>[_nodeStation[ordered.first]];
    var legLine = _nodeLine[ordered.first];
    var legSeconds = 0;
    final legCrowd = <double>[];

    void closeLeg() {
      if (legStations.length > 1) {
        legs.add(JourneyLeg(
          lineId: legLine,
          stationIds: List<String>.from(legStations),
          travelSeconds: legSeconds,
          averageCrowdIndex: legCrowd.isEmpty
              ? 0
              : legCrowd.reduce((a, b) => a + b) / legCrowd.length,
        ));
      }
      legStations = [];
      legSeconds = 0;
      legCrowd.clear();
    }

    for (var index = 1; index < ordered.length; index++) {
      final previous = ordered[index - 1];
      final current = ordered[index];
      final arc = _adjacency[previous].firstWhere(
        (candidate) => candidate.target == current,
        orElse: () => const _Arc(-1, 0, _ArcKind.ride),
      );
      final hour = departureTime.add(Duration(seconds: elapsed)).hour;

      if (arc.kind == _ArcKind.ride) {
        legStations.add(_nodeStation[current]);
        legSeconds += arc.seconds;
        travelSeconds += arc.seconds;
        legCrowd.add(crowdIndex(
          lineId: _nodeLine[current],
          stationId: _nodeStation[current],
          hour: hour,
        ));
      } else {
        closeLeg();
        transfers.add(TransferStep(
          stationId: _nodeStation[previous],
          fromLineId: _nodeLine[previous],
          toLineId: _nodeLine[current],
          transferSeconds: arc.seconds,
          isWalkingLink: arc.kind == _ArcKind.walk,
          toStationId: arc.kind == _ArcKind.walk ? _nodeStation[current] : null,
        ));
        transferSeconds += arc.seconds;
        legStations = [_nodeStation[current]];
        legLine = _nodeLine[current];
      }
      elapsed += arc.seconds;
    }
    closeLeg();

    var weightedCrowd = 0.0;
    var weightedSeconds = 0;
    for (final leg in legs) {
      weightedCrowd += leg.averageCrowdIndex * leg.travelSeconds;
      weightedSeconds += leg.travelSeconds;
    }

    return Journey(
      preference: preference,
      legs: legs,
      transfers: transfers,
      travelSeconds: travelSeconds,
      transferSeconds: transferSeconds,
      crowdIndex: weightedSeconds <= 0 ? 0 : weightedCrowd / weightedSeconds,
      departureTime: departureTime,
    );
  }
}

class _MinHeap {
  final List<int> _nodes = [];
  final List<double> _costs = [];

  bool get isEmpty => _nodes.isEmpty;

  void push(int node, double cost) {
    _nodes.add(node);
    _costs.add(cost);
    var child = _nodes.length - 1;
    while (child > 0) {
      final parent = (child - 1) ~/ 2;
      if (_costs[parent] <= _costs[child]) break;
      _swap(parent, child);
      child = parent;
    }
  }

  int pop() {
    final top = _nodes.first;
    final lastNode = _nodes.removeLast();
    final lastCost = _costs.removeLast();
    if (_nodes.isNotEmpty) {
      _nodes[0] = lastNode;
      _costs[0] = lastCost;
      var parent = 0;
      while (true) {
        final left = parent * 2 + 1;
        final right = left + 1;
        var smallest = parent;
        if (left < _nodes.length && _costs[left] < _costs[smallest]) {
          smallest = left;
        }
        if (right < _nodes.length && _costs[right] < _costs[smallest]) {
          smallest = right;
        }
        if (smallest == parent) break;
        _swap(parent, smallest);
        parent = smallest;
      }
    }
    return top;
  }

  void _swap(int a, int b) {
    final node = _nodes[a];
    _nodes[a] = _nodes[b];
    _nodes[b] = node;
    final cost = _costs[a];
    _costs[a] = _costs[b];
    _costs[b] = cost;
  }
}

class JourneyFormatter {
  static String duration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return '$hours h';
    return '$hours h $remainder min';
  }

  static String clockTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String crowdLabel(double index) {
    if (index <= 0) return 'Not scored';
    if (index < 0.35) return 'Calm';
    if (index < 0.60) return 'Moderate';
    if (index < 0.85) return 'Busy';
    return 'Very busy';
  }

  static double normalisedCrowd(double index) => math.min(index / 1.2, 1.0);
}
