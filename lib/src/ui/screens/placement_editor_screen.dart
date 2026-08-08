import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: <Widget>[
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: PixelPalette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: PixelPalette.line),
                  ),
                  child: DioramaView(snapshot: controller.dioramaSnapshot),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (controller.placements.isEmpty)
              const PixelCard(
                child: Text('배치된 물건이 없습니다. 물건을 만들면 빈 칸에 자동으로 놓입니다.'),
              )
            else ...<Widget>[
              SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.placements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final placement = controller.placements[index];
                    final object = controller.craftedObjects.firstWhere(
                      (CraftedObject value) =>
                          value.id == placement.craftedObjectId,
                    );
                    final selected = object.id == _selectedObjectId;
                    return SizedBox(
                      width: 116,
                      child: PixelCard(
                        highlighted: selected,
                        padding: const EdgeInsets.all(9),
                        onTap: () =>
                            setState(() => _selectedObjectId = object.id),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              objectIcon(object.kind),
                              color: weatherColor(object.weatherKind),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                object.kind.labelKo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              if (selectedPlacement != null && selectedObject != null)
                _PlacementControls(
                  object: selectedObject,
                  placement: selectedPlacement,
                  onMove: (int dx, int dy) =>
                      _move(controller, selectedPlacement, dx, dy),
                  onRotate: () => _rotate(controller, selectedPlacement),
                  onRemove: () => _remove(controller, selectedPlacement),
                ),
            ],
          ],
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
    await controller.placeOrMoveObject(
      craftedObjectId: placement.craftedObjectId,
      column: placement.column + dx,
      row: placement.row + dy,
      rotation: placement.rotation,
    );
  }

  Future<void> _rotate(AppController controller, Placement placement) async {
    await controller.placeOrMoveObject(
      craftedObjectId: placement.craftedObjectId,
      column: placement.column,
      row: placement.row,
      rotation: placement.rotation + 1,
    );
  }

  Future<void> _remove(AppController controller, Placement placement) async {
    await controller.removePlacement(placement.craftedObjectId);
    if (mounted) {
      setState(
        () => _selectedObjectId =
            controller.placements.firstOrNull?.craftedObjectId,
      );
    }
  }
}

class _PlacementControls extends StatelessWidget {
  const _PlacementControls({
    required this.object,
    required this.placement,
    required this.onMove,
    required this.onRotate,
    required this.onRemove,
  });

  final CraftedObject object;
  final Placement placement;
  final void Function(int dx, int dy) onMove;
  final VoidCallback onRotate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  object.kind.labelKo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '칸 ${placement.column + 1}, ${placement.row + 1} · 방향 ${placement.rotation + 1}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _MoveButton(
                      icon: Icons.arrow_left,
                      onTap: () => onMove(-1, 0),
                    ),
                    _MoveButton(
                      icon: Icons.arrow_upward,
                      onTap: () => onMove(0, -1),
                    ),
                    _MoveButton(
                      icon: Icons.arrow_downward,
                      onTap: () => onMove(0, 1),
                    ),
                    _MoveButton(
                      icon: Icons.arrow_right,
                      onTap: () => onMove(1, 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              IconButton.filledTonal(
                onPressed: onRotate,
                tooltip: '회전',
                icon: const Icon(Icons.rotate_right),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: onRemove,
                tooltip: '보관함으로 회수',
                icon: const Icon(Icons.inventory_2_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: PixelPalette.mint,
      constraints: const BoxConstraints.tightFor(width: 42, height: 42),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
