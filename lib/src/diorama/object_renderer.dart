import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show Colors, RadialGradient;
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';

/// The single deterministic object renderer used by the scene and UI previews.
///
/// Seeded details stay inside each object's fixed silhouette so visual variety
/// never changes placement or connection rules.
final class DeterministicObjectRenderer {
  const DeterministicObjectRenderer();

  static const Size previewLogicalSize = Size(96, 104);
  static const Offset previewAnchor = Offset(48, 91);

  void paintAt(
    Canvas canvas, {
    required Offset anchor,
    required ObjectVisualDescriptor visual,
    int rotation = 0,
  }) {
    if (visual.completion < 1) {
      _drawConstruction(canvas, anchor, visual.completion);
      return;
    }

    final weatherAccent = _weatherAccent(visual.weatherKind);
    final accent = _hasSeededDetails(visual)
        ? _applyTimePalette(weatherAccent, visual.timeBand)
        : weatherAccent;
    switch (visual.kind) {
      case ObjectKind.alleyLamp:
        _drawLampShape(canvas, anchor, accent, visual);
        break;
      case ObjectKind.signpost:
        _drawSignShape(canvas, anchor, accent, rotation, visual);
        break;
      case ObjectKind.planter:
        _drawPlanterShape(canvas, anchor, accent, visual);
        break;
      case ObjectKind.bench:
        _drawBenchShape(canvas, anchor, accent, visual: visual);
        break;
      case ObjectKind.stairs:
        _drawStairsShape(canvas, anchor, accent, rotation, visual);
        break;
      case ObjectKind.tree:
        _drawTreeShape(canvas, anchor, accent, visual: visual);
        break;
      case ObjectKind.busStop:
        _drawBusStopShape(canvas, anchor, accent, visual);
        break;
      case ObjectKind.pond:
        _drawPondShape(canvas, anchor, accent, visual);
        break;
      case ObjectKind.bridge:
        _drawBridgeShape(canvas, anchor, accent, rotation, visual);
        break;
      case ObjectKind.tower:
        _drawTowerShape(canvas, anchor, accent, visual);
        break;
    }
    _drawConnectorMark(canvas, anchor, visual.surroundingKind);
  }

  void paintFitted(
    Canvas canvas,
    Size outputSize, {
    required ObjectVisualDescriptor visual,
    int rotation = 0,
  }) {
    if (outputSize.isEmpty) {
      return;
    }
    final scale = math.min(
      outputSize.width / previewLogicalSize.width,
      outputSize.height / previewLogicalSize.height,
    );
    final offset = Offset(
      (outputSize.width - previewLogicalSize.width * scale) / 2,
      (outputSize.height - previewLogicalSize.height * scale) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.clipRect(Offset.zero & previewLogicalSize);
    paintAt(canvas, anchor: previewAnchor, visual: visual, rotation: rotation);
    canvas.restore();
  }

  /// Fixed scenery deliberately has no material provenance or connector mark.
  void paintFixedTree(Canvas canvas, Offset anchor, Color accent) {
    _drawTreeShape(canvas, anchor, accent, fixed: true);
  }

  /// Fixed scenery deliberately has no material provenance or connector mark.
  void paintFixedBench(Canvas canvas, Offset anchor, Color accent) {
    _drawBenchShape(canvas, anchor, accent);
  }

  void _drawConstruction(Canvas canvas, Offset anchor, double completion) {
    final wood = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF8A603B);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 17, anchor.dy - 17, 34, 7), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 13, anchor.dy - 29, 4, 20), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx + 9, anchor.dy - 29, 4, 20), wood);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 15, anchor.dy - 34, 30 * completion, 3),
      Paint()..color = PixelPalette.mint,
    );
  }

  void _drawLampShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 18, 7);
    final metal = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF2C3237);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 3, anchor.dy - 43, 6, 36), metal);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 8, anchor.dy - 47, 16, 5), metal);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 7, anchor.dy - 61, 14, 15),
      Paint()
        ..isAntiAlias = false
        ..color = accent,
    );
    final seededDetails = _hasSeededDetails(visual);
    final highlightShift = seededDetails
        ? _detail(visual, 'lamp-highlight', 3) - 1
        : 0;
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 4 + highlightShift, anchor.dy - 58, 8, 9),
      Paint()
        ..isAntiAlias = false
        ..color = PixelPalette.cream,
    );
    if (seededDetails) {
      canvas.drawRect(
        Rect.fromLTWH(
          anchor.dx + (_detail(visual, 'lamp-rivet', 3) - 1),
          anchor.dy - 31,
          2,
          2,
        ),
        Paint()..color = accent.withValues(alpha: 0.78),
      );
    }
    canvas.drawCircle(
      anchor.translate(0, -53),
      15,
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                accent.withValues(alpha: 0.28),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: anchor.translate(0, -53), radius: 15),
            ),
    );
  }

  void _drawBenchShape(
    Canvas canvas,
    Offset anchor,
    Color accent, {
    ObjectVisualDescriptor? visual,
  }) {
    _drawShadow(canvas, anchor, 28, 8);
    final wood = Paint()
      ..isAntiAlias = false
      ..color = Color.lerp(const Color(0xFF6F4A2F), accent, 0.18)!;
    final slatShift = visual == null || !_hasSeededDetails(visual)
        ? 0.0
        : (_detail(visual, 'bench-slats', 3) - 1).toDouble();
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 22, anchor.dy - 18 + slatShift, 44, 7),
      wood,
    );
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 22, anchor.dy - 31, 44, 7), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 18, anchor.dy - 12, 4, 12), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx + 14, anchor.dy - 12, 4, 12), wood);
  }

  void _drawTreeShape(
    Canvas canvas,
    Offset anchor,
    Color accent, {
    ObjectVisualDescriptor? visual,
    bool fixed = false,
  }) {
    _drawShadow(canvas, anchor, 33, 12);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 5, anchor.dy - 45, 10, 38),
      Paint()
        ..isAntiAlias = false
        ..color = const Color(0xFF5B3B26),
    );
    final leaves = Color.lerp(
      const Color(0xFF4E7148),
      accent,
      fixed ? 0.05 : 0.24,
    )!;
    final paint = Paint()
      ..isAntiAlias = false
      ..color = leaves;
    final canopyShift = visual == null || !_hasSeededDetails(visual)
        ? 0.0
        : (_detail(visual, 'tree-canopy', 3) - 1).toDouble();
    for (final data in <(double, double, double)>[
      (-12 + canopyShift, -50, 17),
      (9, -49 - canopyShift, 18),
      (-2, -66, 21),
      (-20, -66, 13),
      (17, -65, 13),
    ]) {
      canvas.drawCircle(anchor.translate(data.$1, data.$2), data.$3, paint);
    }
  }

  void _drawPlanterShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 22, 8);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 16, anchor.dy - 17, 32, 12),
      Paint()..color = const Color(0xFF77513B),
    );
    final green = Color.lerp(const Color(0xFF628558), accent, 0.25)!;
    final tallStem = _hasSeededDetails(visual)
        ? _detail(visual, 'planter-stem', 4)
        : -1;
    for (var index = 0; index < 4; index += 1) {
      final dx = <double>[-10, -3, 5, 11][index];
      final height = 14.0 + (index == tallStem ? 3 : 0);
      canvas.drawRect(
        Rect.fromLTWH(anchor.dx + dx - 2, anchor.dy - 15 - height, 5, height),
        Paint()..color = green,
      );
    }
  }

  void _drawStairsShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    int rotation,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 28, 10);
    final direction = rotation == 1 || rotation == 2 ? -1.0 : 1.0;
    final tintShift = _hasSeededDetails(visual)
        ? _detail(visual, 'stairs-tint', 3) * 0.02
        : 0.0;
    for (var index = 0; index < 4; index += 1) {
      final width = 34 - index * 5;
      canvas.drawRect(
        Rect.fromLTWH(
          anchor.dx - width / 2 + direction * index * 2,
          anchor.dy - 8 - index * 7,
          width.toDouble(),
          7,
        ),
        Paint()
          ..isAntiAlias = false
          ..color = Color.lerp(
            const Color(0xFF515A5C),
            accent,
            0.10 + index * 0.04 + tintShift,
          )!,
      );
    }
  }

  void _drawBusStopShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 33, 11);
    final frame = Paint()..color = const Color(0xFF29373B);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 24, anchor.dy - 48, 5, 42),
      frame,
    );
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx + 19, anchor.dy - 48, 5, 42),
      frame,
    );
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 27, anchor.dy - 51, 54, 6),
      frame,
    );
    final panelInset = _hasSeededDetails(visual)
        ? (_detail(visual, 'bus-panel', 3) - 1).toDouble()
        : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 18 + panelInset, anchor.dy - 43, 36, 25),
      Paint()..color = accent.withValues(alpha: 0.45),
    );
    _drawBenchShape(
      canvas,
      anchor.translate(0, 1),
      const Color(0xFF6E4C2E),
      visual: visual,
    );
  }

  void _drawPondShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    ObjectVisualDescriptor visual,
  ) {
    final water = Color.lerp(const Color(0xFF3D6F84), accent, 0.25)!;
    canvas.drawOval(
      Rect.fromCenter(center: anchor.translate(0, -4), width: 48, height: 20),
      Paint()
        ..isAntiAlias = false
        ..color = const Color(0xFF253038),
    );
    canvas.drawOval(
      Rect.fromCenter(center: anchor.translate(0, -6), width: 40, height: 14),
      Paint()
        ..isAntiAlias = false
        ..color = water,
    );
    final rippleShift = _hasSeededDetails(visual)
        ? (_detail(visual, 'pond-ripple', 5) - 2).toDouble()
        : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 8 + rippleShift, anchor.dy - 8, 16, 2),
      Paint()..color = PixelPalette.cream.withValues(alpha: 0.45),
    );
  }

  void _drawSignShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    int rotation,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 18, 7);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 2, anchor.dy - 35, 4, 30),
      Paint()..color = const Color(0xFF4B3426),
    );
    final direction = rotation == 1 || rotation == 2 ? -1.0 : 1.0;
    canvas.drawRect(
      Rect.fromLTWH(
        direction > 0 ? anchor.dx - 3 : anchor.dx - 22,
        anchor.dy - 35,
        25,
        10,
      ),
      Paint()..color = accent,
    );
    if (_hasSeededDetails(visual)) {
      final markX = direction > 0 ? anchor.dx + 4 : anchor.dx - 10;
      canvas.drawRect(
        Rect.fromLTWH(
          markX + _detail(visual, 'sign-mark', 3) - 1,
          anchor.dy - 32,
          5,
          2,
        ),
        Paint()..color = PixelPalette.cream.withValues(alpha: 0.68),
      );
    }
  }

  void _drawBridgeShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    int rotation,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 44, 12);
    final vertical = rotation.isOdd;
    final rect = vertical
        ? Rect.fromLTWH(anchor.dx - 14, anchor.dy - 42, 28, 48)
        : Rect.fromLTWH(anchor.dx - 35, anchor.dy - 24, 70, 20);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF6A4930));
    final line = Paint()
      ..color = accent
      ..strokeWidth = 2;
    final spacing = _hasSeededDetails(visual)
        ? 8.0 + _detail(visual, 'bridge-planks', 3)
        : 8.0;
    if (vertical) {
      for (var y = rect.top + 6; y < rect.bottom; y += spacing) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
      }
    } else {
      for (var x = rect.left + 8; x < rect.right; x += spacing + 2) {
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), line);
      }
    }
  }

  void _drawTowerShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    ObjectVisualDescriptor visual,
  ) {
    _drawShadow(canvas, anchor, 30, 10);
    final stone = Paint()..color = const Color(0xFF4A5558);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 15, anchor.dy - 65, 30, 58),
      stone,
    );
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 20, anchor.dy - 70, 40, 8),
      stone,
    );
    final windowShift = _hasSeededDetails(visual)
        ? (_detail(visual, 'tower-window', 3) - 1).toDouble()
        : 0.0;
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 5 + windowShift, anchor.dy - 55, 10, 13),
      Paint()..color = accent,
    );
  }

  void _drawConnectorMark(
    Canvas canvas,
    Offset anchor,
    SurroundingMaterialKind? kind,
  ) {
    if (kind == null) {
      return;
    }
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
    for (var index = 0; index < count; index += 1) {
      canvas.drawRect(
        Rect.fromLTWH(anchor.dx - 8 + index * 7, anchor.dy - 7, 3, 3),
        Paint()
          ..isAntiAlias = false
          ..color = color,
      );
    }
  }

  int _detail(ObjectVisualDescriptor visual, String channel, int modulo) {
    return stableSeed(<Object?>[
          visual.generatorVersion,
          visual.visualSeed,
          visual.kind.name,
          channel,
        ]) %
        modulo;
  }

  bool _hasSeededDetails(ObjectVisualDescriptor visual) =>
      visual.generatorVersion != legacyObjectGeneratorVersion;

  Color _applyTimePalette(Color accent, TimeBand? timeBand) =>
      switch (timeBand) {
        TimeBand.dawn => Color.lerp(accent, PixelPalette.violet, 0.18)!,
        TimeBand.morning => Color.lerp(accent, PixelPalette.cream, 0.14)!,
        TimeBand.afternoon => accent,
        TimeBand.evening => Color.lerp(accent, PixelPalette.amber, 0.16)!,
        TimeBand.night => Color.lerp(accent, PixelPalette.blue, 0.20)!,
        null => accent,
      };

  void _drawShadow(Canvas canvas, Offset anchor, double width, double height) {
    canvas.drawOval(
      Rect.fromCenter(
        center: anchor.translate(0, -4),
        width: width,
        height: height,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.27),
    );
  }

  Color _weatherAccent(WeatherMaterialKind? kind) => switch (kind) {
    WeatherMaterialKind.clear => const Color(0xFFE2B85F),
    WeatherMaterialKind.rain => const Color(0xFF6FA9C8),
    WeatherMaterialKind.cloudy => const Color(0xFF9EADB0),
    WeatherMaterialKind.windy => const Color(0xFF82B8A0),
    WeatherMaterialKind.cold => const Color(0xFFB8D8E8),
    WeatherMaterialKind.warm => const Color(0xFFD98855),
    null => PixelPalette.muted,
  };
}
