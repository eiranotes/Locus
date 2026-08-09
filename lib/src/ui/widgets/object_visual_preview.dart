import 'package:flutter/material.dart';
import 'package:reality_diorama/src/diorama/object_renderer.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';

/// A thin widget surface over the same renderer used by the home diorama.
class ObjectVisualPreview extends StatelessWidget {
  const ObjectVisualPreview({
    required this.visual,
    this.rotation = 0,
    this.semanticLabel,
    super.key,
  });

  final ObjectVisualDescriptor visual;
  final int rotation;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final preview = CustomPaint(
      painter: ObjectVisualPainter(visual: visual, rotation: rotation),
      size: Size.zero,
    );
    if (semanticLabel == null) {
      return preview;
    }
    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: preview,
    );
  }
}

class ObjectVisualPainter extends CustomPainter {
  const ObjectVisualPainter({required this.visual, this.rotation = 0});

  static const DeterministicObjectRenderer _renderer =
      DeterministicObjectRenderer();

  final ObjectVisualDescriptor visual;
  final int rotation;

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.paintFitted(canvas, size, visual: visual, rotation: rotation);
  }

  @override
  bool shouldRepaint(ObjectVisualPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.visual.kind != visual.kind ||
        oldDelegate.visual.weatherKind != visual.weatherKind ||
        oldDelegate.visual.timeBand != visual.timeBand ||
        oldDelegate.visual.surroundingKind != visual.surroundingKind ||
        oldDelegate.visual.visualSeed != visual.visualSeed ||
        oldDelegate.visual.generatorVersion != visual.generatorVersion ||
        oldDelegate.visual.completion != visual.completion;
  }
}
