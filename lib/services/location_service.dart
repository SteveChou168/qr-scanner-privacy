// lib/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final bool isSuccess;
  final String? placeName;
  final String source; // 'none' | 'approx'

  const LocationResult._({
    required this.isSuccess,
    this.placeName,
    required this.source,
  });

  factory LocationResult.success({
    required String placeName,
    required String source,
  }) =>
      LocationResult._(
        isSuccess: true,
        placeName: placeName,
        source: source,
      );

  factory LocationResult.denied() => const LocationResult._(
        isSuccess: false,
        source: 'none',
      );

  factory LocationResult.failed() => const LocationResult._(
        isSuccess: false,
        source: 'none',
      );
}

class LocationService {
  /// Get approximate location (city/district only)
  /// Follows PDR's privacy-friendly principle
  Future<LocationResult> getApproximateLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.denied();
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return LocationResult.denied();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult.denied();
      }

      // Get position with low accuracy (privacy friendly)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      // Reverse geocode - get only city/district
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return LocationResult.failed();
      }

      final place = placemarks.first;
      // Combine city + district
      final parts = [
        place.locality, // City
        place.subLocality, // District
      ].where((p) => p != null && p.isNotEmpty);

      if (parts.isEmpty) {
        return LocationResult.failed();
      }

      return LocationResult.success(
        placeName: parts.join(', '),
        source: 'approx',
      );
    } catch (e) {
      return LocationResult.failed();
    }
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
