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

  Future<List<Specimen>> loadSpecimens({
    int limit = 24,
    int offset = 0,
  }) async {
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
    final names = statuses?.map((VisitorRequestStatus value) => value.name).toList()
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
      throw ArgumentError('Specimen must reference the supplied capture record.');
    }
    if (matches.any((SpecimenMatch value) => value.specimenId != specimen.id)) {
      throw ArgumentError('Every match must reference the supplied specimen.');
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
        await transaction.insert(
          'sense_profile',
          <String, Object?>{
            'axis_key': axis.name,
            'unlocked': 1,
            'calibration_json': '{}',
            'unlocked_at': null,
            'source_visitor_id': null,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
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
  }) async {
    if (fulfilledRequest.id != assignment.requestId ||
        fulfilledRequest.visitorId != assignment.visitorId ||
        fulfilledRequest.status != VisitorRequestStatus.fulfilled) {
      throw ArgumentError('Fulfilled request and assignment are inconsistent.');
    }
    if (relationship.visitorId != assignment.visitorId) {
      throw ArgumentError('Relationship and assignment visitor are inconsistent.');
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

      await transaction.insert(
        'specimen_assignments',
        assignment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await transaction.update(
        'visitor_requests',
        fulfilledRequest.toMap(),
        where: 'id = ?',
        whereArgs: <Object?>[fulfilledRequest.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
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
        await transaction.insert(
          'sense_profile',
          <String, Object?>{
            'axis_key': axis.name,
            'unlocked': 1,
            'calibration_json': jsonEncode(<String, Object?>{}),
            'unlocked_at': assignment.assignedAt.millisecondsSinceEpoch,
            'source_visitor_id': assignment.visitorId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final object in grantedSceneObjects) {
        await transaction.insert(
          'scene_objects',
          object.toMap(),
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
