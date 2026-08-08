import 'package:geolocator/geolocator.dart';
import 'package:reality_diorama/src/domain/entities.dart';

class LocationFix {
  const LocationFix({
    required this.point,
    required this.label,
    required this.isFallback,
  });

  final GeoPoint point;
  final String label;
  final bool isFallback;
}

abstract interface class LocationGateway {
  Future<LocationFix> current();
}

class GeolocatorLocationGateway implements LocationGateway {
  const GeolocatorLocationGateway({
    this.fallbackLatitude = 37.5665,
    this.fallbackLongitude = 126.9780,
  });

  final double fallbackLatitude;
  final double fallbackLongitude;

  @override
  Future<LocationFix> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return _fallback();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _fallback();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LocationFix(
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
        ),
        label: '현재 지역',
        isFallback: false,
      );
    } on Exception {
      return _fallback();
    }
  }

  LocationFix _fallback() => LocationFix(
        point: GeoPoint(
          latitude: fallbackLatitude,
          longitude: fallbackLongitude,
          accuracyMeters: 5000,
        ),
        label: '위치 권한 필요',
        isFallback: true,
      );
}

class DemoLocationGateway implements LocationGateway {
  const DemoLocationGateway();

  @override
  Future<LocationFix> current() async => const LocationFix(
        point: GeoPoint(
          latitude: 37.5446,
          longitude: 127.0559,
          accuracyMeters: 30,
        ),
        label: '성수동',
        isFallback: false,
      );
}
