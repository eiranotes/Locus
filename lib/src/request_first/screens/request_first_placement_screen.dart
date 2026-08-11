import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/request_first/request_first_controller.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/placement_direction_pad.dart';

class RequestFirstPlacementScreen extends StatefulWidget {
  const RequestFirstPlacementScreen({super.key});

  @override
  State<RequestFirstPlacementScreen> createState() =>
      _RequestFirstPlacementScreenState();
}

class _RequestFirstPlacementScreenState
    extends State<RequestFirstPlacementScreen> {
  String? _selectedObjectId;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final objects = controller.sceneObjects;
    if (_selectedObjectId == null && objects.isNotEmpty) {
      _selectedObjectId = objects.first.id;
    }
    final selected = objects
        .where((SceneObject value) => value.id == _selectedObjectId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('기념물 배치')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: <Widget>[
            Text(
              '배치는 관계 진행 조건이 아닙니다. 받은 기념물을 내 공간에 정리하는 표현 도구입니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.02,
              child: DioramaView(
                snapshot: controller.sceneSnapshot,
                semanticLabel:
                    '5 곱하기 5 관계 디오라마, 놓인 기념물 ${controller.scenePlacements.length}개',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '기념물',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${controller.scenePlacements.length}/${controller.catalog.balance.activeObjectLimit} 배치',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: objects.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final object = objects[index];
                  return _ObjectTile(
                    object: object,
                    selected: object.id == selected?.id,
                    onTap: () => setState(() => _selectedObjectId = object.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (selected != null)
              _PlacementControls(object: selected)
            else
              const PixelCard(
                color: PixelPalette.scene,
                child: Text('배치할 기념물이 없습니다.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ObjectTile extends StatelessWidget {
  const _ObjectTile({
    required this.object,
    required this.selected,
    required this.onTap,
  });

  final SceneObject object;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final details = _detailsFor(controller, object);
    final placementStatus = object.lifecycle == SceneObjectLifecycle.placed
        ? '배치됨'
        : '보관 중';
    return Semantics(
      button: true,
      selected: selected,
      label: '${details.name}, $placementStatus',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PixelRadii.tile),
          child: Container(
            width: 92,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? PixelPalette.raised : PixelPalette.scene,
              border: Border.all(
                color: selected ? PixelPalette.action : PixelPalette.divider,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(PixelRadii.tile),
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Image.asset(
                    GeneratedArtPaths.object(details.recipe.kind),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacementControls extends StatelessWidget {
  const _PlacementControls({required this.object});

  final SceneObject object;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final details = _detailsFor(controller, object);
    final placement = controller.placementForSceneObject(object.id);
    if (placement == null) {
      return PixelCard(
        color: PixelPalette.raised,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(details.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('보관 중 · 첫 번째 유효한 빈칸에 놓습니다.'),
            const SizedBox(height: 12),
            PixelButton(
              label: '내 공간에 놓기',
              onPressed: controller.busy
                  ? null
                  : () => _place(controller, object.id),
              fallbackIcon: Icons.add_location_alt_outlined,
              actionAsset: 'place',
              expand: true,
            ),
          ],
        ),
      );
    }
    final catalogEntry = controller.legacyCatalog.placement.entryForRecipe(
      details.recipe.id,
    );
    final direction = controller.legacyCatalog.placement.directionFor(
      placement.rotation,
    );
    final nextRotation = _nextValidRotation(
      controller,
      object,
      placement,
      catalogEntry,
    );
    bool canMove(int dx, int dy) => controller
        .validateScenePlacementCandidate(
          sceneObjectId: object.id,
          column: placement.column + dx,
          row: placement.row + dy,
          rotation: placement.rotation,
        )
        .valid;
    return PixelCard(
      color: PixelPalette.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      details.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${direction.labelKo} · ${placement.column + 1}열 ${placement.row + 1}행',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: controller.busy
                    ? null
                    : () => _store(controller, object.id),
                tooltip: '보관함으로 회수',
                icon: const Icon(Icons.inventory_2_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                      canLeft: !controller.busy && canMove(-1, 0),
                      canUp: !controller.busy && canMove(0, -1),
                      canDown: !controller.busy && canMove(0, 1),
                      canRight: !controller.busy && canMove(1, 0),
                      onMove: (int dx, int dy) =>
                          _move(controller, placement, dx, dy),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('방향 바꾸기', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  PixelButton(
                    label: nextRotation == null
                        ? '회전 공간 필요'
                        : controller.legacyCatalog.placement
                              .directionFor(nextRotation)
                              .shortLabelKo,
                    onPressed: controller.busy || nextRotation == null
                        ? null
                        : () => _rotate(controller, placement, nextRotation),
                    fallbackIcon: Icons.rotate_right,
                    actionAsset: 'rotate',
                    tone: PixelButtonTone.secondary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int? _nextValidRotation(
    RequestFirstController controller,
    SceneObject object,
    ScenePlacement placement,
    PlacementCatalogEntry entry,
  ) {
    var candidate = placement.rotation;
    for (
      var attempt = 0;
      attempt < entry.allowedRotations.length;
      attempt += 1
    ) {
      candidate = entry.nextRotation(candidate);
      if (candidate == placement.rotation) break;
      if (controller
          .validateScenePlacementCandidate(
            sceneObjectId: object.id,
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

  static Future<void> _place(
    RequestFirstController controller,
    String sceneObjectId,
  ) async {
    if (await controller.placeSceneObjectAtFirstAvailable(
      sceneObjectId: sceneObjectId,
    )) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> _move(
    RequestFirstController controller,
    ScenePlacement placement,
    int dx,
    int dy,
  ) async {
    if (await controller.placeOrMoveSceneObject(
      sceneObjectId: placement.sceneObjectId,
      column: placement.column + dx,
      row: placement.row + dy,
      rotation: placement.rotation,
    )) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> _rotate(
    RequestFirstController controller,
    ScenePlacement placement,
    int rotation,
  ) async {
    if (await controller.placeOrMoveSceneObject(
      sceneObjectId: placement.sceneObjectId,
      column: placement.column,
      row: placement.row,
      rotation: rotation,
    )) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> _store(
    RequestFirstController controller,
    String sceneObjectId,
  ) async {
    if (await controller.storeSceneObject(sceneObjectId)) {
      await HapticFeedback.lightImpact();
    }
  }
}

({String name, RecipeDefinition recipe}) _detailsFor(
  RequestFirstController controller,
  SceneObject object,
) {
  if (object.origin == SceneObjectOrigin.relationshipReward) {
    final definition = controller.catalog.sceneObjectById(object.definitionId);
    return (
      name: definition.nameKo,
      recipe: controller.legacyCatalog.recipeById(definition.legacyRecipeId),
    );
  }
  final recipe = controller.legacyCatalog.recipeById(object.definitionId);
  return (name: recipe.nameKo, recipe: recipe);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
