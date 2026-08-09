part of 'entities.dart';

class StepBucket {
  const StepBucket({
    required this.dayKey,
    required this.observedSteps,
    required this.spentSteps,
    required this.lastSyncedAt,
  });

  final String dayKey;
  final int observedSteps;
  final int spentSteps;
  final DateTime lastSyncedAt;

  int get available => (observedSteps - spentSteps).clamp(0, 1 << 31).toInt();

  StepBucket copyWith({
    int? observedSteps,
    int? spentSteps,
    DateTime? lastSyncedAt,
  }) => StepBucket(
    dayKey: dayKey,
    observedSteps: observedSteps ?? this.observedSteps,
    spentSteps: spentSteps ?? this.spentSteps,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'day_key': dayKey,
    'observed_steps': observedSteps,
    'spent_steps': spentSteps,
    'last_synced_at': lastSyncedAt.millisecondsSinceEpoch,
  };

  factory StepBucket.fromMap(Map<String, Object?> map) => StepBucket(
    dayKey: map['day_key']! as String,
    observedSteps: map['observed_steps']! as int,
    spentSteps: map['spent_steps']! as int,
    lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(
      map['last_synced_at']! as int,
    ),
  );
}

class Footprint {
  const Footprint({required this.width, required this.height});

  final int width;
  final int height;

  factory Footprint.fromJson(Map<String, Object?> json) =>
      Footprint(width: json['width']! as int, height: json['height']! as int);
}

class RecipeDefinition {
  const RecipeDefinition({
    required this.id,
    required this.kind,
    required this.nameKo,
    required this.descriptionKo,
    required this.stepCost,
    required this.footprint,
    required this.height,
    required this.initiallyUnlocked,
    required this.tags,
    required this.baseEffects,
    this.traitAffinities = const <AtmosphericTrait>{},
  });

  final String id;
  final ObjectKind kind;
  final String nameKo;
  final String descriptionKo;
  final int stepCost;
  final Footprint footprint;
  final HeightBand height;
  final bool initiallyUnlocked;
  final Set<String> tags;
  final Map<String, int> baseEffects;
  final Set<AtmosphericTrait> traitAffinities;

  factory RecipeDefinition.fromJson(Map<String, Object?> json) {
    final rawEffects = json['baseEffects']! as Map<String, Object?>;
    return RecipeDefinition(
      id: json['id']! as String,
      kind: enumByName(
        ObjectKind.values,
        json['kind']! as String,
        ObjectKind.alleyLamp,
      ),
      nameKo: json['nameKo']! as String,
      descriptionKo: json['descriptionKo']! as String,
      stepCost: json['stepCost']! as int,
      footprint: Footprint.fromJson(json['footprint']! as Map<String, Object?>),
      height: enumByName(
        HeightBand.values,
        json['height']! as String,
        HeightBand.low,
      ),
      initiallyUnlocked: json['initiallyUnlocked']! as bool,
      tags: (json['tags']! as List<Object?>).cast<String>().toSet(),
      baseEffects: rawEffects.map(
        (String key, Object? value) =>
            MapEntry<String, int>(key, value! as int),
      ),
      traitAffinities:
          ((json['traitAffinities'] as List<Object?>?) ?? const <Object?>[])
              .whereType<String>()
              .map(AtmosphericTrait.values.byName)
              .toSet(),
    );
  }
}

class CraftedObject {
  const CraftedObject({
    required this.id,
    required this.recipeId,
    required this.kind,
    required this.weatherMaterialId,
    required this.weatherKind,
    required this.requiredSteps,
    required this.appliedSteps,
    required this.lifecycle,
    required this.visualSeed,
    required this.generatorVersion,
    required this.createdAt,
    this.focusTrait,
    this.variantKey = 'base',
    this.surroundingMaterialId,
    this.surroundingKind,
  });

  final String id;
  final String recipeId;
  final ObjectKind kind;
  final String weatherMaterialId;
  final WeatherMaterialKind weatherKind;
  final String? surroundingMaterialId;
  final SurroundingMaterialKind? surroundingKind;
  final int requiredSteps;
  final int appliedSteps;
  final ObjectLifecycle lifecycle;
  final int visualSeed;
  final String generatorVersion;
  final DateTime createdAt;
  final AtmosphericTrait? focusTrait;
  final String variantKey;

  int get remainingSteps =>
      (requiredSteps - appliedSteps).clamp(0, 1 << 31).toInt();
  bool get isComplete => remainingSteps == 0;

  CraftedObject copyWith({int? appliedSteps, ObjectLifecycle? lifecycle}) =>
      CraftedObject(
        id: id,
        recipeId: recipeId,
        kind: kind,
        weatherMaterialId: weatherMaterialId,
        weatherKind: weatherKind,
        surroundingMaterialId: surroundingMaterialId,
        surroundingKind: surroundingKind,
        requiredSteps: requiredSteps,
        appliedSteps: appliedSteps ?? this.appliedSteps,
        lifecycle: lifecycle ?? this.lifecycle,
        visualSeed: visualSeed,
        generatorVersion: generatorVersion,
        createdAt: createdAt,
        focusTrait: focusTrait,
        variantKey: variantKey,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'recipe_id': recipeId,
    'kind': kind.name,
    'weather_material_id': weatherMaterialId,
    'weather_kind': weatherKind.name,
    'surrounding_material_id': surroundingMaterialId,
    'surrounding_kind': surroundingKind?.name,
    'required_steps': requiredSteps,
    'applied_steps': appliedSteps,
    'lifecycle': lifecycle.name,
    'visual_seed': visualSeed,
    'generator_version': generatorVersion,
    'created_at': createdAt.millisecondsSinceEpoch,
    'focus_trait': focusTrait?.name,
    'variant_key': variantKey,
  };

  factory CraftedObject.fromMap(Map<String, Object?> map) => CraftedObject(
    id: map['id']! as String,
    recipeId: map['recipe_id']! as String,
    kind: enumByName(
      ObjectKind.values,
      map['kind']! as String,
      ObjectKind.alleyLamp,
    ),
    weatherMaterialId: map['weather_material_id']! as String,
    weatherKind: enumByName(
      WeatherMaterialKind.values,
      map['weather_kind']! as String,
      WeatherMaterialKind.cloudy,
    ),
    surroundingMaterialId: map['surrounding_material_id'] as String?,
    surroundingKind: map['surrounding_kind'] == null
        ? null
        : enumByName(
            SurroundingMaterialKind.values,
            map['surrounding_kind']! as String,
            SurroundingMaterialKind.sparse,
          ),
    requiredSteps: map['required_steps']! as int,
    appliedSteps: map['applied_steps']! as int,
    lifecycle: enumByName(
      ObjectLifecycle.values,
      map['lifecycle']! as String,
      ObjectLifecycle.stored,
    ),
    visualSeed: map['visual_seed']! as int,
    generatorVersion: map['generator_version']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    focusTrait: _decodeAtmosphericTrait(map['focus_trait']),
    variantKey: map['variant_key'] as String? ?? 'base',
  );
}

class Placement {
  const Placement({
    required this.id,
    required this.craftedObjectId,
    required this.column,
    required this.row,
    required this.rotation,
  });

  final String id;
  final String craftedObjectId;
  final int column;
  final int row;
  final int rotation;

  Placement copyWith({int? column, int? row, int? rotation}) => Placement(
    id: id,
    craftedObjectId: craftedObjectId,
    column: column ?? this.column,
    row: row ?? this.row,
    rotation: rotation ?? this.rotation,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'crafted_object_id': craftedObjectId,
    'column_index': column,
    'row_index': row,
    'rotation': rotation,
  };

  factory Placement.fromMap(Map<String, Object?> map) => Placement(
    id: map['id']! as String,
    craftedObjectId: map['crafted_object_id']! as String,
    column: map['column_index']! as int,
    row: map['row_index']! as int,
    rotation: map['rotation']! as int,
  );
}
