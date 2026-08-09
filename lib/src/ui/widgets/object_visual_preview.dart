import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/diorama/object_renderer.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';

/// A thin widget surface over the same renderer used by the home diorama.
class ObjectVisualPreview extends StatelessWidget {
  const ObjectVisualPreview({
    required this.visual,
    this.rotation = 0,
    this.semanticLabel,
    this.assetPath,
    this.constructionAssetPath,
    this.mirrorX,
    super.key,
  });

  final ObjectVisualDescriptor visual;
  final int rotation;
  final String? semanticLabel;
  final String? assetPath;
  final String? constructionAssetPath;
  final bool? mirrorX;

  @override
  Widget build(BuildContext context) {
    final fallback = CustomPaint(
      painter: ObjectVisualPainter(visual: visual, rotation: rotation),
      size: Size.zero,
    );
    final isConstruction = visual.completion < 1;
    final spritePath = isConstruction
        ? constructionAssetPath
        : assetPath ?? GeneratedArtPaths.object(visual.kind);
    final preview = spritePath == null
        ? fallback
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(2),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    ObjectVisualPainter.renderer.spriteTint(visual),
                    BlendMode.modulate,
                  ),
                  child: Transform.flip(
                    flipX: isConstruction ? false : mirrorX ?? rotation.isOdd,
                    child: Image.asset(
                      spritePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => fallback,
                    ),
                  ),
                ),
              ),
              if (visual.surroundingKind != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: _ConnectorDots(kind: visual.surroundingKind!),
                ),
            ],
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

  static const DeterministicObjectRenderer renderer =
      DeterministicObjectRenderer();

  final ObjectVisualDescriptor visual;
  final int rotation;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paintFitted(canvas, size, visual: visual, rotation: rotation);
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

class _ConnectorDots extends StatelessWidget {
  const _ConnectorDots({required this.kind});

  final SurroundingMaterialKind kind;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      SurroundingMaterialKind.dense => PixelPalette.mint,
      SurroundingMaterialKind.dynamic => PixelPalette.blue,
      SurroundingMaterialKind.stable => PixelPalette.amber,
      SurroundingMaterialKind.sparse => PixelPalette.violet,
    };
    final count = switch (kind) {
      SurroundingMaterialKind.dense => 3,
      SurroundingMaterialKind.dynamic => 2,
      SurroundingMaterialKind.stable => 1,
      SurroundingMaterialKind.sparse => 2,
    };
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          count,
          (_) => Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(left: 2),
            color: color,
          ),
        ),
      ),
    );
  }
}
