part of 'entities.dart';

class SceneObject {
  SceneObject({
    required this.id,
    required this.definitionId,
    required this.origin,
    required this.visualSeed,
    required this.generatorVersion,
    required this.variantKey,
    required this.lifecycle,
    required this.createdAt,
    this.sourceVisitorId,
    this.sourceRequestId,
    Map<String, Object?>? legacyPayload,
  }) : legacyPayload = legacyPayload == null
           ? null
           : Map<String, Object?>.unmodifiable(legacyPayload);

  final String id;
  final String definitionId;
  final SceneObjectOrigin origin;
  final String? sourceVisitorId;
  final String? sourceRequestId;
  final int visualSeed;
  final String generatorVersion;
  final String variantKey;
  final SceneObjectLifecycle lifecycle;
  final DateTime createdAt;
  final Map<String, Object?>? legacyPayload;

  SceneObject copyWith({SceneObjectLifecycle? lifecycle}) => SceneObject(
    id: id,
    definitionId: definitionId,
    origin: origin,
    sourceVisitorId: sourceVisitorId,
    sourceRequestId: sourceRequestId,
    visualSeed: visualSeed,
    generatorVersion: generatorVersion,
    variantKey: variantKey,
    lifecycle: lifecycle ?? this.lifecycle,
    createdAt: createdAt,
    legacyPayload: legacyPayload,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'definition_id': definitionId,
    'origin_kind': origin.name,
    'source_visitor_id': sourceVisitorId,
    'source_request_id': sourceRequestId,
    'visual_seed': visualSeed,
    'generator_version': generatorVersion,
    'variant_key': variantKey,
    'lifecycle': lifecycle.name,
    'created_at': createdAt.millisecondsSinceEpoch,
    'legacy_payload_json': legacyPayload == null
        ? null
        : jsonEncode(legacyPayload),
  };

  factory SceneObject.fromMap(Map<String, Object?> map) => SceneObject(
    id: map['id']! as String,
    definitionId: map['definition_id']! as String,
    origin: enumByName(
      SceneObjectOrigin.values,
      map['origin_kind']! as String,
      SceneObjectOrigin.legacyCrafted,
    ),
    sourceVisitorId: map['source_visitor_id'] as String?,
    sourceRequestId: map['source_request_id'] as String?,
    visualSeed: map['visual_seed']! as int,
    generatorVersion: map['generator_version']! as String,
    variantKey: map['variant_key']! as String,
    lifecycle: enumByName(
      SceneObjectLifecycle.values,
      map['lifecycle']! as String,
      SceneObjectLifecycle.stored,
    ),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
    legacyPayload: _requestFirstDecodeJsonOrNull(map['legacy_payload_json']),
  );
}

class ScenePlacement {
  const ScenePlacement({
    required this.id,
    required this.sceneObjectId,
    required this.column,
    required this.row,
    required this.rotation,
  });

  final String id;
  final String sceneObjectId;
  final int column;
  final int row;
  final int rotation;

  ScenePlacement copyWith({int? column, int? row, int? rotation}) =>
      ScenePlacement(
        id: id,
        sceneObjectId: sceneObjectId,
        column: column ?? this.column,
        row: row ?? this.row,
        rotation: rotation ?? this.rotation,
      );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'scene_object_id': sceneObjectId,
    'column_index': column,
    'row_index': row,
    'rotation': rotation,
  };

  factory ScenePlacement.fromMap(Map<String, Object?> map) => ScenePlacement(
    id: map['id']! as String,
    sceneObjectId: map['scene_object_id']! as String,
    column: map['column_index']! as int,
    row: map['row_index']! as int,
    rotation: map['rotation']! as int,
  );
}
