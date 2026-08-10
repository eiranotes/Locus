import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class RecordSceneVisual {
  const RecordSceneVisual({
    required this.sceneryName,
    required this.seasonalDetailName,
    required this.atmosphereDetailName,
  });

  final String sceneryName;
  final String seasonalDetailName;
  final String atmosphereDetailName;
}

RecordSceneVisual recordSceneVisualFor(
  CaptureRecord record,
  WeatherMaterial? weather,
) {
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
  final seasonal = switch (record.season) {
    Season.spring => const <String>['wildflowers', 'flower_petals', 'clover'],
    Season.summer => const <String>['grass_blades', 'fern', 'moss'],
    Season.autumn => const <String>['autumn_leaves', 'acorns', 'twig'],
    Season.winter => const <String>['snow_tuft', 'dry_weed', 'pebbles'],
  };
  final atmosphere = switch (weather?.kind) {
    WeatherMaterialKind.rain => const <String>[
      'falling_raindrops',
      'rain_ripples',
    ],
    WeatherMaterialKind.cloudy => const <String>['mist_wisp'],
    WeatherMaterialKind.windy => const <String>['wind_leaves'],
    WeatherMaterialKind.cold => const <String>['frost_sparkles'],
    WeatherMaterialKind.warm => const <String>['warm_motes'],
    WeatherMaterialKind.clear || null => switch (record.timeBand) {
      TimeBand.dawn => const <String>['dawn_sparkle'],
      TimeBand.morning || TimeBand.afternoon => const <String>['morning_rays'],
      TimeBand.evening => const <String>['evening_windows'],
      TimeBand.night => const <String>['night_moths'],
    },
  };
  return RecordSceneVisual(
    sceneryName: scenery[seed % scenery.length],
    seasonalDetailName: seasonal[(seed ~/ 7) % seasonal.length],
    atmosphereDetailName: atmosphere[(seed ~/ 13) % atmosphere.length],
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
    final visual = recordSceneVisualFor(record, weather);
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
                seed: _stableSeed(record.id),
              ),
            ),
            Opacity(
              opacity: 0.28,
              child: _RecordAsset(
                path: GeneratedArtPaths.timeOverlay(record.timeBand),
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 0.88,
                heightFactor: 0.82,
                child: _RecordAsset(
                  path: GeneratedArtPaths.scenery(visual.sceneryName),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (weatherKind != null)
              Opacity(
                opacity: 0.42,
                child: _RecordAsset(
                  path: GeneratedArtPaths.weatherOverlay(weatherKind),
                  fit: BoxFit.cover,
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: FractionallySizedBox(
                widthFactor: 0.30,
                heightFactor: 0.34,
                child: _RecordAsset(
                  path: GeneratedArtPaths.terrainDetail(
                    visual.seasonalDetailName,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Opacity(
              opacity: 0.70,
              child: _RecordAsset(
                path: GeneratedArtPaths.atmosphereDetail(
                  visual.atmosphereDetailName,
                ),
                fit: BoxFit.cover,
              ),
            ),
            if (surroundings != null)
              Positioned(
                right: 7,
                bottom: 7,
                width: 25,
                height: 25,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: PixelPalette.canvas.withValues(alpha: 0.82),
                    border: Border.all(color: PixelPalette.visitor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: _RecordAsset(
                      path: GeneratedArtPaths.surroundingMaterial(
                        surroundings!.kind,
                      ),
                      fit: BoxFit.contain,
                    ),
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
    required this.seed,
  });

  final TimeBand timeBand;
  final Season season;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..isAntiAlias = false
      ..color = switch (timeBand) {
        TimeBand.dawn => const Color(0xFF27364D),
        TimeBand.morning => const Color(0xFF365A68),
        TimeBand.afternoon => const Color(0xFF2E5362),
        TimeBand.evening => const Color(0xFF44364D),
        TimeBand.night => const Color(0xFF111D35),
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
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
      ground,
    );

    final light = Paint()
      ..isAntiAlias = false
      ..color = timeBand == TimeBand.night
          ? const Color(0xFFC7D4D0)
          : const Color(0xFFE6BC68);
    final unit = (size.shortestSide / 32).clamp(2.0, 4.0);
    final x = size.width * (0.18 + (seed % 4) * 0.12);
    final y = size.height * 0.15;
    canvas.drawRect(Rect.fromLTWH(x, y, unit * 3, unit * 3), light);

    if (timeBand == TimeBand.night || timeBand == TimeBand.dawn) {
      for (var index = 0; index < 7; index += 1) {
        final starX = ((seed ~/ (index + 5) + index * 23) % 90) / 100;
        final starY = ((seed ~/ (index + 9) + index * 17) % 42) / 100;
        canvas.drawRect(
          Rect.fromLTWH(size.width * starX, size.height * starY, unit, unit),
          light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RecordBackdropPainter oldDelegate) =>
      oldDelegate.timeBand != timeBand ||
      oldDelegate.season != season ||
      oldDelegate.seed != seed;
}

int _stableSeed(String input) {
  var hash = 17;
  for (final unit in input.codeUnits) {
    hash = (hash * 31 + unit) & 0x7FFFFFFF;
  }
  return hash;
}
