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
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool? selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(
        color: highlighted ? PixelPalette.mint : PixelPalette.line,
        width: highlighted ? 1.4 : 1,
      ),
    );
    if (onTap == null) {
      return Material(
        color: highlighted ? PixelPalette.surfaceRaised : PixelPalette.surface,
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
        color: highlighted ? PixelPalette.surfaceRaised : PixelPalette.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: PixelPalette.mint.withValues(alpha: 0.14),
          highlightColor: PixelPalette.mint.withValues(alpha: 0.08),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
