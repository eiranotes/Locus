import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/object_renderer.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';

void main() {
  const renderer = DeterministicObjectRenderer();

  test('same descriptor renders identical pixels', () async {
    final visual = _visual(visualSeed: 99);

    final first = await _render(renderer, visual);
    final second = await _render(renderer, visual);

    expect(first, orderedEquals(second));
  });

  test('seed, materials, construction, and rotation affect output', () async {
    final baseline = await _render(renderer, _visual(visualSeed: 99));
    final changedSeed = await _render(renderer, _visual(visualSeed: 101));
    final changedWeather = await _render(
      renderer,
      _visual(visualSeed: 99, weatherKind: WeatherMaterialKind.warm),
    );
    final changedTime = await _render(
      renderer,
      _visual(visualSeed: 99, timeBand: TimeBand.night),
    );
    final noSurroundings = await _render(
      renderer,
      _visual(visualSeed: 99, surroundingKind: null),
    );
    final construction = await _render(
      renderer,
      _visual(visualSeed: 99, completion: 0.4),
    );
    final stairs = _visual(kind: ObjectKind.stairs, visualSeed: 99);
    final stairsNorth = await _render(renderer, stairs);
    final stairsEast = await _render(renderer, stairs, rotation: 1);

    expect(changedSeed, isNot(orderedEquals(baseline)));
    expect(changedWeather, isNot(orderedEquals(baseline)));
    expect(changedTime, isNot(orderedEquals(baseline)));
    expect(noSurroundings, isNot(orderedEquals(baseline)));
    expect(construction, isNot(orderedEquals(baseline)));
    expect(stairsEast, isNot(orderedEquals(stairsNorth)));
  });

  test('legacy v1 keeps its pre-seeded geometry and palette', () async {
    final first = await _render(
      renderer,
      _visual(
        visualSeed: 1,
        timeBand: TimeBand.dawn,
        generatorVersion: legacyObjectGeneratorVersion,
      ),
    );
    final second = await _render(
      renderer,
      _visual(
        visualSeed: 999,
        timeBand: TimeBand.night,
        generatorVersion: legacyObjectGeneratorVersion,
      ),
    );

    expect(second, orderedEquals(first));
  });

  test('every object kind renders inside the shared preview surface', () async {
    for (final kind in ObjectKind.values) {
      final bytes = await _render(renderer, _visual(kind: kind));
      expect(bytes, hasLength(96 * 104 * 4), reason: kind.name);
      expect(bytes.any((int value) => value != 0), isTrue, reason: kind.name);
    }
  });
}

ObjectVisualDescriptor _visual({
  ObjectKind kind = ObjectKind.alleyLamp,
  WeatherMaterialKind? weatherKind = WeatherMaterialKind.rain,
  TimeBand? timeBand = TimeBand.evening,
  SurroundingMaterialKind? surroundingKind = SurroundingMaterialKind.dynamic,
  int visualSeed = 99,
  double completion = 1,
  String generatorVersion = 'test-v1',
}) => ObjectVisualDescriptor(
  kind: kind,
  weatherKind: weatherKind,
  timeBand: timeBand,
  surroundingKind: surroundingKind,
  visualSeed: visualSeed,
  generatorVersion: generatorVersion,
  completion: completion,
);

Future<Uint8List> _render(
  DeterministicObjectRenderer renderer,
  ObjectVisualDescriptor visual, {
  int rotation = 0,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  renderer.paintFitted(
    canvas,
    const Size(96, 104),
    visual: visual,
    rotation: rotation,
  );
  final image = await recorder.endRecording().toImage(96, 104);
  final data = await image.toByteData(format: ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}
