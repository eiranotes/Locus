import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/request_scheduler.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';

void main() {
  const balance = RequestFirstBalance(
    tutorialRequestSlots: 1,
    requestSlots: 2,
    gameDayBoundaryHour: 4,
    requestLifetimeHours: 72,
    requestReplacementCooldownHours: 24,
    specimenCaptureSeconds: 4,
    minimumCaptureConfidence: 0.60,
    everydayRequestRatio: 0.70,
    overlapPairRate: 1.0,
    historyRequestMinimumSpecimens: 5,
    relationshipStageThresholds: <int>[1, 3, 6, 10],
    gridColumns: 5,
    gridRows: 5,
    activeObjectLimit: 8,
  );
  final templates = <RequestTemplateDefinition>[
    RequestTemplateDefinition(
      id: 'quiet',
      visitorIds: const <String>['fog_cat', 'night_moth'],
      promptKo: '조용한 것',
      constraints: const <RequestConstraint>[
        RequestConstraint(axis: SenseAxis.loudness, maximum: 0.30),
      ],
      overlapTags: const <String>{'quiet'},
      accessTier: RequestAccessTier.everyday,
      difficulty: 1,
      minimumRelationshipStage: 0,
      historyComparison: HistoryComparison.none,
    ),
    RequestTemplateDefinition(
      id: 'quiet-night',
      visitorIds: const <String>['night_moth', 'tea_mouse'],
      promptKo: '밤의 조용한 것',
      constraints: const <RequestConstraint>[
        RequestConstraint(axis: SenseAxis.loudness, maximum: 0.30),
        RequestConstraint(
          axis: SenseAxis.timeBand,
          anyOf: <String>['night'],
        ),
      ],
      overlapTags: const <String>{'quiet', 'night'},
      accessTier: RequestAccessTier.everyday,
      difficulty: 2,
      minimumRelationshipStage: 0,
      historyComparison: HistoryComparison.none,
    ),
    RequestTemplateDefinition(
      id: 'rhythm',
      visitorIds: const <String>['tea_mouse'],
      promptKo: '리듬 있는 것',
      constraints: const <RequestConstraint>[
        RequestConstraint(axis: SenseAxis.rhythmicity, minimum: 0.70),
      ],
      overlapTags: const <String>{'rhythm'},
      accessTier: RequestAccessTier.outing,
      difficulty: 3,
      minimumRelationshipStage: 2,
      historyComparison: HistoryComparison.none,
    ),
  ];

  test('fills two slots with distinct visitors and overlapping requests', () {
    var id = 0;
    final result = const RequestScheduler(balance: balance).ensureSlots(
      now: DateTime(2026, 8, 11, 9),
      requests: const <VisitorRequest>[],
      templates: templates,
      relationships: const <String, VisitorRelationship>{},
      unlockedAxes: const <SenseAxis>{
        SenseAxis.loudness,
        SenseAxis.timeBand,
      },
      slotCount: 2,
      historySpecimenIds: const <String>[],
      idFactory: () => 'request-${id++}',
    );

    expect(result.activeRequests, hasLength(2));
    expect(
      result.activeRequests
          .map((VisitorRequest value) => value.visitorId)
          .toSet(),
      hasLength(2),
    );
    expect(
      result.activeRequests
          .map((VisitorRequest value) => value.templateId)
          .toSet(),
      containsAll(<String>['quiet', 'quiet-night']),
    );
  });

  test('does not issue requests for locked axes', () {
    var id = 0;
    final result = const RequestScheduler(balance: balance).ensureSlots(
      now: DateTime(2026, 8, 11, 9),
      requests: const <VisitorRequest>[],
      templates: <RequestTemplateDefinition>[templates.last],
      relationships: <String, VisitorRelationship>{
        'tea_mouse': VisitorRelationship(
          visitorId: 'tea_mouse',
          stage: 3,
          fulfilledCount: 6,
          unlockedRewardKeys: const <String>{},
        ),
      },
      unlockedAxes: const <SenseAxis>{SenseAxis.loudness},
      slotCount: 1,
      historySpecimenIds: const <String>[],
      idFactory: () => 'request-${id++}',
    );

    expect(result.activeRequests, isEmpty);
  });

  test('expires stale requests before filling their slots', () {
    var id = 0;
    final now = DateTime(2026, 8, 11, 9);
    final stale = VisitorRequest(
      id: 'stale',
      visitorId: 'fog_cat',
      templateId: 'quiet',
      promptKo: '조용한 것',
      issuedAt: now.subtract(const Duration(days: 4)),
      expiresAt: now.subtract(const Duration(minutes: 1)),
      slotIndex: 0,
      status: VisitorRequestStatus.active,
      constraints: const <RequestConstraint>[
        RequestConstraint(axis: SenseAxis.loudness, maximum: 0.30),
      ],
      difficulty: 1,
      historyComparison: HistoryComparison.none,
      requestSchemaVersion: 'test',
    );
    final result = const RequestScheduler(balance: balance).ensureSlots(
      now: now,
      requests: <VisitorRequest>[stale],
      templates: templates,
      relationships: const <String, VisitorRelationship>{},
      unlockedAxes: const <SenseAxis>{
        SenseAxis.loudness,
        SenseAxis.timeBand,
      },
      slotCount: 1,
      historySpecimenIds: const <String>[],
      idFactory: () => 'replacement-${id++}',
    );

    expect(result.expiredRequests.single.status, VisitorRequestStatus.expired);
    expect(result.issuedRequests, hasLength(1));
    expect(result.activeRequests.single.id, startsWith('replacement-'));
  });

  test('same day and state produce the same template and visitor', () {
    RequestScheduleResult run() {
      var id = 0;
      return const RequestScheduler(balance: balance).ensureSlots(
        now: DateTime(2026, 8, 11, 9),
        requests: const <VisitorRequest>[],
        templates: templates,
        relationships: const <String, VisitorRelationship>{},
        unlockedAxes: const <SenseAxis>{
          SenseAxis.loudness,
          SenseAxis.timeBand,
        },
        slotCount: 2,
        historySpecimenIds: const <String>[],
        idFactory: () => 'id-${id++}',
      );
    }

    final first = run();
    final second = run();
    expect(
      first.activeRequests.map((VisitorRequest value) => value.templateId),
      second.activeRequests.map((VisitorRequest value) => value.templateId),
    );
    expect(
      first.activeRequests.map((VisitorRequest value) => value.visitorId),
      second.activeRequests.map((VisitorRequest value) => value.visitorId),
    );
  });

  test('history requests persist a deterministic reference specimen', () {
    var id = 0;
    final historyTemplate = RequestTemplateDefinition(
      id: 'similar-memory',
      visitorIds: const <String>['fog_cat'],
      promptKo: '전에 준 것과 닮은 것',
      constraints: const <RequestConstraint>[
        RequestConstraint(
          axis: SenseAxis.loudness,
          minimum: 0,
          maximum: 1,
          hard: false,
        ),
      ],
      overlapTags: const <String>{'memory'},
      accessTier: RequestAccessTier.everyday,
      difficulty: 4,
      minimumRelationshipStage: 4,
      historyComparison: HistoryComparison.similar,
    );
    final result = const RequestScheduler(balance: balance).ensureSlots(
      now: DateTime(2026, 8, 11, 9),
      requests: const <VisitorRequest>[],
      templates: <RequestTemplateDefinition>[historyTemplate],
      relationships: <String, VisitorRelationship>{
        'fog_cat': VisitorRelationship(
          visitorId: 'fog_cat',
          stage: 4,
          fulfilledCount: 10,
          unlockedRewardKeys: const <String>{},
        ),
      },
      unlockedAxes: const <SenseAxis>{SenseAxis.loudness},
      slotCount: 1,
      historySpecimenIds: const <String>[
        'specimen-5',
        'specimen-3',
        'specimen-1',
        'specimen-4',
        'specimen-2',
      ],
      idFactory: () => 'history-request-${id++}',
    );

    expect(result.activeRequests, hasLength(1));
    expect(result.activeRequests.single.historySpecimenId, isNotNull);
    expect(
      const <String>{
        'specimen-1',
        'specimen-2',
        'specimen-3',
        'specimen-4',
        'specimen-5',
      },
      contains(result.activeRequests.single.historySpecimenId),
    );
  });
}
