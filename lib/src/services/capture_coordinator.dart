import 'package:geolocator/geolocator.dart';
import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/cooldown_engine.dart';
import 'package:reality_diorama/src/domain/engines/collection_pattern_engine.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/engines/surrounding_classifier.dart';
import 'package:reality_diorama/src/domain/engines/time_context.dart';
import 'package:reality_diorama/src/domain/engines/weather_classifier.dart';
import 'package:reality_diorama/src/platform/ambient_scanner.dart';
import 'package:reality_diorama/src/services/location_gateway.dart';
import 'package:reality_diorama/src/services/weather_gateway.dart';
import 'package:uuid/uuid.dart';

class CapturePreparation {
  const CapturePreparation({
    required this.location,
    required this.weatherSnapshot,
    required this.weatherKind,
    required this.atmosphericTraits,
    required this.timeBand,
    required this.season,
    required this.weatherReadiness,
    required this.surroundingReadiness,
  });

  final LocationFix location;
  final WeatherSnapshot? weatherSnapshot;
  final WeatherMaterialKind? weatherKind;
  final List<AtmosphericTrait> atmosphericTraits;
  final TimeBand timeBand;
  final Season season;
  final ResourceReadiness weatherReadiness;
  final ResourceReadiness surroundingReadiness;
}

class CaptureBundle {
  const CaptureBundle({
    required this.record,
    required this.weatherMaterial,
    required this.surroundingMaterial,
    required this.ambientFeatures,
    required this.patterns,
  });

  final CaptureRecord record;
  final WeatherMaterial? weatherMaterial;
  final SurroundingMaterial? surroundingMaterial;
  final AmbientFeatures? ambientFeatures;
  final List<CollectedPattern> patterns;
}

class CaptureCoordinator {
  const CaptureCoordinator({
    required this.locationGateway,
    required this.weatherGateway,
    required this.ambientScanner,
    required this.catalog,
    this.uuid = const Uuid(),
  });

  final LocationGateway locationGateway;
  final WeatherGateway weatherGateway;
  final AmbientScanner ambientScanner;
  final ContentCatalog catalog;
  final Uuid uuid;

  Future<CapturePreparation> prepare({
    required DateTime now,
    WeatherMaterial? lastWeather,
    SurroundingMaterial? lastSurrounding,
    ({double latitude, double longitude})? lastAmbientCoordinate,
    bool requestLocationPermission = true,
  }) async {
    final location = await locationGateway.current(
      requestPermission: requestLocationPermission,
    );
    final timeBand = timeBandFor(now);
    final cooldown = CooldownEngine(catalog.balance);

    WeatherSnapshot? weather;
    WeatherMaterialKind? weatherKind;
    var atmosphericTraits = const <AtmosphericTrait>[];
    ResourceReadiness weatherReadiness;
    if (location.isFallback) {
      weatherReadiness = const ResourceReadiness.unavailable(
        '위치를 허용하면 날씨 재료를 모을 수 있습니다.',
      );
    } else {
      try {
        weather = await weatherGateway.current(location.point);
        weatherKind = const WeatherClassifier().classify(weather);
        atmosphericTraits = catalog.atmosphericTraits.classify(weather);
        weatherReadiness = cooldown.weatherReadiness(
          now: now,
          currentKind: weatherKind,
          currentTimeBand: timeBand,
          lastMaterial: lastWeather,
        );
      } catch (_) {
        weatherReadiness = const ResourceReadiness.unavailable(
          '날씨 정보를 불러오지 못했습니다. 주변 재료는 계속 모을 수 있습니다.',
        );
      }
    }

    var distance = 0.0;
    if (!location.isFallback && lastAmbientCoordinate != null) {
      distance = Geolocator.distanceBetween(
        lastAmbientCoordinate.latitude,
        lastAmbientCoordinate.longitude,
        location.point.latitude,
        location.point.longitude,
      );
    }

    return CapturePreparation(
      location: location,
      weatherSnapshot: weather,
      weatherKind: weatherKind,
      atmosphericTraits: atmosphericTraits,
      timeBand: timeBand,
      season: seasonFor(now, northernHemisphere: location.point.latitude >= 0),
      weatherReadiness: weatherReadiness,
      surroundingReadiness: cooldown.surroundingReadiness(
        now: now,
        distanceFromLastCaptureMeters: distance,
        lastMaterial: lastSurrounding,
      ),
    );
  }

  Future<CaptureBundle> capture({
    required CapturePreparation preparation,
    required DateTime now,
    required bool includeSurroundings,
  }) async {
    final recordId = uuid.v4();
    WeatherMaterial? weatherMaterial;
    final weatherKind = preparation.weatherKind;
    final weatherSnapshot = preparation.weatherSnapshot;
    if (preparation.weatherReadiness.isReady &&
        weatherKind != null &&
        weatherSnapshot != null) {
      final weatherId = uuid.v4();
      weatherMaterial = WeatherMaterial(
        id: weatherId,
        kind: weatherKind,
        timeBand: preparation.timeBand,
        season: preparation.season,
        capturedAt: now,
        coarseCellId: preparation.location.isFallback
            ? null
            : preparation.location.point.coarseCellId,
        sourceRecordId: recordId,
        visualSeed: stableSeed(<Object?>[
          recordId,
          weatherKind.name,
          preparation.timeBand.name,
        ]),
        providerName: weatherSnapshot.providerName,
        atmosphericTraits: preparation.atmosphericTraits,
        traitSchemaVersion: catalog.atmosphericTraits.classifierVersion,
      );
    }

    AmbientFeatures? ambientFeatures;
    SurroundingMaterial? surroundingMaterial;
    if (includeSurroundings && preparation.surroundingReadiness.isReady) {
      ambientFeatures = await ambientScanner.scan(
        duration: Duration(seconds: catalog.balance.surroundingScanSeconds),
      );
      if (ambientFeatures != null) {
        final classification = SurroundingClassifier(
          minimumConfidence: catalog.balance.surroundingConfidenceThreshold,
        ).classify(ambientFeatures);
        if (classification != null) {
          surroundingMaterial = SurroundingMaterial(
            id: uuid.v4(),
            kind: classification.kind,
            confidence: classification.confidence,
            capturedAt: now,
            coarseCellId: preparation.location.isFallback
                ? null
                : preparation.location.point.coarseCellId,
            sourceRecordId: recordId,
            featureSchemaVersion: SurroundingClassifier.version,
          );
        }
      }
    }

    final record = CaptureRecord(
      id: recordId,
      capturedAt: now,
      coarseCellId: preparation.location.isFallback
          ? null
          : preparation.location.point.coarseCellId,
      userPlaceLabel: preparation.location.label,
      timeBand: preparation.timeBand,
      season: preparation.season,
      weatherBasis: weatherSnapshot?.basis ?? WeatherBasis.unavailable,
      sourceVersion: 'capture-v3',
      weatherMaterialId: weatherMaterial?.id,
      surroundingMaterialId: surroundingMaterial?.id,
    );

    final patterns = const CollectionPatternEngine().derive(
      sourceRecordId: recordId,
      capturedAt: now,
      timeBand: preparation.timeBand,
      season: preparation.season,
      weatherSnapshot: weatherMaterial == null ? null : weatherSnapshot,
      weatherKind: weatherMaterial?.kind,
      ambientFeatures: surroundingMaterial == null ? null : ambientFeatures,
      surroundingKind: surroundingMaterial?.kind,
    );

    return CaptureBundle(
      record: record,
      weatherMaterial: weatherMaterial,
      surroundingMaterial: surroundingMaterial,
      ambientFeatures: ambientFeatures,
      patterns: patterns,
    );
  }
}
