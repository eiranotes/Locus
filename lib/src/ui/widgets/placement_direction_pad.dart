import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_surface.dart';

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
              assetName: 'arrow_left',
              tooltip: '화면 왼쪽 위 칸으로 이동',
              onTap: canLeft ? () => onMove(-1, 0) : null,
            ),
            const SizedBox(width: 6),
            _MoveButton(
              key: const ValueKey<String>('move-up'),
              assetName: 'arrow_up',
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
              assetName: 'arrow_down',
              tooltip: '화면 왼쪽 아래 칸으로 이동',
              onTap: canDown ? () => onMove(0, 1) : null,
            ),
            const SizedBox(width: 6),
            _MoveButton(
              key: const ValueKey<String>('move-right'),
              assetName: 'arrow_right',
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
    required this.assetName,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final String assetName;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = PixelCutBorder(
      color: onTap == null ? PixelPalette.divider : PixelPalette.action,
      cut: 5,
    );
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: tooltip,
        child: Material(
          color: PixelPalette.panel,
          shape: shape,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Opacity(
                opacity: onTap == null ? 0.32 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    GeneratedArtPaths.editorMarker(assetName),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
