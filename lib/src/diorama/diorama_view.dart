import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:reality_diorama/src/diorama/diorama_game.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

class DioramaView extends StatefulWidget {
  const DioramaView({
    required this.snapshot,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.semanticLabel,
    super.key,
  });

  final DioramaSnapshot snapshot;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  State<DioramaView> createState() => _DioramaViewState();
}

class _DioramaViewState extends State<DioramaView> {
  late final DioramaGame _game = DioramaGame(widget.snapshot);

  @override
  void didUpdateWidget(DioramaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateSnapshot(widget.snapshot);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.semanticLabel ?? '5 곱하기 5 동네 디오라마',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: RepaintBoundary(child: GameWidget<DioramaGame>(game: _game)),
      ),
    );
  }
}
