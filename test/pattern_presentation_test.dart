import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/engines/collection_pattern_engine.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/pattern_presentation.dart';

void main() {
  final capturedAt = DateTime.utc(2026, 8, 10, 12);
  final patterns = const CollectionPatternEngine().derive(
    sourceRecordId: 'presentation',
    capturedAt: capturedAt,
    timeBand: TimeBand.afternoon,
    season: Season.summer,
    weatherKind: WeatherMaterialKind.cloudy,
    weatherSnapshot: WeatherSnapshot(
      temperatureCelsius: 24,
      apparentTemperatureCelsius: 25,
      precipitationRateMmPerHour: 0,
      cloudCoverPercent: 94,
      windSpeedKph: 22,
      visibilityMeters: 12000,
      weatherCode: 3,
      observedAt: capturedAt,
      basis: WeatherBasis.demo,
      providerName: 'Test',
    ),
    surroundingKind: SurroundingMaterialKind.dynamic,
    ambientFeatures: const AmbientFeatures(
      uniqueCount: 10,
      medianRssi: -68,
      strongSignalRatio: 0.25,
      persistence: 0.52,
      churn: 0.64,
      observationCoverage: 0.92,
    ),
  );
  final patternsByKey = <String, CollectedPattern>{
    for (final pattern in patterns) pattern.patternKey: pattern,
  };

  test(
    'combination presentation uses short fixed titles and value summaries',
    () {
      final scene = patterns.singleWhere(
        (CollectedPattern value) =>
            value.patternKey.startsWith('combination.scene.'),
      );

      expect(combinationPatternTitle(scene), '장면 조합');
      expect(combinationPatternSummary(scene, patternsByKey), contains(' · '));
      expect(
        combinationPatternSummary(scene, patternsByKey),
        isNot(contains('/')),
      );
      expect(
        combinationPatternSummary(scene, patternsByKey),
        isNot(contains('패턴')),
      );
    },
  );

  test('capture result chooses the full scene and one channel weave', () {
    final representatives = representativeCombinationPatterns(patterns);

    expect(representatives, hasLength(2));
    expect(combinationPatternTitle(representatives.first), '장면 조합');
    expect(
      combinationPatternTitle(representatives.last),
      anyOf('기상 조합', '주변 조합'),
    );
  });

  test('visual descriptor keeps normalized source families for the mark', () {
    final scene = patterns.singleWhere(
      (CollectedPattern value) =>
          value.patternKey.startsWith('combination.scene.'),
    );
    final visual = combinationPatternVisualDescriptor(scene, patternsByKey);

    expect(visual.title, '장면 조합');
    expect(visual.componentCount, 3);
    expect(visual.componentFamilies, <CapturePatternFamily>[
      CapturePatternFamily.weather,
      CapturePatternFamily.time,
      CapturePatternFamily.surroundings,
    ]);
  });

  test('visual descriptor preserves repeated families for channel weaves', () {
    final weatherWeave = patterns.singleWhere(
      (CollectedPattern value) =>
          value.patternKey.startsWith('combination.weather.weather.'),
    );
    final visual = combinationPatternVisualDescriptor(
      weatherWeave,
      patternsByKey,
    );

    expect(visual.componentCount, 3);
    expect(
      visual.componentFamilies,
      everyElement(CapturePatternFamily.weather),
    );
  });

  test('individual labels remove redundant category suffixes', () {
    final time = patterns.singleWhere(
      (CollectedPattern value) => value.family == CapturePatternFamily.time,
    );
    final weather = patterns.singleWhere(
      (CollectedPattern value) => value.patternKey == 'weather.kind.cloudy',
    );

    expect(compactPatternLabel(time), TimeBand.afternoon.labelKo);
    expect(compactPatternLabel(weather), WeatherMaterialKind.cloudy.labelKo);
  });
}
