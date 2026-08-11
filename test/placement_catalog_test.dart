import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';

void main() {
  final recipeDocument =
      jsonDecode(File('assets/content/recipes.json').readAsStringSync())
          as Map<String, Object?>;
  final recipes = (recipeDocument['recipes']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(RecipeDefinition.fromJson)
      .toList(growable: false);
  final placementDocument =
      jsonDecode(
            File('assets/content/placement_catalog.json').readAsStringSync(),
          )
          as Map<String, Object?>;
  final catalog = PlacementCatalog.fromJson(placementDocument);

  test('placement catalog covers every recipe and directional asset', () {
    catalog.validateRecipes(recipes);
    expect(catalog.directions.map((value) => value.rotation), <int>[
      0,
      1,
      2,
      3,
    ]);

    for (final recipe in recipes) {
      final entry = catalog.entryForRecipe(recipe.id);
      expect(entry.allowedRotations, <int>{0, 1, 2, 3}, reason: recipe.id);
      final directionalPaths = <String>{};
      for (var rotation = 0; rotation < 4; rotation += 1) {
        final visual = entry.visualFor(rotation);
        expect(File(visual.assetPath).existsSync(), isTrue);
        expect(visual.mirrorX, isFalse, reason: '${recipe.id}:$rotation');
        expect(visual.assetPath, endsWith('_r$rotation.png'));
        directionalPaths.add(visual.assetPath);
        expect(catalog.directionFor(rotation).labelKo, isNotEmpty);
      }
      expect(directionalPaths, hasLength(4), reason: recipe.id);
    }
  });

  test(
    'directional sprites keep a stable bottom-center ground anchor',
    () async {
      for (final entry in catalog.entries) {
        for (final visual in entry.visuals) {
          final codec = await ui.instantiateImageCodec(
            await File(visual.assetPath).readAsBytes(),
          );
          final frame = await codec.getNextFrame();
          codec.dispose();
          final image = frame.image;
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          expect(bytes, isNotNull, reason: visual.assetPath);
          final rgba = bytes!.buffer.asUint8List();
          var minX = image.width;
          var maxX = -1;
          var maxY = -1;
          for (var y = 0; y < image.height; y += 1) {
            for (var x = 0; x < image.width; x += 1) {
              final alpha = rgba[(y * image.width + x) * 4 + 3];
              if (alpha == 0) continue;
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
            }
          }
          image.dispose();

          expect(
            maxY,
            255,
            reason: '${visual.assetPath} must touch its anchor',
          );
          expect(
            (minX + maxX) / 2,
            closeTo(127.5, 6.5),
            reason: '${visual.assetPath} must stay centered on its anchor',
          );
        }
      }
    },
  );

  test('every recipe fits, rotates, and rejects every out-of-bounds edge', () {
    const engine = PlacementEngine(columns: 5, rows: 5);
    for (final recipe in recipes) {
      final entry = catalog.entryForRecipe(recipe.id);
      for (var rotation = 0; rotation < 4; rotation += 1) {
        final footprint = engine.rotatedFootprint(
          footprint: recipe.footprint,
          rotation: rotation,
        );
        final candidate = Placement(
          id: 'candidate-${recipe.id}-$rotation',
          craftedObjectId: 'object-${recipe.id}',
          column: 0,
          row: 0,
          rotation: rotation,
        );
        final anchors = engine.validAnchors(
          candidate: candidate,
          recipe: recipe,
          existing: const <Placement>[],
          recipeByObjectId: const <String, RecipeDefinition>{},
          allowedRotations: entry.allowedRotations,
        );
        expect(
          anchors.length,
          (6 - footprint.width) * (6 - footprint.height),
          reason: '${recipe.id}:$rotation',
        );
        expect(
          engine
              .occupiedCells(placement: candidate, footprint: recipe.footprint)
              .length,
          recipe.footprint.width * recipe.footprint.height,
        );

        final lastValid = candidate.copyWith(
          column: 5 - footprint.width,
          row: 5 - footprint.height,
        );
        expect(
          engine
              .validate(
                candidate: lastValid,
                recipe: recipe,
                existing: const <Placement>[],
                recipeByObjectId: const <String, RecipeDefinition>{},
                allowedRotations: entry.allowedRotations,
              )
              .valid,
          isTrue,
        );
        for (final outside in <Placement>[
          candidate.copyWith(column: -1),
          candidate.copyWith(row: -1),
          lastValid.copyWith(column: lastValid.column + 1),
          lastValid.copyWith(row: lastValid.row + 1),
        ]) {
          expect(
            engine
                .validate(
                  candidate: outside,
                  recipe: recipe,
                  existing: const <Placement>[],
                  recipeByObjectId: const <String, RecipeDefinition>{},
                  allowedRotations: entry.allowedRotations,
                )
                .valid,
            isFalse,
            reason: '${recipe.id}:$rotation $outside',
          );
        }
      }
    }
  });

  test('collision and unsupported direction fail without mutating state', () {
    const engine = PlacementEngine(columns: 5, rows: 5);
    final recipe = recipes.first;
    const existing = Placement(
      id: 'existing',
      craftedObjectId: 'existing-object',
      column: 2,
      row: 2,
      rotation: 0,
    );
    const candidate = Placement(
      id: 'candidate',
      craftedObjectId: 'candidate-object',
      column: 2,
      row: 2,
      rotation: 1,
    );
    final occupiedBefore = engine.occupiedCells(
      placement: existing,
      footprint: recipe.footprint,
    );

    expect(
      engine
          .validate(
            candidate: candidate,
            recipe: recipe,
            existing: const <Placement>[existing],
            recipeByObjectId: <String, RecipeDefinition>{
              existing.craftedObjectId: recipe,
            },
          )
          .message,
      '다른 물건과 겹칩니다.',
    );
    expect(
      engine
          .validate(
            candidate: candidate,
            recipe: recipe,
            existing: const <Placement>[],
            recipeByObjectId: const <String, RecipeDefinition>{},
            allowedRotations: const <int>{0, 2},
          )
          .message,
      '이 물건이 지원하지 않는 방향입니다.',
    );
    expect(
      engine.occupiedCells(placement: existing, footprint: recipe.footprint),
      occupiedBefore,
    );
    expect(normalizeQuarterTurns(-1), 3);
    expect(normalizeQuarterTurns(5), 1);
  });

  test('first valid anchor is deterministic and skips occupied cells', () {
    const engine = PlacementEngine(columns: 5, rows: 5);
    final oneCell = recipes.firstWhere(
      (RecipeDefinition recipe) => recipe.id == 'alley_lamp',
    );
    final stairs = recipes.firstWhere(
      (RecipeDefinition recipe) => recipe.id == 'stairs',
    );
    const occupied = Placement(
      id: 'occupied',
      craftedObjectId: 'lamp-object',
      column: 0,
      row: 0,
      rotation: 0,
    );
    const candidate = Placement(
      id: 'candidate',
      craftedObjectId: 'stairs-object',
      column: 0,
      row: 0,
      rotation: 1,
    );

    final anchor = engine.firstValidAnchor(
      candidate: candidate,
      recipe: stairs,
      existing: const <Placement>[occupied],
      recipeByObjectId: <String, RecipeDefinition>{
        occupied.craftedObjectId: oneCell,
      },
      allowedRotations: catalog.entryForRecipe(stairs.id).allowedRotations,
    );

    expect(anchor, isNotNull);
    expect(anchor!.column, 1);
    expect(anchor.row, 0);
  });
}
