import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/connection_graph.dart';
import 'package:reality_diorama/src/domain/engines/environment_grid.dart';
import 'package:reality_diorama/src/domain/engines/time_context.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';

class RequestFirstSceneAdapter {
  const RequestFirstSceneAdapter();

  DioramaSnapshot build({
    required DateTime now,
    required List<SceneObject> sceneObjects,
    required List<ScenePlacement> scenePlacements,
    required Map<String, VisitorRelationship> relationships,
    required RequestFirstCatalog requestCatalog,
    required ContentCatalog legacyCatalog,
  }) {
    final craftedObjects = <CraftedObject>[];
    final weatherMaterials = <String, WeatherMaterial>{};
    final recipesByObjectId = <String, RecipeDefinition>{};

    for (final sceneObject in sceneObjects) {
      final recipeId = _legacyRecipeId(
        sceneObject,
        requestCatalog: requestCatalog,
      );
      final recipe = _tryRecipe(legacyCatalog, recipeId);
      if (recipe == null) continue;
      final weatherKind = _weatherKind(sceneObject.legacyPayload);
      final weatherId = 'request-first-weather:${sceneObject.id}';
      final surroundingKind = _surroundingKind(sceneObject.legacyPayload);
      final focusTrait = _focusTrait(sceneObject.legacyPayload);
      craftedObjects.add(
        CraftedObject(
          id: sceneObject.id,
          recipeId: recipe.id,
          kind: recipe.kind,
          weatherMaterialId: weatherId,
          weatherKind: weatherKind,
          surroundingMaterialId: surroundingKind == null
              ? null
              : 'request-first-surroundings:${sceneObject.id}',
          surroundingKind: surroundingKind,
          requiredSteps: 0,
          appliedSteps: 0,
          lifecycle: sceneObject.lifecycle == SceneObjectLifecycle.placed
              ? ObjectLifecycle.placed
              : ObjectLifecycle.stored,
          visualSeed: sceneObject.visualSeed,
          generatorVersion: sceneObject.generatorVersion,
          createdAt: sceneObject.createdAt,
          focusTrait: focusTrait,
          variantKey: sceneObject.variantKey,
        ),
      );
      weatherMaterials[weatherId] = WeatherMaterial(
        id: weatherId,
        kind: weatherKind,
        timeBand: timeBandFor(sceneObject.createdAt),
        season: seasonFor(sceneObject.createdAt, northernHemisphere: true),
        capturedAt: sceneObject.createdAt,
        sourceRecordId: 'request-first:${sceneObject.id}',
        visualSeed: sceneObject.visualSeed,
        providerName: 'Locus specimen',
        atmosphericTraits: focusTrait == null
            ? const <AtmosphericTrait>[]
            : <AtmosphericTrait>[focusTrait],
        traitSchemaVersion: 'request-first-scene-v1',
      );
      recipesByObjectId[sceneObject.id] = recipe;
    }

    final objectIds = craftedObjects
        .map((CraftedObject value) => value.id)
        .toSet();
    final placements = scenePlacements
        .where(
          (ScenePlacement value) => objectIds.contains(value.sceneObjectId),
        )
        .map(
          (ScenePlacement value) => Placement(
            id: value.id,
            craftedObjectId: value.sceneObjectId,
            column: value.column,
            row: value.row,
            rotation: value.rotation,
          ),
        )
        .toList(growable: false);
    final objectsById = <String, CraftedObject>{
      for (final object in craftedObjects) object.id: object,
    };
    final recipesById = <String, RecipeDefinition>{
      for (final recipe in legacyCatalog.recipes) recipe.id: recipe,
    };
    final grid =
        EnvironmentGridBuilder(
          columns: legacyCatalog.balance.gridColumns,
          rows: legacyCatalog.balance.gridRows,
          atmosphericTraits: legacyCatalog.atmosphericTraits,
        ).build(
          placements: placements,
          objectsById: objectsById,
          recipesById: recipesById,
        );
    final graph = ConnectionGraphBuilder(
      atmosphericTraits: legacyCatalog.atmosphericTraits,
    ).build(placements: placements, objectsById: objectsById);
    final activeVisitorId = _activeVisitorId(relationships);
    final sceneWeather = craftedObjects.isEmpty
        ? WeatherMaterialKind.cloudy
        : craftedObjects.first.weatherKind;

    return DioramaSnapshot(
      objects: craftedObjects,
      placements: placements,
      recipesById: recipesById,
      weatherMaterialsById: weatherMaterials,
      environmentGrid: grid,
      connectionGraph: graph,
      timeBand: timeBandFor(now),
      weatherKind: sceneWeather,
      visitorEvaluations: const [],
      placementCatalog: legacyCatalog.placement,
      visualLayerCatalog: legacyCatalog.visualLayers,
      atmosphericTraitCatalog: legacyCatalog.atmosphericTraits,
      activeVisitorId: activeVisitorId,
    );
  }

  String _legacyRecipeId(
    SceneObject object, {
    required RequestFirstCatalog requestCatalog,
  }) {
    if (object.origin != SceneObjectOrigin.relationshipReward) {
      return object.definitionId;
    }
    try {
      return requestCatalog.sceneObjectById(object.definitionId).legacyRecipeId;
    } on StateError {
      return object.definitionId;
    }
  }

  RecipeDefinition? _tryRecipe(ContentCatalog catalog, String recipeId) {
    for (final recipe in catalog.recipes) {
      if (recipe.id == recipeId) return recipe;
    }
    return null;
  }

  WeatherMaterialKind _weatherKind(Map<String, Object?>? payload) => enumByName(
    WeatherMaterialKind.values,
    payload?['weatherKind'] as String? ?? '',
    WeatherMaterialKind.cloudy,
  );

  SurroundingMaterialKind? _surroundingKind(Map<String, Object?>? payload) {
    final raw = payload?['surroundingKind'];
    if (raw is! String) return null;
    return enumByName(
      SurroundingMaterialKind.values,
      raw,
      SurroundingMaterialKind.sparse,
    );
  }

  AtmosphericTrait? _focusTrait(Map<String, Object?>? payload) {
    final raw = payload?['focusTrait'];
    if (raw is! String) return null;
    for (final value in AtmosphericTrait.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  String? _activeVisitorId(Map<String, VisitorRelationship> relationships) {
    final residents =
        relationships.values
            .where((VisitorRelationship value) => value.stage >= 1)
            .toList(growable: false)
          ..sort((VisitorRelationship a, VisitorRelationship b) {
            final byStage = b.stage.compareTo(a.stage);
            if (byStage != 0) return byStage;
            final aTime =
                a.lastFulfilledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.lastFulfilledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final byTime = bTime.compareTo(aTime);
            if (byTime != 0) return byTime;
            return a.visitorId.compareTo(b.visitorId);
          });
    return residents.isEmpty ? null : residents.first.visitorId;
  }
}
