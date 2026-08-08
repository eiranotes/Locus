import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/step_ledger.dart';
import 'package:reality_diorama/src/domain/engines/time_context.dart';
import 'package:reality_diorama/src/platform/step_source.dart';

class StepSyncService {
  const StepSyncService({
    required this.source,
    required this.fallbackDailySteps,
  });

  final StepSource source;
  final int fallbackDailySteps;

  List<StepBucket> sourceChangeBaseline(List<StepBucket> existing) {
    return existing
        .map(
          (StepBucket bucket) =>
              bucket.copyWith(observedSteps: bucket.spentSteps),
        )
        .toList(growable: false);
  }

  Future<List<StepBucket>> syncReal({
    required List<StepBucket> existing,
    required DateTime now,
  }) async {
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: 6));
    final observed = await source.dailySteps(from: from, to: now);
    return const StepLedger().mergeObserved(
      existing: existing,
      observedByDay: observed,
      syncedAt: now,
    );
  }

  List<StepBucket> syncFallback({
    required List<StepBucket> existing,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    return const StepLedger().mergeObserved(
      existing: existing,
      observedByDay: <String, int>{dayKey(today): fallbackDailySteps},
      syncedAt: now,
    );
  }
}
