class RailEdge {
  final String lineId;
  final String fromStationId;
  final String toStationId;
  final int travelSeconds;
  final int distanceMetres;

  const RailEdge({
    required this.lineId,
    required this.fromStationId,
    required this.toStationId,
    required this.travelSeconds,
    required this.distanceMetres,
  });

  factory RailEdge.fromJson(Map<String, dynamic> json) => RailEdge(
        lineId: json['line_id'] as String,
        fromStationId: json['from_station_id'] as String,
        toStationId: json['to_station_id'] as String,
        travelSeconds: (json['travel_seconds'] as num).toInt(),
        distanceMetres: (json['distance_metres'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'from_station_id': fromStationId,
        'to_station_id': toStationId,
        'travel_seconds': travelSeconds,
        'distance_metres': distanceMetres,
      };
}

class StationLink {
  final String fromStationId;
  final String toStationId;
  final int walkSeconds;

  const StationLink({
    required this.fromStationId,
    required this.toStationId,
    required this.walkSeconds,
  });

  factory StationLink.fromJson(Map<String, dynamic> json) => StationLink(
        fromStationId: json['from_station_id'] as String,
        toStationId: json['to_station_id'] as String,
        walkSeconds: (json['walk_seconds'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'from_station_id': fromStationId,
        'to_station_id': toStationId,
        'walk_seconds': walkSeconds,
      };
}

class StationLine {
  final String stationId;
  final String lineId;
  final int stopSequence;

  const StationLine({
    required this.stationId,
    required this.lineId,
    required this.stopSequence,
  });

  factory StationLine.fromJson(Map<String, dynamic> json) => StationLine(
        stationId: json['station_id'] as String,
        lineId: json['line_id'] as String,
        stopSequence: (json['stop_sequence'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'station_id': stationId,
        'line_id': lineId,
        'stop_sequence': stopSequence,
      };
}
