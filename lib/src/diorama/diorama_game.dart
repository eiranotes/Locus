import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Colors, RadialGradient;
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/diorama/object_renderer.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

class DioramaGame extends FlameGame {
  DioramaGame(this._snapshot);

  DioramaSnapshot _snapshot;
  DioramaArtImages? _art;

  void updateSnapshot(DioramaSnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _art = await DioramaArtImages.load();
    } catch (error, stackTrace) {
      debugPrint('Generated diorama art failed to load: $error\n$stackTrace');
      _art = null;
    }
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    DioramaScenePainter(
      _snapshot,
      art: _art,
    ).paint(canvas, Size(size.x, size.y));
  }
}

class DioramaScenePainter {
  DioramaScenePainter(this.snapshot, {this.art});

  static const double logicalSize = 360;
  static const double tileWidth = 52;
  static const double tileHeight = 26;
  static const Offset origin = Offset(180, 128);
  static const DeterministicObjectRenderer _objectRenderer =
      DeterministicObjectRenderer();

  final DioramaSnapshot snapshot;
  final DioramaArtImages? art;

  void paint(Canvas canvas, Size outputSize) {
    final scale = math.min(
      outputSize.width / logicalSize,
      outputSize.height / logicalSize,
    );
    final offset = Offset(
      (outputSize.width - logicalSize * scale) / 2,
      (outputSize.height - logicalSize * scale) / 2,
    );
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, logicalSize, logicalSize));

    _drawBackdrop(canvas);
    _drawPlatform(canvas);
    _drawFixedArchitecture(canvas);
    _drawConnections(canvas);
    _drawPlacedObjects(canvas);
    _drawVisitor(canvas);
    _drawWeather(canvas);

    canvas.restore();
  }

  void _drawBackdrop(Canvas canvas) {
    final background = switch (snapshot.timeBand) {
      TimeBand.dawn => const Color(0xFF102536),
      TimeBand.morning => const Color(0xFF264552),
      TimeBand.afternoon => const Color(0xFF304D55),
      TimeBand.evening => const Color(0xFF17293A),
      TimeBand.night => const Color(0xFF071522),
    };
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, logicalSize, logicalSize),
      Paint()..color = background,
    );

    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              PixelPalette.amber.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: const Offset(180, 180), radius: 180),
          );
    canvas.drawRect(const Rect.fromLTWH(0, 0, logicalSize, logicalSize), glow);
  }

  void _drawPlatform(Canvas canvas) {
    final sidePaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF17222A);
    final platformTop = <Offset>[
      _tileTop(-0.55, 2.5),
      _tileTop(2.5, -0.55),
      _tileTop(5.55, 2.5),
      _tileTop(2.5, 5.55),
    ];
    final side = Path()
      ..moveTo(platformTop[3].dx, platformTop[3].dy)
      ..lineTo(platformTop[2].dx, platformTop[2].dy)
      ..lineTo(platformTop[2].dx, platformTop[2].dy + 20)
      ..lineTo(platformTop[3].dx, platformTop[3].dy + 20)
      ..close();
    canvas.drawPath(side, sidePaint);

    for (var order = 0; order <= 8; order += 1) {
      for (var row = 0; row < 5; row += 1) {
        final column = order - row;
        if (column < 0 || column >= 5) {
          continue;
        }
        _drawTile(canvas, column, row);
      }
    }
  }

  void _drawTile(Canvas canvas, int column, int row) {
    final center = _tileTop(column.toDouble(), row.toDouble());
    final path = Path()
      ..moveTo(center.dx, center.dy - tileHeight / 2)
      ..lineTo(center.dx + tileWidth / 2, center.dy)
      ..lineTo(center.dx, center.dy + tileHeight / 2)
      ..lineTo(center.dx - tileWidth / 2, center.dy)
      ..close();
    final effects = snapshot.environmentGrid.at(column, row);
    var color = const Color(0xFF344048);
    if (effects.wet > 0) {
      color = Color.lerp(color, const Color(0xFF315569), 0.55)!;
    }
    if (effects.warm > 0) {
      color = Color.lerp(color, const Color(0xFF65513B), 0.38)!;
    }
    if (effects.cool > 0) {
      color = Color.lerp(color, const Color(0xFF35485C), 0.40)!;
    }
    if (effects.nature > 0) {
      color = Color.lerp(color, const Color(0xFF3D5546), 0.45)!;
    }
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = false
        ..color = color,
    );
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF17222A),
    );
    if (effects.wet > 0 && (column + row).isEven) {
      canvas.drawRect(
        Rect.fromCenter(center: center.translate(0, 2), width: 14, height: 2),
        Paint()
          ..isAntiAlias = false
          ..color = const Color(0xFF75A7BD).withValues(alpha: 0.42),
      );
    }
  }

  void _drawFixedArchitecture(Canvas canvas) {
    final houseBase = _tileTop(2.6, 0.15).translate(0, -4);
    final generatedArt = art;
    if (generatedArt != null) {
      _drawArtImage(
        canvas,
        generatedArt.scenery['house'],
        anchor: houseBase,
        size: const Size(132, 132),
      );
      _drawArtImage(
        canvas,
        generatedArt.scenery['tree'],
        anchor: _tileTop(0.25, 0.35),
        size: const Size(94, 94),
      );
      _drawArtImage(
        canvas,
        generatedArt.scenery['bench'],
        anchor: _tileTop(0.45, 1.6),
        size: const Size(88, 72),
      );
      _drawArtImage(
        canvas,
        generatedArt.scenery['fence'],
        anchor: _tileTop(4.25, 1.0),
        size: const Size(92, 70),
      );
      _drawArtImage(
        canvas,
        generatedArt.scenery['path_junction'],
        anchor: _tileTop(2.6, 4.15).translate(0, 3),
        size: const Size(96, 66),
      );
      return;
    }
    final wall = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF354047);
    final roof = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF17232D);
    final timber = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF4B3426);
    final window = Paint()
      ..isAntiAlias = false
      ..color = snapshot.timeBand == TimeBand.afternoon
          ? const Color(0xFF87A7A4)
          : PixelPalette.amber;

    canvas.drawRect(
      Rect.fromLTWH(houseBase.dx - 53, houseBase.dy - 56, 106, 54),
      wall,
    );
    final roofPath = Path()
      ..moveTo(houseBase.dx - 60, houseBase.dy - 56)
      ..lineTo(houseBase.dx - 25, houseBase.dy - 80)
      ..lineTo(houseBase.dx + 60, houseBase.dy - 56)
      ..lineTo(houseBase.dx + 25, houseBase.dy - 34)
      ..close();
    canvas.drawPath(roofPath, roof);
    canvas.drawRect(
      Rect.fromLTWH(houseBase.dx - 8, houseBase.dy - 38, 18, 36),
      timber,
    );
    for (final dx in <double>[-37, 24]) {
      canvas.drawRect(
        Rect.fromLTWH(houseBase.dx + dx, houseBase.dy - 38, 18, 16),
        window,
      );
      canvas.drawRect(
        Rect.fromLTWH(houseBase.dx + dx + 7, houseBase.dy - 38, 2, 16),
        timber,
      );
    }

    final backTree = _tileTop(0.4, 0.4).translate(-6, -6);
    _objectRenderer.paintFixedTree(canvas, backTree, const Color(0xFF536D47));
    _objectRenderer.paintFixedBench(
      canvas,
      _tileTop(0.4, 1.5),
      const Color(0xFF6E4C2E),
    );
  }

  void _drawConnections(Canvas canvas) {
    final placementByObject = <String, Placement>{
      for (final placement in snapshot.placements)
        placement.craftedObjectId: placement,
    };
    for (final edge in snapshot.connectionGraph.edges) {
      final from = placementByObject[edge.fromObjectId];
      final to = placementByObject[edge.toObjectId];
      if (from == null || to == null) {
        continue;
      }
      final a = _tileTop(
        from.column.toDouble(),
        from.row.toDouble(),
      ).translate(0, -16);
      final b = _tileTop(
        to.column.toDouble(),
        to.row.toDouble(),
      ).translate(0, -16);
      final color = switch (edge.mode) {
        ConnectionMode.adjacent => PixelPalette.muted,
        ConnectionMode.dense => PixelPalette.mint,
        ConnectionMode.sequential => PixelPalette.blue,
        ConnectionMode.stable => PixelPalette.amber,
        ConnectionMode.far => PixelPalette.violet,
      };
      final paint = Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge.mode == ConnectionMode.far ? 2 : 1.4
        ..color = color.withValues(alpha: 0.55);
      if (edge.mode == ConnectionMode.sequential) {
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo((a.dx + b.dx) / 2, a.dy - 4)
          ..lineTo(b.dx, b.dy);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(a, b, paint);
      }
      canvas.drawRect(
        Rect.fromCenter(center: a, width: 3, height: 3),
        Paint()..color = color,
      );
      canvas.drawRect(
        Rect.fromCenter(center: b, width: 3, height: 3),
        Paint()..color = color,
      );
    }
  }

  void _drawPlacedObjects(Canvas canvas) {
    final objects = <String, CraftedObject>{
      for (final object in snapshot.objects) object.id: object,
    };
    final placements = List<Placement>.of(snapshot.placements)
      ..sort((Placement a, Placement b) {
        return (a.row + a.column).compareTo(b.row + b.column);
      });

    for (final placement in placements) {
      final object = objects[placement.craftedObjectId];
      if (object == null) {
        continue;
      }
      final anchor = _tileTop(
        placement.column.toDouble(),
        placement.row.toDouble(),
      );
      _objectRenderer.paintAt(
        canvas,
        anchor: anchor,
        visual: ObjectVisualDescriptor.fromCraftedObject(
          object,
          timeBand:
              snapshot.weatherMaterialsById[object.weatherMaterialId]?.timeBand,
        ),
        rotation: placement.rotation,
        sprite: art?.objects[object.kind],
      );
    }
  }

  void _drawVisitor(Canvas canvas) {
    if (snapshot.activeVisitorId == null) {
      return;
    }
    final anchor = _tileTop(2.2, 4.1).translate(0, -4);
    final generatedVisitor = art?.visitors[snapshot.activeVisitorId];
    if (generatedVisitor != null) {
      _drawArtImage(
        canvas,
        generatedVisitor,
        anchor: anchor,
        size: const Size(66, 66),
      );
      return;
    }
    _drawShadow(canvas, anchor, 20, 7);
    final coat = snapshot.activeVisitorId == 'umbrella_walker'
        ? PixelPalette.amber
        : PixelPalette.mint;
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 7, anchor.dy - 27, 14, 20),
      Paint()..color = coat,
    );
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 4, anchor.dy - 37, 8, 9),
      Paint()..color = const Color(0xFFD4B08A),
    );
    if (snapshot.activeVisitorId == 'umbrella_walker') {
      final umbrella = Path()
        ..moveTo(anchor.dx - 18, anchor.dy - 39)
        ..quadraticBezierTo(
          anchor.dx,
          anchor.dy - 57,
          anchor.dx + 18,
          anchor.dy - 39,
        )
        ..close();
      canvas.drawPath(umbrella, Paint()..color = PixelPalette.blue);
      canvas.drawRect(
        Rect.fromLTWH(anchor.dx, anchor.dy - 42, 2, 19),
        Paint()..color = PixelPalette.cream,
      );
    }
  }

  void _drawWeather(Canvas canvas) {
    final generatedArt = art;
    if (generatedArt != null) {
      final timeOpacity = switch (snapshot.timeBand) {
        TimeBand.dawn => 0.14,
        TimeBand.morning => 0.0,
        TimeBand.afternoon => 0.0,
        TimeBand.evening => 0.12,
        TimeBand.night => 0.14,
      };
      if (timeOpacity > 0) {
        _drawOverlay(
          canvas,
          generatedArt.timeOverlays[snapshot.timeBand],
          opacity: timeOpacity,
        );
      }
      final weatherOpacity = switch (snapshot.weatherKind) {
        WeatherMaterialKind.rain => 0.24,
        WeatherMaterialKind.cloudy => 0.14,
        WeatherMaterialKind.windy => 0.18,
        WeatherMaterialKind.cold => 0.22,
        WeatherMaterialKind.clear => 0.0,
        WeatherMaterialKind.warm => 0.10,
      };
      if (weatherOpacity > 0) {
        _drawOverlay(
          canvas,
          generatedArt.weatherOverlays[snapshot.weatherKind],
          opacity: weatherOpacity,
        );
      }
      return;
    }
    switch (snapshot.weatherKind) {
      case WeatherMaterialKind.rain:
        final paint = Paint()
          ..isAntiAlias = false
          ..color = PixelPalette.blue.withValues(alpha: 0.42)
          ..strokeWidth = 1;
        for (var index = 0; index < 28; index += 1) {
          final x = ((index * 47 + snapshot.objects.length * 19) % 360)
              .toDouble();
          final y = ((index * 83 + 11) % 300).toDouble();
          canvas.drawLine(Offset(x, y), Offset(x - 3, y + 9), paint);
        }
        break;
      case WeatherMaterialKind.cloudy:
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, logicalSize, logicalSize),
          Paint()..color = const Color(0xFFB8C7CB).withValues(alpha: 0.035),
        );
        break;
      case WeatherMaterialKind.windy:
        final paint = Paint()
          ..color = PixelPalette.cream.withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        for (var index = 0; index < 6; index += 1) {
          final y = 75.0 + index * 39;
          canvas.drawArc(
            Rect.fromLTWH(20 + index * 7, y, 100, 22),
            0.1,
            2.1,
            false,
            paint,
          );
        }
        break;
      case WeatherMaterialKind.cold:
        final paint = Paint()..color = Colors.white.withValues(alpha: 0.48);
        for (var index = 0; index < 22; index += 1) {
          final x = ((index * 61 + 17) % 350).toDouble();
          final y = ((index * 37 + 23) % 330).toDouble();
          canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), paint);
        }
        break;
      case WeatherMaterialKind.clear:
      case WeatherMaterialKind.warm:
        break;
    }
  }

  Offset _tileTop(double column, double row) => Offset(
    origin.dx + (column - row) * tileWidth / 2,
    origin.dy + (column + row) * tileHeight / 2,
  );

  void _drawArtImage(
    Canvas canvas,
    Image? image, {
    required Offset anchor,
    required Size size,
  }) {
    if (image == null) {
      return;
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        anchor.dx - size.width / 2,
        anchor.dy - size.height,
        size.width,
        size.height,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  void _drawOverlay(Canvas canvas, Image? image, {required double opacity}) {
    if (image == null || opacity <= 0) {
      return;
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, logicalSize, logicalSize),
      Paint()
        ..filterQuality = FilterQuality.none
        ..color = Colors.white.withValues(alpha: opacity),
    );
  }

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
}
