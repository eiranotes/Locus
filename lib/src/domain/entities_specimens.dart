part of 'entities.dart';

class SenseVector {
  SenseVector(Map<SenseAxis, double> values)
    : values = Map<SenseAxis, double>.unmodifiable(
        values.map(
          (SenseAxis key, double value) => MapEntry<SenseAxis, double>(
            key,
            value.clamp(0.0, 1.0).toDouble(),
          ),
        ),
      );

  final Map<SenseAxis, double> values;

  double? operator [](SenseAxis axis) => values[axis];

  Map<String, Object?> toJson() => <String, Object?>{
    for (final entry in values.entries) entry.key.name: entry.value,
  };

  factory SenseVector.fromJson(Object? raw) {
    if (raw is! Map<Object?, Object?>) return SenseVector(const {});
    final output = <SenseAxis, double>{};
    for (final axis in SenseAxis.values) {
      final value = raw[axis.name];
      if (value is num) output[axis] = value.toDouble();
    }
    return SenseVector(output);
  }
}

class SpecimenContext {
  const SpecimenContext({
    required this.timeBand,
    required this.season,
    this.placeLabel,
  });

  final TimeBand timeBand;
  final Season season;
  final String? placeLabel;

  Map<String, Object?> toJson() => <String, Object?>{
    'timeBand': timeBand.name,
    'season': season.name,
    'placeLabel': placeLabel,
  };

  factory SpecimenContext.fromJson(Object? raw) {
    final json = raw is Map<Object?, Object?>
        ? raw
        : const <Object?, Object?>{};
    return SpecimenContext(
      timeBand: enumByName(
        TimeBand.values,
        json['timeBand'] as String? ?? '',
        TimeBand.afternoon,
      ),
      season: enumByName(
        Season.values,
        json['season'] as String? ?? '',
        Season.summer,
      ),
      placeLabel: json['placeLabel'] as String?,
    );
  }
}

class Specimen {
  const Specimen({
    required this.id,
    required this.captureRecordId,
    required this.capturedAt,
    required this.channels,
    required this.features,
    required this.context,
    required this.confidence,
    required this.eligibility,
    required this.previewSeed,
    required this.featureSchemaVersion,
    this.legacyPayload,
  });

  final String id;
  final String captureRecordId;
  final DateTime capturedAt;
  final Set<SenseChannel> channels;
  final SenseVector features;
  final SpecimenContext context;
  final double confidence;
  final SpecimenEligibility eligibility;
  final int previewSeed;
  final String featureSchemaVersion;
  final Map<String, Object?>? legacyPayload;

  bool get isAssignable => eligibility == SpecimenEligibility.assignable;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'capture_record_id': captureRecordId,
    'captured_at': capturedAt.millisecondsSinceEpoch,
    'channel_keys_json': jsonEncode(
      channels.map((SenseChannel value) => value.name).toList()..sort(),
    ),
    'feature_vector_json': jsonEncode(features.toJson()),
    'context_json': jsonEncode(context.toJson()),
    'confidence': confidence,
    'eligibility': eligibility.name,
    'preview_seed': previewSeed,
    'feature_schema_version': featureSchemaVersion,
    'legacy_payload_json': legacyPayload == null
        ? null
        : jsonEncode(legacyPayload),
  };

  factory Specimen.fromMap(Map<String, Object?> map) => Specimen(
    id: map['id']! as String,
    captureRecordId: map['capture_record_id']! as String,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(map['captured_at']! as int),
    channels: _decodeSenseChannels(map['channel_keys_json']),
    features: SenseVector.fromJson(
      _requestFirstDecodeJson(map['feature_vector_json']),
    ),
    context: SpecimenContext.fromJson(
      _requestFirstDecodeJson(map['context_json']),
    ),
    confidence: (map['confidence']! as num).toDouble(),
    eligibility: enumByName(
      SpecimenEligibility.values,
      map['eligibility']! as String,
      SpecimenEligibility.lowConfidence,
    ),
    previewSeed: map['preview_seed']! as int,
    featureSchemaVersion: map['feature_schema_version']! as String,
    legacyPayload: _requestFirstDecodeJsonOrNull(map['legacy_payload_json']),
  );
}

class ConstraintMatch {
  const ConstraintMatch({
    required this.constraintKey,
    required this.score,
    required this.satisfied,
    required this.hard,
    required this.observed,
    required this.target,
    this.axis,
  });

  final String constraintKey;
  final SenseAxis? axis;
  final double score;
  final bool satisfied;
  final bool hard;
  final String observed;
  final String target;

  Map<String, Object?> toJson() => <String, Object?>{
    'constraintKey': constraintKey,
    'axis': axis?.name,
    'score': score,
    'satisfied': satisfied,
    'hard': hard,
    'observed': observed,
    'target': target,
  };

  factory ConstraintMatch.fromJson(Map<Object?, Object?> json) =>
      ConstraintMatch(
        constraintKey: json['constraintKey']! as String,
        axis: json['axis'] == null
            ? null
            : enumByName(
                SenseAxis.values,
                json['axis']! as String,
                SenseAxis.loudness,
              ),
        score: (json['score']! as num).toDouble(),
        satisfied: json['satisfied'] == true,
        hard: json['hard'] == true,
        observed: json['observed']! as String,
        target: json['target']! as String,
      );
}

class SpecimenMatch {
  const SpecimenMatch({
    required this.specimenId,
    required this.requestId,
    required this.score,
    required this.passed,
    required this.verdict,
    required this.breakdown,
    required this.matcherVersion,
  });

  final String specimenId;
  final String requestId;
  final double score;
  final bool passed;
  final MatchVerdict verdict;
  final List<ConstraintMatch> breakdown;
  final String matcherVersion;

  Map<String, Object?> toMap() => <String, Object?>{
    'specimen_id': specimenId,
    'request_id': requestId,
    'score': score,
    'passed': passed ? 1 : 0,
    'verdict': verdict.name,
    'breakdown_json': jsonEncode(
      breakdown.map((ConstraintMatch value) => value.toJson()).toList(),
    ),
    'matcher_version': matcherVersion,
  };

  factory SpecimenMatch.fromMap(Map<String, Object?> map) => SpecimenMatch(
    specimenId: map['specimen_id']! as String,
    requestId: map['request_id']! as String,
    score: (map['score']! as num).toDouble(),
    passed: (map['passed']! as num).toInt() == 1,
    verdict: enumByName(
      MatchVerdict.values,
      map['verdict']! as String,
      MatchVerdict.mismatch,
    ),
    breakdown: _decodeConstraintMatches(map['breakdown_json']),
    matcherVersion: map['matcher_version']! as String,
  );
}

class SpecimenAssignment {
  const SpecimenAssignment({
    required this.id,
    required this.specimenId,
    required this.requestId,
    required this.visitorId,
    required this.assignedAt,
    required this.acceptedScore,
  });

  final String id;
  final String specimenId;
  final String requestId;
  final String visitorId;
  final DateTime assignedAt;
  final double acceptedScore;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'specimen_id': specimenId,
    'request_id': requestId,
    'visitor_id': visitorId,
    'assigned_at': assignedAt.millisecondsSinceEpoch,
    'accepted_score': acceptedScore,
  };

  factory SpecimenAssignment.fromMap(Map<String, Object?> map) =>
      SpecimenAssignment(
        id: map['id']! as String,
        specimenId: map['specimen_id']! as String,
        requestId: map['request_id']! as String,
        visitorId: map['visitor_id']! as String,
        assignedAt: DateTime.fromMillisecondsSinceEpoch(
          map['assigned_at']! as int,
        ),
        acceptedScore: (map['accepted_score']! as num).toDouble(),
      );
}

Set<SenseChannel> _decodeSenseChannels(Object? raw) {
  final decoded = _requestFirstDecodeJson(raw);
  if (decoded is! List<Object?>) return const <SenseChannel>{};
  final names = decoded.whereType<String>().toSet();
  return SenseChannel.values
      .where((SenseChannel value) => names.contains(value.name))
      .toSet();
}

List<ConstraintMatch> _decodeConstraintMatches(Object? raw) {
  final decoded = _requestFirstDecodeJson(raw);
  if (decoded is! List<Object?>) return const <ConstraintMatch>[];
  return decoded
      .whereType<Map<Object?, Object?>>()
      .map(ConstraintMatch.fromJson)
      .toList(growable: false);
}

Object? _requestFirstDecodeJson(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  try {
    return jsonDecode(raw);
  } on Object {
    return null;
  }
}

Map<String, Object?>? _requestFirstDecodeJsonOrNull(Object? raw) {
  final decoded = _requestFirstDecodeJson(raw);
  if (decoded is! Map<Object?, Object?>) return null;
  return decoded.map(
    (Object? key, Object? value) =>
        MapEntry<String, Object?>(key.toString(), value),
  );
}
