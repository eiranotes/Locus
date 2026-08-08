import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/engines/cooldown_engine.dart';
import 'package:reality_diorama/src/domain/enums.dart';

import 'test_fixtures.dart';

void main() {
  final engine = CooldownEngine(testBalance());
  final base = DateTime.utc(2026, 8, 8, 12);

  test('first weather and surroundings captures are ready', () {
    expect(
      engine
          .weatherReadiness(
            now: base,
            currentKind: WeatherMaterialKind.clear,
            currentTimeBand: TimeBand.afternoon,
          )
          .isReady,
      isTrue,
    );
    expect(
      engine
          .surroundingReadiness(now: base, distanceFromLastCaptureMeters: 0)
          .isReady,
      isTrue,
    );
  });

  test('weather unlocks early after a type change and minimum interval', () {
    final last = testWeather(
      kind: WeatherMaterialKind.clear,
      timeBand: TimeBand.afternoon,
      capturedAt: base,
    );
    final beforeMinimum = engine.weatherReadiness(
      now: base.add(const Duration(minutes: 29)),
      currentKind: WeatherMaterialKind.rain,
      currentTimeBand: TimeBand.afternoon,
      lastMaterial: last,
    );
    final afterMinimum = engine.weatherReadiness(
      now: base.add(const Duration(minutes: 31)),
      currentKind: WeatherMaterialKind.rain,
      currentTimeBand: TimeBand.afternoon,
      lastMaterial: last,
    );
    expect(beforeMinimum.isReady, isFalse);
    expect(afterMinimum.isReady, isTrue);
  });

  test('surroundings unlock early after moving 300 meters', () {
    final last = testSurrounding(capturedAt: base);
    expect(
      engine
          .surroundingReadiness(
            now: base.add(const Duration(minutes: 21)),
            distanceFromLastCaptureMeters: 299,
            lastMaterial: last,
          )
          .isReady,
      isFalse,
    );
    expect(
      engine
          .surroundingReadiness(
            now: base.add(const Duration(minutes: 21)),
            distanceFromLastCaptureMeters: 301,
            lastMaterial: last,
          )
          .isReady,
      isTrue,
    );
  });
}
