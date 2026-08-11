import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/specimen_matcher.dart';

void main() {
  final now = DateTime(2026, 8, 11, 20);

  Specimen specimen({
    String id = 'specimen',
    double loudness = 0.20,
    double intermittency = 0.30,
    double rhythmicity = 0.70,
    double confidence = 0.90,
  }) => Specimen(
    id: id,
    captureRecordId: 'record-$id',
    capturedAt: now,
    channels: const <SenseChannel>{SenseChannel.audio},
    features: SenseVector(<SenseAxis, double>{
      SenseAxis.loudness: loudness,
      SenseAxis.intermittency: intermittency,
      SenseAxis.rhythmicity: rhythmicity,
    }),
    context: const SpecimenContext(
      timeBand: TimeBand.night,
      season: Season.summer,
    ),
    confidence: confidence,
    eligibility: confidence >= 0.60
        ? SpecimenEligibility.assignable
        : SpecimenEligibility.lowConfidence,
    previewSeed: 1,
    featureSchemaVersion: 'test-v1',
  );

  VisitorRequest request({
    String id = 'request',
    List<RequestConstraint> constraints = const <RequestConstraint>[],
    HistoryComparison historyComparison = HistoryComparison.none,
    String? historySpecimenId,
  }) => VisitorRequest(
    id: id,
    visitorId: 'fog_cat',
    templateId: 'template',
    promptKo: '테스트 요청',
    issuedAt: now,
    expiresAt: now.add(const Duration(hours: 72)),
    slotIndex: 0,
    status: VisitorRequestStatus.active,
    constraints: constraints,
    difficulty: constraints.length,
    historyComparison: historyComparison,
    historySpecimenId: historySpecimenId,
    requestSchemaVersion: 'test-v1',
  );

  test('quiet night specimen satisfies a bounded request', () {
    final result = const SpecimenMatcher().match(
      specimen: specimen(),
      request: request(
        constraints: const <RequestConstraint>[
          RequestConstraint(
            axis: SenseAxis.loudness,
            maximum: 0.30,
            tolerance: 0.20,
          ),
          RequestConstraint(
            axis: SenseAxis.timeBand,
            anyOf: <String>['evening', 'night'],
          ),
        ],
      ),
    );

    expect(result.passed, isTrue);
    expect(result.verdict, MatchVerdict.match);
    expect(result.score, 1);
  });

  test('partial feedback preserves the failed axis', () {
    final result = const SpecimenMatcher().match(
      specimen: specimen(loudness: 0.44, intermittency: 0.25),
      request: request(
        constraints: const <RequestConstraint>[
          RequestConstraint(
            axis: SenseAxis.loudness,
            maximum: 0.30,
            tolerance: 0.30,
          ),
          RequestConstraint(
            axis: SenseAxis.intermittency,
            maximum: 0.30,
          ),
        ],
      ),
    );

    expect(result.passed, isFalse);
    expect(result.verdict, MatchVerdict.partial);
    expect(
      result.breakdown.singleWhere(
        (ConstraintMatch value) => value.axis == SenseAxis.loudness,
      ).satisfied,
      isFalse,
    );
  });

  test('low-confidence specimens fail closed', () {
    final result = const SpecimenMatcher().match(
      specimen: specimen(confidence: 0.40),
      request: request(
        constraints: const <RequestConstraint>[
          RequestConstraint(axis: SenseAxis.loudness, maximum: 1),
        ],
      ),
    );

    expect(result.passed, isFalse);
    expect(result.verdict, MatchVerdict.lowConfidence);
    expect(result.breakdown, isEmpty);
  });

  test('one specimen may match several requests before assignment', () {
    final matcher = const SpecimenMatcher();
    final value = specimen();
    final first = matcher.match(
      specimen: value,
      request: request(
        id: 'quiet',
        constraints: const <RequestConstraint>[
          RequestConstraint(axis: SenseAxis.loudness, maximum: 0.30),
        ],
      ),
    );
    final second = matcher.match(
      specimen: value,
      request: request(
        id: 'steady',
        constraints: const <RequestConstraint>[
          RequestConstraint(axis: SenseAxis.intermittency, maximum: 0.40),
        ],
      ),
    );

    expect(first.passed, isTrue);
    expect(second.passed, isTrue);
  });

  test('history comparison distinguishes similar and contrasting specimens', () {
    final matcher = const SpecimenMatcher();
    final reference = specimen(id: 'reference', loudness: 0.20);
    final similar = matcher.match(
      specimen: specimen(id: 'similar', loudness: 0.24),
      request: request(
        id: 'similar-request',
        historyComparison: HistoryComparison.similar,
        historySpecimenId: reference.id,
      ),
      referenceSpecimen: reference,
    );
    final contrast = matcher.match(
      specimen: specimen(
        id: 'contrast',
        loudness: 0.95,
        intermittency: 0.95,
        rhythmicity: 0.05,
      ),
      request: request(
        id: 'contrast-request',
        historyComparison: HistoryComparison.contrast,
        historySpecimenId: reference.id,
      ),
      referenceSpecimen: reference,
    );

    expect(similar.passed, isTrue);
    expect(contrast.passed, isTrue);
  });
}
