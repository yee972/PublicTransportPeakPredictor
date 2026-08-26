import 'dart:math' as math;

class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int transferSeconds;
  final List<String> lineIds;

  const Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.transferSeconds,
    this.lineIds = const [],
  });

  bool get isInterchange => lineIds.length > 1;

  Station withLines(List<String> ids) => Station(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        transferSeconds: transferSeconds,
        lineIds: ids,
      );

  double metresTo(double lat, double lon) {
    const radius = 6371000.0;
    final dLat = _radians(lat - latitude);
    final dLon = _radians(lon - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(latitude)) *
            math.cos(_radians(lat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * radius * math.asin(math.sqrt(a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180.0;

  factory Station.fromJson(Map<String, dynamic> json) {
    final rawLines = json['line_ids'];
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      transferSeconds: (json['transfer_seconds'] as num?)?.toInt() ?? 0,
      lineIds: rawLines is String
          ? rawLines.split(',').where((e) => e.isNotEmpty).toList()
          : (rawLines as List?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'transfer_seconds': transferSeconds,
        'line_ids': lineIds.join(','),
      };
}
