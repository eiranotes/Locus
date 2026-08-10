import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/diorama_game.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

void main() {
  test('rain advances in stepped pixel frames', () {
    expect(rainAnimationFrame(0, reduceMotion: false), 0);
    expect(rainAnimationFrame(0.124, reduceMotion: false), 0);
    expect(rainAnimationFrame(0.125, reduceMotion: false), 1);
    expect(rainAnimationFrame(1, reduceMotion: false), 0);
    expect(rainAnimationFrame(5, reduceMotion: true), 0);
  });

  test('rain painting changes by frame and stops for reduced motion', () async {
    final snapshot = _withRain(DioramaSnapshot.empty());
    final first = await _render(snapshot, elapsed: 0);
    final second = await _render(snapshot, elapsed: 0.25);
    final reducedFirst = await _render(
      snapshot,
      elapsed: 0,
      reduceMotion: true,
    );
    final reducedSecond = await _render(
      snapshot,
      elapsed: 0.75,
      reduceMotion: true,
    );

    expect(listEquals(first, second), isFalse);
    expect(listEquals(reducedFirst, reducedSecond), isTrue);
  });
}

DioramaSnapshot _withRain(DioramaSnapshot snapshot) => DioramaSnapshot(
  objects: snapshot.objects,
  placements: snapshot.placements,
  recipesById: snapshot.recipesById,
  weatherMaterialsById: snapshot.weatherMaterialsById,
  environmentGrid: snapshot.environmentGrid,
  connectionGraph: snapshot.connectionGraph,
  timeBand: snapshot.timeBand,
  weatherKind: WeatherMaterialKind.rain,
  visitorEvaluations: snapshot.visitorEvaluations,
  placementCatalog: snapshot.placementCatalog,
  visualLayerCatalog: snapshot.visualLayerCatalog,
  atmosphericTraitCatalog: snapshot.atmosphericTraitCatalog,
);

Future<Uint8List> _render(
  DioramaSnapshot snapshot, {
  required double elapsed,
  bool reduceMotion = false,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  DioramaScenePainter(
    snapshot,
    weatherElapsed: elapsed,
    reduceMotion: reduceMotion,
  ).paint(canvas, const Size(360, 360));
  final image = await recorder.endRecording().toImage(360, 360);
  final data = await image.toByteData(format: ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}
