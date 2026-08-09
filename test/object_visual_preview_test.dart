import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';

void main() {
  testWidgets('shared object preview fits list and detail sizes', (
    WidgetTester tester,
  ) async {
    const visual = ObjectVisualDescriptor(
      kind: ObjectKind.alleyLamp,
      weatherKind: WeatherMaterialKind.rain,
      timeBand: TimeBand.evening,
      surroundingKind: SurroundingMaterialKind.dynamic,
      visualSeed: 99,
      generatorVersion: 'test-v1',
      completion: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              SizedBox(
                width: 50,
                height: 50,
                child: ObjectVisualPreview(
                  visual: visual,
                  semanticLabel: '목록 골목등 미리보기',
                ),
              ),
              SizedBox(
                width: 280,
                height: 180,
                child: ObjectVisualPreview(
                  visual: visual,
                  semanticLabel: '상세 골목등 미리보기',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ObjectVisualPreview), findsNWidgets(2));
    expect(find.bySemanticsLabel('목록 골목등 미리보기'), findsOneWidget);
    expect(find.bySemanticsLabel('상세 골목등 미리보기'), findsOneWidget);
  });

  test('preview painter repaints when the descriptor changes', () {
    const complete = ObjectVisualDescriptor(
      kind: ObjectKind.planter,
      weatherKind: WeatherMaterialKind.clear,
      timeBand: TimeBand.morning,
      surroundingKind: null,
      visualSeed: 42,
      generatorVersion: 'test-v1',
      completion: 1,
    );
    const building = ObjectVisualDescriptor(
      kind: ObjectKind.planter,
      weatherKind: WeatherMaterialKind.clear,
      timeBand: TimeBand.morning,
      surroundingKind: null,
      visualSeed: 42,
      generatorVersion: 'test-v1',
      completion: 0.35,
    );

    const completePainter = ObjectVisualPainter(visual: complete);
    const buildingPainter = ObjectVisualPainter(visual: building);

    expect(buildingPainter.shouldRepaint(completePainter), isTrue);
    expect(completePainter.shouldRepaint(completePainter), isFalse);
  });
}
