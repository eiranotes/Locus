import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/platform/ambient_scanner.dart';
import 'package:reality_diorama/src/services/capture_coordinator.dart';
import 'package:reality_diorama/src/services/location_gateway.dart';
import 'package:reality_diorama/src/services/weather_gateway.dart';

import 'test_fixtures.dart';

void main() {
  final traitCatalog = AtmosphericTraitCatalog.fromJson(
    jsonDecode(
          File('assets/content/atmospheric_traits.json').readAsStringSync(),
        )
        as Map<String, Object?>,
  );
  final now = DateTime(2026, 8, 8, 19, 14);
  final snapshot = WeatherSnapshot(
    temperatureCelsius: 22,
    apparentTemperatureCelsius: 22,
    precipitationRateMmPerHour: 0.7,
    cloudCoverPercent: 90,
    windSpeedKph: 8,
    visibilityMeters: 12000,
    weatherCode: 61,
    observedAt: now,
    basis: WeatherBasis.providerCurrentModel,
    providerName: 'Test provider',
  );

  test(
    'provider failure creates no fake weather and keeps surroundings usable',
    () async {
      final coordinator = CaptureCoordinator(
        locationGateway: const _FixedLocationGateway(),
        weatherGateway: _ThrowingWeatherGateway(),
        ambientScanner: const _FixedAmbientScanner(),
        catalog: ContentCatalog(
          recipes: const <RecipeDefinition>[],
          visitors: const <VisitorDefinition>[],
          balance: testBalance(),
          placement: PlacementCatalog.empty,
          atmosphericTraits: traitCatalog,
        ),
      );

      final preparation = await coordinator.prepare(now: now);
      expect(preparation.weatherSnapshot, isNull);
      expect(preparation.weatherKind, isNull);
      expect(preparation.weatherReadiness.status, ReadinessStatus.unavailable);
      expect(preparation.surroundingReadiness.isReady, isTrue);

      final result = await coordinator.capture(
        preparation: preparation,
        now: now,
        includeSurroundings: true,
      );

      expect(result.weatherMaterial, isNull);
      expect(result.surroundingMaterial, isNotNull);
      expect(result.record.weatherBasis, WeatherBasis.unavailable);
      expect(result.record.weatherMaterialId, isNull);
      expect(result.record.surroundingMaterialId, isNotNull);
      expect(result.patterns, hasLength(10));
      expect(
        result.patterns.where((CollectedPattern value) => value.isCombination),
        hasLength(2),
      );
    },
  );

  test('fallback location does not call the weather provider', () async {
    final gateway = _CountingWeatherGateway(snapshot);
    final coordinator = CaptureCoordinator(
      locationGateway: const _FallbackLocationGateway(),
      weatherGateway: gateway,
      ambientScanner: const _FixedAmbientScanner(),
      catalog: ContentCatalog(
        recipes: const <RecipeDefinition>[],
        visitors: const <VisitorDefinition>[],
        balance: testBalance(),
        placement: PlacementCatalog.empty,
      ),
    );

    final preparation = await coordinator.prepare(now: now);
    expect(gateway.callCount, 0);
    expect(preparation.weatherSnapshot, isNull);
    expect(preparation.weatherKind, isNull);
    expect(preparation.weatherReadiness.status, ReadinessStatus.unavailable);

    final result = await coordinator.capture(
      preparation: preparation,
      now: now,
      includeSurroundings: false,
    );

    expect(result.weatherMaterial, isNull);
    expect(result.record.weatherBasis, WeatherBasis.unavailable);
    expect(result.record.coarseCellId, isNull);
    expect(result.record.userPlaceLabel, '위치 권한 필요');
  });

  test(
    'available provider creates a weather material with its provenance',
    () async {
      final coordinator = CaptureCoordinator(
        locationGateway: const _FixedLocationGateway(),
        weatherGateway: _CountingWeatherGateway(snapshot),
        ambientScanner: const _FixedAmbientScanner(),
        catalog: ContentCatalog(
          recipes: const <RecipeDefinition>[],
          visitors: const <VisitorDefinition>[],
          balance: testBalance(),
          placement: PlacementCatalog.empty,
          atmosphericTraits: traitCatalog,
        ),
      );

      final preparation = await coordinator.prepare(now: now);
      expect(preparation.weatherKind, WeatherMaterialKind.rain);
      expect(preparation.weatherReadiness.isReady, isTrue);

      final result = await coordinator.capture(
        preparation: preparation,
        now: now,
        includeSurroundings: false,
      );

      expect(result.weatherMaterial?.providerName, 'Test provider');
      expect(result.weatherMaterial?.atmosphericTraits, <AtmosphericTrait>[
        AtmosphericTrait.deepCloud,
      ]);
      expect(result.weatherMaterial?.traitSchemaVersion, 'weather-traits-v1');
      expect(result.record.weatherBasis, WeatherBasis.providerCurrentModel);
      expect(result.patterns, hasLength(10));
    },
  );

  test('simultaneous weather and surroundings create cross patterns', () async {
    final coordinator = CaptureCoordinator(
      locationGateway: const _FixedLocationGateway(),
      weatherGateway: _CountingWeatherGateway(snapshot),
      ambientScanner: const _FixedAmbientScanner(),
      catalog: ContentCatalog(
        recipes: const <RecipeDefinition>[],
        visitors: const <VisitorDefinition>[],
        balance: testBalance(),
        placement: PlacementCatalog.empty,
        atmosphericTraits: traitCatalog,
      ),
    );

    final preparation = await coordinator.prepare(now: now);
    final result = await coordinator.capture(
      preparation: preparation,
      now: now,
      includeSurroundings: true,
    );

    expect(result.patterns, hasLength(20));
    expect(
      result.patterns.where((CollectedPattern value) => value.isCombination),
      hasLength(6),
    );
    expect(
      result.patterns.map((CollectedPattern value) => value.patternKey),
      contains(
        'combination.scene.weather.kind.rain.time.evening.surroundings.kind.dynamic',
      ),
    );
  });

  test('passive preparation does not request location permission', () async {
    final location = _PermissionRecordingLocationGateway();
    final coordinator = CaptureCoordinator(
      locationGateway: location,
      weatherGateway: _CountingWeatherGateway(
        WeatherSnapshot(
          temperatureCelsius: 20,
          apparentTemperatureCelsius: 20,
          precipitationRateMmPerHour: 0,
          cloudCoverPercent: 10,
          windSpeedKph: 4,
          visibilityMeters: 12000,
          weatherCode: 0,
          observedAt: DateTime.utc(2026, 8, 10),
          basis: WeatherBasis.demo,
          providerName: 'Test',
        ),
      ),
      ambientScanner: const _FixedAmbientScanner(),
      catalog: ContentCatalog(
        recipes: const <RecipeDefinition>[],
        visitors: const <VisitorDefinition>[],
        balance: testBalance(),
        placement: PlacementCatalog.empty,
      ),
    );

    await coordinator.prepare(
      now: DateTime.utc(2026, 8, 10),
      requestLocationPermission: false,
    );

    expect(location.lastRequestPermission, isFalse);
  });
}

class _CountingWeatherGateway implements WeatherGateway {
  _CountingWeatherGateway(this.snapshot);

  final WeatherSnapshot snapshot;
  int callCount = 0;

  @override
  Future<WeatherAttributionInfo> attribution() async =>
      const WeatherAttributionInfo(
        serviceName: 'Test',
        notice: 'Test attribution',
      );

  @override
  Future<WeatherSnapshot> current(GeoPoint point) async {
    callCount += 1;
    return snapshot;
  }
}

class _ThrowingWeatherGateway implements WeatherGateway {
  @override
  Future<WeatherAttributionInfo> attribution() async =>
      const WeatherAttributionInfo(
        serviceName: 'Unavailable',
        notice: 'Unavailable provider',
      );

  @override
  Future<WeatherSnapshot> current(GeoPoint point) async {
    throw StateError('provider unavailable');
  }
}

class _FixedAmbientScanner implements AmbientScanner {
  const _FixedAmbientScanner();

  @override
  Future<AmbientFeatures?> scan({required Duration duration}) async =>
      const AmbientFeatures(
        uniqueCount: 11,
        medianRssi: -67,
        strongSignalRatio: 0.27,
        persistence: 0.52,
        churn: 0.61,
        observationCoverage: 0.93,
      );
}

class _FixedLocationGateway implements LocationGateway {
  const _FixedLocationGateway();

  @override
  Future<LocationFix> current({bool requestPermission = true}) async =>
      const LocationFix(
        point: GeoPoint(
          latitude: 37.5446,
          longitude: 127.0559,
          accuracyMeters: 30,
        ),
        label: '성수동',
        isFallback: false,
      );
}

class _FallbackLocationGateway implements LocationGateway {
  const _FallbackLocationGateway();

  @override
  Future<LocationFix> current({bool requestPermission = true}) async =>
      const LocationFix(
        point: GeoPoint(
          latitude: 37.5665,
          longitude: 126.9780,
          accuracyMeters: 5000,
        ),
        label: '위치 권한 필요',
        isFallback: true,
      );
}

class _PermissionRecordingLocationGateway implements LocationGateway {
  bool? lastRequestPermission;

  @override
  Future<LocationFix> current({bool requestPermission = true}) async {
    lastRequestPermission = requestPermission;
    return const LocationFix(
      point: GeoPoint(
        latitude: 37.5446,
        longitude: 127.0559,
        accuracyMeters: 30,
      ),
      label: '성수동',
      isFallback: false,
    );
  }
}
