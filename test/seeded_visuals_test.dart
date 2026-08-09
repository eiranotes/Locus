import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/crafting_engine.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';

import 'test_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 18);

  group('craft visual seed', () {
    for (final includeSurrounding in <bool>[false, true]) {
      test('preview matches the crafted object '
          '${includeSurrounding ? 'with' : 'without'} surroundings', () {
        final recipe = testRecipe();
        final weather = testWeather();
        final surrounding = includeSurrounding ? testSurrounding() : null;
        const generatorVersion = 'object-test-v2';

        final preview = ObjectVisualDescriptor.forCraftingPreview(
          recipe: recipe,
          weather: weather,
          surrounding: surrounding,
          generatorVersion: generatorVersion,
        );
        final result = const CraftingEngine(generatorVersion: generatorVersion)
            .start(
              objectId: 'object-1',
              recipe: recipe,
              weather: weather,
              surrounding: surrounding,
              stepBuckets: <StepBucket>[
                StepBucket(
                  dayKey: '2026-08-08',
                  observedSteps: recipe.stepCost,
                  spentSteps: 0,
                  lastSyncedAt: now,
                ),
              ],
              now: now,
            );

        expect(preview.visualSeed, result.object.visualSeed);
        expect(preview.generatorVersion, result.object.generatorVersion);
      });
    }

    test('the same craft inputs are deterministic', () {
      final recipe = testRecipe();
      final weather = testWeather();
      final surrounding = testSurrounding();

      final first = objectVisualSeedForCraft(
        recipe: recipe,
        weather: weather,
        surrounding: surrounding,
      );
      final second = objectVisualSeedForCraft(
        recipe: recipe,
        weather: weather,
        surrounding: surrounding,
      );

      expect(second, first);
    });
  });

  group('ObjectVisualDescriptor', () {
    test('crafted object preserves visual inputs and reports completion', () {
      final descriptor = ObjectVisualDescriptor.fromCraftedObject(
        testObject(
          kind: ObjectKind.bridge,
          weatherKind: WeatherMaterialKind.windy,
          surroundingKind: SurroundingMaterialKind.stable,
          requiredSteps: 1500,
          appliedSteps: 375,
        ),
      );

      expect(descriptor.kind, ObjectKind.bridge);
      expect(descriptor.weatherKind, WeatherMaterialKind.windy);
      expect(descriptor.timeBand, isNull);
      expect(descriptor.surroundingKind, SurroundingMaterialKind.stable);
      expect(descriptor.visualSeed, 99);
      expect(descriptor.generatorVersion, 'test-v1');
      expect(descriptor.completion, 0.25);
    });

    test('crafted completion stays within the renderable range', () {
      final overComplete = ObjectVisualDescriptor.fromCraftedObject(
        testObject(requiredSteps: 100, appliedSteps: 140),
      );
      final belowZero = ObjectVisualDescriptor.fromCraftedObject(
        testObject(requiredSteps: 100, appliedSteps: -20),
      );
      final zeroCost = ObjectVisualDescriptor.fromCraftedObject(
        testObject(requiredSteps: 0, appliedSteps: 0),
      );

      expect(overComplete.completion, 1);
      expect(belowZero.completion, 0);
      expect(zeroCost.completion, 1);
    });

    test('crafting preview carries selected material variants', () {
      final descriptor = ObjectVisualDescriptor.forCraftingPreview(
        recipe: testRecipe(kind: ObjectKind.pond),
        weather: testWeather(kind: WeatherMaterialKind.rain),
        surrounding: testSurrounding(kind: SurroundingMaterialKind.dynamic),
      );

      expect(descriptor.kind, ObjectKind.pond);
      expect(descriptor.weatherKind, WeatherMaterialKind.rain);
      expect(descriptor.timeBand, TimeBand.evening);
      expect(descriptor.surroundingKind, SurroundingMaterialKind.dynamic);
      expect(descriptor.generatorVersion, currentObjectGeneratorVersion);
      expect(descriptor.completion, 1);
    });

    test('recipe descriptor is deterministic and material-neutral', () {
      final recipe = testRecipe(kind: ObjectKind.bench);
      final first = ObjectVisualDescriptor.forRecipe(recipe);
      final second = ObjectVisualDescriptor.forRecipe(recipe);

      expect(first.kind, ObjectKind.bench);
      expect(first.weatherKind, isNull);
      expect(first.timeBand, isNull);
      expect(first.surroundingKind, isNull);
      expect(first.visualSeed, second.visualSeed);
      expect(first.generatorVersion, currentObjectGeneratorVersion);
      expect(first.completion, 1);
    });
  });
}
