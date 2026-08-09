import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/enums.dart';

void main() {
  test('generated art paths cover every runtime enum and visitor', () {
    final paths = <String>{
      for (final kind in ObjectKind.values) GeneratedArtPaths.object(kind),
      for (final kind in WeatherMaterialKind.values)
        GeneratedArtPaths.weatherMaterial(kind),
      for (final kind in SurroundingMaterialKind.values)
        GeneratedArtPaths.surroundingMaterial(kind),
      for (final kind in WeatherMaterialKind.values)
        GeneratedArtPaths.weatherOverlay(kind),
      for (final timeBand in TimeBand.values)
        GeneratedArtPaths.timeOverlay(timeBand),
      for (final id in const <String>[
        'umbrella_walker',
        'night_moth',
        'roof_bird',
        'fog_cat',
        'transfer_guest',
        'light_swarm',
      ])
        GeneratedArtPaths.visitor(id),
    };

    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
