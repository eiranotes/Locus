part of 'entities.dart';

class VisitorRelationship {
  VisitorRelationship({
    required this.visitorId,
    required this.stage,
    required this.fulfilledCount,
    required Set<String> unlockedRewardKeys,
    this.lastFulfilledAt,
    Map<String, Object?> state = const <String, Object?>{},
  }) : unlockedRewardKeys = Set<String>.unmodifiable(unlockedRewardKeys),
       state = Map<String, Object?>.unmodifiable(state);

  final String visitorId;
  final int stage;
  final int fulfilledCount;
  final DateTime? lastFulfilledAt;
  final Set<String> unlockedRewardKeys;
  final Map<String, Object?> state;

  VisitorRelationship copyWith({
    int? stage,
    int? fulfilledCount,
    DateTime? lastFulfilledAt,
    Set<String>? unlockedRewardKeys,
    Map<String, Object?>? state,
  }) => VisitorRelationship(
    visitorId: visitorId,
    stage: stage ?? this.stage,
    fulfilledCount: fulfilledCount ?? this.fulfilledCount,
    lastFulfilledAt: lastFulfilledAt ?? this.lastFulfilledAt,
    unlockedRewardKeys: unlockedRewardKeys ?? this.unlockedRewardKeys,
    state: state ?? this.state,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'visitor_id': visitorId,
    'stage': stage,
    'fulfilled_count': fulfilledCount,
    'last_fulfilled_at': lastFulfilledAt?.millisecondsSinceEpoch,
    'unlocked_reward_keys_json': jsonEncode(
      unlockedRewardKeys.toList()..sort(),
    ),
    'state_json': jsonEncode(state),
  };

  factory VisitorRelationship.fromMap(Map<String, Object?> map) =>
      VisitorRelationship(
        visitorId: map['visitor_id']! as String,
        stage: map['stage']! as int,
        fulfilledCount: map['fulfilled_count']! as int,
        lastFulfilledAt: map['last_fulfilled_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                map['last_fulfilled_at']! as int,
              ),
        unlockedRewardKeys: _decodeStringSet(map['unlocked_reward_keys_json']),
        state:
            _requestFirstDecodeJsonOrNull(map['state_json']) ??
            const <String, Object?>{},
      );
}

class RelationshipEvent {
  RelationshipEvent({
    required this.id,
    required this.visitorId,
    required this.kind,
    required this.occurredAt,
    this.requestId,
    this.specimenId,
    this.matchScore,
    Map<String, Object?> snapshot = const <String, Object?>{},
  }) : snapshot = Map<String, Object?>.unmodifiable(snapshot);

  final String id;
  final String visitorId;
  final String? requestId;
  final String? specimenId;
  final RelationshipEventKind kind;
  final DateTime occurredAt;
  final double? matchScore;
  final Map<String, Object?> snapshot;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'visitor_id': visitorId,
    'request_id': requestId,
    'specimen_id': specimenId,
    'event_kind': kind.name,
    'occurred_at': occurredAt.millisecondsSinceEpoch,
    'match_score': matchScore,
    'snapshot_json': jsonEncode(snapshot),
  };

  factory RelationshipEvent.fromMap(Map<String, Object?> map) =>
      RelationshipEvent(
        id: map['id']! as String,
        visitorId: map['visitor_id']! as String,
        requestId: map['request_id'] as String?,
        specimenId: map['specimen_id'] as String?,
        kind: enumByName(
          RelationshipEventKind.values,
          map['event_kind']! as String,
          RelationshipEventKind.requestFulfilled,
        ),
        occurredAt: DateTime.fromMillisecondsSinceEpoch(
          map['occurred_at']! as int,
        ),
        matchScore: (map['match_score'] as num?)?.toDouble(),
        snapshot:
            _requestFirstDecodeJsonOrNull(map['snapshot_json']) ??
            const <String, Object?>{},
      );
}

Set<String> _decodeStringSet(Object? raw) {
  final decoded = _requestFirstDecodeJson(raw);
  if (decoded is! List<Object?>) return const <String>{};
  return decoded.whereType<String>().toSet();
}
