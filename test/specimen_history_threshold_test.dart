import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/specimen_matcher.dart';

void main() {
  final now = DateTime.utc(2026, 8, 11);

  Specimen specimen(String id, double loudness) => Specimen(
    id: id,
    captureRecordId: 'record-$id',
    capturedAt: now,
    channels: const <SenseChannel>{SenseChannel.audio},
    features: SenseVector(<SenseAxis, double>{SenseAxis.loudness: loudness}),
    context: const SpecimenContext(
      timeBand: TimeBand.afternoon,
      season: Season.summer,
    ),
    confidence: 1,
    eligibility: SpecimenEligibility.assignable,
    previewSeed: 1,
    featureSchemaVersion: 'test-v1',
  );

  VisitorRequest request(HistoryComparison comparison) => VisitorRequest(
    id: 'request-${comparison.name}',
    visitorId: 'fog_cat',
    templateId: 'history-${comparison.name}',
    promptKo: '기억 표본',
    issuedAt: now,
    expiresAt: now.add(const Duration(hours: 72)),
    slotIndex: 0,
    status: VisitorRequestStatus.active,
    constraints: const <RequestConstraint>[],
    difficulty: 4,
    historyComparison: comparison,
    historySpecimenId: 'reference',
    requestSchemaVersion: 'test-v1',
  );

  test('similarity accepts exactly 0.20 and rejects a larger distance', () {
    final reference = specimen('reference', 0);
    final matcher = const SpecimenMatcher();

    final boundary = matcher.match(
      specimen: specimen('boundary', 0.20),
      request: request(HistoryComparison.similar),
      referenceSpecimen: reference,
    );
    final outside = matcher.match(
      specimen: specimen('outside', 0.201),
      request: request(HistoryComparison.similar),
      referenceSpecimen: reference,
    );

    expect(boundary.passed, isTrue);
    expect(outside.passed, isFalse);
  });

  test('contrast accepts exactly 0.55 and rejects a smaller distance', () {
    final reference = specimen('reference', 0);
    final matcher = const SpecimenMatcher();

    final boundary = matcher.match(
      specimen: specimen('boundary', 0.55),
      request: request(HistoryComparison.contrast),
      referenceSpecimen: reference,
    );
    final inside = matcher.match(
      specimen: specimen('inside', 0.549),
      request: request(HistoryComparison.contrast),
      referenceSpecimen: reference,
    );

    expect(boundary.passed, isTrue);
    expect(inside.passed, isFalse);
  });
}
