import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

final class AtmosphericTraitConditions {
  const AtmosphericTraitConditions({
    this.visibilityMetersMin,
    this.visibilityMetersMax,
    this.precipitationRateMmPerHourMin,
    this.precipitationRateMmPerHourMax,
    this.cloudCoverPercentMin,
    this.cloudCoverPercentMax,
    this.windSpeedKphMin,
    this.apparentTemperatureCelsiusMin,
    this.apparentTemperatureCelsiusMax,
  });

  factory AtmosphericTraitConditions.fromJson(Map<String, Object?> json) =>
      AtmosphericTraitConditions(
        visibilityMetersMin: _numberOrNull(json['visibilityMetersMin']),
        visibilityMetersMax: _numberOrNull(json['visibilityMetersMax']),
        precipitationRateMmPerHourMin: _numberOrNull(
          json['precipitationRateMmPerHourMin'],
        ),
        precipitationRateMmPerHourMax: _numberOrNull(
          json['precipitationRateMmPerHourMax'],
        ),
        cloudCoverPercentMin: _numberOrNull(json['cloudCoverPercentMin']),
        cloudCoverPercentMax: _numberOrNull(json['cloudCoverPercentMax']),
        windSpeedKphMin: _numberOrNull(json['windSpeedKphMin']),
        apparentTemperatureCelsiusMin: _numberOrNull(
          json['apparentTemperatureCelsiusMin'],
        ),
        apparentTemperatureCelsiusMax: _numberOrNull(
          json['apparentTemperatureCelsiusMax'],
        ),
      );

  final double? visibilityMetersMin;
  final double? visibilityMetersMax;
  final double? precipitationRateMmPerHourMin;
  final double? precipitationRateMmPerHourMax;
  final double? cloudCoverPercentMin;
  final double? cloudCoverPercentMax;
  final double? windSpeedKphMin;
  final double? apparentTemperatureCelsiusMin;
  final double? apparentTemperatureCelsiusMax;

  bool matches(WeatherSnapshot snapshot) {
    if (!<double>[
      snapshot.temperatureCelsius,
      snapshot.apparentTemperatureCelsius,
      snapshot.precipitationRateMmPerHour,
      snapshot.cloudCoverPercent,
      snapshot.windSpeedKph,
      snapshot.visibilityMeters,
    ].every((double value) => value.isFinite)) {
      return false;
    }
    return _atLeast(snapshot.visibilityMeters, visibilityMetersMin) &&
        _atMost(snapshot.visibilityMeters, visibilityMetersMax) &&
        _atLeast(
          snapshot.precipitationRateMmPerHour,
          precipitationRateMmPerHourMin,
        ) &&
        _atMost(
          snapshot.precipitationRateMmPerHour,
          precipitationRateMmPerHourMax,
        ) &&
        _atLeast(snapshot.cloudCoverPercent, cloudCoverPercentMin) &&
        _atMost(snapshot.cloudCoverPercent, cloudCoverPercentMax) &&
        _atLeast(snapshot.windSpeedKph, windSpeedKphMin) &&
        _atLeast(
          snapshot.apparentTemperatureCelsius,
          apparentTemperatureCelsiusMin,
        ) &&
        _atMost(
          snapshot.apparentTemperatureCelsius,
          apparentTemperatureCelsiusMax,
        );
  }

  static bool _atLeast(double value, double? minimum) =>
      minimum == null || value >= minimum;

  static bool _atMost(double value, double? maximum) =>
      maximum == null || value <= maximum;
}

final class AtmosphericTraitDefinition {
  const AtmosphericTraitDefinition({
    required this.id,
    required this.labelKo,
    required this.descriptionKo,
    required this.effectLabelKo,
    required this.namePrefixKo,
    required this.priority,
    required this.conditions,
    required this.effects,
    required this.spread,
    required this.surfaceOpacityBoost,
    required this.layerKind,
    required this.connectionRangeBonus,
    required this.quietZoneOverride,
    required this.severitySaturation,
  });

  factory AtmosphericTraitDefinition.fromJson(Map<String, Object?> json) {
    final rawEffects = json['effects']! as Map<String, Object?>;
    return AtmosphericTraitDefinition(
      id: AtmosphericTrait.values.byName(json['id']! as String),
      labelKo: json['labelKo']! as String,
      descriptionKo: json['descriptionKo']! as String,
      effectLabelKo: json['effectLabelKo']! as String,
      namePrefixKo: json['namePrefixKo']! as String,
      priority: json['priority']! as int,
      conditions: AtmosphericTraitConditions.fromJson(
        json['conditions']! as Map<String, Object?>,
      ),
      effects: rawEffects.map(
        (String key, Object? value) =>
            MapEntry<String, int>(key, value! as int),
      ),
      spread: AtmosphericTraitSpread.values.byName(json['spread']! as String),
      surfaceOpacityBoost: (json['surfaceOpacityBoost']! as num).toDouble(),
      layerKind: WeatherMaterialKind.values.byName(
        json['layerKind']! as String,
      ),
      connectionRangeBonus: json['connectionRangeBonus']! as int,
      quietZoneOverride: json['quietZoneOverride']! as bool,
      severitySaturation: (json['severitySaturation']! as num).toDouble(),
    );
  }

  final AtmosphericTrait id;
  final String labelKo;
  final String descriptionKo;
  final String effectLabelKo;
  final String namePrefixKo;
  final int priority;
  final AtmosphericTraitConditions conditions;
  final Map<String, int> effects;
  final AtmosphericTraitSpread spread;
  final double surfaceOpacityBoost;
  final WeatherMaterialKind layerKind;
  final int connectionRangeBonus;
  final bool quietZoneOverride;
  final double severitySaturation;

  double severity(WeatherSnapshot snapshot) => switch (id) {
    AtmosphericTrait.activePrecipitation => _ascendingSeverity(
      snapshot.precipitationRateMmPerHour,
      conditions.precipitationRateMmPerHourMin!,
      severitySaturation,
    ),
    AtmosphericTrait.lowVisibility => _descendingSeverity(
      snapshot.visibilityMeters,
      conditions.visibilityMetersMax!,
      severitySaturation,
    ),
    AtmosphericTrait.deepCloud => _ascendingSeverity(
      snapshot.cloudCoverPercent,
      conditions.cloudCoverPercentMin!,
      severitySaturation,
    ),
    AtmosphericTrait.strongWind => _ascendingSeverity(
      snapshot.windSpeedKph,
      conditions.windSpeedKphMin!,
      severitySaturation,
    ),
    AtmosphericTrait.sharpCold => _descendingSeverity(
      snapshot.apparentTemperatureCelsius,
      conditions.apparentTemperatureCelsiusMax!,
      severitySaturation,
    ),
    AtmosphericTrait.intenseHeat => _ascendingSeverity(
      snapshot.apparentTemperatureCelsius,
      conditions.apparentTemperatureCelsiusMin!,
      severitySaturation,
    ),
  };
}

final class AtmosphericTraitCatalog {
  const AtmosphericTraitCatalog({
    required this.classifierVersion,
    required this.maxTraitsPerMaterial,
    required this.definitions,
  });

  static const AtmosphericTraitCatalog empty = AtmosphericTraitCatalog(
    classifierVersion: 'legacy-none',
    maxTraitsPerMaterial: 0,
    definitions: <AtmosphericTraitDefinition>[],
  );

  factory AtmosphericTraitCatalog.fromJson(Map<String, Object?> json) =>
      AtmosphericTraitCatalog(
        classifierVersion: json['classifierVersion']! as String,
        maxTraitsPerMaterial: json['maxTraitsPerMaterial']! as int,
        definitions: (json['traits']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(AtmosphericTraitDefinition.fromJson)
            .toList(growable: false),
      );

  final String classifierVersion;
  final int maxTraitsPerMaterial;
  final List<AtmosphericTraitDefinition> definitions;

  AtmosphericTraitDefinition definitionFor(AtmosphericTrait trait) =>
      definitions.firstWhere(
        (AtmosphericTraitDefinition definition) => definition.id == trait,
      );

  AtmosphericTraitDefinition? tryDefinitionFor(AtmosphericTrait trait) {
    for (final definition in definitions) {
      if (definition.id == trait) return definition;
    }
    return null;
  }

  List<AtmosphericTrait> classify(WeatherSnapshot snapshot) {
    final matches =
        definitions
            .where(
              (AtmosphericTraitDefinition definition) =>
                  definition.conditions.matches(snapshot),
            )
            .toList(growable: false)
          ..sort((AtmosphericTraitDefinition a, AtmosphericTraitDefinition b) {
            final bySeverity = b
                .severity(snapshot)
                .compareTo(a.severity(snapshot));
            if (bySeverity != 0) return bySeverity;
            final byPriority = b.priority.compareTo(a.priority);
            return byPriority != 0
                ? byPriority
                : a.id.index.compareTo(b.id.index);
          });
    return matches
        .take(maxTraitsPerMaterial)
        .map((AtmosphericTraitDefinition definition) => definition.id)
        .toList(growable: false);
  }

  void validate() {
    final ids = definitions
        .map((AtmosphericTraitDefinition definition) => definition.id)
        .toSet();
    if (maxTraitsPerMaterial < 1 || maxTraitsPerMaterial > 2) {
      throw const FormatException(
        'Atmospheric materials must select one or two traits at most.',
      );
    }
    if (definitions.length != AtmosphericTrait.values.length ||
        ids.length != definitions.length ||
        !ids.containsAll(AtmosphericTrait.values)) {
      throw const FormatException(
        'Atmospheric trait catalog must cover every trait exactly once.',
      );
    }
    for (final definition in definitions) {
      if (definition.surfaceOpacityBoost < 0 ||
          definition.surfaceOpacityBoost > 0.2) {
        throw FormatException('${definition.id.name} has invalid modifiers.');
      }
    }
  }
}

double? _numberOrNull(Object? value) => (value as num?)?.toDouble();

double _ascendingSeverity(double value, double threshold, double saturation) {
  if (saturation == threshold) return 1;
  return ((value - threshold) / (saturation - threshold))
      .clamp(0, 1)
      .toDouble();
}

double _descendingSeverity(double value, double threshold, double saturation) {
  if (saturation == threshold) return 1;
  return ((threshold - value) / (threshold - saturation))
      .clamp(0, 1)
      .toDouble();
}
