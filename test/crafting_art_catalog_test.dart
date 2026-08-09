import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/crafting_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';

void main() {
  final recipeDocument =
      jsonDecode(File('assets/content/recipes.json').readAsStringSync())
          as Map<String, Object?>;
  final recipes = (recipeDocument['recipes']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(RecipeDefinition.fromJson)
      .toList(growable: false);
  final artDocument =
      jsonDecode(
            File('assets/content/crafting_art_catalog.json').readAsStringSync(),
          )
          as Map<String, Object?>;
  final catalog = CraftingArtCatalog.fromJson(artDocument);

  test('crafting art catalog covers every recipe and stage asset', () {
    catalog.validateRecipes(recipes);
    expect(catalog.entries, hasLength(recipes.length));

    for (final recipe in recipes) {
      final entry = catalog.entryForRecipe(recipe.id);
      expect(
        entry.construction.map((ConstructionArtStage value) => value.stage),
        <String>['foundation', 'frame', 'finish'],
        reason: recipe.id,
      );
      for (final stage in entry.construction) {
        expect(
          File(stage.assetPath).existsSync(),
          isTrue,
          reason: stage.assetPath,
        );
      }
    }
  });

  test('construction completion resolves to a bounded authored stage', () {
    final entry = catalog.entryForRecipe('alley_lamp');

    expect(entry.stageFor(0)?.stage, 'foundation');
    expect(entry.stageFor(0.34)?.stage, 'foundation');
    expect(entry.stageFor(0.35)?.stage, 'frame');
    expect(entry.stageFor(0.72)?.stage, 'frame');
    expect(entry.stageFor(0.73)?.stage, 'finish');
    expect(entry.stageFor(0.999)?.stage, 'finish');
    expect(entry.stageFor(1), isNull);
  });
}
