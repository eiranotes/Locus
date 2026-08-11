part of 'request_first_controller.dart';

extension RequestFirstPlacementActions on RequestFirstController {
  ScenePlacement? placementForSceneObject(String sceneObjectId) =>
      _scenePlacements
          .where(
            (ScenePlacement placement) =>
                placement.sceneObjectId == sceneObjectId,
          )
          .firstOrNull;

  PlacementValidation validateScenePlacementCandidate({
    required String sceneObjectId,
    required int column,
    required int row,
    required int rotation,
  }) {
    final object = _sceneObjects
        .where((SceneObject value) => value.id == sceneObjectId)
        .firstOrNull;
    if (object == null) {
      return const PlacementValidation(
        valid: false,
        message: '배치할 기념물을 찾을 수 없습니다.',
      );
    }
    final recipe = _tryRecipe(_legacyRecipeId(object));
    if (recipe == null) {
      return const PlacementValidation(
        valid: false,
        message: '이 기념물의 배치 규칙을 찾을 수 없습니다.',
      );
    }
    final existing = placementForSceneObject(sceneObjectId);
    final normalizedRotation = normalizeQuarterTurns(rotation);
    final candidate = Placement(
      id: existing?.id ?? 'preview-$sceneObjectId',
      craftedObjectId: sceneObjectId,
      column: column,
      row: row,
      rotation: normalizedRotation,
    );
    return PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    ).validate(
      candidate: candidate,
      recipe: recipe,
      existing: _legacyPlacements(),
      recipeByObjectId: _recipesBySceneObjectId(),
      allowedRotations: legacyCatalog.placement
          .entryForRecipe(recipe.id)
          .allowedRotations,
    );
  }

  GridCell? firstAvailableSceneAnchor({
    required String sceneObjectId,
    required int rotation,
  }) {
    final object = _sceneObjects
        .where((SceneObject value) => value.id == sceneObjectId)
        .firstOrNull;
    if (object == null) return null;
    final existing = placementForSceneObject(sceneObjectId);
    if (existing == null &&
        _scenePlacements.length >= catalog.balance.activeObjectLimit) {
      return null;
    }
    final recipe = _tryRecipe(_legacyRecipeId(object));
    if (recipe == null) return null;
    final normalizedRotation = normalizeQuarterTurns(rotation);
    return PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    ).firstValidAnchor(
      candidate: Placement(
        id: existing?.id ?? 'preview-$sceneObjectId',
        craftedObjectId: sceneObjectId,
        column: existing?.column ?? 0,
        row: existing?.row ?? 0,
        rotation: normalizedRotation,
      ),
      recipe: recipe,
      existing: _legacyPlacements(),
      recipeByObjectId: _recipesBySceneObjectId(),
      allowedRotations: legacyCatalog.placement
          .entryForRecipe(recipe.id)
          .allowedRotations,
    );
  }

  Future<bool> placeSceneObjectAtFirstAvailable({
    required String sceneObjectId,
    int rotation = 0,
  }) async {
    final alreadyPlaced = placementForSceneObject(sceneObjectId) != null;
    if (!alreadyPlaced &&
        _scenePlacements.length >= catalog.balance.activeObjectLimit) {
      _errorMessage =
          '내 공간에는 기념물을 ${catalog.balance.activeObjectLimit}개까지 놓을 수 있습니다.';
      notifyChanged();
      return false;
    }
    final anchor = firstAvailableSceneAnchor(
      sceneObjectId: sceneObjectId,
      rotation: rotation,
    );
    if (anchor == null) {
      _errorMessage = '배치할 수 있는 빈 칸이 없습니다.';
      notifyChanged();
      return false;
    }
    return placeOrMoveSceneObject(
      sceneObjectId: sceneObjectId,
      column: anchor.column,
      row: anchor.row,
      rotation: rotation,
    );
  }

  Future<bool> placeOrMoveSceneObject({
    required String sceneObjectId,
    required int column,
    required int row,
    required int rotation,
  }) async {
    if (_busy) return false;
    final object = _sceneObjects
        .where((SceneObject value) => value.id == sceneObjectId)
        .firstOrNull;
    if (object == null) return false;
    final existing = placementForSceneObject(sceneObjectId);
    if (existing == null &&
        _scenePlacements.length >= catalog.balance.activeObjectLimit) {
      _errorMessage =
          '내 공간에는 기념물을 ${catalog.balance.activeObjectLimit}개까지 놓을 수 있습니다.';
      notifyChanged();
      return false;
    }
    final normalizedRotation = normalizeQuarterTurns(rotation);
    final validation = validateScenePlacementCandidate(
      sceneObjectId: sceneObjectId,
      column: column,
      row: row,
      rotation: normalizedRotation,
    );
    if (!validation.valid) {
      _errorMessage = validation.message;
      notifyChanged();
      return false;
    }
    final placement = ScenePlacement(
      id: existing?.id ?? uuid.v4(),
      sceneObjectId: sceneObjectId,
      column: column,
      row: row,
      rotation: normalizedRotation,
    );
    var saved = false;
    await _guard(() async {
      await repository.saveScenePlacement(placement);
      _scenePlacements = _replaceById(
        _scenePlacements,
        placement,
        (ScenePlacement value) => value.sceneObjectId,
      );
      _sceneObjects = _replaceById(
        _sceneObjects,
        object.copyWith(lifecycle: SceneObjectLifecycle.placed),
        (SceneObject value) => value.id,
      );
      saved = true;
    });
    notifyChanged();
    return saved;
  }

  Future<bool> storeSceneObject(String sceneObjectId) async {
    if (_busy) return false;
    final object = _sceneObjects
        .where((SceneObject value) => value.id == sceneObjectId)
        .firstOrNull;
    final placement = placementForSceneObject(sceneObjectId);
    if (object == null || placement == null) return false;
    var stored = false;
    await _guard(() async {
      await repository.removeScenePlacement(sceneObjectId);
      _scenePlacements = _scenePlacements
          .where((ScenePlacement value) => value.sceneObjectId != sceneObjectId)
          .toList(growable: false);
      _sceneObjects = _replaceById(
        _sceneObjects,
        object.copyWith(lifecycle: SceneObjectLifecycle.stored),
        (SceneObject value) => value.id,
      );
      stored = true;
    });
    notifyChanged();
    return stored;
  }

  List<Placement> _legacyPlacements() => _scenePlacements
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

  Map<String, RecipeDefinition> _recipesBySceneObjectId() =>
      <String, RecipeDefinition>{
        for (final object in _sceneObjects)
          if (_tryRecipe(_legacyRecipeId(object)) case final recipe?)
            object.id: recipe,
      };
}
