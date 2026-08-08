import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';

class PixelCard extends StatelessWidget {
  const PixelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlighted = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? PixelPalette.surfaceRaised : PixelPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? PixelPalette.mint : PixelPalette.line,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: child,
    );
    if (onTap == null) {
      return content;
    }
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: content,
      ),
    );
  }
}
