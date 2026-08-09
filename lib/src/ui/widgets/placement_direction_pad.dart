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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MoveButton(
          key: const ValueKey<String>('move-left'),
          icon: Icons.arrow_left,
          tooltip: '왼쪽 칸으로 이동',
          onTap: canLeft ? () => onMove(-1, 0) : null,
        ),
        _MoveButton(
          key: const ValueKey<String>('move-up'),
          icon: Icons.arrow_upward,
          tooltip: '위쪽 칸으로 이동',
          onTap: canUp ? () => onMove(0, -1) : null,
        ),
        _MoveButton(
          key: const ValueKey<String>('move-down'),
          icon: Icons.arrow_downward,
          tooltip: '아래쪽 칸으로 이동',
          onTap: canDown ? () => onMove(0, 1) : null,
        ),
        _MoveButton(
          key: const ValueKey<String>('move-right'),
          icon: Icons.arrow_right,
          tooltip: '오른쪽 칸으로 이동',
          onTap: canRight ? () => onMove(1, 0) : null,
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
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    );
  }
}
