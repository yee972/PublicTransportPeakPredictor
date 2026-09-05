enum JourneyPreference { fastest, balanced, leastCrowded }

extension JourneyPreferenceLabel on JourneyPreference {
  String get storageValue {
    switch (this) {
      case JourneyPreference.fastest:
        return 'fastest';
      case JourneyPreference.balanced:
        return 'balanced';
      case JourneyPreference.leastCrowded:
        return 'least_crowded';
    }
  }

  String get label {
    switch (this) {
      case JourneyPreference.fastest:
        return 'Fastest';
      case JourneyPreference.balanced:
        return 'Balanced';
      case JourneyPreference.leastCrowded:
        return 'Least crowded';
    }
  }

  String get description {
    switch (this) {
      case JourneyPreference.fastest:
        return 'Shortest travel time, ignores predicted crowding';
      case JourneyPreference.balanced:
        return 'Trades a little time for a calmer trip';
      case JourneyPreference.leastCrowded:
        return 'Avoids predicted peaks even if it takes longer';
    }
  }

  double get crowdWeight {
    switch (this) {
      case JourneyPreference.fastest:
        return 0;
      case JourneyPreference.balanced:
        return 0.35;
      case JourneyPreference.leastCrowded:
        return 0.9;
    }
  }

  static JourneyPreference fromStorage(String value) {
    switch (value) {
      case 'fastest':
        return JourneyPreference.fastest;
      case 'least_crowded':
        return JourneyPreference.leastCrowded;
      default:
        return JourneyPreference.balanced;
    }
  }
}

class JourneyLeg {
  final String lineId;
  final List<String> stationIds;
  final int travelSeconds;
  final double averageCrowdIndex;

  const JourneyLeg({
    required this.lineId,
    required this.stationIds,
    required this.travelSeconds,
    required this.averageCrowdIndex,
  });

  String get boardStationId => stationIds.first;
  String get alightStationId => stationIds.last;
  int get stopCount => stationIds.length - 1;
}

class TransferStep {
  final String stationId;
  final String fromLineId;
  final String toLineId;
  final int transferSeconds;
  final bool isWalkingLink;
  final String? toStationId;

  const TransferStep({
    required this.stationId,
    required this.fromLineId,
    required this.toLineId,
    required this.transferSeconds,
    this.isWalkingLink = false,
    this.toStationId,
  });
}

class Journey {
  final JourneyPreference preference;
  final List<JourneyLeg> legs;
  final List<TransferStep> transfers;
  final int travelSeconds;
  final int transferSeconds;
  final double crowdIndex;
  final DateTime departureTime;

  const Journey({
    required this.preference,
    required this.legs,
    required this.transfers,
    required this.travelSeconds,
    required this.transferSeconds,
    required this.crowdIndex,
    required this.departureTime,
  });

  int get totalSeconds => travelSeconds + transferSeconds;
  int get totalMinutes => (totalSeconds / 60).round();
  int get interchangeCount => transfers.length;
  DateTime get arrivalTime => departureTime.add(Duration(seconds: totalSeconds));

  String get originStationId => legs.first.boardStationId;
  String get destinationStationId => legs.last.alightStationId;

  String signature() =>
      legs.map((leg) => leg.stationIds.join('>')).join('|');
}
