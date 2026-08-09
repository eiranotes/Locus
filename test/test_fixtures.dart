import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

BalanceDefinition testBalance() => const BalanceDefinition(
  weatherCooldownMinutes: 120,
  weatherMinimumMinutes: 30,
  surroundingCooldownMinutes: 60,
  surroundingMinimumMinutes: 20,
  surroundingDistanceTriggerMeters: 300,
  surroundingScanSeconds: 8,
  surroundingConfidenceThreshold: 0.60,
  fallbackDailySteps: 2000,
  gridColumns: 5,
  gridRows: 5,
  activeObjectLimit: 8,
  repeatVisitorCooldownHours: 6,
);

WeatherMaterial testWeather({
  String id = 'weather-1',
  WeatherMaterialKind kind = WeatherMaterialKind.rain,
  TimeBand timeBand = TimeBand.evening,
  List<AtmosphericTrait> atmosphericTraits = const <AtmosphericTrait>[],
  String traitSchemaVersion = 'weather-traits-v1',
  DateTime? capturedAt,
}) => WeatherMaterial(
  id: id,
  kind: kind,
  timeBand: timeBand,
  season: Season.summer,
  capturedAt: capturedAt ?? DateTime.utc(2026, 8, 8, 18),
  coarseCellId: '37.54:127.05',
  sourceRecordId: 'capture-$id',
  visualSeed: 42,
  providerName: 'Test Weather',
  atmosphericTraits: atmosphericTraits,
  traitSchemaVersion: traitSchemaVersion,
);

SurroundingMaterial testSurrounding({
  String id = 'surrounding-1',
  SurroundingMaterialKind kind = SurroundingMaterialKind.dynamic,
  DateTime? capturedAt,
}) => SurroundingMaterial(
  id: id,
  kind: kind,
  confidence: 0.86,
  capturedAt: capturedAt ?? DateTime.utc(2026, 8, 8, 18),
  coarseCellId: '37.54:127.05',
  sourceRecordId: 'capture-$id',
  featureSchemaVersion: 'test-v1',
);

RecipeDefinition testRecipe({
  String id = 'alley-lamp',
  ObjectKind kind = ObjectKind.alleyLamp,
  int stepCost = 1500,
  int width = 1,
  int height = 1,
  HeightBand heightBand = HeightBand.low,
  Set<String> tags = const <String>{'light'},
  Map<String, int> effects = const <String, int>{'light': 1},
  Set<AtmosphericTrait> traitAffinities = const <AtmosphericTrait>{},
}) => RecipeDefinition(
  id: id,
  kind: kind,
  nameKo: '테스트 물건',
  descriptionKo: '테스트 설명',
  stepCost: stepCost,
  footprint: Footprint(width: width, height: height),
  height: heightBand,
  initiallyUnlocked: true,
  tags: tags,
  baseEffects: effects,
  traitAffinities: traitAffinities,
);

CraftedObject testObject({
  String id = 'object-1',
  String recipeId = 'alley-lamp',
  ObjectKind kind = ObjectKind.alleyLamp,
  WeatherMaterialKind weatherKind = WeatherMaterialKind.rain,
  SurroundingMaterialKind? surroundingKind = SurroundingMaterialKind.dynamic,
  int requiredSteps = 1500,
  int appliedSteps = 1500,
  AtmosphericTrait? focusTrait,
  String? variantKey,
}) => CraftedObject(
  id: id,
  recipeId: recipeId,
  kind: kind,
  weatherMaterialId: 'weather-$id',
  weatherKind: weatherKind,
  surroundingMaterialId: surroundingKind == null ? null : 'surrounding-$id',
  surroundingKind: surroundingKind,
  requiredSteps: requiredSteps,
  appliedSteps: appliedSteps,
  lifecycle: appliedSteps >= requiredSteps
      ? ObjectLifecycle.placed
      : ObjectLifecycle.building,
  visualSeed: 99,
  generatorVersion: 'test-v1',
  createdAt: DateTime.utc(2026, 8, 8),
  focusTrait: focusTrait,
  variantKey:
      variantKey ??
      (focusTrait == null ? 'base' : 'weather-trait-v1/${focusTrait.name}'),
);
