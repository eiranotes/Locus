import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors, RadialGradient;
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';

class DioramaGame extends FlameGame {
  DioramaGame(this._snapshot);

  DioramaSnapshot _snapshot;

  void updateSnapshot(DioramaSnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  void render(Canvas canvas) {
    DioramaScenePainter(_snapshot).paint(canvas, Size(size.x, size.y));
  }
}

class DioramaScenePainter {
  DioramaScenePainter(this.snapshot);

  static const double logicalSize = 360;
  static const double tileWidth = 52;
  static const double tileHeight = 26;
  static const Offset origin = Offset(180, 128);

  final DioramaSnapshot snapshot;

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
            const Rect.fromCircle(center: Offset(180, 180), radius: 180),
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
    _drawTreeShape(canvas, backTree, const Color(0xFF536D47), fixed: true);
    _drawBenchShape(canvas, _tileTop(0.4, 1.5), const Color(0xFF6E4C2E));
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
      if (!object.isComplete) {
        _drawConstruction(canvas, anchor, object);
        continue;
      }
      final accent = _weatherAccent(object.weatherKind);
      switch (object.kind) {
        case ObjectKind.alleyLamp:
          _drawLampShape(canvas, anchor, accent);
          break;
        case ObjectKind.signpost:
          _drawSignShape(canvas, anchor, accent, placement.rotation);
          break;
        case ObjectKind.planter:
          _drawPlanterShape(canvas, anchor, accent);
          break;
        case ObjectKind.bench:
          _drawBenchShape(canvas, anchor, accent);
          break;
        case ObjectKind.stairs:
          _drawStairsShape(canvas, anchor, accent, placement.rotation);
          break;
        case ObjectKind.tree:
          _drawTreeShape(canvas, anchor, accent);
          break;
        case ObjectKind.busStop:
          _drawBusStopShape(canvas, anchor, accent);
          break;
        case ObjectKind.pond:
          _drawPondShape(canvas, anchor, accent);
          break;
        case ObjectKind.bridge:
          _drawBridgeShape(canvas, anchor, accent, placement.rotation);
          break;
        case ObjectKind.tower:
          _drawTowerShape(canvas, anchor, accent);
          break;
      }
      _drawConnectorMark(canvas, anchor, object.surroundingKind);
    }
  }

  void _drawConstruction(Canvas canvas, Offset anchor, CraftedObject object) {
    final progress = object.requiredSteps == 0
        ? 0.0
        : object.appliedSteps / object.requiredSteps;
    final wood = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF8A603B);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 17, anchor.dy - 17, 34, 7), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 13, anchor.dy - 29, 4, 20), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx + 9, anchor.dy - 29, 4, 20), wood);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 15, anchor.dy - 34, 30 * progress, 3),
      Paint()..color = PixelPalette.mint,
    );
  }

  void _drawLampShape(Canvas canvas, Offset anchor, Color accent) {
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
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 4, anchor.dy - 58, 8, 9),
      Paint()
        ..isAntiAlias = false
        ..color = PixelPalette.cream,
    );
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

  void _drawBenchShape(Canvas canvas, Offset anchor, Color accent) {
    _drawShadow(canvas, anchor, 28, 8);
    final wood = Paint()
      ..isAntiAlias = false
      ..color = Color.lerp(const Color(0xFF6F4A2F), accent, 0.18)!;
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 22, anchor.dy - 18, 44, 7), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 22, anchor.dy - 31, 44, 7), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx - 18, anchor.dy - 12, 4, 12), wood);
    canvas.drawRect(Rect.fromLTWH(anchor.dx + 14, anchor.dy - 12, 4, 12), wood);
  }

  void _drawTreeShape(
    Canvas canvas,
    Offset anchor,
    Color accent, {
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
    for (final data in <(double, double, double)>[
      (-12, -50, 17),
      (9, -49, 18),
      (-2, -66, 21),
      (-20, -66, 13),
      (17, -65, 13),
    ]) {
      canvas.drawCircle(anchor.translate(data.$1, data.$2), data.$3, paint);
    }
  }

  void _drawPlanterShape(Canvas canvas, Offset anchor, Color accent) {
    _drawShadow(canvas, anchor, 22, 8);
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 16, anchor.dy - 17, 32, 12),
      Paint()..color = const Color(0xFF77513B),
    );
    final green = Color.lerp(const Color(0xFF628558), accent, 0.25)!;
    for (final dx in <double>[-10, -3, 5, 11]) {
      canvas.drawRect(
        Rect.fromLTWH(anchor.dx + dx - 2, anchor.dy - 29, 5, 14),
        Paint()..color = green,
      );
    }
  }

  void _drawStairsShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    int rotation,
  ) {
    _drawShadow(canvas, anchor, 28, 10);
    final direction = rotation == 1 || rotation == 2 ? -1.0 : 1.0;
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
            0.10 + index * 0.04,
          )!,
      );
    }
  }

  void _drawBusStopShape(Canvas canvas, Offset anchor, Color accent) {
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
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 18, anchor.dy - 43, 36, 25),
      Paint()..color = accent.withValues(alpha: 0.45),
    );
    _drawBenchShape(canvas, anchor.translate(0, 1), const Color(0xFF6E4C2E));
  }

  void _drawPondShape(Canvas canvas, Offset anchor, Color accent) {
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
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 8, anchor.dy - 8, 16, 2),
      Paint()..color = PixelPalette.cream.withValues(alpha: 0.45),
    );
  }

  void _drawSignShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    int rotation,
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
  }

  void _drawBridgeShape(
    Canvas canvas,
    Offset anchor,
    Color accent,
    int rotation,
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
    if (vertical) {
      for (var y = rect.top + 6; y < rect.bottom; y += 8) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), line);
      }
    } else {
      for (var x = rect.left + 8; x < rect.right; x += 10) {
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), line);
      }
    }
  }

  void _drawTowerShape(Canvas canvas, Offset anchor, Color accent) {
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
    canvas.drawRect(
      Rect.fromLTWH(anchor.dx - 5, anchor.dy - 55, 10, 13),
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
    final paint = Paint()
      ..isAntiAlias = false
      ..color = color;
    final count = switch (kind) {
      SurroundingMaterialKind.dense => 3,
      SurroundingMaterialKind.dynamic => 2,
      SurroundingMaterialKind.stable => 1,
      SurroundingMaterialKind.sparse => 2,
    };
    for (var index = 0; index < count; index += 1) {
      canvas.drawRect(
        Rect.fromLTWH(anchor.dx - 8 + index * 7, anchor.dy - 7, 3, 3),
        paint,
      );
    }
  }

  void _drawVisitor(Canvas canvas) {
    if (snapshot.activeVisitorId == null) {
      return;
    }
    final anchor = _tileTop(2.2, 4.1).translate(0, -4);
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

  Color _weatherAccent(WeatherMaterialKind kind) => switch (kind) {
    WeatherMaterialKind.clear => const Color(0xFFE2B85F),
    WeatherMaterialKind.rain => const Color(0xFF6FA9C8),
    WeatherMaterialKind.cloudy => const Color(0xFF9EADB0),
    WeatherMaterialKind.windy => const Color(0xFF82B8A0),
    WeatherMaterialKind.cold => const Color(0xFFB8D8E8),
    WeatherMaterialKind.warm => const Color(0xFFD98855),
  };
}
