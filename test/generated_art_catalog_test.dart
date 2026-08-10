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
      for (final name in const <String>[
        'pebbles',
        'moss',
        'grass_blades',
        'clover',
        'mushrooms',
        'autumn_leaves',
        'wildflowers',
        'twig',
        'fern',
        'drain_grate',
        'cracked_cobble',
        'chalk_star',
        'puddle_glint',
        'wet_leaf',
        'snow_tuft',
        'dry_weed',
        'acorns',
        'flower_petals',
        'stepping_marks',
        'crack_grass',
      ])
        GeneratedArtPaths.terrainDetail(name),
      for (final name in const <String>[
        'rain_ripples',
        'mist_wisp',
        'frost_sparkles',
        'warm_motes',
        'wind_leaves',
        'dawn_sparkle',
        'morning_rays',
        'evening_windows',
        'night_moths',
        'falling_raindrops',
      ])
        GeneratedArtPaths.atmosphereDetail(name),
      for (final name in const <String>[
        'valid_target',
        'selected_target',
        'invalid_target',
        'grab_hand',
        'place_chevron',
        'arrow_left',
        'arrow_up',
        'arrow_down',
        'arrow_right',
        'rotate',
      ])
        GeneratedArtPaths.editorMarker(name),
      for (final name in const <String>[
        'capture',
        'craft',
        'place',
        'rotate',
        'store',
        'weather',
        'surroundings',
        'visitor',
        'codex',
        'settings',
      ])
        GeneratedArtPaths.action(name),
    };

    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('scene/UI ImageGen package contains 50 distinct runtime assets', () {
    final manifest =
        jsonDecode(
              File(
                'artifacts/imagegen/locus-scene-ui-v1/manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final assets = (manifest['assets']! as List<Object?>)
        .cast<Map<String, Object?>>();

    expect(assets, hasLength(50));
    expect(assets.map((item) => item['sha256']).toSet(), hasLength(50));
    expect(assets.map((item) => item['category']).toSet(), <Object?>{
      'terrain',
      'atmosphere',
      'editor',
      'action',
    });
  });
}
