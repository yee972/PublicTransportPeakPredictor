import 'package:geolocator/geolocator.dart';

enum LocationOutcome { success, serviceDisabled, permissionDenied, permissionDeniedForever, failed }

class LocationResult {
  final LocationOutcome outcome;
  final double? latitude;
  final double? longitude;

  const LocationResult(this.outcome, {this.latitude, this.longitude});

  bool get isSuccess => outcome == LocationOutcome.success;

  String get message {
    switch (outcome) {
      case LocationOutcome.success:
        return 'Location found';
      case LocationOutcome.serviceDisabled:
        return 'Turn on location services to find your nearest station';
      case LocationOutcome.permissionDenied:
        return 'Location permission is needed to find your nearest station';
      case LocationOutcome.permissionDeniedForever:
        return 'Location permission is blocked. Enable it in system settings';
      case LocationOutcome.failed:
        return 'Could not read your location. Try again';
    }
  }
}

class LocationService {
  Future<LocationResult> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationOutcome.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationOutcome.permissionDeniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationOutcome.permissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 12),
      );
      return LocationResult(
        LocationOutcome.success,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationResult(LocationOutcome.failed);
    }
  }
}
