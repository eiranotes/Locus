import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class CooldownEngine {
  const CooldownEngine(this.balance);

  final BalanceDefinition balance;

  ResourceReadiness weatherReadiness({
    required DateTime now,
    required WeatherMaterialKind currentKind,
    required TimeBand currentTimeBand,
    WeatherMaterial? lastMaterial,
  }) {
    if (lastMaterial == null) {
      return const ResourceReadiness.ready('첫 날씨 수집');
    }

    final elapsed = now.difference(lastMaterial.capturedAt);
    final minimum = Duration(minutes: balance.weatherMinimumMinutes);
    final standard = Duration(minutes: balance.weatherCooldownMinutes);

    if (elapsed >= standard) {
      return const ResourceReadiness.ready('기본 준비 시간이 지남');
    }
    if (elapsed >= minimum && currentKind != lastMaterial.kind) {
      return const ResourceReadiness.ready('날씨 유형이 달라짐');
    }
    if (elapsed >= minimum && currentTimeBand != lastMaterial.timeBand) {
      return const ResourceReadiness.ready('시간대가 달라짐');
    }

    return ResourceReadiness.waiting(
      lastMaterial.capturedAt.add(standard),
      '날씨나 시간대가 바뀌면 더 일찍 준비됩니다.',
    );
  }

  ResourceReadiness surroundingReadiness({
    required DateTime now,
    required double distanceFromLastCaptureMeters,
    SurroundingMaterial? lastMaterial,
  }) {
    if (lastMaterial == null) {
      return const ResourceReadiness.ready('첫 주변 수집');
    }

    final elapsed = now.difference(lastMaterial.capturedAt);
    final minimum = Duration(minutes: balance.surroundingMinimumMinutes);
    final standard = Duration(minutes: balance.surroundingCooldownMinutes);

    if (elapsed >= standard) {
      return const ResourceReadiness.ready('기본 준비 시간이 지남');
    }
    if (elapsed >= minimum &&
        distanceFromLastCaptureMeters >=
            balance.surroundingDistanceTriggerMeters) {
      return const ResourceReadiness.ready('다른 장소로 이동함');
    }

    return ResourceReadiness.waiting(
      lastMaterial.capturedAt.add(standard),
      '다른 장소로 이동하면 더 일찍 준비됩니다.',
    );
  }
}
