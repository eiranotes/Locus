import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/step_ledger.dart';

void main() {
  const ledger = StepLedger();
  final now = DateTime.utc(2026, 8, 8, 18);

  test('spends oldest available steps first', () {
    final buckets = <StepBucket>[
      StepBucket(
        dayKey: '2026-08-07',
        observedSteps: 1000,
        spentSteps: 0,
        lastSyncedAt: now,
      ),
      StepBucket(
        dayKey: '2026-08-08',
        observedSteps: 1000,
        spentSteps: 0,
        lastSyncedAt: now,
      ),
    ];
    final result = ledger.spend(buckets, 1500);
    expect(result.spent, 1500);
    expect(result.unfilled, 0);
    expect(result.buckets[0].spentSteps, 1000);
    expect(result.buckets[1].spentSteps, 500);
  });

  test('observed counts never move backwards after fallback or resync', () {
    final existing = <StepBucket>[
      StepBucket(
        dayKey: '2026-08-08',
        observedSteps: 2000,
        spentSteps: 1500,
        lastSyncedAt: now,
      ),
    ];
    final merged = ledger.mergeObserved(
      existing: existing,
      observedByDay: const <String, int>{'2026-08-08': 250},
      syncedAt: now.add(const Duration(minutes: 10)),
    );
    expect(merged.single.observedSteps, 2000);
    expect(merged.single.spentSteps, 1500);
    expect(merged.single.available, 500);
  });

  test('retains only the rolling seven day window', () {
    final merged = ledger.mergeObserved(
      existing: const <StepBucket>[],
      observedByDay: const <String, int>{
        '2026-08-01': 100,
        '2026-08-02': 200,
        '2026-08-08': 300,
      },
      syncedAt: now,
    );
    expect(merged.map((StepBucket value) => value.dayKey), <String>[
      '2026-08-02',
      '2026-08-08',
    ]);
  });
}
