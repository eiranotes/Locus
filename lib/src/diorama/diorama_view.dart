import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:reality_diorama/src/diorama/diorama_game.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

class DioramaView extends StatefulWidget {
  const DioramaView({
    required this.snapshot,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    super.key,
  });

  final DioramaSnapshot snapshot;
  final BorderRadius borderRadius;

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
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: RepaintBoundary(
        child: GameWidget<DioramaGame>(game: _game),
      ),
    );
  }
}
