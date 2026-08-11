import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

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

  test('catalog directions render distinct production sprites', () async {
    final northeast = await _decodeSprite(
      'assets/art/generated/v1/directional/object_bus_stop_r0.png',
    );
    final southeast = await _decodeSprite(
      'assets/art/generated/v1/directional/object_bus_stop_r1.png',
    );
    final firstDirection = await _render(
      renderer,
      _visual(kind: ObjectKind.busStop),
      sprite: northeast,
    );
    final secondDirection = await _render(
      renderer,
      _visual(kind: ObjectKind.busStop),
      sprite: southeast,
    );
    northeast.dispose();
    southeast.dispose();

    expect(secondDirection, isNot(orderedEquals(firstDirection)));
  });

  test('v3 alpha-clips weather surface without a footprint halo', () async {
    final sprite = await _decodeSprite(
      'assets/art/generated/v1/directional/object_alley_lamp_r0.png',
    );
    final surface = await _decodeSprite(
      'assets/art/generated/v1/weather/surface_rain.png',
    );
    final visual = _visual(
      generatorVersion: currentObjectGeneratorVersion,
      focusTrait: AtmosphericTrait.activePrecipitation,
    );
    final plain = await _render(renderer, visual, sprite: sprite);
    final layered = await _render(
      renderer,
      visual,
      sprite: sprite,
      surfacePattern: surface,
      surfaceOpacity: 0.5,
    );
    final cleanEditor = await _render(
      renderer,
      visual,
      sprite: sprite,
      surfacePattern: surface,
      surfaceOpacity: 0.5,
      showContextEffects: false,
    );
    sprite.dispose();
    surface.dispose();

    expect(layered, isNot(orderedEquals(plain)));
    expect(cleanEditor, isNot(orderedEquals(layered)));
  });

  test('sprite bounds and fitted preview share one bottom-center anchor', () {
    const anchor = Offset(180, 220);
    for (final kind in ObjectKind.values) {
      final bounds = DeterministicObjectRenderer.spriteBoundsAt(anchor, kind);
      expect(bounds.bottom, anchor.dy, reason: kind.name);
      expect(bounds.center.dx, anchor.dx, reason: kind.name);
    }

    const previewSize = Size(82, 92);
    final fittedAnchor = DeterministicObjectRenderer.previewAnchorIn(
      previewSize,
    );
    expect(fittedAnchor.dx, closeTo(41, 0.01));
    expect(fittedAnchor.dy, closeTo(79.3125, 0.001));
  });
}

Future<Image> _decodeSprite(String path) async {
  final codec = await instantiateImageCodec(await File(path).readAsBytes());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

ObjectVisualDescriptor _visual({
  ObjectKind kind = ObjectKind.alleyLamp,
  WeatherMaterialKind? weatherKind = WeatherMaterialKind.rain,
  TimeBand? timeBand = TimeBand.evening,
  SurroundingMaterialKind? surroundingKind = SurroundingMaterialKind.dynamic,
  int visualSeed = 99,
  double completion = 1,
  String generatorVersion = 'test-v1',
  AtmosphericTrait? focusTrait,
}) => ObjectVisualDescriptor(
  kind: kind,
  weatherKind: weatherKind,
  timeBand: timeBand,
  surroundingKind: surroundingKind,
  visualSeed: visualSeed,
  generatorVersion: generatorVersion,
  completion: completion,
  focusTrait: focusTrait,
  variantKey: focusTrait == null
      ? 'base'
      : 'weather-trait-v1/${focusTrait.name}',
);

Future<Uint8List> _render(
  DeterministicObjectRenderer renderer,
  ObjectVisualDescriptor visual, {
  int rotation = 0,
  Image? sprite,
  bool spriteMirrorX = false,
  Image? surfacePattern,
  double surfaceOpacity = 0,
  bool showContextEffects = true,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  renderer.paintFitted(
    canvas,
    const Size(96, 104),
    visual: visual,
    rotation: rotation,
    sprite: sprite,
    spriteMirrorX: spriteMirrorX,
    surfacePattern: surfacePattern,
    surfaceOpacity: surfaceOpacity,
    showContextEffects: showContextEffects,
  );
  final image = await recorder.endRecording().toImage(96, 104);
  final data = await image.toByteData(format: ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}
