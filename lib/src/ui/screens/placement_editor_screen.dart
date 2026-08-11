import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/diorama/diorama_geometry.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/diorama/object_renderer.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_surface.dart';
import 'package:reality_diorama/src/ui/widgets/placement_direction_pad.dart';

const Size _catalogDragFeedbackSize = Size(82, 92);

Offset _catalogDragAnchorStrategy(
  Draggable<Object> draggable,
  BuildContext context,
  Offset position,
) => DeterministicObjectRenderer.previewAnchorIn(_catalogDragFeedbackSize);

class PlacementEditorScreen extends StatefulWidget {
  const PlacementEditorScreen({this.initialObjectId, super.key});

  final String? initialObjectId;

  @override
  State<PlacementEditorScreen> createState() => _PlacementEditorScreenState();
}

class _PlacementEditorScreenState extends State<PlacementEditorScreen> {
  String? _selectedObjectId;
  final Map<String, int> _pendingRotations = <String, int>{};
  final GlobalKey _boardKey = GlobalKey();
  String? _draggingObjectId;
  GridCell? _dragAnchor;
  int? _dragRotation;
  bool _dragValid = false;
  bool _catalogDrag = false;
  Offset? _pointerToAnchor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    _selectedObjectId ??=
        widget.initialObjectId ??
        controller.placements.firstOrNull?.craftedObjectId;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final selectedPlacement = controller.placements
        .where((Placement value) => value.craftedObjectId == _selectedObjectId)
        .firstOrNull;
    final selectedObject = controller.craftedObjects
        .where((CraftedObject value) => value.id == _selectedObjectId)
        .firstOrNull;
    final selectedRecipe = selectedObject == null
        ? null
        : controller.catalog.recipeById(selectedObject.recipeId);
    final selectedCatalogEntry = selectedRecipe == null
        ? null
        : controller.catalog.placement.entryForRecipe(selectedRecipe.id);
    final selectedRotation =
        selectedPlacement?.rotation ??
        (selectedCatalogEntry == null
            ? 0
            : _pendingRotations.putIfAbsent(
                selectedObject!.id,
                () => selectedCatalogEntry.allowedRotations.first,
              ));
    final editorObjects = _editorObjects(controller);
    final editorSnapshot = _editorSnapshot(
      controller: controller,
      placement: selectedPlacement,
      object: selectedObject,
      recipe: selectedRecipe,
      catalogEntry: selectedCatalogEntry,
      rotation: selectedRotation,
    );
    final currentVisitor = controller.targetVisitor;
    final previewVisitor = _dragAnchor == null || _draggingObjectId == null
        ? null
        : controller.previewTargetVisitor(
            craftedObjectId: _draggingObjectId!,
            column: _dragAnchor!.column,
            row: _dragAnchor!.row,
            rotation: _dragRotation ?? selectedRotation,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('배치 편집'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('완료'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: <Widget>[
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    color: PixelPalette.scene,
                    shape: const PixelCutBorder(
                      color: PixelPalette.divider,
                      width: 2,
                      cut: 8,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: DragTarget<_CatalogPlacementDrag>(
                      onWillAcceptWithDetails: (_) => true,
                      onMove:
                          (DragTargetDetails<_CatalogPlacementDrag> value) =>
                              _updateCatalogDrag(controller, value),
                      onLeave: (_) => _cancelCatalogDrag(),
                      onAcceptWithDetails:
                          (DragTargetDetails<_CatalogPlacementDrag> value) =>
                              _acceptCatalogDrag(controller, value.data),
                      builder: (BuildContext context, _, __) => Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: DioramaView(
                              key: _boardKey,
                              snapshot: editorSnapshot,
                              borderRadius: BorderRadius.zero,
                              semanticLabel: '배치 편집판. 놓인 물건은 끌어서 옮길 수 있습니다.',
                              onDragStart: (Offset logical) =>
                                  _startSceneDrag(controller, logical),
                              onDragUpdate: (Offset logical) =>
                                  _updateSceneDrag(controller, logical),
                              onDragEnd: () => _finishSceneDrag(controller),
                              onDragCancel: _cancelSceneDrag,
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            top: 10,
                            child: _PlacementFeedback(
                              dragging: _dragAnchor != null,
                              valid: _dragValid,
                              current: currentVisitor,
                              preview: previewVisitor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (editorObjects.isEmpty)
                const PixelCard(child: Text('만든 물건이 없습니다.'))
              else ...<Widget>[
                _PlacementObjectCatalog(
                  controller: controller,
                  objects: editorObjects,
                  selectedObjectId: _selectedObjectId,
                  pendingRotations: _pendingRotations,
                  onSelected: (String objectId) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedObjectId = objectId);
                  },
                  onDragStarted: _startCatalogDrag,
                  onDragCancelled: _cancelCatalogDrag,
                ),
                const SizedBox(height: 10),
                if (selectedPlacement != null &&
                    selectedObject != null &&
                    selectedRecipe != null &&
                    selectedCatalogEntry != null)
                  _PlacementControls(
                    controller: controller,
                    object: selectedObject,
                    recipe: selectedRecipe,
                    catalogEntry: selectedCatalogEntry,
                    placement: selectedPlacement,
                    onMove: (int dx, int dy) =>
                        _move(controller, selectedPlacement, dx, dy),
                    onRotate: (int rotation) =>
                        _rotate(controller, selectedPlacement, rotation),
                    onRemove: () => _remove(controller, selectedPlacement),
                  ),
                if (selectedPlacement == null &&
                    selectedObject != null &&
                    selectedRecipe != null &&
                    selectedCatalogEntry != null)
                  _StoredObjectPlacementControls(
                    controller: controller,
                    object: selectedObject,
                    recipe: selectedRecipe,
                    catalogEntry: selectedCatalogEntry,
                    rotation: selectedRotation,
                    onRotate: (int rotation) {
                      HapticFeedback.selectionClick();
                      setState(
                        () => _pendingRotations[selectedObject.id] = rotation,
                      );
                    },
                    onPlace: () => _placeStoredObject(
                      controller,
                      selectedObject,
                      selectedRotation,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  DioramaSnapshot _editorSnapshot({
    required AppController controller,
    required Placement? placement,
    required CraftedObject? object,
    required RecipeDefinition? recipe,
    required PlacementCatalogEntry? catalogEntry,
    required int rotation,
  }) {
    final snapshot = controller.dioramaSnapshot;
    if (object == null || recipe == null || catalogEntry == null) {
      return snapshot;
    }
    final engine = PlacementEngine(
      columns: controller.catalog.balance.gridColumns,
      rows: controller.catalog.balance.gridRows,
    );
    final draggingSelected =
        _draggingObjectId == object.id && _dragAnchor != null;
    final previewPlacement = draggingSelected
        ? Placement(
            id: placement?.id ?? 'preview-${object.id}',
            craftedObjectId: object.id,
            column: _dragAnchor!.column,
            row: _dragAnchor!.row,
            rotation: _dragRotation ?? rotation,
          )
        : null;
    final highlightedPlacement = previewPlacement ?? placement;
    return snapshot.withEditorOverlay(
      DioramaEditorOverlay(
        selectedObjectId: object.id,
        selectedCells: highlightedPlacement == null
            ? const <GridCell>{}
            : engine.occupiedCells(
                placement: highlightedPlacement,
                footprint: recipe.footprint,
              ),
        validAnchorCells: placement == null || draggingSelected
            ? controller.validPlacementAnchors(
                craftedObjectId: object.id,
                rotation: _dragRotation ?? rotation,
              )
            : const <GridCell>{},
        previewPlacement: previewPlacement,
        previewValid: draggingSelected ? _dragValid : true,
        dragging: draggingSelected,
      ),
    );
  }

  List<CraftedObject> _editorObjects(AppController controller) =>
      controller.craftedObjects.toList(growable: false);

  Future<void> _placeStoredObject(
    AppController controller,
    CraftedObject object,
    int rotation,
  ) async {
    final placed = await controller.placeObjectAtFirstAvailable(
      craftedObjectId: object.id,
      rotation: rotation,
    );
    if (placed) HapticFeedback.lightImpact();
  }

  void _startSceneDrag(AppController controller, Offset logical) {
    final placement = _placementAt(controller, logical);
    if (placement == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedObjectId = placement.craftedObjectId;
      _draggingObjectId = placement.craftedObjectId;
      _dragAnchor = GridCell(placement.column, placement.row);
      _dragRotation = placement.rotation;
      _dragValid = true;
      _catalogDrag = false;
      _pointerToAnchor =
          logical -
          DioramaGeometry.tileTop(
            placement.column.toDouble(),
            placement.row.toDouble(),
          );
    });
  }

  void _updateSceneDrag(AppController controller, Offset logical) {
    final objectId = _draggingObjectId;
    final pointerOffset = _pointerToAnchor;
    final rotation = _dragRotation;
    if (objectId == null || pointerOffset == null || rotation == null) return;
    final anchor = DioramaGeometry.nearestCell(logical - pointerOffset);
    final validation = controller.validatePlacementCandidate(
      craftedObjectId: objectId,
      column: anchor.column,
      row: anchor.row,
      rotation: rotation,
    );
    if (_dragAnchor == anchor && _dragValid == validation.valid) return;
    setState(() {
      _dragAnchor = anchor;
      _dragValid = validation.valid;
    });
  }

  Future<void> _finishSceneDrag(AppController controller) async {
    if (_catalogDrag) return;
    final objectId = _draggingObjectId;
    final anchor = _dragAnchor;
    final rotation = _dragRotation;
    final valid = _dragValid;
    _clearDragState();
    if (!valid || objectId == null || anchor == null || rotation == null) {
      return;
    }
    final placement = controller.placements
        .where((Placement item) => item.craftedObjectId == objectId)
        .firstOrNull;
    if (placement != null &&
        placement.column == anchor.column &&
        placement.row == anchor.row &&
        placement.rotation == rotation) {
      return;
    }
    final moved = await controller.placeOrMoveObject(
      craftedObjectId: objectId,
      column: anchor.column,
      row: anchor.row,
      rotation: rotation,
    );
    if (moved) HapticFeedback.mediumImpact();
  }

  void _cancelSceneDrag() {
    if (_catalogDrag) return;
    _clearDragState();
  }

  Placement? _placementAt(AppController controller, Offset logical) {
    final objectById = <String, CraftedObject>{
      for (final object in controller.craftedObjects) object.id: object,
    };
    final placements = DioramaGeometry.orderedPlacements(
      controller.placements,
      footprintFor: (Placement placement) {
        final object = objectById[placement.craftedObjectId];
        return object == null
            ? null
            : controller.catalog.recipeById(object.recipeId).footprint;
      },
    );
    final cell = DioramaGeometry.nearestCell(logical);
    final engine = PlacementEngine(
      columns: controller.catalog.balance.gridColumns,
      rows: controller.catalog.balance.gridRows,
    );
    for (final placement in placements.reversed) {
      final object = objectById[placement.craftedObjectId];
      if (object == null) continue;
      final recipe = controller.catalog.recipeById(object.recipeId);
      if (engine
          .occupiedCells(placement: placement, footprint: recipe.footprint)
          .contains(cell)) {
        return placement;
      }
    }
    for (final placement in placements.reversed) {
      final object = objectById[placement.craftedObjectId];
      if (object == null) continue;
      final recipe = controller.catalog.recipeById(object.recipeId);
      final anchor = DioramaGeometry.placementGroundAnchor(
        placement,
        recipe.footprint,
      );
      final bounds = object.isComplete
          ? DeterministicObjectRenderer.spriteBoundsAt(anchor, object.kind)
          : Rect.fromLTRB(
              anchor.dx - 28,
              anchor.dy - 48,
              anchor.dx + 28,
              anchor.dy + 8,
            );
      if (bounds.inflate(4).contains(logical)) {
        return placement;
      }
    }
    return null;
  }

  void _startCatalogDrag(_CatalogPlacementDrag drag) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedObjectId = drag.objectId;
      _draggingObjectId = drag.objectId;
      _dragRotation = drag.rotation;
      _dragAnchor = null;
      _dragValid = false;
      _catalogDrag = true;
      _pointerToAnchor = Offset.zero;
    });
  }

  void _updateCatalogDrag(
    AppController controller,
    DragTargetDetails<_CatalogPlacementDrag> details,
  ) {
    if (!_catalogDrag || _draggingObjectId != details.data.objectId) return;
    final renderObject = _boardKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    final local = renderObject.globalToLocal(details.offset);
    final logical = DioramaGeometry.localToLogical(local, renderObject.size);
    final object = controller.craftedObjects
        .where((CraftedObject item) => item.id == details.data.objectId)
        .firstOrNull;
    if (object == null) return;
    final recipe = controller.catalog.recipeById(object.recipeId);
    final anchor = DioramaGeometry.nearestPlacementAnchor(
      logical,
      footprint: recipe.footprint,
      rotation: details.data.rotation,
    );
    final alreadyPlaced = controller.placements.any(
      (Placement item) => item.craftedObjectId == details.data.objectId,
    );
    final atLimit =
        !alreadyPlaced &&
        controller.placements.length >=
            controller.catalog.balance.activeObjectLimit;
    final validation = controller.validatePlacementCandidate(
      craftedObjectId: details.data.objectId,
      column: anchor.column,
      row: anchor.row,
      rotation: details.data.rotation,
    );
    final valid = !atLimit && validation.valid;
    if (_dragAnchor == anchor && _dragValid == valid) return;
    setState(() {
      _dragAnchor = anchor;
      _dragValid = valid;
    });
  }

  Future<void> _acceptCatalogDrag(
    AppController controller,
    _CatalogPlacementDrag drag,
  ) async {
    final anchor = _dragAnchor;
    final valid = _dragValid && _draggingObjectId == drag.objectId;
    _clearDragState();
    if (!valid || anchor == null) return;
    final placed = await controller.placeOrMoveObject(
      craftedObjectId: drag.objectId,
      column: anchor.column,
      row: anchor.row,
      rotation: drag.rotation,
    );
    if (placed) HapticFeedback.mediumImpact();
  }

  void _cancelCatalogDrag() {
    if (!_catalogDrag) return;
    _clearDragState();
  }

  void _clearDragState() {
    if (!mounted) return;
    setState(() {
      _draggingObjectId = null;
      _dragAnchor = null;
      _dragRotation = null;
      _dragValid = false;
      _catalogDrag = false;
      _pointerToAnchor = null;
    });
  }

  Future<void> _move(
    AppController controller,
    Placement placement,
    int dx,
    int dy,
  ) async {
    final moved = await controller.placeOrMoveObject(
      craftedObjectId: placement.craftedObjectId,
      column: placement.column + dx,
      row: placement.row + dy,
      rotation: placement.rotation,
    );
    if (moved) HapticFeedback.selectionClick();
  }

  Future<void> _rotate(
    AppController controller,
    Placement placement,
    int rotation,
  ) async {
    final rotated = await controller.placeOrMoveObject(
      craftedObjectId: placement.craftedObjectId,
      column: placement.column,
      row: placement.row,
      rotation: rotation,
    );
    if (rotated) HapticFeedback.selectionClick();
  }

  Future<void> _remove(AppController controller, Placement placement) async {
    await controller.removePlacement(placement.craftedObjectId);
    HapticFeedback.lightImpact();
    if (mounted) {
      setState(
        () => _selectedObjectId =
            controller.placements.firstOrNull?.craftedObjectId,
      );
    }
  }
}

class _PlacementObjectCatalog extends StatelessWidget {
  const _PlacementObjectCatalog({
    required this.controller,
    required this.objects,
    required this.selectedObjectId,
    required this.pendingRotations,
    required this.onSelected,
    required this.onDragStarted,
    required this.onDragCancelled,
  });

  final AppController controller;
  final List<CraftedObject> objects;
  final String? selectedObjectId;
  final Map<String, int> pendingRotations;
  final ValueChanged<String> onSelected;
  final ValueChanged<_CatalogPlacementDrag> onDragStarted;
  final VoidCallback onDragCancelled;

  @override
  Widget build(BuildContext context) {
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    return SizedBox(
      height: 88,
      child: ListView.separated(
        key: const ValueKey<String>('placement-object-catalog'),
        scrollDirection: Axis.horizontal,
        itemCount: objects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final object = objects[index];
          final placement = controller.placements
              .where((Placement value) => value.craftedObjectId == object.id)
              .firstOrNull;
          final recipe = controller.catalog.recipeById(object.recipeId);
          final entry = controller.catalog.placement.entryForRecipe(recipe.id);
          final rotation =
              placement?.rotation ??
              pendingRotations[object.id] ??
              entry.allowedRotations.first;
          final visual = entry.visualFor(rotation);
          final direction = controller.catalog.placement.directionFor(rotation);
          final selected = object.id == selectedObjectId;
          final card = SizedBox(
            width: 124,
            child: PixelCard(
              radius: PixelRadii.tile,
              color: selected ? PixelPalette.raised : PixelPalette.scene,
              highlighted: selected,
              selected: selected,
              semanticLabel:
                  '${recipe.nameKo} ${direction.labelKo} ${placement == null ? '보관 중' : '배치됨'}',
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              onTap: () => onSelected(object.id),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 48,
                    height: 58,
                    child: ObjectVisualPreview(
                      visual: ObjectVisualDescriptor.fromCraftedObject(
                        object,
                        timeBand:
                            weatherById[object.weatherMaterialId]?.timeBand,
                      ),
                      rotation: rotation,
                      assetPath: visual.assetPath,
                      mirrorX: visual.mirrorX,
                      constructionAssetPath: controller.catalog.craftingArt
                          .constructionAssetFor(
                            object.recipeId,
                            object.requiredSteps <= 0
                                ? 1
                                : object.appliedSteps / object.requiredSteps,
                          ),
                      visualLayerCatalog: controller.catalog.visualLayers,
                      atmosphericTraitCatalog:
                          controller.catalog.atmosphericTraits,
                      showContextEffects: false,
                      semanticLabel: '${recipe.nameKo} ${direction.labelKo}',
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          recipe.nameKo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          direction.shortLabelKo,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          final drag = _CatalogPlacementDrag(
            objectId: object.id,
            rotation: rotation,
          );
          return LongPressDraggable<_CatalogPlacementDrag>(
            data: drag,
            dragAnchorStrategy: _catalogDragAnchorStrategy,
            hapticFeedbackOnStart: true,
            onDragStarted: () => onDragStarted(drag),
            onDraggableCanceled: (_, __) => onDragCancelled(),
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.72,
                child: SizedBox.fromSize(
                  size: _catalogDragFeedbackSize,
                  child: ObjectVisualPreview(
                    visual: ObjectVisualDescriptor.fromCraftedObject(
                      object,
                      timeBand: weatherById[object.weatherMaterialId]?.timeBand,
                    ),
                    rotation: rotation,
                    assetPath: visual.assetPath,
                    mirrorX: visual.mirrorX,
                    constructionAssetPath: controller.catalog.craftingArt
                        .constructionAssetFor(
                          object.recipeId,
                          object.requiredSteps <= 0
                              ? 1
                              : object.appliedSteps / object.requiredSteps,
                        ),
                    visualLayerCatalog: controller.catalog.visualLayers,
                    atmosphericTraitCatalog:
                        controller.catalog.atmosphericTraits,
                    showContextEffects: false,
                    semanticLabel: '${recipe.nameKo} 끌어서 배치',
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.42, child: card),
            child: card,
          );
        },
      ),
    );
  }
}

class _StoredObjectPlacementControls extends StatelessWidget {
  const _StoredObjectPlacementControls({
    required this.controller,
    required this.object,
    required this.recipe,
    required this.catalogEntry,
    required this.rotation,
    required this.onRotate,
    required this.onPlace,
  });

  final AppController controller;
  final CraftedObject object;
  final RecipeDefinition recipe;
  final PlacementCatalogEntry catalogEntry;
  final int rotation;
  final ValueChanged<int> onRotate;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    final placementCatalog = controller.catalog.placement;
    final direction = placementCatalog.directionFor(rotation);
    final footprint = PlacementEngine(
      columns: controller.catalog.balance.gridColumns,
      rows: controller.catalog.balance.gridRows,
    ).rotatedFootprint(footprint: recipe.footprint, rotation: rotation);
    final atLimit =
        controller.placements.length >=
        controller.catalog.balance.activeObjectLimit;
    final anchors = atLimit
        ? const <GridCell>{}
        : controller.validPlacementAnchors(
            craftedObjectId: object.id,
            rotation: rotation,
          );
    final nextRotation = _nextPlaceableRotation(atLimit: atLimit);
    final lifecycleLabel = object.isComplete ? '보관 중' : '공사 중';

    return PixelCard(
      radius: PixelRadii.tray,
      color: PixelPalette.raised,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe.nameKo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$lifecycleLabel · ${direction.labelKo} · '
                      '${footprint.width}×${footprint.height}칸 · '
                      '배치 가능 ${anchors.length}곳',
                      key: const ValueKey<String>('placement-status'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              PixelButton(
                key: const ValueKey<String>('placement-rotate-stored'),
                onPressed: nextRotation == null
                    ? null
                    : () => onRotate(nextRotation),
                actionAsset: 'rotate',
                fallbackIcon: Icons.rotate_right,
                tone: PixelButtonTone.secondary,
                label: nextRotation == null
                    ? '회전 공간 필요'
                    : placementCatalog.directionFor(nextRotation).shortLabelKo,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PixelButton(
                  key: const ValueKey<String>('placement-place-stored'),
                  onPressed: anchors.isEmpty ? null : onPlace,
                  actionAsset: 'place',
                  fallbackIcon: Icons.grid_view_outlined,
                  expand: true,
                  label: atLimit ? '배치 한도 도달' : '빈 칸에 배치',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _nextPlaceableRotation({required bool atLimit}) {
    if (atLimit) return null;
    var candidate = rotation;
    for (
      var attempt = 0;
      attempt < catalogEntry.allowedRotations.length;
      attempt += 1
    ) {
      candidate = catalogEntry.nextRotation(candidate);
      if (candidate == rotation) break;
      if (controller
          .validPlacementAnchors(
            craftedObjectId: object.id,
            rotation: candidate,
          )
          .isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }
}

class _PlacementControls extends StatelessWidget {
  const _PlacementControls({
    required this.controller,
    required this.object,
    required this.recipe,
    required this.catalogEntry,
    required this.placement,
    required this.onMove,
    required this.onRotate,
    required this.onRemove,
  });

  final AppController controller;
  final CraftedObject object;
  final RecipeDefinition recipe;
  final PlacementCatalogEntry catalogEntry;
  final Placement placement;
  final void Function(int dx, int dy) onMove;
  final ValueChanged<int> onRotate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final placementCatalog = controller.catalog.placement;
    final direction = placementCatalog.directionFor(placement.rotation);
    final engine = PlacementEngine(
      columns: controller.catalog.balance.gridColumns,
      rows: controller.catalog.balance.gridRows,
    );
    final footprint = engine.rotatedFootprint(
      footprint: recipe.footprint,
      rotation: placement.rotation,
    );
    final validAnchorCount = controller
        .validPlacementAnchors(
          craftedObjectId: object.id,
          rotation: placement.rotation,
        )
        .length;
    final nextRotation = _nextValidRotation();

    return PixelCard(
      radius: PixelRadii.tray,
      color: PixelPalette.raised,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe.nameKo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${direction.labelKo} · ${footprint.width}×${footprint.height}칸 · 이동 가능 $validAnchorCount곳',
                      key: const ValueKey<String>('placement-status'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: '보관함으로 회수',
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('미세 조정', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 5),
                    PlacementDirectionPad(
                      canLeft: _canMove(-1, 0),
                      canUp: _canMove(0, -1),
                      canDown: _canMove(0, 1),
                      canRight: _canMove(1, 0),
                      onMove: onMove,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('방향 바꾸기', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  PixelButton(
                    key: const ValueKey<String>('placement-rotate'),
                    onPressed: nextRotation == null
                        ? null
                        : () => onRotate(nextRotation),
                    assetPath: GeneratedArtPaths.editorMarker('rotate'),
                    fallbackIcon: Icons.rotate_right,
                    tone: PixelButtonTone.secondary,
                    label: nextRotation == null
                        ? '회전 공간 필요'
                        : placementCatalog
                              .directionFor(nextRotation)
                              .shortLabelKo,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canMove(int dx, int dy) => controller
      .validatePlacementCandidate(
        craftedObjectId: object.id,
        column: placement.column + dx,
        row: placement.row + dy,
        rotation: placement.rotation,
      )
      .valid;

  int? _nextValidRotation() {
    var candidate = placement.rotation;
    for (
      var attempt = 0;
      attempt < catalogEntry.allowedRotations.length;
      attempt += 1
    ) {
      candidate = catalogEntry.nextRotation(candidate);
      if (candidate == placement.rotation) break;
      if (controller
          .validatePlacementCandidate(
            craftedObjectId: object.id,
            column: placement.column,
            row: placement.row,
            rotation: candidate,
          )
          .valid) {
        return candidate;
      }
    }
    return null;
  }
}

class _PlacementFeedback extends StatelessWidget {
  const _PlacementFeedback({
    required this.dragging,
    required this.valid,
    required this.current,
    required this.preview,
  });

  final bool dragging;
  final bool valid;
  final VisitorEvaluation? current;
  final VisitorEvaluation? preview;

  @override
  Widget build(BuildContext context) {
    if (!dragging) {
      return const _SceneInstruction(
        icon: 'grab_hand',
        label: '놓인 물건은 끌기 · 보관 물건은 길게 눌러 배치',
        color: PixelPalette.textBody,
      );
    }
    if (!valid) {
      return const _SceneInstruction(
        icon: 'invalid_target',
        label: '이 칸에는 놓을 수 없습니다',
        color: PixelPalette.danger,
      );
    }
    final before = current?.satisfiedCount;
    final after = preview?.satisfiedCount;
    final total = preview?.progress.length;
    final improved = before != null && after != null && after > before;
    final completedLabels = current == null || preview == null
        ? const <String>[]
        : <String>[
            for (var index = 0; index < preview!.progress.length; index += 1)
              if (index < current!.progress.length &&
                  !current!.progress[index].satisfied &&
                  preview!.progress[index].satisfied)
                preview!.progress[index].label,
          ];
    final label = completedLabels.isNotEmpty
        ? '${preview!.visitor.nameKo} · ${completedLabels.join(' · ')} 완성'
        : before == null || after == null || total == null
        ? '놓으면 저장'
        : '${preview!.visitor.nameKo} 조건 $before/$total → $after/$total';
    return _SceneInstruction(
      icon: 'place_chevron',
      label: label,
      color: improved ? PixelPalette.action : PixelPalette.textStrong,
    );
  }
}

class _SceneInstruction extends StatelessWidget {
  const _SceneInstruction({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: Material(
      color: PixelPalette.canvas.withValues(alpha: 0.90),
      shape: const PixelCutBorder(color: PixelPalette.divider, cut: 5),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(
              GeneratedArtPaths.editorMarker(icon),
              width: 22,
              height: 22,
              filterQuality: FilterQuality.none,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _CatalogPlacementDrag {
  const _CatalogPlacementDrag({required this.objectId, required this.rotation});

  final String objectId;
  final int rotation;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
