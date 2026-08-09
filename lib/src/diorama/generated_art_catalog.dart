import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/domain/visual_layer_catalog.dart';

abstract final class GeneratedArtPaths {
  static const String root = 'assets/art/generated/v1';

  static String object(ObjectKind kind) =>
      '$root/${switch (kind) {
        ObjectKind.alleyLamp => 'object_alley_lamp',
        ObjectKind.signpost => 'object_signpost',
        ObjectKind.planter => 'object_planter',
        ObjectKind.bench => 'object_bench',
        ObjectKind.stairs => 'object_stairs',
        ObjectKind.tree => 'object_tree',
        ObjectKind.busStop => 'object_bus_stop',
        ObjectKind.pond => 'object_pond',
        ObjectKind.bridge => 'object_bridge',
        ObjectKind.tower => 'object_tower',
        ObjectKind.mailbox => 'object_mailbox',
        ObjectKind.rainShelter => 'object_rain_shelter',
        ObjectKind.stoneGate => 'object_stone_gate',
        ObjectKind.clockPost => 'object_clock_post',
        ObjectKind.bookKiosk => 'object_book_kiosk',
        ObjectKind.laundryLine => 'object_laundry_line',
        ObjectKind.flowerArch => 'object_flower_arch',
        ObjectKind.birdBath => 'object_bird_bath',
        ObjectKind.greenhouse => 'object_greenhouse',
        ObjectKind.fountain => 'object_fountain',
        ObjectKind.picnicTable => 'object_picnic_table',
        ObjectKind.willow => 'object_willow',
        ObjectKind.lanternString => 'object_lantern_string',
        ObjectKind.windChime => 'object_wind_chime',
        ObjectKind.teaTable => 'object_tea_table',
        ObjectKind.marketStall => 'object_market_stall',
        ObjectKind.stoneLantern => 'object_stone_lantern',
        ObjectKind.observatory => 'object_observatory',
      }}.png';

  static String visitor(String id) => '$root/visitor_$id.png';

  static String weatherMaterial(WeatherMaterialKind kind) =>
      '$root/material_${kind.name}.png';

  static String surroundingMaterial(SurroundingMaterialKind kind) =>
      '$root/material_${kind.name}.png';

  static String weatherOverlay(WeatherMaterialKind kind) =>
      '$root/${switch (kind) {
        WeatherMaterialKind.rain => 'overlay_rain',
        WeatherMaterialKind.cloudy => 'overlay_fog',
        WeatherMaterialKind.windy => 'overlay_wind',
        WeatherMaterialKind.cold => 'overlay_snow',
        WeatherMaterialKind.clear => 'overlay_morning',
        WeatherMaterialKind.warm => 'overlay_evening',
      }}.png';

  static String timeOverlay(TimeBand timeBand) =>
      '$root/${switch (timeBand) {
        TimeBand.dawn => 'overlay_dawn',
        TimeBand.morning => 'overlay_morning',
        TimeBand.afternoon => 'overlay_morning',
        TimeBand.evening => 'overlay_evening',
        TimeBand.night => 'overlay_night',
      }}.png';

  static String scenery(String name) => '$root/scenery_$name.png';
}

final class DioramaArtImages {
  const DioramaArtImages({
    required this.objectAssets,
    required this.visitors,
    required this.scenery,
    required this.weatherOverlays,
    required this.timeOverlays,
    required this.weatherSurfaces,
    required this.weatherFootprints,
  });

  final Map<String, ui.Image> objectAssets;
  final Map<String, ui.Image> visitors;
  final Map<String, ui.Image> scenery;
  final Map<WeatherMaterialKind, ui.Image> weatherOverlays;
  final Map<TimeBand, ui.Image> timeOverlays;
  final Map<WeatherMaterialKind, ui.Image> weatherSurfaces;
  final Map<WeatherMaterialKind, ui.Image> weatherFootprints;

  static Future<DioramaArtImages> load(
    PlacementCatalog placementCatalog,
    VisualLayerCatalog visualLayerCatalog, {
    required Iterable<String> visitorIds,
  }) async {
    final catalogPaths = <String>{
      for (final entry in placementCatalog.entries)
        for (final visual in entry.visuals) visual.assetPath,
    };
    final objectPaths = <String, String>{
      for (final path
          in catalogPaths.isEmpty
              ? <String>{
                  for (final kind in ObjectKind.values)
                    GeneratedArtPaths.object(kind),
                }
              : catalogPaths)
        path: path,
    };
    final visitorPaths = <String, String>{
      for (final id in visitorIds) id: GeneratedArtPaths.visitor(id),
    };
    final sceneryPaths = <String, String>{
      for (final name in const <String>[
        'house',
        'workshop',
        'kiosk',
        'shed',
        'tree',
        'bench',
        'fence',
        'path_junction',
      ])
        name: GeneratedArtPaths.scenery(name),
    };
    final weatherPaths = <WeatherMaterialKind, String>{
      for (final kind in WeatherMaterialKind.values)
        kind: GeneratedArtPaths.weatherOverlay(kind),
    };
    final timePaths = <TimeBand, String>{
      for (final timeBand in TimeBand.values)
        timeBand: GeneratedArtPaths.timeOverlay(timeBand),
    };
    final surfacePaths = <WeatherMaterialKind, String>{
      for (final layer in visualLayerCatalog.weather)
        layer.kind: layer.surfacePatternPath,
    };
    final footprintPaths = <WeatherMaterialKind, String>{
      for (final layer in visualLayerCatalog.weather)
        layer.kind: layer.footprintEffectPath,
    };

    return DioramaArtImages(
      objectAssets: await _loadMap(objectPaths),
      visitors: await _loadMap(visitorPaths),
      scenery: await _loadMap(sceneryPaths),
      weatherOverlays: await _loadMap(weatherPaths),
      timeOverlays: await _loadMap(timePaths),
      weatherSurfaces: await _loadMap(surfacePaths),
      weatherFootprints: await _loadMap(footprintPaths),
    );
  }

  static Future<Map<K, ui.Image>> _loadMap<K>(Map<K, String> paths) async {
    final entries = await Future.wait(
      paths.entries.map((entry) async {
        return MapEntry<K, ui.Image>(
          entry.key,
          await GeneratedArtImageCache.load(entry.value),
        );
      }),
    );
    return Map<K, ui.Image>.fromEntries(entries);
  }
}

abstract final class GeneratedArtImageCache {
  static final Map<String, Future<ui.Image>> _images =
      <String, Future<ui.Image>>{};

  static Future<ui.Image> load(String path) =>
      _images.putIfAbsent(path, () => _load(path));

  static Future<ui.Image> _load(String path) async {
    final data = await rootBundle.load(path);
    final bytes = Uint8List.sublistView(data);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}
