import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

enum RecordEffectSource { surroundings, weather, trace }

class RecordEffectVisual {
  const RecordEffectVisual({
    required this.source,
    required this.label,
    required this.accent,
    this.assetPath,
  });

  final RecordEffectSource source;
  final String label;
  final Color accent;
  final String? assetPath;
}

RecordEffectVisual recordEffectVisualFor({
  required CaptureRecord record,
  WeatherMaterial? weather,
  SurroundingMaterial? surroundings,
}) {
  if (surroundings != null) {
    return RecordEffectVisual(
      source: RecordEffectSource.surroundings,
      label: '${surroundings.kind.shortLabelKo} 주변 효과',
      accent: _surroundingAccent(surroundings.kind),
      assetPath: GeneratedArtPaths.surroundingMaterial(surroundings.kind),
    );
  }
  if (weather != null) {
    return RecordEffectVisual(
      source: RecordEffectSource.weather,
      label: '${weather.kind.labelKo} 날씨 표본',
      accent: _weatherAccent(weather.kind),
      assetPath: GeneratedArtPaths.weatherMaterial(weather.kind),
    );
  }
  return const RecordEffectVisual(
    source: RecordEffectSource.trace,
    label: '주변 기록 파형',
    accent: PixelPalette.textMuted,
  );
}

class RecordScenePreview extends StatelessWidget {
  const RecordScenePreview({
    required this.record,
    required this.weather,
    required this.surroundings,
    super.key,
  });

  final CaptureRecord record;
  final WeatherMaterial? weather;
  final SurroundingMaterial? surroundings;

  @override
  Widget build(BuildContext context) {
    final visual = recordEffectVisualFor(
      record: record,
      weather: weather,
      surroundings: surroundings,
    );
    final place = record.userPlaceLabel ?? '현재 지역';
    return Semantics(
      image: true,
      label: '$place, ${record.timeBand.labelKo}, ${visual.label} 기록',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PixelRadii.tile),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              painter: _EffectSamplePainter(
                accent: visual.accent,
                timeBand: record.timeBand,
                seed: _stableSeed(record.id),
              ),
            ),
            if (visual.assetPath case final path?)
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  heightFactor: 0.68,
                  child: Image.asset(
                    path,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EffectSamplePainter extends CustomPainter {
  const _EffectSamplePainter({
    required this.accent,
    required this.timeBand,
    required this.seed,
  });

  final Color accent;
  final TimeBand timeBand;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final background = switch (timeBand) {
      TimeBand.dawn => const Color(0xFF142B38),
      TimeBand.morning => const Color(0xFF1C3640),
      TimeBand.afternoon => const Color(0xFF18313B),
      TimeBand.evening => const Color(0xFF112635),
      TimeBand.night => const Color(0xFF081724),
    };
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final scanPaint = Paint()
      ..isAntiAlias = false
      ..color = PixelPalette.cream.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var y = 7.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }

    final chamber = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.12,
      size.width * 0.70,
      size.height * 0.74,
    );
    canvas.drawRect(
      chamber,
      Paint()..color = const Color(0xFF07131E).withValues(alpha: 0.42),
    );
    canvas.drawRect(
      chamber,
      Paint()
        ..isAntiAlias = false
        ..color = accent.withValues(alpha: 0.52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tracePaint = Paint()
      ..isAntiAlias = false
      ..color = accent.withValues(alpha: 0.62)
      ..strokeWidth = 2;
    final centerY = size.height * 0.51;
    final points = <Offset>[];
    for (var index = 0; index < 9; index += 1) {
      final x = size.width * (0.04 + index * 0.115);
      final bit = (seed >> (index % 12)) & 3;
      final y = centerY + (bit - 1.5) * 4;
      points.add(Offset(x, y));
    }
    for (var index = 1; index < points.length; index += 1) {
      canvas.drawLine(points[index - 1], points[index], tracePaint);
    }

    final motePaint = Paint()
      ..isAntiAlias = false
      ..color = accent.withValues(alpha: 0.78);
    for (var index = 0; index < 6; index += 1) {
      final x =
          ((seed + index * 37) % 89) / 100 * size.width + size.width * 0.05;
      final y =
          ((seed ~/ 7 + index * 29) % 70) / 100 * size.height +
          size.height * 0.14;
      final side = index.isEven ? 2.0 : 3.0;
      canvas.drawRect(Rect.fromLTWH(x, y, side, side), motePaint);
    }
  }

  @override
  bool shouldRepaint(_EffectSamplePainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.timeBand != timeBand ||
      oldDelegate.seed != seed;
}

Color _surroundingAccent(SurroundingMaterialKind kind) => switch (kind) {
  SurroundingMaterialKind.dense => PixelPalette.amber,
  SurroundingMaterialKind.dynamic => PixelPalette.violet,
  SurroundingMaterialKind.stable => PixelPalette.mint,
  SurroundingMaterialKind.sparse => PixelPalette.blue,
};

Color _weatherAccent(WeatherMaterialKind kind) => switch (kind) {
  WeatherMaterialKind.clear => PixelPalette.amber,
  WeatherMaterialKind.rain => PixelPalette.blue,
  WeatherMaterialKind.cloudy => PixelPalette.textMuted,
  WeatherMaterialKind.windy => PixelPalette.mint,
  WeatherMaterialKind.cold => const Color(0xFFB8D8E8),
  WeatherMaterialKind.warm => const Color(0xFFD98855),
};

int _stableSeed(String input) {
  var hash = 17;
  for (final unit in input.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return hash;
}
