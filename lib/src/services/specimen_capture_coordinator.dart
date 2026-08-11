import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/engines/specimen_matcher.dart';
import 'package:reality_diorama/src/domain/engines/time_context.dart';
import 'package:reality_diorama/src/platform/sense_sampler.dart';
import 'package:uuid/uuid.dart';

class SpecimenCaptureBundle {
  const SpecimenCaptureBundle({
    required this.record,
    required this.specimen,
    required this.matches,
  });

  final CaptureRecord record;
  final Specimen specimen;
  final List<SpecimenMatch> matches;
}

class SpecimenCaptureCoordinator {
  const SpecimenCaptureCoordinator({
    required this.sampler,
    this.matcher = const SpecimenMatcher(),
    this.captureDuration = const Duration(seconds: 4),
    this.minimumConfidence = 0.60,
    this.uuid = const Uuid(),
  });

  final SenseSampler sampler;
  final SpecimenMatcher matcher;
  final Duration captureDuration;
  final double minimumConfidence;
  final Uuid uuid;

  Future<SpecimenCaptureBundle> capture({
    required DateTime now,
    required List<VisitorRequest> activeRequests,
    Map<String, Specimen> referenceSpecimensById = const <String, Specimen>{},
    String? placeLabel,
  }) async {
    final sample = await sampler.sample(
      channels: const <SenseChannel>{SenseChannel.audio},
      duration: captureDuration,
    );
    final recordId = uuid.v4();
    final specimenId = uuid.v4();
    final timeBand = timeBandFor(now);
    final season = seasonFor(now, northernHemisphere: true);
    final record = CaptureRecord(
      id: recordId,
      capturedAt: now,
      userPlaceLabel: placeLabel,
      timeBand: timeBand,
      season: season,
      weatherBasis: WeatherBasis.unavailable,
      sourceVersion: 'specimen-v1',
    );
    final eligibility = sample.confidence >= minimumConfidence
        ? SpecimenEligibility.assignable
        : SpecimenEligibility.lowConfidence;
    final specimen = Specimen(
      id: specimenId,
      captureRecordId: recordId,
      capturedAt: now,
      channels: sample.channels,
      features: sample.features,
      context: SpecimenContext(
        timeBand: timeBand,
        season: season,
        placeLabel: placeLabel,
      ),
      confidence: sample.confidence,
      eligibility: eligibility,
      previewSeed: stableSeed(<Object?>[
        specimenId,
        now.millisecondsSinceEpoch,
        sample.schemaVersion,
      ]),
      featureSchemaVersion: sample.schemaVersion,
    );
    final matches = activeRequests
        .map((VisitorRequest request) {
          return matcher.match(
            specimen: specimen,
            request: request,
            referenceSpecimen: request.historySpecimenId == null
                ? null
                : referenceSpecimensById[request.historySpecimenId],
          );
        })
        .toList(growable: false);
    return SpecimenCaptureBundle(
      record: record,
      specimen: specimen,
      matches: matches,
    );
  }
}
