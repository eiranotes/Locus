import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:reality_diorama/src/diorama/diorama_game.dart';
import 'package:reality_diorama/src/diorama/diorama_geometry.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

class DioramaView extends StatefulWidget {
  const DioramaView({
    required this.snapshot,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.semanticLabel,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    super.key,
  });

  final DioramaSnapshot snapshot;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final ValueChanged<Offset>? onDragStart;
  final ValueChanged<Offset>? onDragUpdate;
  final VoidCallback? onDragEnd;
  final VoidCallback? onDragCancel;

  @override
  State<DioramaView> createState() => _DioramaViewState();
}

class _DioramaViewState extends State<DioramaView> {
  late final DioramaGame _game = DioramaGame(widget.snapshot);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.updateReduceMotion(
      MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    );
  }

  @override
  void didUpdateWidget(DioramaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateSnapshot(widget.snapshot);
  }

  @override
  Widget build(BuildContext context) {
    final game = ClipRRect(
      borderRadius: widget.borderRadius,
      child: RepaintBoundary(child: GameWidget<DioramaGame>(game: _game)),
    );
    final interactive = widget.onDragStart == null
        ? game
        : LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final viewport = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              Offset logical(Offset local) =>
                  DioramaGeometry.localToLogical(local, viewport);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (DragStartDetails details) =>
                    widget.onDragStart!(logical(details.localPosition)),
                onPanUpdate: (DragUpdateDetails details) =>
                    widget.onDragUpdate?.call(logical(details.localPosition)),
                onPanEnd: (_) => widget.onDragEnd?.call(),
                onPanCancel: widget.onDragCancel,
                child: game,
              );
            },
          );
    return Semantics(
      image: true,
      label: widget.semanticLabel ?? '5 곱하기 5 동네 디오라마',
      excludeSemantics: true,
      child: interactive,
    );
  }
}
