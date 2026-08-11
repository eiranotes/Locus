import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/diorama/object_renderer.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/visual_layer_catalog.dart';

/// A thin widget surface over the same renderer used by the home diorama.
class ObjectVisualPreview extends StatelessWidget {
  const ObjectVisualPreview({
    required this.visual,
    this.rotation = 0,
    this.semanticLabel,
    this.assetPath,
    this.constructionAssetPath,
    this.mirrorX,
    this.visualLayerCatalog = VisualLayerCatalog.empty,
    this.atmosphericTraitCatalog = AtmosphericTraitCatalog.empty,
    this.showContextEffects = true,
    super.key,
  });

  final ObjectVisualDescriptor visual;
  final int rotation;
  final String? semanticLabel;
  final String? assetPath;
  final String? constructionAssetPath;
  final bool? mirrorX;
  final VisualLayerCatalog visualLayerCatalog;
  final AtmosphericTraitCatalog atmosphericTraitCatalog;
  final bool showContextEffects;

  static final Map<String, Future<_ObjectPreviewImages>> _layerBundles =
      <String, Future<_ObjectPreviewImages>>{};

  @override
  Widget build(BuildContext context) {
    Widget fallback() => CustomPaint(
      painter: ObjectVisualPainter(
        visual: visual,
        rotation: rotation,
        showContextEffects: showContextEffects,
      ),
      size: Size.zero,
    );
    final isConstruction = visual.completion < 1;
    final spritePath = isConstruction
        ? constructionAssetPath
        : assetPath ?? GeneratedArtPaths.object(visual.kind);
    final layer = showContextEffects && visual.usesLayeredWeather
        ? visualLayerCatalog.tryForWeather(visual.weatherKind)
        : null;
    final traitDefinition = !showContextEffects || visual.focusTrait == null
        ? null
        : atmosphericTraitCatalog.tryDefinitionFor(visual.focusTrait!);
    final traitLayer = traitDefinition == null
        ? null
        : visualLayerCatalog.tryForWeather(traitDefinition.layerKind);
    final distinctTraitLayer =
        traitLayer != null && traitLayer.kind != layer?.kind;
    final preview = spritePath == null
        ? fallback()
        : FutureBuilder<_ObjectPreviewImages>(
            future: _loadImages(
              spritePath,
              surfacePath: layer?.surfacePatternPath,
              traitSurfacePath: distinctTraitLayer
                  ? traitLayer.surfacePatternPath
                  : null,
            ),
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<_ObjectPreviewImages> data,
                ) {
                  if (!data.hasData) return fallback();
                  final images = data.requireData;
                  final traitBoost = traitDefinition?.surfaceOpacityBoost ?? 0;
                  return CustomPaint(
                    painter: ObjectVisualPainter(
                      visual: visual,
                      rotation: rotation,
                      sprite: images.sprite,
                      surfacePattern: images.surface,
                      traitSurfacePattern: images.traitSurface,
                      spriteMirrorX: isConstruction
                          ? false
                          : mirrorX ?? rotation.isOdd,
                      surfaceOpacity:
                          (layer?.surfaceOpacity ?? 0) +
                          (distinctTraitLayer ? 0 : traitBoost),
                      traitSurfaceOpacity: distinctTraitLayer
                          ? (traitLayer.surfaceOpacity * 0.58 + traitBoost)
                                .clamp(0, 0.32)
                                .toDouble()
                          : 0,
                      constructionSprite:
                          isConstruction && constructionAssetPath != null,
                      showContextEffects: showContextEffects,
                    ),
                    size: Size.zero,
                  );
                },
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

  Future<_ObjectPreviewImages> _loadImages(
    String spritePath, {
    String? surfacePath,
    String? traitSurfacePath,
  }) {
    final key = <String?>[spritePath, surfacePath, traitSurfacePath].join('|');
    return _layerBundles.putIfAbsent(
      key,
      () async => _ObjectPreviewImages(
        sprite: await GeneratedArtImageCache.load(spritePath),
        surface: surfacePath == null
            ? null
            : await GeneratedArtImageCache.load(surfacePath),
        traitSurface: traitSurfacePath == null
            ? null
            : await GeneratedArtImageCache.load(traitSurfacePath),
      ),
    );
  }
}

final class _ObjectPreviewImages {
  const _ObjectPreviewImages({
    required this.sprite,
    this.surface,
    this.traitSurface,
  });

  final ui.Image sprite;
  final ui.Image? surface;
  final ui.Image? traitSurface;
}

class ObjectVisualPainter extends CustomPainter {
  const ObjectVisualPainter({
    required this.visual,
    this.rotation = 0,
    this.sprite,
    this.surfacePattern,
    this.traitSurfacePattern,
    this.spriteMirrorX = false,
    this.surfaceOpacity = 0,
    this.traitSurfaceOpacity = 0,
    this.constructionSprite = false,
    this.showContextEffects = true,
  });

  static const DeterministicObjectRenderer renderer =
      DeterministicObjectRenderer();

  final ObjectVisualDescriptor visual;
  final int rotation;
  final ui.Image? sprite;
  final ui.Image? surfacePattern;
  final ui.Image? traitSurfacePattern;
  final bool spriteMirrorX;
  final double surfaceOpacity;
  final double traitSurfaceOpacity;
  final bool constructionSprite;
  final bool showContextEffects;

  @override
  void paint(Canvas canvas, Size size) {
    renderer.paintFitted(
      canvas,
      size,
      visual: visual,
      rotation: rotation,
      sprite: sprite,
      surfacePattern: surfacePattern,
      traitSurfacePattern: traitSurfacePattern,
      spriteMirrorX: spriteMirrorX,
      surfaceOpacity: surfaceOpacity,
      traitSurfaceOpacity: traitSurfaceOpacity,
      constructionSprite: constructionSprite,
      showContextEffects: showContextEffects,
    );
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
        oldDelegate.visual.completion != visual.completion ||
        oldDelegate.visual.focusTrait != visual.focusTrait ||
        oldDelegate.visual.variantKey != visual.variantKey ||
        oldDelegate.sprite != sprite ||
        oldDelegate.surfacePattern != surfacePattern ||
        oldDelegate.traitSurfacePattern != traitSurfacePattern ||
        oldDelegate.spriteMirrorX != spriteMirrorX ||
        oldDelegate.surfaceOpacity != surfaceOpacity ||
        oldDelegate.traitSurfaceOpacity != traitSurfaceOpacity ||
        oldDelegate.constructionSprite != constructionSprite ||
        oldDelegate.showContextEffects != showContextEffects;
  }
}
