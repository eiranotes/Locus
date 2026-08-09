import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';

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
    final borderRadius = BorderRadius.circular(radius);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: highlighted
          ? const BorderSide(color: PixelPalette.action, width: 1.5)
          : BorderSide.none,
    );
    if (onTap == null) {
      return Material(
        color:
            color ?? (highlighted ? PixelPalette.raised : PixelPalette.panel),
        shape: shape,
        clipBehavior: Clip.antiAlias,
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
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: PixelPalette.action.withValues(alpha: 0.12),
          highlightColor: PixelPalette.action.withValues(alpha: 0.07),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
