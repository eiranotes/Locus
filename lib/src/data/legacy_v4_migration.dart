import 'package:reality_diorama/src/data/database.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:sqflite/sqflite.dart';

class LegacyV4MigrationReport {
  const LegacyV4MigrationReport({
    required this.alreadyCompleted,
    required this.specimensCreated,
    required this.sceneObjectsCreated,
    required this.placementsCreated,
    required this.relationshipsCreated,
    required this.eventsCreated,
  });

  final bool alreadyCompleted;
  final int specimensCreated;
  final int sceneObjectsCreated;
  final int placementsCreated;
  final int relationshipsCreated;
  final int eventsCreated;
}

class LegacyV4MigrationService {
  LegacyV4MigrationService(this._database);

  static const String markerKey = 'request_first_migration_v1';
  static const String markerValue = 'complete';

  final AppDatabase _database;

  Future<LegacyV4MigrationReport> run() async {
    return _database.database.transaction((Transaction transaction) async {
      final marker = await transaction.query(
        'metadata',
        columns: const <String>['value'],
        where: 'key = ?',
        whereArgs: const <Object?>[markerKey],
        limit: 1,
      );
      if (marker.isNotEmpty && marker.single['value'] == markerValue) {
        return const LegacyV4MigrationReport(
          alreadyCompleted: true,
          specimensCreated: 0,
          sceneObjectsCreated: 0,
          placementsCreated: 0,
          relationshipsCreated: 0,
          eventsCreated: 0,
        );
      }

      var specimensCreated = 0;
      var sceneObjectsCreated = 0;
      var placementsCreated = 0;
      var relationshipsCreated = 0;
      var eventsCreated = 0;

      final captureRows = await transaction.query('capture_records');
      for (final row in captureRows) {
        final record = CaptureRecord.fromMap(row);
        final specimen = LegacyV4Mapper.specimenFor(record);
        specimensCreated += await transaction.insert(
          'specimens',
          specimen.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final placementRows = await transaction.query('placements');
      final placedObjectIds = placementRows
          .map((Map<String, Object?> row) => row['crafted_object_id'])
          .whereType<String>()
          .toSet();
      final objectRows = await transaction.query('crafted_objects');
      for (final row in objectRows) {
        final object = CraftedObject.fromMap(row);
        final sceneObject = LegacyV4Mapper.sceneObjectFor(
          object,
          hasPlacement: placedObjectIds.contains(object.id),
        );
        sceneObjectsCreated += await transaction.insert(
          'scene_objects',
          sceneObject.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      for (final row in placementRows) {
        final placement = Placement.fromMap(row);
        final scenePlacement = LegacyV4Mapper.scenePlacementFor(placement);
        placementsCreated += await transaction.insert(
          'scene_placements',
          scenePlacement.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      final sightingRows = await transaction.query('visitor_sightings');
      for (final row in sightingRows) {
        final sighting = VisitorSighting.fromMap(row);
        final relationship = LegacyV4Mapper.relationshipFor(sighting);
        relationshipsCreated += await transaction.insert(
          'visitor_relationships',
          relationship.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        final event = LegacyV4Mapper.relationshipEventFor(sighting);
        eventsCreated += await transaction.insert(
          'relationship_events',
          event.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await transaction.insert('metadata', const <String, Object?>{
        'key': markerKey,
        'value': markerValue,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return LegacyV4MigrationReport(
        alreadyCompleted: false,
        specimensCreated: specimensCreated,
        sceneObjectsCreated: sceneObjectsCreated,
        placementsCreated: placementsCreated,
        relationshipsCreated: relationshipsCreated,
        eventsCreated: eventsCreated,
      );
    });
  }
}

class LegacyV4Mapper {
  const LegacyV4Mapper._();

  static Specimen specimenFor(CaptureRecord record) => Specimen(
    id: 'legacy-specimen:${record.id}',
    captureRecordId: record.id,
    capturedAt: record.capturedAt,
    channels: const <SenseChannel>{SenseChannel.clock},
    features: SenseVector(const <SenseAxis, double>{}),
    context: SpecimenContext(
      timeBand: record.timeBand,
      season: record.season,
      placeLabel: record.userPlaceLabel,
    ),
    confidence: 1,
    eligibility: SpecimenEligibility.legacyArchive,
    previewSeed: stableSeed(<Object?>[
      'legacy-specimen-v1',
      record.id,
      record.capturedAt.millisecondsSinceEpoch,
    ]),
    featureSchemaVersion: 'legacy-v6',
    legacyPayload: <String, Object?>{
      'sourceVersion': record.sourceVersion,
      'weatherBasis': record.weatherBasis.name,
      'weatherMaterialId': record.weatherMaterialId,
      'surroundingMaterialId': record.surroundingMaterialId,
      'coarseCellId': record.coarseCellId,
    },
  );

  static SceneObject sceneObjectFor(
    CraftedObject object, {
    required bool hasPlacement,
  }) => SceneObject(
    id: object.id,
    definitionId: object.recipeId,
    origin: SceneObjectOrigin.legacyCrafted,
    visualSeed: object.visualSeed,
    generatorVersion: object.generatorVersion,
    variantKey: object.variantKey,
    lifecycle: hasPlacement || object.lifecycle == ObjectLifecycle.placed
        ? SceneObjectLifecycle.placed
        : SceneObjectLifecycle.stored,
    createdAt: object.createdAt,
    legacyPayload: <String, Object?>{
      'kind': object.kind.name,
      'weatherMaterialId': object.weatherMaterialId,
      'weatherKind': object.weatherKind.name,
      'surroundingMaterialId': object.surroundingMaterialId,
      'surroundingKind': object.surroundingKind?.name,
      'requiredSteps': object.requiredSteps,
      'appliedSteps': object.appliedSteps,
      'originalLifecycle': object.lifecycle.name,
      'focusTrait': object.focusTrait?.name,
    },
  );

  static ScenePlacement scenePlacementFor(Placement placement) =>
      ScenePlacement(
        id: placement.id,
        sceneObjectId: placement.craftedObjectId,
        column: placement.column,
        row: placement.row,
        rotation: placement.rotation,
      );

  static VisitorRelationship relationshipFor(VisitorSighting sighting) =>
      VisitorRelationship(
        visitorId: sighting.visitorId,
        stage: 1,
        fulfilledCount: 0,
        lastFulfilledAt: sighting.lastSeenAt,
        unlockedRewardKeys: const <String>{'legacy:resident'},
        state: <String, Object?>{
          'legacyFirstSeenAt': sighting.firstSeenAt.millisecondsSinceEpoch,
          'legacyLastSeenAt': sighting.lastSeenAt.millisecondsSinceEpoch,
        },
      );

  static RelationshipEvent relationshipEventFor(VisitorSighting sighting) =>
      RelationshipEvent(
        id: 'legacy-arrival:${sighting.id}',
        visitorId: sighting.visitorId,
        kind: RelationshipEventKind.legacyArrival,
        occurredAt: sighting.lastSeenAt,
        snapshot: <String, Object?>{
          'variantKey': sighting.variantKey,
          'legacySnapshotJson': sighting.snapshotJson,
        },
      );
}
