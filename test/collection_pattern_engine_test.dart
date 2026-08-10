import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/collection_pattern_engine.dart';
import 'package:reality_diorama/src/domain/enums.dart';

void main() {
  const engine = CollectionPatternEngine();
  final capturedAt = DateTime.utc(2026, 8, 10, 9, 30);
  final weather = WeatherSnapshot(
    temperatureCelsius: 22,
    apparentTemperatureCelsius: 22,
    precipitationRateMmPerHour: 1.2,
    cloudCoverPercent: 92,
    windSpeedKph: 12,
    visibilityMeters: 8000,
    weatherCode: 61,
    observedAt: capturedAt,
    basis: WeatherBasis.providerCurrentModel,
    providerName: 'Test',
  );
  const ambient = AmbientFeatures(
    uniqueCount: 11,
    medianRssi: -67,
    strongSignalRatio: 0.27,
    persistence: 0.52,
    churn: 0.61,
    observationCoverage: 0.93,
  );

  test('derives bounded individual and simultaneous combination patterns', () {
    final patterns = engine.derive(
      sourceRecordId: 'capture-1',
      capturedAt: capturedAt,
      timeBand: TimeBand.morning,
      season: Season.summer,
      weatherSnapshot: weather,
      weatherKind: WeatherMaterialKind.rain,
      ambientFeatures: ambient,
      surroundingKind: SurroundingMaterialKind.dynamic,
    );

    final individual = patterns
        .where((CollectedPattern value) => !value.isCombination)
        .toList();
    final combinations = patterns
        .where((CollectedPattern value) => value.isCombination)
        .toList();

    expect(patterns, hasLength(20));
    expect(individual, hasLength(14));
    expect(combinations, hasLength(6));
    expect(
      combinations.length,
      lessThanOrEqualTo(CollectionPatternEngine.maxCombinationPatterns),
    );
    expect(
      patterns.map((CollectedPattern value) => value.patternKey).toSet(),
      hasLength(patterns.length),
    );
    expect(
      individual.map((CollectedPattern value) => value.patternKey),
      containsAll(<String>[
        'time.morning',
        'season.summer',
        'weather.kind.rain',
        'weather.temperature.mild',
        'weather.precipitation.steady',
        'weather.cloud.overcast',
        'weather.wind.breeze',
        'weather.visibility.soft',
        'surroundings.kind.dynamic',
        'ambient.density.dense',
        'ambient.signal.mixed',
        'ambient.persistence.recurring',
        'ambient.churn.flowing',
        'ambient.coverage.clear',
      ]),
    );
    expect(
      combinations.every(
        (CollectedPattern value) => value.componentKeys.length >= 2,
      ),
      isTrue,
    );
    expect(
      combinations
          .singleWhere(
            (CollectedPattern value) =>
                value.patternKey.startsWith('combination.scene.'),
          )
          .componentKeys,
      hasLength(3),
    );
  });

  test('keeps weather-only and surroundings-only combinations independent', () {
    final weatherOnly = engine.derive(
      sourceRecordId: 'weather-only',
      capturedAt: capturedAt,
      timeBand: TimeBand.morning,
      season: Season.summer,
      weatherSnapshot: weather,
      weatherKind: WeatherMaterialKind.rain,
    );
    final surroundingsOnly = engine.derive(
      sourceRecordId: 'surroundings-only',
      capturedAt: capturedAt,
      timeBand: TimeBand.morning,
      season: Season.summer,
      ambientFeatures: ambient,
      surroundingKind: SurroundingMaterialKind.dynamic,
    );

    expect(weatherOnly, hasLength(10));
    expect(surroundingsOnly, hasLength(10));
    expect(
      weatherOnly.any(
        (CollectedPattern value) =>
            value.patternKey.contains('surrounding') ||
            value.patternKey.contains('ambient'),
      ),
      isFalse,
    );
    expect(
      surroundingsOnly.any(
        (CollectedPattern value) => value.patternKey.contains('weather'),
      ),
      isFalse,
    );
  });

  test('pattern persistence map preserves combination provenance', () {
    final pattern = engine
        .derive(
          sourceRecordId: 'capture-1',
          capturedAt: capturedAt,
          timeBand: TimeBand.morning,
          season: Season.summer,
          weatherSnapshot: weather,
          weatherKind: WeatherMaterialKind.rain,
          ambientFeatures: ambient,
          surroundingKind: SurroundingMaterialKind.dynamic,
        )
        .firstWhere((CollectedPattern value) => value.isCombination);

    final restored = CollectedPattern.fromMap(pattern.toMap());
    expect(restored.patternKey, pattern.patternKey);
    expect(restored.scope, CapturePatternScope.combination);
    expect(restored.family, CapturePatternFamily.combination);
    expect(restored.componentKeys, pattern.componentKeys);
    expect(restored.sourceRecordId, 'capture-1');
    expect(restored.schemaVersion, CollectionPatternEngine.schemaVersion);
  });

  test('does not create contextual patterns when no channel was collected', () {
    expect(
      engine.derive(
        sourceRecordId: 'empty',
        capturedAt: capturedAt,
        timeBand: TimeBand.morning,
        season: Season.summer,
      ),
      isEmpty,
    );
  });
}
