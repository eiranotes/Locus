import 'dart:math' as math;

import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class SurroundingClassification {
  const SurroundingClassification({
    required this.kind,
    required this.confidence,
  });

  final SurroundingMaterialKind kind;
  final double confidence;
}

class SurroundingClassifier {
  const SurroundingClassifier({this.minimumConfidence = 0.60});

  static const String version = 'surrounding-v1';
  final double minimumConfidence;

  SurroundingClassification? classify(AmbientFeatures features) {
    if (features.uniqueCount < 1 ||
        features.observationCoverage < minimumConfidence) {
      return null;
    }

    final signalEvidence = math.min(1.0, features.uniqueCount / 10.0);
    final confidence = (features.observationCoverage * 0.55 +
            signalEvidence * 0.20 +
            features.persistence.clamp(0.0, 1.0) * 0.15 +
            (1 - (features.churn - 0.5).abs() * 0.5).clamp(0.0, 1.0) *
                0.10)
        .clamp(0.0, 1.0)
        .toDouble();

    if (confidence < minimumConfidence) {
      return null;
    }

    final kind = switch ((features.churn, features.persistence)) {
      (>= 0.45, _) => SurroundingMaterialKind.dynamic,
      (_, >= 0.65) => SurroundingMaterialKind.stable,
      _ when features.uniqueCount >= 8 ||
              features.strongSignalRatio >= 0.35 =>
        SurroundingMaterialKind.dense,
      _ => SurroundingMaterialKind.sparse,
    };

    return SurroundingClassification(kind: kind, confidence: confidence);
  }
}
