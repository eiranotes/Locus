part of 'entities.dart';

class RequestConstraint {
  const RequestConstraint({
    required this.axis,
    this.minimum,
    this.maximum,
    this.anyOf = const <String>[],
    this.tolerance = 0.20,
    this.weight = 1.0,
    this.hard = true,
  });

  final SenseAxis axis;
  final double? minimum;
  final double? maximum;
  final List<String> anyOf;
  final double tolerance;
  final double weight;
  final bool hard;

  Map<String, Object?> toJson() => <String, Object?>{
    'axis': axis.name,
    'minimum': minimum,
    'maximum': maximum,
    'anyOf': anyOf,
    'tolerance': tolerance,
    'weight': weight,
    'hard': hard,
  };

  factory RequestConstraint.fromJson(Map<Object?, Object?> json) =>
      RequestConstraint(
        axis: enumByName(
          SenseAxis.values,
          json['axis']! as String,
          SenseAxis.loudness,
        ),
        minimum: (json['minimum'] as num?)?.toDouble(),
        maximum: (json['maximum'] as num?)?.toDouble(),
        anyOf: (json['anyOf'] as List<Object?>? ?? const <Object?>[])
            .whereType<String>()
            .toList(growable: false),
        tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0.20,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
        hard: json['hard'] as bool? ?? true,
      );
}

class VisitorRequest {
  const VisitorRequest({
    required this.id,
    required this.visitorId,
    required this.templateId,
    required this.promptKo,
    required this.issuedAt,
    required this.expiresAt,
    required this.slotIndex,
    required this.status,
    required this.constraints,
    required this.difficulty,
    required this.historyComparison,
    required this.requestSchemaVersion,
    this.historySpecimenId,
    this.completedAt,
  });

  final String id;
  final String visitorId;
  final String templateId;
  final String promptKo;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int slotIndex;
  final VisitorRequestStatus status;
  final List<RequestConstraint> constraints;
  final int difficulty;
  final HistoryComparison historyComparison;
  final String? historySpecimenId;
  final String requestSchemaVersion;
  final DateTime? completedAt;

  bool get isActive => status == VisitorRequestStatus.active;

  Set<SenseAxis> get requiredAxes =>
      constraints.map((RequestConstraint value) => value.axis).toSet();

  VisitorRequest copyWith({
    VisitorRequestStatus? status,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => VisitorRequest(
    id: id,
    visitorId: visitorId,
    templateId: templateId,
    promptKo: promptKo,
    issuedAt: issuedAt,
    expiresAt: expiresAt,
    slotIndex: slotIndex,
    status: status ?? this.status,
    constraints: constraints,
    difficulty: difficulty,
    historyComparison: historyComparison,
    historySpecimenId: historySpecimenId,
    requestSchemaVersion: requestSchemaVersion,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'visitor_id': visitorId,
    'template_id': templateId,
    'prompt_ko': promptKo,
    'issued_at': issuedAt.millisecondsSinceEpoch,
    'expires_at': expiresAt?.millisecondsSinceEpoch,
    'slot_index': slotIndex,
    'status': status.name,
    'target_json': jsonEncode(
      constraints.map((RequestConstraint value) => value.toJson()).toList(),
    ),
    'difficulty': difficulty,
    'history_comparison': historyComparison.name,
    'history_specimen_id': historySpecimenId,
    'request_schema_version': requestSchemaVersion,
    'completed_at': completedAt?.millisecondsSinceEpoch,
  };

  factory VisitorRequest.fromMap(Map<String, Object?> map) => VisitorRequest(
    id: map['id']! as String,
    visitorId: map['visitor_id']! as String,
    templateId: map['template_id']! as String,
    promptKo: map['prompt_ko']! as String,
    issuedAt: DateTime.fromMillisecondsSinceEpoch(map['issued_at']! as int),
    expiresAt: map['expires_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['expires_at']! as int),
    slotIndex: map['slot_index']! as int,
    status: enumByName(
      VisitorRequestStatus.values,
      map['status']! as String,
      VisitorRequestStatus.expired,
    ),
    constraints: _decodeRequestConstraints(map['target_json']),
    difficulty: map['difficulty']! as int,
    historyComparison: enumByName(
      HistoryComparison.values,
      map['history_comparison'] as String? ?? '',
      HistoryComparison.none,
    ),
    historySpecimenId: map['history_specimen_id'] as String?,
    requestSchemaVersion: map['request_schema_version']! as String,
    completedAt: map['completed_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['completed_at']! as int),
  );
}

List<RequestConstraint> _decodeRequestConstraints(Object? raw) {
  final decoded = _requestFirstDecodeJson(raw);
  if (decoded is! List<Object?>) return const <RequestConstraint>[];
  return decoded
      .whereType<Map<Object?, Object?>>()
      .map(RequestConstraint.fromJson)
      .toList(growable: false);
}
