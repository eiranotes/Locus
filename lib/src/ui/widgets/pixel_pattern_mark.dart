import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/enums.dart';

/// A compact, state-derived mark for simultaneous collection patterns.
///
/// The painter uses only axis-aligned rectangles on a 10 x 10 grid. Distinct
/// families keep fixed positions while same-family weaves fill the available
/// source positions, so two- and three-input patterns remain recognizable at
/// small sizes without relying on a generic network glyph.
class PixelWeaveMark extends StatelessWidget {
  const PixelWeaveMark({
    required this.families,
    this.size = 24,
    this.animate = false,
    super.key,
  });

  final List<CapturePatternFamily> families;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final staticMark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: PixelWeavePainter(families: families, progress: 1),
      ),
    );
    if (!animate || reducedMotion) return staticMark;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (BuildContext context, double progress, Widget? child) {
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: PixelWeavePainter(families: families, progress: progress),
          ),
        );
      },
    );
  }
}

class PatternFamilyMark extends StatelessWidget {
  const PatternFamilyMark({required this.family, this.size = 24, super.key});

  final CapturePatternFamily family;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: PatternFamilyPainter(family: family)),
  );
}

/// A small multi-family stamp for pattern section headers and empty states.
class PixelPatternStamp extends StatelessWidget {
  const PixelPatternStamp({this.size = 24, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: PixelPatternStampPainter(color: color)),
  );
}

/// A stepped disclosure indicator. It points right when collapsed and down
/// when expanded, matching the spatial change of the content below it.
class PixelCaret extends StatelessWidget {
  const PixelCaret({required this.expanded, this.size = 20, super.key});

  final bool expanded;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedRotation(
      turns: expanded ? 0.25 : 0,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: PixelCaretPainter()),
      ),
    );
  }
}

/// A quiet ledger divider with square terminals instead of a floating line.
class PixelRule extends StatelessWidget {
  const PixelRule({
    this.color = PixelPalette.divider,
    this.height = 7,
    super.key,
  });

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: CustomPaint(painter: PixelRulePainter(color: color)),
  );
}

class PixelWeavePainter extends CustomPainter {
  const PixelWeavePainter({required this.families, this.progress = 1});

  final List<CapturePatternFamily> families;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _PixelGrid(size);
    final slots = _sourceSlots(families);
    final boundedProgress = progress.clamp(0.0, 1.0);
    if (boundedProgress <= 0) return;

    final corePaint = Paint()
      ..isAntiAlias = false
      ..color = PixelPalette.reward;
    grid.rect(canvas, corePaint, 4, 4, 2, 2);
    final glintPaint = Paint()
      ..isAntiAlias = false
      ..color = PixelPalette.textStrong;
    grid.rect(canvas, glintPaint, 5, 4, 1, 1);

    for (var index = 0; index < slots.length; index += 1) {
      final threshold = (index + 1) / (slots.length + 1);
      if (boundedProgress < threshold) continue;
      _paintSource(canvas, grid, slots[index]);
    }
  }

  @override
  bool shouldRepaint(PixelWeavePainter oldDelegate) =>
      !listEquals(oldDelegate.families, families) ||
      oldDelegate.progress != progress;
}

class PatternFamilyPainter extends CustomPainter {
  const PatternFamilyPainter({required this.family});

  final CapturePatternFamily family;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _PixelGrid(size);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = patternFamilyColor(family);
    switch (_normalizedFamily(family)) {
      case CapturePatternFamily.time:
        _paintTimeFamily(canvas, grid, paint);
      case CapturePatternFamily.weather:
        _paintWeatherFamily(canvas, grid, paint);
      case CapturePatternFamily.surroundings:
        _paintSurroundingsFamily(canvas, grid, paint);
      case CapturePatternFamily.season:
      case CapturePatternFamily.combination:
        _paintTimeFamily(canvas, grid, paint);
    }
  }

  @override
  bool shouldRepaint(PatternFamilyPainter oldDelegate) =>
      oldDelegate.family != family;
}

class PixelPatternStampPainter extends CustomPainter {
  const PixelPatternStampPainter({this.color});

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _PixelGrid(size);
    final colors = color == null
        ? const <Color>[
            PixelPalette.reward,
            PixelPalette.weather,
            PixelPalette.visitor,
            PixelPalette.textBody,
          ]
        : List<Color>.filled(4, color!);
    final paint = Paint()..isAntiAlias = false;
    paint.color = colors[0];
    grid.rect(canvas, paint, 1, 1, 3, 3);
    paint.color = colors[1];
    grid.rect(canvas, paint, 5, 0, 2, 2);
    grid.rect(canvas, paint, 7, 2, 2, 3);
    paint.color = colors[2];
    grid.rect(canvas, paint, 1, 5, 3, 3);
    paint.color = colors[3];
    grid.rect(canvas, paint, 5, 6, 4, 2);
    grid.rect(canvas, paint, 4, 8, 2, 1);
  }

  @override
  bool shouldRepaint(PixelPatternStampPainter oldDelegate) =>
      oldDelegate.color != color;
}

class PixelCaretPainter extends CustomPainter {
  const PixelCaretPainter({this.color = PixelPalette.textBody});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _PixelGrid(size);
    final paint = Paint()
      ..isAntiAlias = false
      ..color = color;
    grid.rect(canvas, paint, 1, 1, 2, 1);
    grid.rect(canvas, paint, 3, 2, 2, 1);
    grid.rect(canvas, paint, 5, 3, 2, 2);
    grid.rect(canvas, paint, 3, 5, 2, 1);
    grid.rect(canvas, paint, 1, 6, 2, 1);
  }

  @override
  bool shouldRepaint(PixelCaretPainter oldDelegate) =>
      oldDelegate.color != color;
}

class PixelRulePainter extends CustomPainter {
  const PixelRulePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = color;
    final center = (size.height / 2).floorToDouble();
    canvas.drawRect(Rect.fromLTWH(0, center, size.width, 1), paint);
    canvas.drawRect(Rect.fromLTWH(0, center - 1, 2, 3), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - 2, center - 1, 2, 3), paint);
  }

  @override
  bool shouldRepaint(PixelRulePainter oldDelegate) =>
      oldDelegate.color != color;
}

Color patternFamilyColor(CapturePatternFamily family) =>
    switch (_normalizedFamily(family)) {
      CapturePatternFamily.time => PixelPalette.reward,
      CapturePatternFamily.weather => PixelPalette.weather,
      CapturePatternFamily.surroundings => PixelPalette.visitor,
      CapturePatternFamily.season => PixelPalette.reward,
      CapturePatternFamily.combination => PixelPalette.reward,
    };

CapturePatternFamily _normalizedFamily(CapturePatternFamily family) =>
    family == CapturePatternFamily.season ? CapturePatternFamily.time : family;

List<_SourceSlot> _sourceSlots(List<CapturePatternFamily> families) {
  final normalized = families
      .map(_normalizedFamily)
      .where(
        (CapturePatternFamily value) =>
            value != CapturePatternFamily.combination,
      )
      .take(3)
      .toList(growable: false);
  if (normalized.isEmpty) return const <_SourceSlot>[];
  final allDistinct = normalized.toSet().length == normalized.length;
  if (!allDistinct) {
    return <_SourceSlot>[
      for (var index = 0; index < normalized.length; index += 1)
        _SourceSlot(index: index, family: normalized[index]),
    ];
  }
  return <_SourceSlot>[
    for (final family in normalized)
      _SourceSlot(
        index: switch (family) {
          CapturePatternFamily.time => 0,
          CapturePatternFamily.weather => 1,
          CapturePatternFamily.surroundings => 2,
          CapturePatternFamily.season => 0,
          CapturePatternFamily.combination => 0,
        },
        family: family,
      ),
  ]..sort(
    (_SourceSlot left, _SourceSlot right) => left.index.compareTo(right.index),
  );
}

void _paintSource(Canvas canvas, _PixelGrid grid, _SourceSlot slot) {
  final paint = Paint()
    ..isAntiAlias = false
    ..color = patternFamilyColor(slot.family);
  switch (slot.index) {
    case 0:
      grid.rect(canvas, paint, 2, 3, 1, 2);
      grid.rect(canvas, paint, 2, 4, 2, 1);
      grid.rect(canvas, paint, 0, 1, 1, 1);
      grid.rect(canvas, paint, 1, 1, 1, 1);
      grid.rect(canvas, paint, 0, 2, 1, 1);
    case 1:
      grid.rect(canvas, paint, 7, 3, 1, 2);
      grid.rect(canvas, paint, 6, 4, 2, 1);
      grid.rect(canvas, paint, 8, 1, 1, 1);
      grid.rect(canvas, paint, 9, 1, 1, 1);
      grid.rect(canvas, paint, 9, 2, 1, 1);
    default:
      grid.rect(canvas, paint, 5, 6, 1, 2);
      grid.rect(canvas, paint, 4, 8, 1, 1);
      grid.rect(canvas, paint, 5, 8, 1, 1);
      grid.rect(canvas, paint, 5, 9, 1, 1);
  }
}

void _paintTimeFamily(Canvas canvas, _PixelGrid grid, Paint paint) {
  grid.rect(canvas, paint, 2, 1, 6, 1);
  grid.rect(canvas, paint, 3, 2, 1, 1);
  grid.rect(canvas, paint, 6, 2, 1, 1);
  grid.rect(canvas, paint, 4, 3, 2, 2);
  grid.rect(canvas, paint, 3, 5, 1, 1);
  grid.rect(canvas, paint, 6, 5, 1, 1);
  grid.rect(canvas, paint, 2, 6, 6, 1);
}

void _paintWeatherFamily(Canvas canvas, _PixelGrid grid, Paint paint) {
  grid.rect(canvas, paint, 3, 2, 4, 1);
  grid.rect(canvas, paint, 2, 3, 6, 1);
  grid.rect(canvas, paint, 1, 4, 8, 2);
  grid.rect(canvas, paint, 2, 6, 6, 1);
  grid.rect(canvas, paint, 3, 8, 1, 1);
  grid.rect(canvas, paint, 6, 8, 1, 1);
}

void _paintSurroundingsFamily(Canvas canvas, _PixelGrid grid, Paint paint) {
  grid.rect(canvas, paint, 4, 4, 2, 2);
  grid.rect(canvas, paint, 4, 1, 2, 1);
  grid.rect(canvas, paint, 4, 8, 2, 1);
  grid.rect(canvas, paint, 1, 4, 1, 2);
  grid.rect(canvas, paint, 8, 4, 1, 2);
  grid.rect(canvas, paint, 2, 2, 1, 2);
  grid.rect(canvas, paint, 2, 6, 1, 2);
  grid.rect(canvas, paint, 7, 2, 1, 2);
  grid.rect(canvas, paint, 7, 6, 1, 2);
}

final class _SourceSlot {
  const _SourceSlot({required this.index, required this.family});

  final int index;
  final CapturePatternFamily family;
}

final class _PixelGrid {
  _PixelGrid(Size size)
    : unit = _unitFor(size),
      origin = _originFor(size, _unitFor(size));

  final double unit;
  final Offset origin;

  static double _unitFor(Size size) {
    final candidate = (size.shortestSide / 10).floorToDouble();
    return candidate < 1 ? 1 : candidate;
  }

  static Offset _originFor(Size size, double unit) => Offset(
    ((size.width - unit * 10) / 2).floorToDouble(),
    ((size.height - unit * 10) / 2).floorToDouble(),
  );

  void rect(Canvas canvas, Paint paint, int x, int y, int width, int height) {
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx + x * unit,
        origin.dy + y * unit,
        width * unit,
        height * unit,
      ),
      paint,
    );
  }
}
