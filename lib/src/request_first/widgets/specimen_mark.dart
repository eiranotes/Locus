import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class SpecimenMark extends StatelessWidget {
  const SpecimenMark({
    required this.specimen,
    this.height = 112,
    this.compact = false,
    super.key,
  });

  final Specimen specimen;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      painter: _SpecimenMarkPainter(specimen: specimen, compact: compact),
    );
    return Semantics(
      image: true,
      label: specimenDescription(specimen),
      child: ExcludeSemantics(
        child: height.isFinite
            ? SizedBox(
                height: height,
                width: double.infinity,
                child: painted,
              )
            : SizedBox.expand(child: painted),
      ),
    );
  }
}

String specimenDescription(Specimen specimen) {
  if (specimen.eligibility == SpecimenEligibility.legacyArchive) {
    return '${specimen.context.timeBand.labelKo}의 이전 수집 기록';
  }
  final loudness = specimen.features[SenseAxis.loudness] ?? 0;
  final intermittency = specimen.features[SenseAxis.intermittency] ?? 0;
  final rhythmicity = specimen.features[SenseAxis.rhythmicity];
  final loudnessLabel = switch (loudness) {
    < 0.30 => '조용한',
    < 0.65 => '보통 크기의',
    _ => '큰',
  };
  final continuityLabel = switch (intermittency) {
    < 0.35 => '이어지는',
    < 0.65 => '가끔 끊기는',
    _ => '드문드문 나타나는',
  };
  final rhythmLabel = rhythmicity == null
      ? ''
      : rhythmicity >= 0.65
      ? ' 규칙적인'
      : rhythmicity <= 0.30
      ? ' 불규칙한'
      : '';
  return '${specimen.context.timeBand.labelKo}의 $loudnessLabel $continuityLabel$rhythmLabel 소리 표본';
}

class _SpecimenMarkPainter extends CustomPainter {
  const _SpecimenMarkPainter({required this.specimen, required this.compact});

  final Specimen specimen;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = PixelPalette.scene;
    canvas.drawRect(Offset.zero & size, background);

    final linePaint = Paint()
      ..color = PixelPalette.divider
      ..strokeWidth = 1
      ..isAntiAlias = false;
    final baseline = (size.height * 0.68).roundToDouble();
    canvas.drawLine(
      Offset(8, baseline),
      Offset(size.width - 8, baseline),
      linePaint,
    );

    if (specimen.eligibility == SpecimenEligibility.legacyArchive) {
      _paintLegacy(canvas, size, baseline);
      return;
    }

    final loudness = specimen.features[SenseAxis.loudness] ?? 0.25;
    final intermittency = specimen.features[SenseAxis.intermittency] ?? 0.35;
    final rhythmicity = specimen.features[SenseAxis.rhythmicity] ?? 0.45;
    final dynamicRange = specimen.features[SenseAxis.dynamicRange] ?? 0.40;
    final brightness = specimen.features[SenseAxis.spectralBrightness] ?? 0.45;
    final count = compact ? 18 : 30;
    final availableWidth = size.width - 18;
    final step = availableWidth / count;
    final barWidth = math.max(2.0, (step * 0.52).floorToDouble());
    final maxHeight = size.height * (0.28 + loudness * 0.48);
    var state = specimen.previewSeed & 0x7fffffff;

    for (var index = 0; index < count; index += 1) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      final random = state / 0x7fffffff;
      final rhythmWave =
          0.55 + 0.45 * math.sin(index * math.pi * (0.18 + rhythmicity * 0.32));
      final missingThreshold = intermittency * 0.58;
      if (random < missingThreshold && index % 3 != 0) continue;
      final variation = 0.78 + (random - 0.5) * dynamicRange;
      final height = math.max(3.0, maxHeight * rhythmWave.abs() * variation);
      final x = 9 + index * step;
      final rect = Rect.fromLTWH(
        x.roundToDouble(),
        (baseline - height).roundToDouble(),
        barWidth,
        height.roundToDouble(),
      );
      final paint = Paint()
        ..isAntiAlias = false
        ..color = Color.lerp(
          PixelPalette.mint,
          PixelPalette.amber,
          brightness,
        )!.withValues(alpha: specimen.confidence.clamp(0.55, 1.0));
      canvas.drawRect(rect, paint);
      if (index % 4 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            baseline + 4,
            math.max(2, barWidth * 0.55),
            3,
          ),
          paint..color = paint.color.withValues(alpha: 0.45),
        );
      }
    }
  }

  void _paintLegacy(Canvas canvas, Size size, double baseline) {
    final paint = Paint()
      ..color = PixelPalette.textMuted.withValues(alpha: 0.62)
      ..strokeWidth = 2
      ..isAntiAlias = false;
    final points = <Offset>[];
    final count = compact ? 12 : 20;
    for (var index = 0; index < count; index += 1) {
      final x = 10 + (size.width - 20) * index / (count - 1);
      final y = baseline - 8 - ((index * 17 + specimen.previewSeed) % 22);
      points.add(Offset(x.roundToDouble(), y.roundToDouble()));
    }
    for (var index = 1; index < points.length; index += 1) {
      canvas.drawLine(points[index - 1], points[index], paint);
    }
    for (final point in points.where(
      (Offset value) => value.dx.round() % 3 == 0,
    )) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 3, height: 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpecimenMarkPainter oldDelegate) =>
      oldDelegate.specimen.id != specimen.id ||
      oldDelegate.specimen.previewSeed != specimen.previewSeed ||
      oldDelegate.compact != compact;
}
