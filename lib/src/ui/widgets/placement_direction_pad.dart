import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';

class PlacementDirectionPad extends StatelessWidget {
  const PlacementDirectionPad({
    required this.canLeft,
    required this.canUp,
    required this.canDown,
    required this.canRight,
    required this.onMove,
    super.key,
  });

  final bool canLeft;
  final bool canUp;
  final bool canDown;
  final bool canRight;
  final void Function(int dx, int dy) onMove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _MoveButton(
              key: const ValueKey<String>('move-left'),
              icon: Icons.north_west,
              tooltip: '화면 왼쪽 위 칸으로 이동',
              onTap: canLeft ? () => onMove(-1, 0) : null,
            ),
            const SizedBox(width: 6),
            _MoveButton(
              key: const ValueKey<String>('move-up'),
              icon: Icons.north_east,
              tooltip: '화면 오른쪽 위 칸으로 이동',
              onTap: canUp ? () => onMove(0, -1) : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _MoveButton(
              key: const ValueKey<String>('move-down'),
              icon: Icons.south_west,
              tooltip: '화면 왼쪽 아래 칸으로 이동',
              onTap: canDown ? () => onMove(0, 1) : null,
            ),
            const SizedBox(width: 6),
            _MoveButton(
              key: const ValueKey<String>('move-right'),
              icon: Icons.south_east,
              tooltip: '화면 오른쪽 아래 칸으로 이동',
              onTap: canRight ? () => onMove(1, 0) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon),
      color: PixelPalette.mint,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    );
  }
}
