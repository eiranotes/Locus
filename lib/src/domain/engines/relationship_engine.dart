import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';

class RelationshipResolution {
  const RelationshipResolution({
    required this.relationship,
    required this.events,
    required this.unlockedAxes,
    required this.grantedSceneObjectIds,
  });

  final VisitorRelationship relationship;
  final List<RelationshipEvent> events;
  final Set<SenseAxis> unlockedAxes;
  final List<String> grantedSceneObjectIds;
}

class RelationshipEngine {
  const RelationshipEngine();

  RelationshipResolution fulfill({
    required String visitorId,
    required String requestId,
    required String specimenId,
    required double matchScore,
    required DateTime now,
    required VisitorRelationship? current,
    required RelationshipTrackDefinition track,
    required String Function() idFactory,
  }) {
    if (track.visitorId != visitorId) {
      throw ArgumentError.value(
        track.visitorId,
        'track.visitorId',
        'must match visitorId',
      );
    }
    final previous = current ??
        VisitorRelationship(
          visitorId: visitorId,
          stage: 0,
          fulfilledCount: 0,
          unlockedRewardKeys: const <String>{},
        );
    final nextCount = previous.fulfilledCount + 1;
    final crossed = track.milestones.where(
      (RelationshipMilestoneDefinition milestone) =>
          milestone.fulfilledCount > previous.fulfilledCount &&
          milestone.fulfilledCount <= nextCount,
    ).toList(growable: false);
    var nextStage = previous.stage;
    final rewardKeys = Set<String>.from(previous.unlockedRewardKeys);
    final unlockedAxes = <SenseAxis>{};
    final sceneObjectIds = <String>[];
    final events = <RelationshipEvent>[
      RelationshipEvent(
        id: idFactory(),
        visitorId: visitorId,
        requestId: requestId,
        specimenId: specimenId,
        kind: RelationshipEventKind.requestFulfilled,
        occurredAt: now,
        matchScore: matchScore,
        snapshot: <String, Object?>{'fulfilledCount': nextCount},
      ),
    ];

    for (final milestone in crossed) {
      nextStage = milestone.stage > nextStage ? milestone.stage : nextStage;
      final stageKey = 'stage:${milestone.stage}';
      if (rewardKeys.add(stageKey)) {
        events.add(
          RelationshipEvent(
            id: idFactory(),
            visitorId: visitorId,
            requestId: requestId,
            specimenId: specimenId,
            kind: RelationshipEventKind.stageAdvanced,
            occurredAt: now,
            snapshot: <String, Object?>{'stage': milestone.stage},
          ),
        );
      }
      final axis = milestone.unlockAxis;
      if (axis != null && rewardKeys.add('axis:${axis.name}')) {
        unlockedAxes.add(axis);
        events.add(
          RelationshipEvent(
            id: idFactory(),
            visitorId: visitorId,
            requestId: requestId,
            specimenId: specimenId,
            kind: RelationshipEventKind.senseUnlocked,
            occurredAt: now,
            snapshot: <String, Object?>{'axis': axis.name},
          ),
        );
      }
      final sceneObjectId = milestone.sceneObjectId;
      if (sceneObjectId != null &&
          rewardKeys.add('sceneObject:$sceneObjectId')) {
        sceneObjectIds.add(sceneObjectId);
        events.add(
          RelationshipEvent(
            id: idFactory(),
            visitorId: visitorId,
            requestId: requestId,
            specimenId: specimenId,
            kind: RelationshipEventKind.keepsakeGranted,
            occurredAt: now,
            snapshot: <String, Object?>{'sceneObjectId': sceneObjectId},
          ),
        );
      }
      if (milestone.becomesResident && rewardKeys.add('resident')) {
        events.add(
          RelationshipEvent(
            id: idFactory(),
            visitorId: visitorId,
            requestId: requestId,
            specimenId: specimenId,
            kind: RelationshipEventKind.becameResident,
            occurredAt: now,
          ),
        );
      }
    }

    return RelationshipResolution(
      relationship: VisitorRelationship(
        visitorId: visitorId,
        stage: nextStage,
        fulfilledCount: nextCount,
        lastFulfilledAt: now,
        unlockedRewardKeys: rewardKeys,
        state: previous.state,
      ),
      events: List<RelationshipEvent>.unmodifiable(events),
      unlockedAxes: Set<SenseAxis>.unmodifiable(unlockedAxes),
      grantedSceneObjectIds: List<String>.unmodifiable(sceneObjectIds),
    );
  }
}
