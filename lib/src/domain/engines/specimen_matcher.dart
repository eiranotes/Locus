import 'dart:math' as math;

import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class SpecimenMatcher {
  const SpecimenMatcher({this.minimumConfidence = 0.60});

  static const String matcherVersion = 'specimen-matcher-v1';

  final double minimumConfidence;

  SpecimenMatch match({
    required Specimen specimen,
    required VisitorRequest request,
    Specimen? referenceSpecimen,
  }) {
    if (!specimen.isAssignable || specimen.confidence < minimumConfidence) {
      return SpecimenMatch(
        specimenId: specimen.id,
        requestId: request.id,
        score: 0,
        passed: false,
        verdict: MatchVerdict.lowConfidence,
        breakdown: const <ConstraintMatch>[],
        matcherVersion: matcherVersion,
      );
    }

    final breakdown = <ConstraintMatch>[
      for (var index = 0; index < request.constraints.length; index += 1)
        _matchConstraint(
          request.constraints[index],
          specimen,
          key: 'axis.$index.${request.constraints[index].axis.name}',
        ),
    ];
    if (request.historyComparison != HistoryComparison.none) {
      breakdown.add(
        _matchHistory(
          comparison: request.historyComparison,
          specimen: specimen,
          reference: referenceSpecimen,
        ),
      );
    }

    var weightedScore = 0.0;
    var totalWeight = 0.0;
    for (var index = 0; index < breakdown.length; index += 1) {
      final weight = index < request.constraints.length
          ? request.constraints[index].weight
          : 1.0;
      weightedScore += breakdown[index].score * weight;
      totalWeight += weight;
    }
    final score = totalWeight == 0 ? 0.0 : weightedScore / totalWeight;
    final hardSatisfied = breakdown
        .where((ConstraintMatch value) => value.hard)
        .every((ConstraintMatch value) => value.score >= 0.65);
    final passed = hardSatisfied && score >= 0.75;
    final verdict = passed
        ? MatchVerdict.match
        : score >= 0.45
        ? MatchVerdict.partial
        : MatchVerdict.mismatch;

    return SpecimenMatch(
      specimenId: specimen.id,
      requestId: request.id,
      score: score.clamp(0.0, 1.0).toDouble(),
      passed: passed,
      verdict: verdict,
      breakdown: List<ConstraintMatch>.unmodifiable(breakdown),
      matcherVersion: matcherVersion,
    );
  }

  ConstraintMatch _matchConstraint(
    RequestConstraint constraint,
    Specimen specimen, {
    required String key,
  }) {
    if (constraint.axis == SenseAxis.timeBand) {
      final observed = specimen.context.timeBand.name;
      final satisfied = constraint.anyOf.contains(observed);
      return ConstraintMatch(
        constraintKey: key,
        axis: constraint.axis,
        score: satisfied ? 1 : 0,
        satisfied: satisfied,
        hard: constraint.hard,
        observed: specimen.context.timeBand.labelKo,
        target: constraint.anyOf.join(' / '),
      );
    }

    final value = specimen.features[constraint.axis];
    if (value == null) {
      return ConstraintMatch(
        constraintKey: key,
        axis: constraint.axis,
        score: 0,
        satisfied: false,
        hard: constraint.hard,
        observed: '측정 없음',
        target: _targetLabel(constraint),
      );
    }
    final score = _rangeScore(value, constraint);
    return ConstraintMatch(
      constraintKey: key,
      axis: constraint.axis,
      score: score,
      satisfied: score >= 0.65,
      hard: constraint.hard,
      observed: value.toStringAsFixed(2),
      target: _targetLabel(constraint),
    );
  }

  ConstraintMatch _matchHistory({
    required HistoryComparison comparison,
    required Specimen specimen,
    required Specimen? reference,
  }) {
    if (reference == null) {
      return ConstraintMatch(
        constraintKey: 'history.${comparison.name}',
        score: 0,
        satisfied: false,
        hard: true,
        observed: '기준 표본 없음',
        target: comparison == HistoryComparison.similar ? '닮음' : '대조',
      );
    }
    final commonAxes = specimen.features.values.keys
        .where(reference.features.values.containsKey)
        .where((SenseAxis value) => value != SenseAxis.timeBand)
        .toList(growable: false);
    if (commonAxes.isEmpty) {
      return ConstraintMatch(
        constraintKey: 'history.${comparison.name}',
        score: 0,
        satisfied: false,
        hard: true,
        observed: '공통 감각 없음',
        target: comparison == HistoryComparison.similar ? '닮음' : '대조',
      );
    }
    var squared = 0.0;
    for (final axis in commonAxes) {
      final delta = specimen.features[axis]! - reference.features[axis]!;
      squared += delta * delta;
    }
    final distance = math.sqrt(squared / commonAxes.length).clamp(0.0, 1.0);
    final score = switch (comparison) {
      HistoryComparison.similar => (1 - distance / 0.40).clamp(0.0, 1.0),
      HistoryComparison.contrast => ((distance - 0.20) / 0.55).clamp(0.0, 1.0),
      HistoryComparison.none => 1.0,
    };
    return ConstraintMatch(
      constraintKey: 'history.${comparison.name}',
      score: score.toDouble(),
      satisfied: score >= 0.65,
      hard: true,
      observed: '거리 ${distance.toStringAsFixed(2)}',
      target: comparison == HistoryComparison.similar ? '닮은 표본' : '대조 표본',
    );
  }

  double _rangeScore(double value, RequestConstraint constraint) {
    final minimum = constraint.minimum;
    final maximum = constraint.maximum;
    if ((minimum == null || value >= minimum) &&
        (maximum == null || value <= maximum)) {
      return 1;
    }
    final tolerance = math.max(0.0001, constraint.tolerance);
    final distance = minimum != null && value < minimum
        ? minimum - value
        : maximum != null && value > maximum
        ? value - maximum
        : 0.0;
    return (1 - distance / tolerance).clamp(0.0, 1.0).toDouble();
  }

  String _targetLabel(RequestConstraint constraint) {
    if (constraint.anyOf.isNotEmpty) return constraint.anyOf.join(' / ');
    if (constraint.minimum != null && constraint.maximum != null) {
      return '${constraint.minimum!.toStringAsFixed(2)}~${constraint.maximum!.toStringAsFixed(2)}';
    }
    if (constraint.minimum != null) {
      return '${constraint.minimum!.toStringAsFixed(2)} 이상';
    }
    if (constraint.maximum != null) {
      return '${constraint.maximum!.toStringAsFixed(2)} 이하';
    }
    return '제한 없음';
  }
}
