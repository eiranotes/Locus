import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/platform/sense_sampler.dart';
import 'package:reality_diorama/src/services/specimen_capture_coordinator.dart';

void main() {
  test(
    'capture creates a permanent record, specimen, and request matches',
    () async {
      final now = DateTime(2026, 8, 11, 20);
      final request = VisitorRequest(
        id: 'request',
        visitorId: 'fog_cat',
        templateId: 'quiet',
        promptKo: '조용한 것',
        issuedAt: now,
        expiresAt: now.add(const Duration(hours: 72)),
        slotIndex: 0,
        status: VisitorRequestStatus.active,
        constraints: const <RequestConstraint>[
          RequestConstraint(axis: SenseAxis.loudness, maximum: 0.30),
        ],
        difficulty: 1,
        historyComparison: HistoryComparison.none,
        requestSchemaVersion: 'test-v1',
      );
      final bundle = await const SpecimenCaptureCoordinator(
        sampler: DemoSenseSampler(),
        captureDuration: Duration(milliseconds: 10),
      ).capture(now: now, activeRequests: <VisitorRequest>[request]);

      expect(bundle.record.id, bundle.specimen.captureRecordId);
      expect(bundle.record.sourceVersion, 'specimen-v1');
      expect(bundle.specimen.isAssignable, isTrue);
      expect(bundle.specimen.channels, <SenseChannel>{SenseChannel.audio});
      expect(bundle.matches.single.requestId, request.id);
      expect(bundle.matches.single.passed, isTrue);
    },
  );
}
