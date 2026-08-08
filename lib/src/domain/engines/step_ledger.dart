import 'package:reality_diorama/src/domain/entities.dart';

class StepSpendResult {
  const StepSpendResult({
    required this.buckets,
    required this.spent,
    required this.unfilled,
  });

  final List<StepBucket> buckets;
  final int spent;
  final int unfilled;
}

class StepLedger {
  const StepLedger();

  List<StepBucket> mergeObserved({
    required List<StepBucket> existing,
    required Map<String, int> observedByDay,
    required DateTime syncedAt,
  }) {
    final byKey = <String, StepBucket>{
      for (final bucket in existing) bucket.dayKey: bucket,
    };

    for (final entry in observedByDay.entries) {
      final old = byKey[entry.key];
      final reported = entry.value < 0 ? 0 : entry.value;
      final safeObserved = old == null
          ? reported
          : reported < old.observedSteps
          ? old.observedSteps
          : reported;
      byKey[entry.key] = StepBucket(
        dayKey: entry.key,
        observedSteps: safeObserved,
        spentSteps: old == null
            ? 0
            : old.spentSteps.clamp(0, safeObserved).toInt(),
        lastSyncedAt: syncedAt,
      );
    }

    final cutoff = DateTime(
      syncedAt.year,
      syncedAt.month,
      syncedAt.day,
    ).subtract(const Duration(days: 6));

    final retained =
        byKey.values.where((StepBucket bucket) {
            final parsed = DateTime.tryParse(bucket.dayKey);
            return parsed != null && !parsed.isBefore(cutoff);
          }).toList()
          ..sort((StepBucket a, StepBucket b) => a.dayKey.compareTo(b.dayKey));
    return retained;
  }

  int available(List<StepBucket> buckets) => buckets.fold<int>(
    0,
    (int sum, StepBucket bucket) => sum + bucket.available,
  );

  StepSpendResult spend(List<StepBucket> buckets, int requested) {
    if (requested <= 0) {
      return StepSpendResult(
        buckets: List<StepBucket>.unmodifiable(buckets),
        spent: 0,
        unfilled: 0,
      );
    }

    var remaining = requested;
    final sorted = List<StepBucket>.of(buckets)
      ..sort((StepBucket a, StepBucket b) => a.dayKey.compareTo(b.dayKey));
    final updated = <StepBucket>[];

    for (final bucket in sorted) {
      final use = remaining.clamp(0, bucket.available).toInt();
      updated.add(bucket.copyWith(spentSteps: bucket.spentSteps + use));
      remaining -= use;
    }

    return StepSpendResult(
      buckets: List<StepBucket>.unmodifiable(updated),
      spent: requested - remaining,
      unfilled: remaining,
    );
  }
}
