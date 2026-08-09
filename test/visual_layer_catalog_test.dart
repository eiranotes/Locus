import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/visual_layer_catalog.dart';

void main() {
  final document =
      jsonDecode(
            File('assets/content/visual_layer_catalog.json').readAsStringSync(),
          )
          as Map<String, Object?>;
  final catalog = VisualLayerCatalog.fromJson(document);

  test('visual layer catalog covers every bounded weather treatment', () {
    catalog.validate();
    expect(catalog.weather, hasLength(WeatherMaterialKind.values.length));

    for (final kind in WeatherMaterialKind.values) {
      final value = catalog.forWeather(kind);
      expect(File(value.surfacePatternPath).existsSync(), isTrue);
      expect(File(value.footprintEffectPath).existsSync(), isTrue);
      expect(value.surfaceOpacity, inInclusiveRange(0.01, 1));
    }
  });
}
