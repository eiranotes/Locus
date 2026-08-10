import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_pattern_mark.dart';

void main() {
  test('two- and three-input weave marks paint distinct pixels', () async {
    const twoInputs = PixelWeavePainter(
      families: <CapturePatternFamily>[
        CapturePatternFamily.weather,
        CapturePatternFamily.surroundings,
      ],
    );
    const threeInputs = PixelWeavePainter(
      families: <CapturePatternFamily>[
        CapturePatternFamily.time,
        CapturePatternFamily.weather,
        CapturePatternFamily.surroundings,
      ],
    );

    final twoBytes = await _paintBytes(twoInputs);
    final threeBytes = await _paintBytes(threeInputs);

    expect(listEquals(twoBytes, threeBytes), isFalse);
    expect(threeInputs.shouldRepaint(twoInputs), isTrue);
    expect(threeInputs.shouldRepaint(threeInputs), isFalse);
  });

  test('same-family weave differs from a mixed-family mark', () async {
    const weatherWeave = PixelWeavePainter(
      families: <CapturePatternFamily>[
        CapturePatternFamily.weather,
        CapturePatternFamily.weather,
        CapturePatternFamily.weather,
      ],
    );
    const mixedWeave = PixelWeavePainter(
      families: <CapturePatternFamily>[
        CapturePatternFamily.time,
        CapturePatternFamily.weather,
        CapturePatternFamily.surroundings,
      ],
    );

    expect(
      listEquals(
        await _paintBytes(weatherWeave),
        await _paintBytes(mixedWeave),
      ),
      isFalse,
    );
  });

  testWidgets('pattern primitives fit their compact UI slots', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Row(
            children: <Widget>[
              PixelPatternStamp(size: 20),
              PatternFamilyMark(family: CapturePatternFamily.time),
              PatternFamilyMark(family: CapturePatternFamily.weather),
              PatternFamilyMark(family: CapturePatternFamily.surroundings),
              PixelWeaveMark(
                families: <CapturePatternFamily>[
                  CapturePatternFamily.weather,
                  CapturePatternFamily.surroundings,
                ],
                animate: true,
              ),
              PixelCaret(expanded: false),
              PixelCaret(expanded: true),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PatternFamilyMark), findsNWidgets(3));
    expect(find.byType(PixelWeaveMark), findsOneWidget);
    expect(find.byType(PixelCaret), findsNWidgets(2));
  });
}

Future<Uint8List> _paintBytes(CustomPainter painter) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, const Size(24, 24));
  final image = await recorder.endRecording().toImage(24, 24);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}
