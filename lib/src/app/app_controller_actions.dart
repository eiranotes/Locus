part of 'app_controller.dart';

extension AppControllerActions on AppController {
  PlacementValidation validatePlacementCandidate({
    required String craftedObjectId,
    required int column,
    required int row,
    required int rotation,
  }) {
    final object = _craftedObjects
        .where((CraftedObject candidate) => candidate.id == craftedObjectId)
        .firstOrNull;
    if (object == null) {
      return const PlacementValidation(
        valid: false,
        message: '배치할 물건을 찾을 수 없습니다.',
      );
    }
    final recipe = catalog.recipeById(object.recipeId);
    final placementEntry = catalog.placement.entryForRecipe(recipe.id);
    final existing = _placements
        .where((Placement item) => item.craftedObjectId == craftedObjectId)
        .firstOrNull;
    final candidate = Placement(
      id: existing?.id ?? 'preview-$craftedObjectId',
      craftedObjectId: craftedObjectId,
      column: column,
      row: row,
      rotation: normalizeQuarterTurns(rotation),
    );
    return PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    ).validate(
      candidate: candidate,
      recipe: recipe,
      existing: _placements,
      recipeByObjectId: <String, RecipeDefinition>{
        for (final item in _craftedObjects)
          item.id: catalog.recipeById(item.recipeId),
      },
      allowedRotations: placementEntry.allowedRotations,
    );
  }

  Set<GridCell> validPlacementAnchors({
    required String craftedObjectId,
    required int rotation,
  }) {
    final object = _craftedObjects
        .where((CraftedObject candidate) => candidate.id == craftedObjectId)
        .firstOrNull;
    if (object == null) return const <GridCell>{};
    final recipe = catalog.recipeById(object.recipeId);
    final placementEntry = catalog.placement.entryForRecipe(recipe.id);
    final current = _placements
        .where((Placement item) => item.craftedObjectId == craftedObjectId)
        .firstOrNull;
    final candidate = Placement(
      id: current?.id ?? 'preview-$craftedObjectId',
      craftedObjectId: craftedObjectId,
      column: current?.column ?? 0,
      row: current?.row ?? 0,
      rotation: normalizeQuarterTurns(rotation),
    );
    return PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    ).validAnchors(
      candidate: candidate,
      recipe: recipe,
      existing: _placements,
      recipeByObjectId: <String, RecipeDefinition>{
        for (final item in _craftedObjects)
          item.id: catalog.recipeById(item.recipeId),
      },
      allowedRotations: placementEntry.allowedRotations,
    );
  }

  GridCell? firstAvailablePlacementAnchor({
    required String craftedObjectId,
    required int rotation,
  }) {
    final object = _craftedObjects
        .where((CraftedObject candidate) => candidate.id == craftedObjectId)
        .firstOrNull;
    if (object == null) return null;
    final existing = _placements
        .where((Placement item) => item.craftedObjectId == craftedObjectId)
        .firstOrNull;
    if (existing == null &&
        _placements.length >= catalog.balance.activeObjectLimit) {
      return null;
    }
    final recipe = catalog.recipeById(object.recipeId);
    final placementEntry = catalog.placement.entryForRecipe(recipe.id);
    return PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    ).firstValidAnchor(
      candidate: Placement(
        id: existing?.id ?? 'preview-$craftedObjectId',
        craftedObjectId: craftedObjectId,
        column: existing?.column ?? 0,
        row: existing?.row ?? 0,
        rotation: normalizeQuarterTurns(rotation),
      ),
      recipe: recipe,
      existing: _placements,
      recipeByObjectId: <String, RecipeDefinition>{
        for (final item in _craftedObjects)
          item.id: catalog.recipeById(item.recipeId),
      },
      allowedRotations: placementEntry.allowedRotations,
    );
  }

  Future<bool> placeObjectAtFirstAvailable({
    required String craftedObjectId,
    required int rotation,
  }) async {
    final object = _craftedObjects
        .where((CraftedObject candidate) => candidate.id == craftedObjectId)
        .firstOrNull;
    if (object == null) return false;
    final alreadyPlaced = _placements.any(
      (Placement item) => item.craftedObjectId == craftedObjectId,
    );
    if (!alreadyPlaced &&
        _placements.length >= catalog.balance.activeObjectLimit) {
      _errorMessage =
          '내 공간에는 물건을 ${catalog.balance.activeObjectLimit}개까지 놓을 수 있습니다.';
      notifyChanged();
      return false;
    }
    final anchor = firstAvailablePlacementAnchor(
      craftedObjectId: craftedObjectId,
      rotation: rotation,
    );
    if (anchor == null) {
      _errorMessage = '배치할 수 있는 빈 칸이 없습니다.';
      notifyChanged();
      return false;
    }
    return placeOrMoveObject(
      craftedObjectId: craftedObjectId,
      column: anchor.column,
      row: anchor.row,
      rotation: rotation,
    );
  }

  Future<CaptureBundle?> performCapture({
    required bool includeSurroundings,
  }) async {
    CaptureBundle? output;
    await _guard(() async {
      var preparation = _capturePreparation;
      preparation ??= await captureCoordinator.prepare(
        now: DateTime.now(),
        lastWeather: _weatherMaterials.isEmpty ? null : _weatherMaterials.first,
        lastSurrounding: _surroundingMaterials.isEmpty
            ? null
            : _surroundingMaterials.first,
        lastAmbientCoordinate: await repository.lastAmbientCoordinate(),
      );
      final bundle = await captureCoordinator.capture(
        preparation: preparation,
        now: DateTime.now(),
        includeSurroundings: includeSurroundings,
      );
      await repository.saveCapture(
        record: bundle.record,
        weather: bundle.weatherMaterial,
        surroundings: bundle.surroundingMaterial,
        patterns: bundle.patterns,
      );
      if (bundle.surroundingMaterial != null &&
          !preparation.location.isFallback) {
        await repository.saveLastAmbientCoordinate(
          preparation.location.point.latitude,
          preparation.location.point.longitude,
        );
      }
      _lastCaptureBundle = bundle;
      output = bundle;
      await _reloadAll();
      await _refreshCapturePreparationState(requestLocationPermission: false);
      await _evaluateAndPersistVisitors();
    });
    notifyChanged();
    return output;
  }

  Future<CraftedObject?> craft({
    required RecipeDefinition recipe,
    required WeatherMaterial weather,
    SurroundingMaterial? surroundings,
    AtmosphericTrait? focusTrait,
  }) async {
    if (!_unlockedRecipeIds.contains(recipe.id)) {
      _errorMessage = '아직 열리지 않은 만드는 법입니다.';
      notifyChanged();
      return null;
    }
    if (construction != null) {
      _errorMessage = '진행 중인 공사를 먼저 마쳐 주세요.';
      notifyChanged();
      return null;
    }

    CraftedObject? created;
    await _guard(() async {
      final result = const CraftingEngine().start(
        objectId: uuid.v4(),
        recipe: recipe,
        weather: weather,
        surrounding: surroundings,
        focusTrait: focusTrait,
        stepBuckets: _stepBuckets,
        now: DateTime.now(),
      );
      final placement = _firstAvailablePlacement(result.object, recipe);
      final markPlaced = placement != null && result.object.isComplete;
      await repository.saveCrafting(
        result,
        placement: placement,
        markPlaced: markPlaced,
      );

      final savedObject = markPlaced
          ? result.object.copyWith(lifecycle: ObjectLifecycle.placed)
          : result.object;
      _stepBuckets = result.stepBuckets;
      _craftedObjects = <CraftedObject>[savedObject, ..._craftedObjects];
      _weatherMaterials = _replaceById(
        _weatherMaterials,
        result.weatherMaterial,
        (WeatherMaterial value) => value.id,
      );
      if (result.surroundingMaterial != null) {
        _surroundingMaterials = _replaceById(
          _surroundingMaterials,
          result.surroundingMaterial!,
          (SurroundingMaterial value) => value.id,
        );
      }
      if (placement != null) {
        _placements = <Placement>[placement, ..._placements];
      }
      created = savedObject;
      await _evaluateAndPersistVisitors();
    });
    notifyChanged();
    return created;
  }

  Future<bool> placeOrMoveObject({
    required String craftedObjectId,
    required int column,
    required int row,
    required int rotation,
  }) async {
    if (_busy) return false;
    final object = _craftedObjects
        .where((CraftedObject candidate) => candidate.id == craftedObjectId)
        .firstOrNull;
    if (object == null) return false;
    final existing = _placements
        .where((Placement item) => item.craftedObjectId == craftedObjectId)
        .firstOrNull;
    if (existing == null &&
        _placements.length >= catalog.balance.activeObjectLimit) {
      _errorMessage =
          '내 공간에는 물건을 ${catalog.balance.activeObjectLimit}개까지 놓을 수 있습니다.';
      notifyChanged();
      return false;
    }
    final normalizedRotation = normalizeQuarterTurns(rotation);
    final candidate = Placement(
      id: existing?.id ?? uuid.v4(),
      craftedObjectId: craftedObjectId,
      column: column,
      row: row,
      rotation: normalizedRotation,
    );
    final validation = validatePlacementCandidate(
      craftedObjectId: craftedObjectId,
      column: column,
      row: row,
      rotation: normalizedRotation,
    );
    if (!validation.valid) {
      _errorMessage = validation.message;
      notifyChanged();
      return false;
    }

    await _guard(() async {
      await repository.savePlacement(candidate, markPlaced: object.isComplete);
      _placements = _replaceById(
        _placements,
        candidate,
        (Placement value) => value.id,
      );
      if (object.isComplete) {
        _craftedObjects = _replaceById(
          _craftedObjects,
          object.copyWith(lifecycle: ObjectLifecycle.placed),
          (CraftedObject value) => value.id,
        );
      }
      await _evaluateAndPersistVisitors();
    });
    notifyChanged();
    return true;
  }

  Future<void> removePlacement(String craftedObjectId) async {
    await _guard(() async {
      final object = _craftedObjects
          .where((CraftedObject item) => item.id == craftedObjectId)
          .firstOrNull;
      if (object == null) return;
      final nextLifecycle = object.isComplete
          ? ObjectLifecycle.stored
          : ObjectLifecycle.building;
      await repository.removePlacement(
        craftedObjectId,
        lifecycle: nextLifecycle,
      );
      _placements = _placements
          .where((Placement item) => item.craftedObjectId != craftedObjectId)
          .toList(growable: false);
      _craftedObjects = _replaceById(
        _craftedObjects,
        object.copyWith(lifecycle: nextLifecycle),
        (CraftedObject value) => value.id,
      );
      await _evaluateAndPersistVisitors();
    });
    notifyChanged();
  }

  VisitorEvaluation? get targetVisitor {
    final snapshot = dioramaSnapshot;
    return const VisitorSelectionPolicy().target(
      evaluations: snapshot.visitorEvaluations,
      sightings: _visitorSightings,
      now: DateTime.now(),
      repeatCooldown: Duration(
        hours: catalog.balance.repeatVisitorCooldownHours,
      ),
    );
  }

  Duration? visitorRepeatWait(String visitorId) {
    final previous = _visitorSightings
        .where((VisitorSighting sighting) => sighting.visitorId == visitorId)
        .firstOrNull;
    if (previous == null) return null;
    final cooldown = Duration(
      hours: catalog.balance.repeatVisitorCooldownHours,
    );
    final measuredElapsed = DateTime.now().difference(previous.lastSeenAt);
    final elapsed = measuredElapsed.isNegative
        ? Duration.zero
        : measuredElapsed;
    if (elapsed >= cooldown) return Duration.zero;
    return cooldown - elapsed;
  }

  VisitorEvaluation? previewTargetVisitor({
    required String craftedObjectId,
    required int column,
    required int row,
    required int rotation,
  }) {
    final target = targetVisitor;
    if (target == null) return null;
    final object = _craftedObjects
        .where((CraftedObject item) => item.id == craftedObjectId)
        .firstOrNull;
    if (object == null) return target;
    final existing = _placements
        .where((Placement item) => item.craftedObjectId == craftedObjectId)
        .firstOrNull;
    if (existing == null &&
        _placements.length >= catalog.balance.activeObjectLimit) {
      return target;
    }
    final candidate = Placement(
      id: existing?.id ?? 'preview-$craftedObjectId',
      craftedObjectId: craftedObjectId,
      column: column,
      row: row,
      rotation: normalizeQuarterTurns(rotation),
    );
    final placements =
        _placements
            .where((Placement item) => item.craftedObjectId != craftedObjectId)
            .toList(growable: true)
          ..add(candidate);
    final objectsById = <String, CraftedObject>{
      for (final item in _craftedObjects) item.id: item,
    };
    final recipesById = <String, RecipeDefinition>{
      for (final recipe in catalog.recipes) recipe.id: recipe,
    };
    final grid =
        EnvironmentGridBuilder(
          columns: catalog.balance.gridColumns,
          rows: catalog.balance.gridRows,
          atmosphericTraits: catalog.atmosphericTraits,
        ).build(
          placements: placements,
          objectsById: objectsById,
          recipesById: recipesById,
        );
    final graph = ConnectionGraphBuilder(
      atmosphericTraits: catalog.atmosphericTraits,
    ).build(placements: placements, objectsById: objectsById);
    return const VisitorEngine().evaluate(
      target.visitor,
      VisitorContext(
        grid: grid,
        graph: graph,
        placements: placements,
        objectsById: objectsById,
        recipesById: recipesById,
        timeBand: sceneTimeBand,
        weatherKind: currentWeatherKind,
        atmosphericTraits: catalog.atmosphericTraits,
      ),
    );
  }

  DioramaSnapshot get dioramaSnapshot {
    final objectsById = <String, CraftedObject>{
      for (final object in _craftedObjects) object.id: object,
    };
    final recipesById = <String, RecipeDefinition>{
      for (final recipe in catalog.recipes) recipe.id: recipe,
    };
    final weatherMaterialsById = <String, WeatherMaterial>{
      for (final material in _weatherMaterials) material.id: material,
    };
    final grid =
        EnvironmentGridBuilder(
          columns: catalog.balance.gridColumns,
          rows: catalog.balance.gridRows,
          atmosphericTraits: catalog.atmosphericTraits,
        ).build(
          placements: _placements,
          objectsById: objectsById,
          recipesById: recipesById,
        );
    final graph = ConnectionGraphBuilder(
      atmosphericTraits: catalog.atmosphericTraits,
    ).build(placements: _placements, objectsById: objectsById);
    final visitorContext = VisitorContext(
      grid: grid,
      graph: graph,
      placements: _placements,
      objectsById: objectsById,
      recipesById: recipesById,
      timeBand: sceneTimeBand,
      weatherKind: currentWeatherKind,
      atmosphericTraits: catalog.atmosphericTraits,
    );
    const visitorEngine = VisitorEngine();
    final evaluations = catalog.visitors
        .map(
          (VisitorDefinition visitor) =>
              visitorEngine.evaluate(visitor, visitorContext),
        )
        .toList(growable: false);
    return DioramaSnapshot(
      objects: _craftedObjects,
      placements: _placements,
      recipesById: recipesById,
      weatherMaterialsById: weatherMaterialsById,
      environmentGrid: grid,
      connectionGraph: graph,
      timeBand: sceneTimeBand,
      weatherKind: sceneWeatherKind,
      visitorEvaluations: evaluations,
      placementCatalog: catalog.placement,
      visualLayerCatalog: catalog.visualLayers,
      atmosphericTraitCatalog: catalog.atmosphericTraits,
      activeVisitorId: sceneVisitorIdFor(
        sightings: _visitorSightings,
        arrivingVisitorId: _newVisitorId,
      ),
    );
  }

  Future<void> _syncStepsAndConstruction() async {
    final now = DateTime.now();
    switch (_stepTrackingMode) {
      case StepTrackingMode.real:
        _stepBuckets = await stepSyncService.syncReal(
          existing: _stepBuckets,
          now: now,
        );
        break;
      case StepTrackingMode.fallback:
        _stepBuckets = stepSyncService.syncFallback(
          existing: _stepBuckets,
          now: now,
        );
        break;
      case StepTrackingMode.undecided:
        return;
    }
    await repository.replaceStepBuckets(_stepBuckets);
    await _advanceConstruction();
  }

  Future<void> _advanceConstruction() async {
    final building = construction;
    if (building == null) return;
    final advanced = const CraftingEngine().advance(
      object: building,
      stepBuckets: _stepBuckets,
    );
    var object = advanced.object;
    final hasPlacement = _placements.any(
      (Placement placement) => placement.craftedObjectId == building.id,
    );
    if (object.isComplete && hasPlacement) {
      object = object.copyWith(lifecycle: ObjectLifecycle.placed);
    }
    _stepBuckets = advanced.buckets;
    _craftedObjects = _replaceById(
      _craftedObjects,
      object,
      (CraftedObject value) => value.id,
    );
    await repository.updateConstruction(object: object, buckets: _stepBuckets);
  }

  Future<void> _evaluateAndPersistVisitors() async {
    final snapshot = dioramaSnapshot;
    final now = DateTime.now();
    final seenById = <String, VisitorSighting>{
      for (final sighting in _visitorSightings) sighting.visitorId: sighting,
    };
    final evaluation = const VisitorSelectionPolicy().arriving(
      evaluations: snapshot.visitorEvaluations,
      sightings: _visitorSightings,
      now: now,
      repeatCooldown: Duration(
        hours: catalog.balance.repeatVisitorCooldownHours,
      ),
    );
    if (evaluation == null) return;
    final previous = seenById[evaluation.visitor.id];
    final variantKey =
        '${sceneWeatherKind.name}_${sceneTimeBand.name}_${_captures.firstOrNull?.coarseCellId ?? 'local'}';
    final snapshotJson = VisitorSighting.encodeSnapshot(<String, Object?>{
      'weather': sceneWeatherKind.name,
      'timeBand': sceneTimeBand.name,
      'objects': _placements
          .map((Placement item) => item.craftedObjectId)
          .toList(),
    });
    final sighting = VisitorSighting(
      id: previous?.id ?? uuid.v4(),
      visitorId: evaluation.visitor.id,
      firstSeenAt: previous?.firstSeenAt ?? now,
      lastSeenAt: now,
      variantKey: variantKey,
      snapshotJson: snapshotJson,
    );
    final encounter = VisitorEncounter(
      id: uuid.v4(),
      visitorId: evaluation.visitor.id,
      seenAt: now,
      variantKey: variantKey,
      snapshotJson: snapshotJson,
    );
    final nextRecipeIds = Set<String>.from(_unlockedRecipeIds);
    final nextRewardKeys = Set<String>.from(_unlockedRewardKeys);
    final reward = evaluation.visitor.reward;
    final rewardKey = '${reward.kind.name}:${reward.value}';
    if (nextRewardKeys.add(rewardKey) &&
        reward.kind == VisitorRewardKind.recipe) {
      nextRecipeIds.add(reward.value);
    }
    await repository.saveVisitorResolution(
      sighting: sighting,
      encounter: encounter,
      unlockedRecipeIds: nextRecipeIds,
      unlockedRewardKeys: nextRewardKeys,
    );
    _visitorSightings = _replaceById(
      _visitorSightings,
      sighting,
      (VisitorSighting value) => value.id,
    );
    _visitorEncounterCounts = <String, int>{
      ..._visitorEncounterCounts,
      evaluation.visitor.id:
          (_visitorEncounterCounts[evaluation.visitor.id] ?? 0) + 1,
    };
    _unlockedRecipeIds = nextRecipeIds;
    _unlockedRewardKeys = nextRewardKeys;
    if (previous == null) _newVisitorId = evaluation.visitor.id;
  }

  Placement? _firstAvailablePlacement(
    CraftedObject object,
    RecipeDefinition recipe,
  ) {
    if (_placements.length >= catalog.balance.activeObjectLimit) return null;
    final engine = PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    );
    final recipesByObject = <String, RecipeDefinition>{
      for (final item in _craftedObjects)
        item.id: catalog.recipeById(item.recipeId),
    };
    recipesByObject[object.id] = recipe;
    for (var row = 0; row < catalog.balance.gridRows; row += 1) {
      for (var column = 0; column < catalog.balance.gridColumns; column += 1) {
        final candidate = Placement(
          id: uuid.v4(),
          craftedObjectId: object.id,
          column: column,
          row: row,
          rotation: 0,
        );
        if (engine
            .validate(
              candidate: candidate,
              recipe: recipe,
              existing: _placements,
              recipeByObjectId: recipesByObject,
            )
            .valid) {
          return candidate;
        }
      }
    }
    return null;
  }

  Future<void> _reloadAll() async {
    _captures = await repository.loadCaptures();
    _weatherMaterials = await repository.loadWeatherMaterials();
    _surroundingMaterials = await repository.loadSurroundingMaterials();
    _collectedPatterns = await repository.loadCollectedPatterns();
    _stepBuckets = await repository.loadStepBuckets();
    _craftedObjects = await repository.loadCraftedObjects();
    _placements = await repository.loadPlacements();
    _visitorSightings = await repository.loadVisitorSightings();
    _visitorEncounterCounts = await repository.loadVisitorEncounterCounts();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    _errorMessage = null;
    notifyChanged();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _busy = false;
    }
  }
}

List<T> _replaceById<T>(
  List<T> source,
  T value,
  String Function(T value) idOf,
) {
  final id = idOf(value);
  final output = <T>[];
  var replaced = false;
  for (final item in source) {
    if (idOf(item) == id) {
      output.add(value);
      replaced = true;
    } else {
      output.add(item);
    }
  }
  if (!replaced) output.insert(0, value);
  return output;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
