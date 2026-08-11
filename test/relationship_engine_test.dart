import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/relationship_engine.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';

void main() {
  final track = RelationshipTrackDefinition(
    visitorId: 'night_moth',
    milestones: const <RelationshipMilestoneDefinition>[
      RelationshipMilestoneDefinition(
        stage: 1,
        fulfilledCount: 1,
        becomesResident: true,
      ),
      RelationshipMilestoneDefinition(
        stage: 2,
        fulfilledCount: 3,
        unlockAxis: SenseAxis.rhythmicity,
      ),
      RelationshipMilestoneDefinition(
        stage: 3,
        fulfilledCount: 6,
        sceneObjectId: 'keepsake_lantern_string',
      ),
      RelationshipMilestoneDefinition(stage: 4, fulfilledCount: 10),
    ],
  );

  RelationshipResolution fulfill({
    VisitorRelationship? current,
    int seed = 0,
  }) {
    var id = seed;
    return const RelationshipEngine().fulfill(
      visitorId: 'night_moth',
      requestId: 'request',
      specimenId: 'specimen',
      matchScore: 0.90,
      now: DateTime(2026, 8, 11),
      current: current,
      track: track,
      idFactory: () => 'event-${id++}',
    );
  }

  test('first fulfillment makes the visitor resident exactly once', () {
    final result = fulfill();

    expect(result.relationship.stage, 1);
    expect(result.relationship.fulfilledCount, 1);
    expect(
      result.events.map((RelationshipEvent value) => value.kind),
      containsAll(<RelationshipEventKind>[
        RelationshipEventKind.requestFulfilled,
        RelationshipEventKind.stageAdvanced,
        RelationshipEventKind.becameResident,
      ]),
    );
  });

  test('third fulfillment unlocks a new axis', () {
    final current = VisitorRelationship(
      visitorId: 'night_moth',
      stage: 1,
      fulfilledCount: 2,
      unlockedRewardKeys: const <String>{'stage:1', 'resident'},
    );
    final result = fulfill(current: current);

    expect(result.relationship.stage, 2);
    expect(result.unlockedAxes, <SenseAxis>{SenseAxis.rhythmicity});
    expect(
      result.relationship.unlockedRewardKeys,
      contains('axis:rhythmicity'),
    );
  });

  test('already crossed milestones are not granted again', () {
    final current = VisitorRelationship(
      visitorId: 'night_moth',
      stage: 2,
      fulfilledCount: 3,
      unlockedRewardKeys: const <String>{
        'stage:1',
        'resident',
        'stage:2',
        'axis:rhythmicity',
      },
    );
    final result = fulfill(current: current);

    expect(result.relationship.fulfilledCount, 4);
    expect(result.unlockedAxes, isEmpty);
    expect(result.grantedSceneObjectIds, isEmpty);
    expect(
      result.events.where(
        (RelationshipEvent value) =>
            value.kind != RelationshipEventKind.requestFulfilled,
      ),
      isEmpty,
    );
  });

  test('sixth fulfillment grants one keepsake', () {
    final current = VisitorRelationship(
      visitorId: 'night_moth',
      stage: 2,
      fulfilledCount: 5,
      unlockedRewardKeys: const <String>{
        'stage:1',
        'resident',
        'stage:2',
        'axis:rhythmicity',
      },
    );
    final result = fulfill(current: current);

    expect(result.relationship.stage, 3);
    expect(
      result.grantedSceneObjectIds,
      <String>['keepsake_lantern_string'],
    );
  });
}
