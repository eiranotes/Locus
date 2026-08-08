part of 'entities.dart';

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  String get coarseCellId {
    final lat = (latitude * 100).floor() / 100;
    final lon = (longitude * 100).floor() / 100;
    return '${lat.toStringAsFixed(2)}:${lon.toStringAsFixed(2)}';
  }
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperatureCelsius,
    required this.apparentTemperatureCelsius,
    required this.precipitationMillimeters,
    required this.cloudCoverPercent,
    required this.windSpeedKph,
    required this.visibilityMeters,
    required this.weatherCode,
    this.conditionKey,
    required this.observedAt,
    required this.basis,
    required this.providerName,
  });

  final double temperatureCelsius;
  final double apparentTemperatureCelsius;
  final double precipitationMillimeters;
  final double cloudCoverPercent;
  final double windSpeedKph;
  final double visibilityMeters;
  final int weatherCode;
  final String? conditionKey;
  final DateTime observedAt;
  final WeatherBasis basis;
  final String providerName;
}

class AmbientFeatures {
  const AmbientFeatures({
    required this.uniqueCount,
    required this.medianRssi,
    required this.strongSignalRatio,
    required this.persistence,
    required this.churn,
    required this.observationCoverage,
  });

  final int uniqueCount;
  final double medianRssi;
  final double strongSignalRatio;
  final double persistence;
  final double churn;
  final double observationCoverage;

  Map<String, Object?> toMap() => <String, Object?>{
        'uniqueCount': uniqueCount,
        'medianRssi': medianRssi,
        'strongSignalRatio': strongSignalRatio,
        'persistence': persistence,
        'churn': churn,
        'observationCoverage': observationCoverage,
      };

  factory AmbientFeatures.fromMap(Map<Object?, Object?> map) {
    double number(String key) => (map[key] as num?)?.toDouble() ?? 0;
    return AmbientFeatures(
      uniqueCount: (map['uniqueCount'] as num?)?.toInt() ?? 0,
      medianRssi: number('medianRssi'),
      strongSignalRatio: number('strongSignalRatio'),
      persistence: number('persistence'),
      churn: number('churn'),
      observationCoverage: number('observationCoverage'),
    );
  }
}

class ResourceReadiness {
  const ResourceReadiness._({
    required this.status,
    this.readyReason,
    this.waitUntil,
    this.message,
  });

  const ResourceReadiness.ready(String reason)
      : this._(status: ReadinessStatus.ready, readyReason: reason);

  const ResourceReadiness.waiting(DateTime until, String message)
      : this._(
          status: ReadinessStatus.waiting,
          waitUntil: until,
          message: message,
        );

  const ResourceReadiness.unavailable(String message)
      : this._(status: ReadinessStatus.unavailable, message: message);

  final ReadinessStatus status;
  final String? readyReason;
  final DateTime? waitUntil;
  final String? message;

  bool get isReady => status == ReadinessStatus.ready;
}

class CaptureRecord {
  const CaptureRecord({
    required this.id,
    required this.capturedAt,
    required this.timeBand,
    required this.season,
    required this.weatherBasis,
    required this.sourceVersion,
    this.coarseCellId,
    this.userPlaceLabel,
    this.weatherMaterialId,
    this.surroundingMaterialId,
  });

  final String id;
  final DateTime capturedAt;
  final String? coarseCellId;
  final String? userPlaceLabel;
  final TimeBand timeBand;
  final Season season;
  final WeatherBasis weatherBasis;
  final String sourceVersion;
  final String? weatherMaterialId;
  final String? surroundingMaterialId;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'captured_at': capturedAt.millisecondsSinceEpoch,
        'coarse_cell_id': coarseCellId,
        'user_place_label': userPlaceLabel,
        'time_band': timeBand.name,
        'season': season.name,
        'weather_basis': weatherBasis.name,
        'source_version': sourceVersion,
        'weather_material_id': weatherMaterialId,
        'surrounding_material_id': surroundingMaterialId,
      };

  factory CaptureRecord.fromMap(Map<String, Object?> map) => CaptureRecord(
        id: map['id']! as String,
        capturedAt:
            DateTime.fromMillisecondsSinceEpoch(map['captured_at']! as int),
        coarseCellId: map['coarse_cell_id'] as String?,
        userPlaceLabel: map['user_place_label'] as String?,
        timeBand: enumByName(
          TimeBand.values,
          map['time_band']! as String,
          TimeBand.afternoon,
        ),
        season: enumByName(
          Season.values,
          map['season']! as String,
          Season.summer,
        ),
        weatherBasis: enumByName(
          WeatherBasis.values,
          map['weather_basis']! as String,
          WeatherBasis.unavailable,
        ),
        sourceVersion: map['source_version']! as String,
        weatherMaterialId: map['weather_material_id'] as String?,
        surroundingMaterialId: map['surrounding_material_id'] as String?,
      );
}

class WeatherMaterial {
  const WeatherMaterial({
    required this.id,
    required this.kind,
    required this.timeBand,
    required this.season,
    required this.capturedAt,
    required this.sourceRecordId,
    required this.visualSeed,
    required this.providerName,
    this.coarseCellId,
    this.consumedAt,
    this.craftedObjectId,
  });

  final String id;
  final WeatherMaterialKind kind;
  final TimeBand timeBand;
  final Season season;
  final DateTime capturedAt;
  final String? coarseCellId;
  final String sourceRecordId;
  final int visualSeed;
  final String providerName;
  final DateTime? consumedAt;
  final String? craftedObjectId;

  bool get isAvailable => consumedAt == null;

  WeatherMaterial consume({required DateTime at, required String objectId}) =>
      WeatherMaterial(
        id: id,
        kind: kind,
        timeBand: timeBand,
        season: season,
        capturedAt: capturedAt,
        coarseCellId: coarseCellId,
        sourceRecordId: sourceRecordId,
        visualSeed: visualSeed,
        providerName: providerName,
        consumedAt: at,
        craftedObjectId: objectId,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'kind': kind.name,
        'time_band': timeBand.name,
        'season': season.name,
        'captured_at': capturedAt.millisecondsSinceEpoch,
        'coarse_cell_id': coarseCellId,
        'source_record_id': sourceRecordId,
        'visual_seed': visualSeed,
        'provider_name': providerName,
        'consumed_at': consumedAt?.millisecondsSinceEpoch,
        'crafted_object_id': craftedObjectId,
      };

  factory WeatherMaterial.fromMap(Map<String, Object?> map) => WeatherMaterial(
        id: map['id']! as String,
        kind: enumByName(
          WeatherMaterialKind.values,
          map['kind']! as String,
          WeatherMaterialKind.cloudy,
        ),
        timeBand: enumByName(
          TimeBand.values,
          map['time_band']! as String,
          TimeBand.afternoon,
        ),
        season: enumByName(
          Season.values,
          map['season']! as String,
          Season.summer,
        ),
        capturedAt:
            DateTime.fromMillisecondsSinceEpoch(map['captured_at']! as int),
        coarseCellId: map['coarse_cell_id'] as String?,
        sourceRecordId: map['source_record_id']! as String,
        visualSeed: map['visual_seed']! as int,
        providerName: map['provider_name']! as String,
        consumedAt: map['consumed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['consumed_at']! as int),
        craftedObjectId: map['crafted_object_id'] as String?,
      );
}

class SurroundingMaterial {
  const SurroundingMaterial({
    required this.id,
    required this.kind,
    required this.confidence,
    required this.capturedAt,
    required this.sourceRecordId,
    required this.featureSchemaVersion,
    this.coarseCellId,
    this.consumedAt,
    this.craftedObjectId,
  });

  final String id;
  final SurroundingMaterialKind kind;
  final double confidence;
  final DateTime capturedAt;
  final String? coarseCellId;
  final String sourceRecordId;
  final String featureSchemaVersion;
  final DateTime? consumedAt;
  final String? craftedObjectId;

  bool get isAvailable => consumedAt == null;

  SurroundingMaterial consume({required DateTime at, required String objectId}) =>
      SurroundingMaterial(
        id: id,
        kind: kind,
        confidence: confidence,
        capturedAt: capturedAt,
        coarseCellId: coarseCellId,
        sourceRecordId: sourceRecordId,
        featureSchemaVersion: featureSchemaVersion,
        consumedAt: at,
        craftedObjectId: objectId,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'kind': kind.name,
        'confidence': confidence,
        'captured_at': capturedAt.millisecondsSinceEpoch,
        'coarse_cell_id': coarseCellId,
        'source_record_id': sourceRecordId,
        'feature_schema_version': featureSchemaVersion,
        'consumed_at': consumedAt?.millisecondsSinceEpoch,
        'crafted_object_id': craftedObjectId,
      };

  factory SurroundingMaterial.fromMap(Map<String, Object?> map) =>
      SurroundingMaterial(
        id: map['id']! as String,
        kind: enumByName(
          SurroundingMaterialKind.values,
          map['kind']! as String,
          SurroundingMaterialKind.sparse,
        ),
        confidence: (map['confidence']! as num).toDouble(),
        capturedAt:
            DateTime.fromMillisecondsSinceEpoch(map['captured_at']! as int),
        coarseCellId: map['coarse_cell_id'] as String?,
        sourceRecordId: map['source_record_id']! as String,
        featureSchemaVersion: map['feature_schema_version']! as String,
        consumedAt: map['consumed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['consumed_at']! as int),
        craftedObjectId: map['crafted_object_id'] as String?,
      );
}
