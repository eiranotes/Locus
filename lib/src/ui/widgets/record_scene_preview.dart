import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class RecordSceneVisual {
  const RecordSceneVisual({required this.sceneryName});

  final String sceneryName;
}

RecordSceneVisual recordSceneVisualFor(CaptureRecord record) {
  final seed = _stableSeed(record.id);
  const scenery = <String>[
    'house',
    'workshop',
    'kiosk',
    'shed',
    'tree',
    'bench',
    'fence',
    'path_junction',
  ];
  return RecordSceneVisual(sceneryName: scenery[seed % scenery.length]);
}

class RecordScenePreview extends StatelessWidget {
  const RecordScenePreview({
    required this.record,
    required this.weather,
    super.key,
  });

  final CaptureRecord record;
  final WeatherMaterial? weather;

  @override
  Widget build(BuildContext context) {
    final visual = recordSceneVisualFor(record);
    final weatherKind = weather?.kind;
    final place = record.userPlaceLabel ?? '현재 지역';
    final weatherLabel = weatherKind?.labelKo ?? '날씨 없음';
    return Semantics(
      image: true,
      label: '$place, ${record.timeBand.labelKo}, $weatherLabel 기록',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PixelRadii.tile),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              painter: _RecordBackdropPainter(
                timeBand: record.timeBand,
                season: record.season,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.76,
                heightFactor: 0.78,
                child: _RecordAsset(
                  path: GeneratedArtPaths.scenery(visual.sceneryName),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordAsset extends StatelessWidget {
  const _RecordAsset({required this.path, required this.fit});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(
    path,
    fit: fit,
    filterQuality: FilterQuality.none,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}

class _RecordBackdropPainter extends CustomPainter {
  const _RecordBackdropPainter({
    required this.timeBand,
    required this.season,
  });

  final TimeBand timeBand;
  final Season season;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..isAntiAlias = false
      ..color = switch (timeBand) {
        TimeBand.dawn => const Color(0xFF203646),
        TimeBand.morning => const Color(0xFF2E4D59),
        TimeBand.afternoon => const Color(0xFF25434F),
        TimeBand.evening => const Color(0xFF1C2E3C),
        TimeBand.night => const Color(0xFF0B1725),
      };
    canvas.drawRect(Offset.zero & size, sky);

    final ground = Paint()
      ..isAntiAlias = false
      ..color = switch (season) {
        Season.spring => const Color(0xFF294B3F),
        Season.summer => const Color(0xFF24483C),
        Season.autumn => const Color(0xFF513D2F),
        Season.winter => const Color(0xFF394A51),
      };
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
      ground,
    );

  }

  @override
  bool shouldRepaint(_RecordBackdropPainter oldDelegate) =>
      oldDelegate.timeBand != timeBand ||
      oldDelegate.season != season;
}

int _stableSeed(String input) {
  var hash = 17;
  for (final unit in input.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return hash;
}
