import 'dart:convert';

import 'package:reality_diorama/src/data/database.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/crafting_engine.dart';
import 'package:sqflite/sqflite.dart';

class GameRepository {
  GameRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Database get _db => _appDatabase.database;

  Future<List<CaptureRecord>> loadCaptures({int limit = 100}) async {
    final rows = await _db.query(
      'capture_records',
      orderBy: 'captured_at DESC',
      limit: limit,
    );
    return rows.map(CaptureRecord.fromMap).toList(growable: false);
  }

  Future<List<WeatherMaterial>> loadWeatherMaterials() async {
    final rows = await _db.query(
      'weather_materials',
      orderBy: 'captured_at DESC',
    );
    return rows.map(WeatherMaterial.fromMap).toList(growable: false);
  }

  Future<List<SurroundingMaterial>> loadSurroundingMaterials() async {
    final rows = await _db.query(
      'surrounding_materials',
      orderBy: 'captured_at DESC',
    );
    return rows.map(SurroundingMaterial.fromMap).toList(growable: false);
  }

  Future<List<CollectedPattern>> loadCollectedPatterns() async {
    final rows = await _db.query(
      'collected_patterns',
      orderBy: 'captured_at DESC, pattern_key ASC',
    );
    return rows.map(CollectedPattern.fromMap).toList(growable: false);
  }

  Future<List<StepBucket>> loadStepBuckets() async {
    final rows = await _db.query('step_buckets', orderBy: 'day_key ASC');
    return rows.map(StepBucket.fromMap).toList(growable: false);
  }

  Future<List<CraftedObject>> loadCraftedObjects() async {
    final rows = await _db.query('crafted_objects', orderBy: 'created_at DESC');
    return rows.map(CraftedObject.fromMap).toList(growable: false);
  }

  Future<List<Placement>> loadPlacements() async {
    final rows = await _db.query('placements');
    return rows.map(Placement.fromMap).toList(growable: false);
  }

  Future<List<VisitorSighting>> loadVisitorSightings() async {
    final rows = await _db.query(
      'visitor_sightings',
      orderBy: 'last_seen_at DESC',
    );
    return rows.map(VisitorSighting.fromMap).toList(growable: false);
  }

  Future<Map<String, int>> loadVisitorEncounterCounts() async {
    final rows = await _db.rawQuery('''
      SELECT visitor_id, COUNT(*) AS encounter_count
      FROM visitor_encounters
      GROUP BY visitor_id
    ''');
    return <String, int>{
      for (final row in rows)
        row['visitor_id']! as String: (row['encounter_count']! as num).toInt(),
    };
  }

  Future<List<VisitorEncounter>> loadRecentVisitorEncounters({
    required String visitorId,
    int limit = 5,
  }) async {
    final boundedLimit = limit.clamp(1, 5);
    final rows = await _db.query(
      'visitor_encounters',
      where: 'visitor_id = ?',
      whereArgs: <Object?>[visitorId],
      orderBy: 'seen_at DESC',
      limit: boundedLimit,
    );
    return rows.map(VisitorEncounter.fromMap).toList(growable: false);
  }

  Future<void> saveCapture({
    required CaptureRecord record,
    WeatherMaterial? weather,
    SurroundingMaterial? surroundings,
    List<CollectedPattern> patterns = const <CollectedPattern>[],
  }) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.insert(
        'capture_records',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (weather != null) {
        await transaction.insert(
          'weather_materials',
          weather.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      if (surroundings != null) {
        await transaction.insert(
          'surrounding_materials',
          surroundings.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final pattern in patterns) {
        await transaction.insert(
          'collected_patterns',
          pattern.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> replaceStepBuckets(List<StepBucket> buckets) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.delete('step_buckets');
      for (final bucket in buckets) {
        await transaction.insert('step_buckets', bucket.toMap());
      }
    });
  }

  Future<void> saveCrafting(
    CraftingResult result, {
    Placement? placement,
    bool markPlaced = false,
  }) async {
    await _db.transaction((Transaction transaction) async {
      final object = markPlaced
          ? result.object.copyWith(lifecycle: ObjectLifecycle.placed)
          : result.object;
      await transaction.insert(
        'crafted_objects',
        object.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.insert(
        'weather_materials',
        result.weatherMaterial.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (result.surroundingMaterial != null) {
        await transaction.insert(
          'surrounding_materials',
          result.surroundingMaterial!.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await transaction.delete('step_buckets');
      for (final bucket in result.stepBuckets) {
        await transaction.insert('step_buckets', bucket.toMap());
      }
      if (placement != null) {
        await transaction.delete(
          'placements',
          where: 'crafted_object_id = ?',
          whereArgs: <Object?>[placement.craftedObjectId],
        );
        await transaction.insert(
          'placements',
          placement.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateConstruction({
    required CraftedObject object,
    required List<StepBucket> buckets,
  }) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.insert(
        'crafted_objects',
        object.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.delete('step_buckets');
      for (final bucket in buckets) {
        await transaction.insert('step_buckets', bucket.toMap());
      }
    });
  }

  Future<void> savePlacement(
    Placement placement, {
    required bool markPlaced,
  }) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.delete(
        'placements',
        where: 'crafted_object_id = ?',
        whereArgs: <Object?>[placement.craftedObjectId],
      );
      await transaction.insert(
        'placements',
        placement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (markPlaced) {
        await transaction.update(
          'crafted_objects',
          <String, Object?>{'lifecycle': 'placed'},
          where: 'id = ?',
          whereArgs: <Object?>[placement.craftedObjectId],
        );
      }
    });
  }

  Future<void> removePlacement(
    String craftedObjectId, {
    required ObjectLifecycle lifecycle,
  }) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.delete(
        'placements',
        where: 'crafted_object_id = ?',
        whereArgs: <Object?>[craftedObjectId],
      );
      await transaction.update(
        'crafted_objects',
        <String, Object?>{'lifecycle': lifecycle.name},
        where: 'id = ?',
        whereArgs: <Object?>[craftedObjectId],
      );
    });
  }

  Future<void> saveVisitorResolution({
    required VisitorSighting sighting,
    required VisitorEncounter encounter,
    required Set<String> unlockedRecipeIds,
    required Set<String> unlockedRewardKeys,
  }) async {
    await _db.transaction((Transaction transaction) async {
      await transaction.insert(
        'visitor_sightings',
        sighting.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.insert(
        'visitor_encounters',
        encounter.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.insert('metadata', <String, Object?>{
        'key': 'unlocked_recipe_ids',
        'value': jsonEncode(unlockedRecipeIds.toList()..sort()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.insert('metadata', <String, Object?>{
        'key': 'unlocked_reward_keys',
        'value': jsonEncode(unlockedRewardKeys.toList()..sort()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<String?> metadata(String key) async {
    final rows = await _db.query(
      'metadata',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value']! as String;
  }

  Future<void> setMetadata(String key, String value) async {
    await _db.insert('metadata', <String, Object?>{
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Set<String>> unlockedRecipeIds() async {
    final raw = await metadata('unlocked_recipe_ids');
    if (raw == null) {
      return <String>{};
    }
    return (jsonDecode(raw) as List<Object?>).cast<String>().toSet();
  }

  Future<void> saveUnlockedRecipeIds(Set<String> ids) =>
      setMetadata('unlocked_recipe_ids', jsonEncode(ids.toList()..sort()));

  Future<({double latitude, double longitude})?> lastAmbientCoordinate() async {
    final raw = await metadata('last_ambient_coordinate');
    if (raw == null) {
      return null;
    }
    final value = jsonDecode(raw) as Map<String, Object?>;
    return (
      latitude: (value['latitude']! as num).toDouble(),
      longitude: (value['longitude']! as num).toDouble(),
    );
  }

  Future<void> saveLastAmbientCoordinate(double latitude, double longitude) =>
      setMetadata(
        'last_ambient_coordinate',
        jsonEncode(<String, Object?>{
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
}
