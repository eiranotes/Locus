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
    final decoration = BoxDecoration(
      color: highlighted ? PixelPalette.surfaceRaised : PixelPalette.surface,
      borderRadius: borderRadius,
      border: Border.all(
        color: highlighted ? PixelPalette.mint : PixelPalette.line,
        width: highlighted ? 1.4 : 1,
      ),
    );
    if (onTap == null) {
      return Container(padding: padding, decoration: decoration, child: child);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: PixelPalette.mint.withValues(alpha: 0.14),
          highlightColor: PixelPalette.mint.withValues(alpha: 0.08),
          child: Ink(padding: padding, decoration: decoration, child: child),
        ),
      ),
    );
  }
}
