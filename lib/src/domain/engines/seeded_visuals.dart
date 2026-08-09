import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

const String legacyObjectGeneratorVersion = 'object-v1';
const String currentObjectGeneratorVersion = 'object-v2';

int stableSeed(Iterable<Object?> parts) {
  var hash = 0x811c9dc5;
  for (final part in parts) {
    final text = part?.toString() ?? 'null';
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    hash ^= 0xff;
  }
  return hash & 0x7fffffff;
}

int objectVisualSeedForCraft({
  required RecipeDefinition recipe,
  required WeatherMaterial weather,
  SurroundingMaterial? surrounding,
  String generatorVersion = currentObjectGeneratorVersion,
}) => stableSeed(<Object?>[
  recipe.id,
  weather.id,
  surrounding?.id,
  weather.capturedAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute,
  generatorVersion,
]);

final class ObjectVisualDescriptor {
  const ObjectVisualDescriptor({
    required this.kind,
    required this.weatherKind,
    required this.timeBand,
    required this.surroundingKind,
    required this.visualSeed,
    required this.generatorVersion,
    required this.completion,
  });

  factory ObjectVisualDescriptor.fromCraftedObject(
    CraftedObject object, {
    TimeBand? timeBand,
  }) => ObjectVisualDescriptor(
    kind: object.kind,
    weatherKind: object.weatherKind,
    timeBand: timeBand,
    surroundingKind: object.surroundingKind,
    visualSeed: object.visualSeed,
    generatorVersion: object.generatorVersion,
    completion: _completionFor(object),
  );

  factory ObjectVisualDescriptor.forCraftingPreview({
    required RecipeDefinition recipe,
    required WeatherMaterial weather,
    SurroundingMaterial? surrounding,
    String generatorVersion = currentObjectGeneratorVersion,
    double completion = 1,
  }) => ObjectVisualDescriptor(
    kind: recipe.kind,
    weatherKind: weather.kind,
    timeBand: weather.timeBand,
    surroundingKind: surrounding?.kind,
    visualSeed: objectVisualSeedForCraft(
      recipe: recipe,
      weather: weather,
      surrounding: surrounding,
      generatorVersion: generatorVersion,
    ),
    generatorVersion: generatorVersion,
    completion: completion.clamp(0, 1).toDouble(),
  );

  factory ObjectVisualDescriptor.forRecipe(
    RecipeDefinition recipe, {
    String generatorVersion = currentObjectGeneratorVersion,
    double completion = 1,
  }) => ObjectVisualDescriptor(
    kind: recipe.kind,
    weatherKind: null,
    timeBand: null,
    surroundingKind: null,
    visualSeed: stableSeed(<Object?>[recipe.id, 'neutral', generatorVersion]),
    generatorVersion: generatorVersion,
    completion: completion.clamp(0, 1).toDouble(),
  );

  final ObjectKind kind;
  final WeatherMaterialKind? weatherKind;
  final TimeBand? timeBand;
  final SurroundingMaterialKind? surroundingKind;
  final int visualSeed;
  final String generatorVersion;
  final double completion;

  static double _completionFor(CraftedObject object) {
    if (object.requiredSteps <= 0) {
      return 1;
    }
    return (object.appliedSteps / object.requiredSteps).clamp(0, 1).toDouble();
  }
}
