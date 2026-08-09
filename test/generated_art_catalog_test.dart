import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/enums.dart';

void main() {
  test('generated art paths cover every runtime enum and visitor', () {
    final visitorDocument =
        jsonDecode(File('assets/content/visitors.json').readAsStringSync())
            as Map<String, Object?>;
    final visitorIds = (visitorDocument['visitors']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map((visitor) => visitor['id']! as String);
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
      for (final id in visitorIds) GeneratedArtPaths.visitor(id),
    };

    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
