import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/crafting_engine.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/enums.dart';

import 'test_fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8, 18);

  test('crafting consumes materials and starts construction when short', () {
    final weather = testWeather(
      atmosphericTraits: const <AtmosphericTrait>[
        AtmosphericTrait.strongWind,
        AtmosphericTrait.deepCloud,
      ],
    );
    final recipe = testRecipe(
      stepCost: 1500,
      traitAffinities: const <AtmosphericTrait>{AtmosphericTrait.deepCloud},
    );
    final result = const CraftingEngine().start(
      objectId: 'object-1',
      recipe: recipe,
      weather: weather,
      surrounding: testSurrounding(),
      stepBuckets: <StepBucket>[
        StepBucket(
          dayKey: '2026-08-08',
          observedSteps: 900,
          spentSteps: 0,
          lastSyncedAt: now,
        ),
      ],
      now: now,
      focusTrait: AtmosphericTrait.deepCloud,
    );
    expect(result.object.lifecycle, ObjectLifecycle.building);
    expect(result.object.appliedSteps, 900);
    expect(result.object.remainingSteps, 600);
    expect(result.object.focusTrait, AtmosphericTrait.deepCloud);
    expect(result.object.variantKey, 'weather-trait-v1/deepCloud');
    expect(result.weatherMaterial.isAvailable, isFalse);
    expect(result.surroundingMaterial?.isAvailable, isFalse);
  });

  test('placement rejects overlaps and respects rotation', () {
    const engine = PlacementEngine(columns: 5, rows: 5);
    final wide = testRecipe(width: 2, height: 1);
    final existing = Placement(
      id: 'placement-a',
      craftedObjectId: 'object-a',
      column: 1,
      row: 1,
      rotation: 0,
    );
    final overlap = Placement(
      id: 'placement-b',
      craftedObjectId: 'object-b',
      column: 2,
      row: 1,
      rotation: 1,
    );
    final validation = engine.validate(
      candidate: overlap,
      recipe: wide,
      existing: <Placement>[existing],
      recipeByObjectId: <String, RecipeDefinition>{'object-a': wide},
    );
    expect(validation.valid, isFalse);
  });

  test('crafting rejects a trace outside the recipe affinity catalog', () {
    expect(
      () => const CraftingEngine().start(
        objectId: 'object-invalid',
        recipe: testRecipe(),
        weather: testWeather(
          atmosphericTraits: const <AtmosphericTrait>[
            AtmosphericTrait.strongWind,
          ],
        ),
        stepBuckets: const <StepBucket>[],
        now: now,
        focusTrait: AtmosphericTrait.strongWind,
      ),
      throwsStateError,
    );
  });
}
