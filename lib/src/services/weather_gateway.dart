import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class WeatherAttributionInfo {
  const WeatherAttributionInfo({
    required this.serviceName,
    required this.notice,
    this.legalPageUri,
    this.combinedMarkDarkUri,
  });

  final String serviceName;
  final String notice;
  final Uri? legalPageUri;
  final Uri? combinedMarkDarkUri;
}

abstract interface class WeatherGateway {
  Future<WeatherAttributionInfo> attribution();
  Future<WeatherSnapshot> current(GeoPoint point);
}

class PlatformWeatherGateway implements WeatherGateway {
  PlatformWeatherGateway({
    WeatherGateway? appleWeather,
    WeatherGateway? otherPlatforms,
  }) : _appleWeather = appleWeather ?? const MethodChannelWeatherGateway(),
       _otherPlatforms = otherPlatforms ?? OpenMeteoWeatherGateway();

  final WeatherGateway _appleWeather;
  final WeatherGateway _otherPlatforms;

  WeatherGateway get _delegate =>
      Platform.isIOS ? _appleWeather : _otherPlatforms;

  @override
  Future<WeatherAttributionInfo> attribution() => _delegate.attribution();

  @override
  Future<WeatherSnapshot> current(GeoPoint point) => _delegate.current(point);
}

class MethodChannelWeatherGateway implements WeatherGateway {
  const MethodChannelWeatherGateway();

  static const MethodChannel _channel = MethodChannel(
    'com.eiranotes.reality_diorama/weather',
  );

  @override
  Future<WeatherAttributionInfo> attribution() async {
    try {
      final result = await _channel.invokeMethod<Object?>('attribution');
      if (result is! Map<Object?, Object?>) {
        return _fallbackAttribution;
      }
      return WeatherAttributionInfo(
        serviceName: result['serviceName']?.toString() ?? 'Weather',
        notice: result['notice']?.toString() ?? _fallbackAttribution.notice,
        legalPageUri: _uriOrNull(result['legalPageURL']),
        combinedMarkDarkUri: _uriOrNull(result['combinedMarkDarkURL']),
      );
    } on PlatformException {
      return _fallbackAttribution;
    } on MissingPluginException {
      return _fallbackAttribution;
    }
  }

  @override
  Future<WeatherSnapshot> current(GeoPoint point) async {
    final result = await _channel.invokeMethod<Object?>(
      'current',
      <String, Object?>{
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
    );
    if (result is! Map<Object?, Object?>) {
      throw const FormatException('WeatherKit returned an invalid payload.');
    }
    double number(String key) => (result[key] as num?)?.toDouble() ?? 0;
    return WeatherSnapshot(
      temperatureCelsius: number('temperatureCelsius'),
      apparentTemperatureCelsius: number('apparentTemperatureCelsius'),
      precipitationRateMmPerHour: number('precipitationIntensity'),
      cloudCoverPercent: number('cloudCoverPercent'),
      windSpeedKph: number('windSpeedKph'),
      visibilityMeters: number('visibilityMeters'),
      weatherCode: (result['weatherCode'] as num?)?.toInt() ?? 0,
      conditionKey: result['conditionKey']?.toString(),
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        (result['observedAtMillis'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      basis: WeatherBasis.providerCurrentModel,
      providerName: result['providerName']?.toString() ?? 'Apple Weather',
    );
  }

  static const WeatherAttributionInfo _fallbackAttribution =
      WeatherAttributionInfo(
        serviceName: 'Weather',
        notice: 'Apple Weather 데이터를 게임용 재료로 변환했습니다.',
      );
}

class OpenMeteoWeatherGateway implements WeatherGateway {
  OpenMeteoWeatherGateway({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<WeatherAttributionInfo> attribution() async => WeatherAttributionInfo(
    serviceName: 'Open-Meteo',
    notice: 'Open-Meteo 날씨 데이터를 게임용 재료로 변환했습니다.',
    legalPageUri: Uri.parse('https://open-meteo.com/'),
  );

  @override
  Future<WeatherSnapshot> current(GeoPoint point) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      <String, String>{
        'latitude': point.latitude.toStringAsFixed(5),
        'longitude': point.longitude.toStringAsFixed(5),
        'current': <String>[
          'temperature_2m',
          'apparent_temperature',
          'precipitation',
          'cloud_cover',
          'wind_speed_10m',
          'visibility',
          'weather_code',
        ].join(','),
        'timezone': 'auto',
      },
    );
    final response = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw StateError('Weather provider returned ${response.statusCode}.');
    }
    final document = jsonDecode(response.body) as Map<String, Object?>;
    final current = document['current']! as Map<String, Object?>;
    final intervalSeconds = (current['interval'] as num?)?.toDouble() ?? 0;
    final precipitationRate = intervalSeconds > 0
        ? _number(current, 'precipitation') * 3600 / intervalSeconds
        : double.nan;
    return WeatherSnapshot(
      temperatureCelsius: _number(current, 'temperature_2m'),
      apparentTemperatureCelsius: _number(current, 'apparent_temperature'),
      precipitationRateMmPerHour: precipitationRate,
      cloudCoverPercent: _number(current, 'cloud_cover'),
      windSpeedKph: _number(current, 'wind_speed_10m'),
      visibilityMeters: _number(current, 'visibility'),
      weatherCode: (current['weather_code']! as num).toInt(),
      observedAt:
          DateTime.tryParse(current['time']! as String)?.toLocal() ??
          DateTime.now(),
      basis: WeatherBasis.providerCurrentModel,
      providerName: 'Open-Meteo',
    );
  }

  double _number(Map<String, Object?> map, String key) =>
      (map[key]! as num).toDouble();
}

class DemoWeatherGateway implements WeatherGateway {
  const DemoWeatherGateway();

  @override
  Future<WeatherAttributionInfo> attribution() async =>
      const WeatherAttributionInfo(
        serviceName: 'Demo',
        notice: '오프라인 데모 날씨를 사용 중입니다.',
      );

  @override
  Future<WeatherSnapshot> current(GeoPoint point) async {
    final now = DateTime.now();
    final wetHour = now.hour % 3 == 1;
    return WeatherSnapshot(
      temperatureCelsius: wetHour ? 18 : 23,
      apparentTemperatureCelsius: wetHour ? 17 : 23,
      precipitationRateMmPerHour: wetHour ? 1.4 : 0,
      cloudCoverPercent: wetHour ? 94 : 90,
      windSpeedKph: 25,
      visibilityMeters: 18000,
      weatherCode: wetHour ? 61 : 3,
      conditionKey: wetHour ? 'rain' : 'cloudy',
      observedAt: now,
      basis: WeatherBasis.demo,
      providerName: 'Demo',
    );
  }
}

Uri? _uriOrNull(Object? raw) {
  final text = raw?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return Uri.tryParse(text);
}
