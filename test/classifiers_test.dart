import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/surrounding_classifier.dart';
import 'package:reality_diorama/src/domain/engines/weather_classifier.dart';
import 'package:reality_diorama/src/domain/enums.dart';

WeatherSnapshot snapshot({
  int weatherCode = 0,
  double apparent = 20,
  double precipitation = 0,
  double clouds = 10,
  double wind = 5,
  String? conditionKey,
}) => WeatherSnapshot(
  temperatureCelsius: apparent,
  apparentTemperatureCelsius: apparent,
  precipitationRateMmPerHour: precipitation,
  cloudCoverPercent: clouds,
  windSpeedKph: wind,
  visibilityMeters: 10000,
  weatherCode: weatherCode,
  conditionKey: conditionKey,
  observedAt: DateTime.utc(2026, 8, 8),
  basis: WeatherBasis.providerCurrentModel,
  providerName: 'test',
);

void main() {
  const weather = WeatherClassifier();
  const surrounding = SurroundingClassifier();

  test('weather classifier prioritizes precipitation and snow', () {
    expect(
      weather.classify(snapshot(precipitation: 0.2)),
      WeatherMaterialKind.rain,
    );
    expect(
      weather.classify(snapshot(weatherCode: 73, apparent: 4)),
      WeatherMaterialKind.cold,
    );
  });

  test('weather classifier maps wind, warmth, cloud, and clear', () {
    expect(weather.classify(snapshot(wind: 30)), WeatherMaterialKind.windy);
    expect(weather.classify(snapshot(apparent: 30)), WeatherMaterialKind.warm);
    expect(weather.classify(snapshot(clouds: 90)), WeatherMaterialKind.cloudy);
    expect(weather.classify(snapshot()), WeatherMaterialKind.clear);
  });

  test('weather classifier understands WeatherKit condition names', () {
    expect(
      weather.classify(snapshot(conditionKey: 'heavyRain')),
      WeatherMaterialKind.rain,
    );
    expect(
      weather.classify(snapshot(conditionKey: 'blizzard', apparent: 4)),
      WeatherMaterialKind.cold,
    );
    expect(
      weather.classify(snapshot(conditionKey: 'breezy')),
      WeatherMaterialKind.windy,
    );
    expect(
      weather.classify(snapshot(conditionKey: 'foggy')),
      WeatherMaterialKind.cloudy,
    );
  });

  test('surrounding classifier rejects low coverage', () {
    expect(
      surrounding.classify(
        const AmbientFeatures(
          uniqueCount: 12,
          medianRssi: -60,
          strongSignalRatio: 0.4,
          persistence: 0.6,
          churn: 0.5,
          observationCoverage: 0.2,
        ),
      ),
      isNull,
    );
  });

  test('surrounding classifier maps distinct connection patterns', () {
    expect(
      surrounding
          .classify(
            const AmbientFeatures(
              uniqueCount: 10,
              medianRssi: -68,
              strongSignalRatio: 0.2,
              persistence: 0.4,
              churn: 0.7,
              observationCoverage: 0.95,
            ),
          )
          ?.kind,
      SurroundingMaterialKind.dynamic,
    );
    expect(
      surrounding
          .classify(
            const AmbientFeatures(
              uniqueCount: 5,
              medianRssi: -72,
              strongSignalRatio: 0.1,
              persistence: 0.8,
              churn: 0.1,
              observationCoverage: 0.95,
            ),
          )
          ?.kind,
      SurroundingMaterialKind.stable,
    );
    expect(
      surrounding
          .classify(
            const AmbientFeatures(
              uniqueCount: 9,
              medianRssi: -62,
              strongSignalRatio: 0.4,
              persistence: 0.3,
              churn: 0.2,
              observationCoverage: 0.95,
            ),
          )
          ?.kind,
      SurroundingMaterialKind.dense,
    );
  });
}
