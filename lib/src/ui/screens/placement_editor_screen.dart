import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/placement_direction_pad.dart';

class PlacementEditorScreen extends StatefulWidget {
  const PlacementEditorScreen({this.initialObjectId, super.key});

  final String? initialObjectId;

  @override
  State<PlacementEditorScreen> createState() => _PlacementEditorScreenState();
}

class _PlacementEditorScreenState extends State<PlacementEditorScreen> {
  String? _selectedObjectId;

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
    final editorSnapshot = _editorSnapshot(
      controller: controller,
      placement: selectedPlacement,
      object: selectedObject,
      recipe: selectedRecipe,
      catalogEntry: selectedCatalogEntry,
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PixelPalette.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: PixelPalette.line),
                    ),
                    child: DioramaView(snapshot: editorSnapshot),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (controller.placements.isEmpty)
                const PixelCard(
                  child: Text('배치된 물건이 없습니다. 물건을 만들면 빈 칸에 자동으로 놓입니다.'),
                )
              else ...<Widget>[
                _PlacedObjectCatalog(
                  controller: controller,
                  selectedObjectId: _selectedObjectId,
                  onSelected: (String objectId) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedObjectId = objectId);
                  },
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
  }) {
    final snapshot = controller.dioramaSnapshot;
    if (placement == null ||
        object == null ||
        recipe == null ||
        catalogEntry == null) {
      return snapshot;
    }
    final engine = PlacementEngine(
      columns: controller.catalog.balance.gridColumns,
      rows: controller.catalog.balance.gridRows,
    );
    return snapshot.withEditorOverlay(
      DioramaEditorOverlay(
        selectedObjectId: object.id,
        selectedCells: engine.occupiedCells(
          placement: placement,
          footprint: recipe.footprint,
        ),
        validAnchorCells: controller.validPlacementAnchors(
          craftedObjectId: object.id,
          rotation: placement.rotation,
        ),
      ),
    );
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

class _PlacedObjectCatalog extends StatelessWidget {
  const _PlacedObjectCatalog({
    required this.controller,
    required this.selectedObjectId,
    required this.onSelected,
  });

  final AppController controller;
  final String? selectedObjectId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    return SizedBox(
      height: 92,
      child: ListView.separated(
        key: const ValueKey<String>('placement-object-catalog'),
        scrollDirection: Axis.horizontal,
        itemCount: controller.placements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final placement = controller.placements[index];
          final object = controller.craftedObjects.firstWhere(
            (CraftedObject value) => value.id == placement.craftedObjectId,
          );
          final recipe = controller.catalog.recipeById(object.recipeId);
          final entry = controller.catalog.placement.entryForRecipe(recipe.id);
          final visual = entry.visualFor(placement.rotation);
          final direction = controller.catalog.placement.directionFor(
            placement.rotation,
          );
          final selected = object.id == selectedObjectId;
          return SizedBox(
            width: 132,
            child: PixelCard(
              highlighted: selected,
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
                      rotation: placement.rotation,
                      assetPath: visual.assetPath,
                      mirrorX: visual.mirrorX,
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
        },
      ),
    );
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
            children: <Widget>[
              Expanded(
                child: PlacementDirectionPad(
                  canLeft: _canMove(-1, 0),
                  canUp: _canMove(0, -1),
                  canDown: _canMove(0, 1),
                  canRight: _canMove(1, 0),
                  onMove: onMove,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton.tonalIcon(
                  key: const ValueKey<String>('placement-rotate'),
                  onPressed: nextRotation == null
                      ? null
                      : () => onRotate(nextRotation),
                  icon: const Icon(Icons.rotate_right),
                  label: Text(
                    nextRotation == null
                        ? '회전 공간 필요'
                        : placementCatalog
                              .directionFor(nextRotation)
                              .shortLabelKo,
                  ),
                ),
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
