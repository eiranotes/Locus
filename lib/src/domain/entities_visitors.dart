part of 'entities.dart';

class VisitorRequirement {
  const VisitorRequirement({
    required this.kind,
    this.minimum,
    this.anyOf = const <String>[],
    this.tag,
  });

  final String kind;
  final int? minimum;
  final List<String> anyOf;
  final String? tag;

  factory VisitorRequirement.fromJson(Map<String, Object?> json) =>
      VisitorRequirement(
        kind: json['kind']! as String,
        minimum: json['min'] as int?,
        anyOf: (json['anyOf'] as List<Object?>? ?? const <Object?>[])
            .cast<String>(),
        tag: json['tag'] as String?,
      );
}

class VisitorReward {
  const VisitorReward({required this.kind, required this.value});

  final VisitorRewardKind kind;
  final String value;

  factory VisitorReward.fromJson(Map<String, Object?> json) => VisitorReward(
    kind: enumByName(
      VisitorRewardKind.values,
      json['kind']! as String,
      VisitorRewardKind.effect,
    ),
    value: json['value']! as String,
  );
}

class VisitorDefinition {
  const VisitorDefinition({
    required this.id,
    required this.nameKo,
    required this.descriptionKo,
    required this.hintsKo,
    required this.requirements,
    required this.reward,
  });

  final String id;
  final String nameKo;
  final String descriptionKo;
  final List<String> hintsKo;
  final List<VisitorRequirement> requirements;
  final VisitorReward reward;

  factory VisitorDefinition.fromJson(Map<String, Object?> json) =>
      VisitorDefinition(
        id: json['id']! as String,
        nameKo: json['nameKo']! as String,
        descriptionKo: json['descriptionKo']! as String,
        hintsKo: (json['hintsKo']! as List<Object?>).cast<String>(),
        requirements: (json['requirements']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(VisitorRequirement.fromJson)
            .toList(growable: false),
        reward: VisitorReward.fromJson(json['reward']! as Map<String, Object?>),
      );
}

class VisitorSighting {
  const VisitorSighting({
    required this.id,
    required this.visitorId,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.variantKey,
    this.snapshotJson,
  });

  final String id;
  final String visitorId;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String variantKey;
  final String? snapshotJson;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'visitor_id': visitorId,
    'first_seen_at': firstSeenAt.millisecondsSinceEpoch,
    'last_seen_at': lastSeenAt.millisecondsSinceEpoch,
    'variant_key': variantKey,
    'snapshot_json': snapshotJson,
  };

  factory VisitorSighting.fromMap(Map<String, Object?> map) => VisitorSighting(
    id: map['id']! as String,
    visitorId: map['visitor_id']! as String,
    firstSeenAt: DateTime.fromMillisecondsSinceEpoch(
      map['first_seen_at']! as int,
    ),
    lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
      map['last_seen_at']! as int,
    ),
    variantKey: map['variant_key']! as String,
    snapshotJson: map['snapshot_json'] as String?,
  );

  static String encodeSnapshot(Map<String, Object?> value) => jsonEncode(value);
}
