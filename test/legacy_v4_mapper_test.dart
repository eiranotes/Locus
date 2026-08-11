import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/data/legacy_v4_migration.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

import 'test_fixtures.dart';

void main() {
  test('legacy captures become permanent non-assignable specimens', () {
    final record = CaptureRecord(
      id: 'capture-1',
      capturedAt: DateTime.utc(2026, 8, 8, 19),
      coarseCellId: '37.54:127.05',
      userPlaceLabel: '성수동',
      timeBand: TimeBand.evening,
      season: Season.summer,
      weatherBasis: WeatherBasis.providerCurrentModel,
      sourceVersion: 'capture-v3',
      weatherMaterialId: 'weather-1',
      surroundingMaterialId: 'surrounding-1',
    );

    final specimen = LegacyV4Mapper.specimenFor(record);

    expect(specimen.captureRecordId, record.id);
    expect(specimen.eligibility, SpecimenEligibility.legacyArchive);
    expect(specimen.isAssignable, isFalse);
    expect(specimen.context.placeLabel, '성수동');
    expect(specimen.legacyPayload?['weatherMaterialId'], 'weather-1');
  });

  test('building objects are completed into storage without losing provenance', () {
    final object = testObject(
      id: 'building',
      recipeId: 'bench',
      kind: ObjectKind.bench,
      requiredSteps: 2400,
      appliedSteps: 1200,
      focusTrait: AtmosphericTrait.deepCloud,
    );

    final scene = LegacyV4Mapper.sceneObjectFor(
      object,
      hasPlacement: false,
    );

    expect(scene.id, object.id);
    expect(scene.definitionId, 'bench');
    expect(scene.origin, SceneObjectOrigin.legacyCrafted);
    expect(scene.lifecycle, SceneObjectLifecycle.stored);
    expect(scene.visualSeed, object.visualSeed);
    expect(scene.generatorVersion, object.generatorVersion);
    expect(scene.variantKey, object.variantKey);
    expect(scene.legacyPayload?['originalLifecycle'], 'building');
    expect(scene.legacyPayload?['appliedSteps'], 1200);
    expect(scene.legacyPayload?['focusTrait'], 'deepCloud');
  });

  test('legacy placements preserve ids coordinates and rotations', () {
    const placement = Placement(
      id: 'placement-1',
      craftedObjectId: 'object-1',
      column: 3,
      row: 2,
      rotation: 3,
    );

    final scene = LegacyV4Mapper.scenePlacementFor(placement);

    expect(scene.id, placement.id);
    expect(scene.sceneObjectId, placement.craftedObjectId);
    expect(scene.column, 3);
    expect(scene.row, 2);
    expect(scene.rotation, 3);
  });

  test('legacy sightings become resident relationships and timeline events', () {
    final sighting = VisitorSighting(
      id: 'sighting-1',
      visitorId: 'fog_cat',
      firstSeenAt: DateTime.utc(2026, 8, 1),
      lastSeenAt: DateTime.utc(2026, 8, 8),
      variantKey: 'rain_evening_local',
      snapshotJson: '{}',
    );

    final relationship = LegacyV4Mapper.relationshipFor(sighting);
    final event = LegacyV4Mapper.relationshipEventFor(sighting);

    expect(relationship.stage, 1);
    expect(relationship.fulfilledCount, 0);
    expect(relationship.unlockedRewardKeys, contains('legacy:resident'));
    expect(event.kind, RelationshipEventKind.legacyArrival);
    expect(event.visitorId, sighting.visitorId);
    expect(event.occurredAt, sighting.lastSeenAt);
  });
}
