import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

void main() {
  test('arriving visitor takes priority over persisted sightings', () {
    expect(
      sceneVisitorIdFor(
        arrivingVisitorId: 'new-visitor',
        sightings: <VisitorSighting>[
          _sighting('older', DateTime.utc(2026, 8, 8)),
        ],
      ),
      'new-visitor',
    );
  });

  test(
    'latest persisted visitor remains in the scene after arrival clears',
    () {
      expect(
        sceneVisitorIdFor(
          sightings: <VisitorSighting>[
            _sighting('older', DateTime.utc(2026, 8, 8)),
            _sighting('latest', DateTime.utc(2026, 8, 9)),
          ],
        ),
        'latest',
      );
    },
  );

  test('scene has no visitor before the first sighting', () {
    expect(sceneVisitorIdFor(sightings: const <VisitorSighting>[]), isNull);
  });

  testWidgets('diorama exposes the supplied scene summary', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DioramaView(
          snapshot: DioramaSnapshot.empty(),
          semanticLabel: '흐린 저녁, 놓인 물건 없음, 머무는 방문자 없음',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('흐린 저녁, 놓인 물건 없음, 머무는 방문자 없음'),
      findsOneWidget,
    );
  });
}

VisitorSighting _sighting(String visitorId, DateTime lastSeenAt) =>
    VisitorSighting(
      id: 'sighting-$visitorId',
      visitorId: visitorId,
      firstSeenAt: lastSeenAt,
      lastSeenAt: lastSeenAt,
      variantKey: 'test',
    );
