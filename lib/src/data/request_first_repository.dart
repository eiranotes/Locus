import 'dart:convert';

import 'package:reality_diorama/src/data/database.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:sqflite/sqflite.dart';

class RequestFirstRepository {
  RequestFirstRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Database get _db => _appDatabase.database;

  Future<int> specimenCount() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS specimen_count FROM specimens',
    );
    return (rows.single['specimen_count']! as num).toInt();
  }

  Future<List<Specimen>> loadSpecimens({int limit = 24, int offset = 0}) async {
    final rows = await _db.query(
      'specimens',
      orderBy: 'captured_at DESC, id DESC',
      limit: limit.clamp(1, 100),
      offset: offset < 0 ? 0 : offset,
    );
    return rows.map(Specimen.fromMap).toList(growable: false);
  }

  Future<List<VisitorRequest>> loadRequests({
    Set<VisitorRequestStatus>? statuses,
  }) async {
    final names =
        statuses?.map((VisitorRequestStatus value) => value.name).toList()
          ?..sort();
    final rows = await _db.query(
      'visitor_requests',
      where: names == null || names.isEmpty
          ? null
          : 'status IN (${List<String>.filled(names.length, '?').join(',')})',
      whereArgs: names,
      orderBy: 'issued_at DESC, slot_index ASC',
    );
    return rows.map(VisitorRequest.fromMap).toList(growable: false);
  }

  Future<List<SpecimenMatch>> loadMatchesForSpecimen(String specimenId) async {
    final rows = await _db.query(
      'specimen_matches',
      where: 'specimen_id = ?',
      whereArgs: <Object?>[specimenId],
      orderBy: 'score DESC, request_id ASC',
    );
    return rows.map(SpecimenMatch.fromMap).toList(growable: false);
  }

  Future<List<SpecimenAssignment>> loadAssignments() async {
    final rows = await _db.query(
      'specimen_assignments',
      orderBy: 'assigned_at DESC, id DESC',
    );
    return rows.map(SpecimenAssignment.fromMap).toList(growable: false);
  }

  Future<Map<String, VisitorRelationship>> loadRelationships() async {
    final rows = await _db.query('visitor_relationships');
    return <String, VisitorRelationship>{
      for (final row in rows)
        row['visitor_id']! as String: VisitorRelationship.fromMap(row),
    };
  }

  Future<List<RelationshipEvent>> loadRelationshipEvents({
    String? visitorId,
    int limit = 50,
  }) async {
    final rows = await _db.query(
      'relationship_events',
      where: visitorId == null ? null : 'visitor_id = ?',
      whereArgs: visitorId == null ? null : <Object?>[visitorId],
      orderBy: 'occurred_at DESC, id DESC',
      limit: limit.clamp(1, 200),
    );
    return rows.map(RelationshipEvent.fromMap).toList(growable: false);
  }

  Future<List<SceneObject>> loadSceneObjects() async {
    final rows = await _db.query(
      'scene_objects',
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(SceneObject.fromMap).toList(growable: false);
  }

  Future<List<ScenePlacement>> loadScenePlacements() async {
    final rows = await _db.query('scene_placements');
    return rows.map(ScenePlacement.fromMap).toList(growable: false);
  }

  Future<Set<SenseAxis>> loadUnlockedAxes() async {
    final rows = await _db.query(
      'sense_profile',
      columns: const <String>['axis_key'],
      where: 'unlocked = 1',
    );
    final names = rows
        .map((Map<String, Object?> row) => row['axis_key'])
        .whereType<String>()
        .toSet();
    return SenseAxis.values
        .where((SenseAxis value) => names.contains(value.name))
        .toSet();
  }

  Future<void> saveSpecimenCapture({
    required CaptureRecord record,
    required Specimen specimen,
    required List<SpecimenMatch> matches,
  }) async {
    if (record.id != specimen.captureRecordId) {
      throw ArgumentError(
        'Specimen must reference the supplied capture record.',
      );
    }
    if (matches.any((SpecimenMatch value) => value.specimenId != specimen.id)) {
      throw ArgumentError('Every match must reference the supplied specimen.');
    }
    final requestIds = matches.map((SpecimenMatch value) => value.requestId).toSet();
    if (requestIds.length != matches.length) {
      throw ArgumentError('A specimen may store only one match per request.');
    }
    await _db.transaction((Transaction transaction) async {
      await transaction.insert(
        'capture_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await transaction.insert(
        'specimens',
        specimen.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      for (final match in matches) {
        await transaction.insert(
          'specimen_matches',
          match.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<void> saveRequestSchedule({
    required List<VisitorRequest> issued,
    required List<VisitorRequest> expired,
  }) async {
    if (issued.any((VisitorRequest value) => !value.isActive)) {
      throw ArgumentError('Issued requests must be active.');
    }
    if (expired.any(
      (VisitorRequest value) =>
          value.status != VisitorRequestStatus.expired,
    )) {
      throw ArgumentError('Expired requests must use the expired status.');
    }
    await _db.transaction((Transaction transaction) async {
      for (final request in <VisitorRequest>[...expired, ...issued]) {
        await transaction.insert(
          'visitor_requests',
          request.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> seedUnlockedAxes(Set<SenseAxis> axes) async {
    await _db.transaction((Transaction transaction) async {
      for (final axis in axes) {
        await transaction.insert('sense_profile', <String, Object?>{
          'axis_key': axis.name,
          'unlocked': 1,
          'calibration_json': '{}',
          'unlocked_at': null,
          'source_visitor_id': null,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> assignSpecimen({
    required SpecimenAssignment assignment,
    required VisitorRequest fulfilledRequest,
    required VisitorRelationship relationship,
    required List<RelationshipEvent> events,
    Set<SenseAxis> unlockedAxes = const <SenseAxis>{},
    List<SceneObject> grantedSceneObjects = const <SceneObject>[],
    List<ScenePlacement> grantedScenePlacements = const <ScenePlacement>[],
  }) async {
    if (fulfilledRequest.id != assignment.requestId ||
        fulfilledRequest.visitorId != assignment.visitorId ||
        fulfilledRequest.status != VisitorRequestStatus.fulfilled ||
        fulfilledRequest.completedAt == null) {
      throw ArgumentError('Fulfilled request and assignment are inconsistent.');
    }
    if (relationship.visitorId != assignment.visitorId) {
      throw ArgumentError(
        'Relationship and assignment visitor are inconsistent.',
      );
    }
    if (events.isEmpty ||
        events
                .where(
                  (RelationshipEvent value) =>
                      value.kind == RelationshipEventKind.requestFulfilled,
                )
                .length !=
            1 ||
        events.any(
          (RelationshipEvent value) =>
              value.visitorId != assignment.visitorId ||
              value.requestId != assignment.requestId ||
              value.specimenId != assignment.specimenId,
        )) {
      throw ArgumentError('Relationship events do not describe this assignment.');
    }
    if (grantedSceneObjects.any(
      (SceneObject value) =>
          value.origin == SceneObjectOrigin.relationshipReward &&
          (value.sourceVisitorId != assignment.visitorId ||
              value.sourceRequestId != assignment.requestId),
    )) {
      throw ArgumentError('Granted scene objects have inconsistent provenance.');
    }
    final grantedObjectIds = grantedSceneObjects
        .map((SceneObject value) => value.id)
        .toSet();
    if (grantedScenePlacements.any(
      (ScenePlacement value) => !grantedObjectIds.contains(value.sceneObjectId),
    )) {
      throw ArgumentError('Granted placements must reference granted objects.');
    }

    await _db.transaction((Transaction transaction) async {
      final priorAssignment = await transaction.query(
        'specimen_assignments',
        columns: const <String>['id'],
        where: 'specimen_id = ? OR request_id = ?',
        whereArgs: <Object?>[assignment.specimenId, assignment.requestId],
        limit: 1,
      );
      if (priorAssignment.isNotEmpty) {
        throw StateError('Specimen or request has already been assigned.');
      }

      final requestRows = await transaction.query(
        'visitor_requests',
        columns: const <String>['status', 'visitor_id'],
        where: 'id = ?',
        whereArgs: <Object?>[assignment.requestId],
        limit: 1,
      );
      if (requestRows.isEmpty ||
          requestRows.single['status'] != VisitorRequestStatus.active.name ||
          requestRows.single['visitor_id'] != assignment.visitorId) {
        throw StateError('Request is not active for this visitor.');
      }

      final matchRows = await transaction.query(
        'specimen_matches',
        columns: const <String>['score', 'passed'],
        where: 'specimen_id = ? AND request_id = ?',
        whereArgs: <Object?>[assignment.specimenId, assignment.requestId],
        limit: 1,
      );
      if (matchRows.isEmpty ||
          (matchRows.single['passed']! as num).toInt() != 1) {
        throw StateError('Stored specimen match does not satisfy the request.');
      }
      final storedScore = (matchRows.single['score']! as num).toDouble();
      if ((storedScore - assignment.acceptedScore).abs() > 0.000001) {
        throw StateError('Assignment score differs from the stored match.');
      }

      final currentRelationship = await transaction.query(
        'visitor_relationships',
        columns: const <String>['stage', 'fulfilled_count'],
        where: 'visitor_id = ?',
        whereArgs: <Object?>[assignment.visitorId],
        limit: 1,
      );
      final currentCount = currentRelationship.isEmpty
          ? 0
          : (currentRelationship.single['fulfilled_count']! as num).toInt();
      final currentStage = currentRelationship.isEmpty
          ? 0
          : (currentRelationship.single['stage']! as num).toInt();
      if (relationship.fulfilledCount != currentCount + 1 ||
          relationship.stage < currentStage) {
        throw StateError('Relationship progression is stale or non-monotonic.');
      }

      await transaction.insert(
        'specimen_assignments',
        assignment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      final updatedRequests = await transaction.update(
        'visitor_requests',
        fulfilledRequest.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[fulfilledRequest.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      if (updatedRequests != 1) {
        throw StateError('Request fulfillment did not update exactly one row.');
      }
      await transaction.insert(
        'visitor_relationships',
        relationship.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final event in events) {
        await transaction.insert(
          'relationship_events',
          event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      for (final axis in unlockedAxes) {
        await transaction.insert('sense_profile', <String, Object?>{
          'axis_key': axis.name,
          'unlocked': 1,
          'calibration_json': jsonEncode(<String, Object?>{}),
          'unlocked_at': assignment.assignedAt.millisecondsSinceEpoch,
          'source_visitor_id': assignment.visitorId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final object in grantedSceneObjects) {
        await transaction.insert(
          'scene_objects',
          object.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      for (final placement in grantedScenePlacements) {
        await transaction.insert(
          'scene_placements',
          placement.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<void> saveScenePlacement(ScenePlacement placement) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.delete(
        'scene_placements',
        where: 'scene_object_id = ?',
        whereArgs: <Object?>[placement.sceneObjectId],
      );
      await transaction.insert(
        'scene_placements',
        placement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await transaction.update(
        'scene_objects',
        <String, Object?>{'lifecycle': SceneObjectLifecycle.placed.name},
        where: 'id = ?',
        whereArgs: <Object?>[placement.sceneObjectId],
      );
    });
  }

  Future<void> removeScenePlacement(String sceneObjectId) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.delete(
        'scene_placements',
        where: 'scene_object_id = ?',
        whereArgs: <Object?>[sceneObjectId],
      );
      await transaction.update(
        'scene_objects',
        <String, Object?>{'lifecycle': SceneObjectLifecycle.stored.name},
        where: 'id = ?',
        whereArgs: <Object?>[sceneObjectId],
      );
    });
  }
}
