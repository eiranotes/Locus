import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/engines/step_ledger.dart';

class CraftingResult {
  const CraftingResult({
    required this.object,
    required this.stepBuckets,
    required this.weatherMaterial,
    required this.surroundingMaterial,
  });

  final CraftedObject object;
  final List<StepBucket> stepBuckets;
  final WeatherMaterial weatherMaterial;
  final SurroundingMaterial? surroundingMaterial;
}

class CraftingEngine {
  const CraftingEngine({this.generatorVersion = currentObjectGeneratorVersion});

  final String generatorVersion;

  CraftingResult start({
    required String objectId,
    required RecipeDefinition recipe,
    required WeatherMaterial weather,
    required List<StepBucket> stepBuckets,
    required DateTime now,
    SurroundingMaterial? surrounding,
  }) {
    if (!weather.isAvailable) {
      throw StateError('The selected weather material is already consumed.');
    }
    if (surrounding != null && !surrounding.isAvailable) {
      throw StateError(
        'The selected surrounding material is already consumed.',
      );
    }

    const ledger = StepLedger();
    final spend = ledger.spend(stepBuckets, recipe.stepCost);
    final lifecycle = spend.unfilled == 0
        ? ObjectLifecycle.stored
        : ObjectLifecycle.building;
    final visualSeed = objectVisualSeedForCraft(
      recipe: recipe,
      weather: weather,
      surrounding: surrounding,
      generatorVersion: generatorVersion,
    );

    final object = CraftedObject(
      id: objectId,
      recipeId: recipe.id,
      kind: recipe.kind,
      weatherMaterialId: weather.id,
      weatherKind: weather.kind,
      surroundingMaterialId: surrounding?.id,
      surroundingKind: surrounding?.kind,
      requiredSteps: recipe.stepCost,
      appliedSteps: spend.spent,
      lifecycle: lifecycle,
      visualSeed: visualSeed,
      generatorVersion: generatorVersion,
      createdAt: now,
    );

    return CraftingResult(
      object: object,
      stepBuckets: spend.buckets,
      weatherMaterial: weather.consume(at: now, objectId: objectId),
      surroundingMaterial: surrounding?.consume(at: now, objectId: objectId),
    );
  }

  ({CraftedObject object, List<StepBucket> buckets}) advance({
    required CraftedObject object,
    required List<StepBucket> stepBuckets,
  }) {
    if (object.isComplete) {
      return (object: object, buckets: stepBuckets);
    }
    const ledger = StepLedger();
    final spend = ledger.spend(stepBuckets, object.remainingSteps);
    final updatedApplied = object.appliedSteps + spend.spent;
    final complete = updatedApplied >= object.requiredSteps;
    return (
      object: object.copyWith(
        appliedSteps: updatedApplied,
        lifecycle: complete ? ObjectLifecycle.stored : ObjectLifecycle.building,
      ),
      buckets: spend.buckets,
    );
  }
}
