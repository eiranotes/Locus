import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/platform/step_source.dart';
import 'package:reality_diorama/src/services/step_sync_service.dart';

void main() {
  final now = DateTime(2026, 8, 8, 18);

  test('real sync never injects the fallback allowance', () async {
    final service = StepSyncService(
      source: const _FixedStepSource(<String, int>{'2026-08-08': 725}),
      fallbackDailySteps: 2000,
    );

    final buckets = await service.syncReal(
      existing: const <StepBucket>[],
      now: now,
    );

    expect(buckets.single.observedSteps, 725);
    expect(buckets.single.spentSteps, 0);
  });

  test('fallback allowance is granted only by explicit fallback sync', () {
    final service = StepSyncService(
      source: const _FixedStepSource(<String, int>{}),
      fallbackDailySteps: 2000,
    );

    final buckets = service.syncFallback(
      existing: const <StepBucket>[],
      now: now,
    );

    expect(buckets.single.observedSteps, 2000);
    expect(buckets.single.available, 2000);
  });

  test('source change discards unspent allowance from the previous source', () async {
    final service = StepSyncService(
      source: const _FixedStepSource(<String, int>{'2026-08-08': 725}),
      fallbackDailySteps: 2000,
    );
    final fallback = service.syncFallback(
      existing: const <StepBucket>[],
      now: now,
    );
    final baseline = service.sourceChangeBaseline(fallback);

    final real = await service.syncReal(existing: baseline, now: now);

    expect(real.single.observedSteps, 725);
    expect(real.single.spentSteps, 0);
    expect(real.single.available, 725);
  });

  test('source change keeps spent work but never creates a negative balance', () async {
    final service = StepSyncService(
      source: const _FixedStepSource(<String, int>{'2026-08-08': 725}),
      fallbackDailySteps: 2000,
    );
    final fallback = service.syncFallback(
      existing: const <StepBucket>[],
      now: now,
    );
    final spent = <StepBucket>[
      fallback.single.copyWith(spentSteps: 1500),
    ];
    final baseline = service.sourceChangeBaseline(spent);

    final real = await service.syncReal(existing: baseline, now: now);

    expect(real.single.observedSteps, 1500);
    expect(real.single.spentSteps, 1500);
    expect(real.single.available, 0);
  });

  test('switching sources preserves previously spent work', () async {
    final service = StepSyncService(
      source: const _FixedStepSource(<String, int>{'2026-08-08': 3200}),
      fallbackDailySteps: 2000,
    );
    final fallback = service.syncFallback(
      existing: const <StepBucket>[],
      now: now,
    );
    final spent = <StepBucket>[
      fallback.single.copyWith(spentSteps: 1500),
    ];

    final real = await service.syncReal(existing: spent, now: now);

    expect(real.single.observedSteps, 3200);
    expect(real.single.spentSteps, 1500);
    expect(real.single.available, 1700);
  });
}

class _FixedStepSource implements StepSource {
  const _FixedStepSource(this.values);

  final Map<String, int> values;

  @override
  Future<Map<String, int>> dailySteps({
    required DateTime from,
    required DateTime to,
  }) async => values;
}
