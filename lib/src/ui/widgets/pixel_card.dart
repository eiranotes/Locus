import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_surface.dart';

class PixelCard extends StatelessWidget {
  const PixelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlighted = false,
    this.selected,
    this.semanticLabel,
    this.radius = PixelRadii.card,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool? selected;
  final String? semanticLabel;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final shape = PixelCutBorder(
      color: highlighted ? PixelPalette.action : PixelPalette.divider,
      width: highlighted ? 2 : 1,
      cut: radius == 0 ? 0 : 6,
    );
    if (onTap == null) {
      return Material(
        color:
            color ?? (highlighted ? PixelPalette.raised : PixelPalette.panel),
        shape: shape,
        clipBehavior: Clip.hardEdge,
        child: Padding(padding: padding, child: child),
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color:
            color ?? (highlighted ? PixelPalette.raised : PixelPalette.panel),
        shape: shape,
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          splashColor: PixelPalette.action.withValues(alpha: 0.12),
          highlightColor: PixelPalette.action.withValues(alpha: 0.07),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
