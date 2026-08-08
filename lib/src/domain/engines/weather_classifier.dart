import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class WeatherClassifier {
  const WeatherClassifier();

  static const String version = 'weather-v1';

  WeatherMaterialKind classify(WeatherSnapshot snapshot) {
    final code = snapshot.weatherCode;
    final condition = snapshot.conditionKey?.toLowerCase() ?? '';
    final isRainCondition = <String>[
      'rain',
      'drizzle',
      'thunderstorm',
      'hail',
    ].any(condition.contains);
    final isRainCode = (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        (code >= 95 && code <= 99);
    if (snapshot.precipitationMillimeters >= 0.1 ||
        isRainCondition ||
        isRainCode) {
      return WeatherMaterialKind.rain;
    }

    final isSnowCondition = <String>[
      'snow',
      'sleet',
      'flurr',
      'blizzard',
      'wintry',
    ].any(condition.contains);
    final isSnowCode = (code >= 71 && code <= 77) ||
        (code >= 85 && code <= 86);
    if (isSnowCondition ||
        isSnowCode ||
        snapshot.apparentTemperatureCelsius <= 0) {
      return WeatherMaterialKind.cold;
    }

    if (condition.contains('wind') ||
        condition.contains('breez') ||
        snapshot.windSpeedKph >= 28) {
      return WeatherMaterialKind.windy;
    }

    if (condition.contains('hot') ||
        snapshot.apparentTemperatureCelsius >= 28) {
      return WeatherMaterialKind.warm;
    }

    final isFogCondition = <String>[
      'fog',
      'haze',
      'smok',
    ].any(condition.contains);
    final isFogCode = code == 45 || code == 48;
    if (isFogCondition || isFogCode || snapshot.cloudCoverPercent >= 70) {
      return WeatherMaterialKind.cloudy;
    }

    return WeatherMaterialKind.clear;
  }
}
