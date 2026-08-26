import 'journey.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String? homeStationId;
  final bool peakAlertsEnabled;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.homeStationId,
    this.peakAlertsEnabled = true,
  });

  UserProfile copyWith({
    String? fullName,
    String? homeStationId,
    bool? peakAlertsEnabled,
    bool clearHomeStation = false,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      homeStationId: clearHomeStation ? null : (homeStationId ?? this.homeStationId),
      peakAlertsEnabled: peakAlertsEnabled ?? this.peakAlertsEnabled,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        fullName: (json['full_name'] as String?) ?? '',
        homeStationId: json['home_station_id'] as String?,
        peakAlertsEnabled: (json['peak_alerts_enabled'] as bool?) ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'home_station_id': homeStationId,
        'peak_alerts_enabled': peakAlertsEnabled,
      };
}

class SavedRoute {
  final String id;
  final String userId;
  final String label;
  final String originStationId;
  final String destinationStationId;
  final JourneyPreference preference;
  final DateTime createdAt;

  const SavedRoute({
    required this.id,
    required this.userId,
    required this.label,
    required this.originStationId,
    required this.destinationStationId,
    required this.preference,
    required this.createdAt,
  });

  factory SavedRoute.fromJson(Map<String, dynamic> json) => SavedRoute(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        label: json['label'] as String,
        originStationId: json['origin_station_id'] as String,
        destinationStationId: json['destination_station_id'] as String,
        preference: JourneyPreferenceLabel.fromStorage(json['preference'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'label': label,
        'origin_station_id': originStationId,
        'destination_station_id': destinationStationId,
        'preference': preference.storageValue,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsert() => {
        'user_id': userId,
        'label': label,
        'origin_station_id': originStationId,
        'destination_station_id': destinationStationId,
        'preference': preference.storageValue,
      };
}
