import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/widgets/record_scene_preview.dart';

void main() {
  final capturedAt = DateTime.utc(2026, 8, 10, 12);
  final record = CaptureRecord(
    id: 'record-scene-1',
    capturedAt: capturedAt,
    timeBand: TimeBand.afternoon,
    season: Season.summer,
    weatherBasis: WeatherBasis.providerCurrentModel,
    sourceVersion: 'test-v1',
    userPlaceLabel: '테스트 지역',
  );
  final rain = WeatherMaterial(
    id: 'weather-rain',
    kind: WeatherMaterialKind.rain,
    timeBand: TimeBand.afternoon,
    season: Season.summer,
    capturedAt: capturedAt,
    sourceRecordId: record.id,
    visualSeed: 1,
    providerName: 'Test',
  );
  final dynamic = SurroundingMaterial(
    id: 'surroundings-dynamic',
    kind: SurroundingMaterialKind.dynamic,
    confidence: 0.82,
    capturedAt: capturedAt,
    sourceRecordId: record.id,
    featureSchemaVersion: 'test-v1',
  );

  test('surroundings effect takes precedence over weather material', () {
    final visual = recordEffectVisualFor(
      record: record,
      weather: rain,
      surroundings: dynamic,
    );

    expect(visual.source, RecordEffectSource.surroundings);
    expect(
      visual.assetPath,
      GeneratedArtPaths.surroundingMaterial(SurroundingMaterialKind.dynamic),
    );
    expect(visual.label, '유동적 주변 효과');
  });

  test('weather-only and unlinked records use honest fallbacks', () {
    final weatherOnly = recordEffectVisualFor(record: record, weather: rain);
    final unlinked = recordEffectVisualFor(record: record);

    expect(weatherOnly.source, RecordEffectSource.weather);
    expect(weatherOnly.assetPath, GeneratedArtPaths.weatherMaterial(rain.kind));
    expect(unlinked.source, RecordEffectSource.trace);
    expect(unlinked.assetPath, isNull);
  });

  testWidgets('record effect sample uses no scenery or placement art', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 140,
            child: RecordScenePreview(
              record: record,
              weather: rain,
              surroundings: dynamic,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      GeneratedArtPaths.surroundingMaterial(SurroundingMaterialKind.dynamic),
    );
    expect(tester.takeException(), isNull);
  });
}
