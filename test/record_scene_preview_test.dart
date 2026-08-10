import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('record scene selection is stable and varies by record', () {
    final first = recordSceneVisualFor(record);
    final second = recordSceneVisualFor(record);
    final other = recordSceneVisualFor(
      CaptureRecord(
        id: 'record-scene-2',
        capturedAt: capturedAt,
        timeBand: TimeBand.night,
        season: Season.winter,
        weatherBasis: WeatherBasis.providerCurrentModel,
        sourceVersion: 'test-v1',
      ),
    );

    expect(second.sceneryName, first.sceneryName);
    expect(other.sceneryName, isNot(first.sceneryName));
  });

  test('paged history records produce varied scenery', () {
    final scenery = <String>{
      for (var index = 0; index < 12; index += 1)
        recordSceneVisualFor(
          CaptureRecord(
            id: 'history-$index',
            capturedAt: capturedAt.subtract(Duration(minutes: index)),
            timeBand: TimeBand.afternoon,
            season: Season.summer,
            weatherBasis: WeatherBasis.demo,
            sourceVersion: 'test-v1',
          ),
        ).sceneryName,
    };

    expect(scenery.length, greaterThanOrEqualTo(4));
  });

  testWidgets('record scene composes shipping pixel assets without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 140,
            child: RecordScenePreview(record: record, weather: rain),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
