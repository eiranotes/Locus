import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

import 'test_fixtures.dart';

void main() {
  final catalog = AtmosphericTraitCatalog.fromJson(
    jsonDecode(
          File('assets/content/atmospheric_traits.json').readAsStringSync(),
        )
        as Map<String, Object?>,
  );

  WeatherSnapshot snapshot({
    double temperature = 20,
    double apparentTemperature = 20,
    double precipitation = 0,
    double cloudCover = 50,
    double windSpeed = 8,
    double visibility = 12000,
  }) => WeatherSnapshot(
    temperatureCelsius: temperature,
    apparentTemperatureCelsius: apparentTemperature,
    precipitationRateMmPerHour: precipitation,
    cloudCoverPercent: cloudCover,
    windSpeedKph: windSpeed,
    visibilityMeters: visibility,
    weatherCode: 0,
    observedAt: DateTime.utc(2026, 8, 9),
    basis: WeatherBasis.providerCurrentModel,
    providerName: 'Test provider',
  );

  test('catalog is complete and caps overlapping traces at two', () {
    catalog.validate();
    final traits = catalog.classify(
      snapshot(
        precipitation: 8,
        cloudCover: 100,
        windSpeed: 80,
        visibility: 500,
      ),
    );

    expect(traits, <AtmosphericTrait>[
      AtmosphericTrait.activePrecipitation,
      AtmosphericTrait.lowVisibility,
    ]);
  });

  test('provider-common numeric boundaries classify deterministically', () {
    expect(
      catalog.classify(snapshot(windSpeed: 40)),
      contains(AtmosphericTrait.strongWind),
    );
    expect(
      catalog.classify(snapshot(apparentTemperature: -5)),
      contains(AtmosphericTrait.sharpCold),
    );
    expect(
      catalog.classify(snapshot(apparentTemperature: 33)),
      contains(AtmosphericTrait.intenseHeat),
    );
    expect(
      catalog.classify(snapshot(cloudCover: 90)),
      contains(AtmosphericTrait.deepCloud),
    );
    expect(
      catalog.classify(snapshot(visibility: 4000)),
      contains(AtmosphericTrait.lowVisibility),
    );
  });

  test('weather and crafted object maps preserve the collected traces', () {
    final weather = testWeather(
      atmosphericTraits: const <AtmosphericTrait>[
        AtmosphericTrait.strongWind,
        AtmosphericTrait.deepCloud,
      ],
    );
    final object = testObject(focusTrait: AtmosphericTrait.deepCloud);

    expect(
      WeatherMaterial.fromMap(weather.toMap()).atmosphericTraits,
      weather.atmosphericTraits,
    );
    expect(
      CraftedObject.fromMap(object.toMap()).focusTrait,
      AtmosphericTrait.deepCloud,
    );
    expect(CraftedObject.fromMap(object.toMap()).variantKey, object.variantKey);
    expect(
      WeatherMaterial.fromMap(weather.toMap()).traitSchemaVersion,
      'weather-traits-v1',
    );
  });
}
