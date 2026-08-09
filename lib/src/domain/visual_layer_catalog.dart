import 'package:reality_diorama/src/domain/enums.dart';

final class WeatherLayerDefinition {
  const WeatherLayerDefinition({
    required this.kind,
    required this.surfacePatternPath,
    required this.footprintEffectPath,
    required this.surfaceOpacity,
  });

  factory WeatherLayerDefinition.fromJson(Map<String, Object?> json) =>
      WeatherLayerDefinition(
        kind: WeatherMaterialKind.values.byName(json['kind']! as String),
        surfacePatternPath: json['surfacePatternPath']! as String,
        footprintEffectPath: json['footprintEffectPath']! as String,
        surfaceOpacity: (json['surfaceOpacity']! as num).toDouble(),
      );

  final WeatherMaterialKind kind;
  final String surfacePatternPath;
  final String footprintEffectPath;
  final double surfaceOpacity;
}

final class VisualLayerCatalog {
  const VisualLayerCatalog({required this.weather});

  static const VisualLayerCatalog empty = VisualLayerCatalog(
    weather: <WeatherLayerDefinition>[],
  );

  factory VisualLayerCatalog.fromJson(Map<String, Object?> json) =>
      VisualLayerCatalog(
        weather: (json['weather']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(WeatherLayerDefinition.fromJson)
            .toList(growable: false),
      );

  final List<WeatherLayerDefinition> weather;

  WeatherLayerDefinition forWeather(WeatherMaterialKind kind) =>
      weather.firstWhere((WeatherLayerDefinition value) => value.kind == kind);

  void validate() {
    final kinds = weather
        .map((WeatherLayerDefinition value) => value.kind)
        .toSet();
    if (weather.length != WeatherMaterialKind.values.length ||
        kinds.length != weather.length ||
        !kinds.containsAll(WeatherMaterialKind.values)) {
      throw const FormatException(
        'Visual layer catalog must cover every weather kind exactly once.',
      );
    }
    for (final value in weather) {
      if (value.surfaceOpacity <= 0 || value.surfaceOpacity > 1) {
        throw FormatException(
          '${value.kind.name} has an invalid surface opacity.',
        );
      }
    }
  }
}
