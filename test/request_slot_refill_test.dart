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
    everydayRequestRatio: 1,
    overlapPairRate: 1,
    historyRequestMinimumSpecimens: 5,
    relationshipStageThresholds: <int>[1, 3, 6, 10],
    gridColumns: 5,
    gridRows: 5,
    activeObjectLimit: 8,
  );
  final templates = <RequestTemplateDefinition>[
    RequestTemplateDefinition(
      id: 'quiet',
      visitorIds: const <String>['fog_cat', 'night_moth', 'tea_mouse'],
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
      id: 'broken',
      visitorIds: const <String>['fog_cat', 'night_moth', 'tea_mouse'],
      promptKo: '끊기는 것',
      constraints: const <RequestConstraint>[
        RequestConstraint(axis: SenseAxis.intermittency, minimum: 0.60),
      ],
      overlapTags: const <String>{'quiet'},
      accessTier: RequestAccessTier.everyday,
      difficulty: 1,
      minimumRelationshipStage: 0,
      historyComparison: HistoryComparison.none,
    ),
  ];

  VisitorRequest completedRequest(DateTime issuedAt) => VisitorRequest(
    id: 'completed',
    visitorId: 'fog_cat',
    templateId: 'quiet',
    promptKo: '조용한 것',
    issuedAt: issuedAt,
    expiresAt: issuedAt.add(const Duration(hours: 72)),
    slotIndex: 0,
    status: VisitorRequestStatus.fulfilled,
    constraints: const <RequestConstraint>[
      RequestConstraint(axis: SenseAxis.loudness, maximum: 0.30),
    ],
    difficulty: 1,
    historyComparison: HistoryComparison.none,
    requestSchemaVersion: 'test-v1',
    completedAt: issuedAt.add(const Duration(hours: 1)),
  );

  test('fulfilled slot stays empty for the rest of its game day', () {
    var id = 0;
    final now = DateTime(2026, 8, 11, 12);
    final result = const RequestScheduler(balance: balance).ensureSlots(
      now: now,
      requests: <VisitorRequest>[completedRequest(DateTime(2026, 8, 11, 8))],
      templates: templates,
      relationships: const <String, VisitorRelationship>{},
      unlockedAxes: const <SenseAxis>{
        SenseAxis.loudness,
        SenseAxis.intermittency,
      },
      slotCount: 1,
      historySpecimenIds: const <String>[],
      idFactory: () => 'request-${id++}',
    );

    expect(result.issuedRequests, isEmpty);
    expect(result.activeRequests, isEmpty);
  });

  test('fulfilled slot refills after the next 04:00 boundary', () {
    var id = 0;
    final result = const RequestScheduler(balance: balance).ensureSlots(
      now: DateTime(2026, 8, 12, 5),
      requests: <VisitorRequest>[
        completedRequest(DateTime(2026, 8, 11, 8)),
      ],
      templates: templates,
      relationships: const <String, VisitorRelationship>{},
      unlockedAxes: const <SenseAxis>{
        SenseAxis.loudness,
        SenseAxis.intermittency,
      },
      slotCount: 1,
      historySpecimenIds: const <String>[],
      idFactory: () => 'request-${id++}',
    );

    expect(result.issuedRequests, hasLength(1));
    expect(result.activeRequests, hasLength(1));
    expect(result.activeRequests.single.slotIndex, 0);
  });
}
