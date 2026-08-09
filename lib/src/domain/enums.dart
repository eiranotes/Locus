enum WeatherMaterialKind { clear, rain, cloudy, windy, cold, warm }

/// A bounded, provider-neutral trace derived from numeric current-weather
/// fields. At most two are attached to one collected material.
enum AtmosphericTrait {
  lowVisibility,
  activePrecipitation,
  strongWind,
  sharpCold,
  intenseHeat,
  deepCloud,
}

enum AtmosphericTraitSpread { none, diagonal, adjacent, distanceTwo }

enum SurroundingMaterialKind { dense, dynamic, stable, sparse }

enum TimeBand { dawn, morning, afternoon, evening, night }

enum Season { spring, summer, autumn, winter }

enum HeightBand { low, medium, high }

enum ObjectKind {
  alleyLamp,
  signpost,
  planter,
  bench,
  stairs,
  tree,
  busStop,
  pond,
  bridge,
  tower,
}

enum ObjectLifecycle { building, complete, stored, placed }

enum ConnectionMode { adjacent, dense, sequential, stable, far }

enum ReadinessStatus { ready, waiting, unavailable }

enum WeatherBasis {
  providerCurrentModel,
  providerHistoricalModel,
  demo,
  unavailable,
}

enum CaptureChannel { weather, surroundings }

enum StepTrackingMode { undecided, real, fallback }

enum VisitorRewardKind { recipe, variant, effect }

T enumByName<T extends Enum>(Iterable<T> values, String raw, T fallback) {
  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  return fallback;
}

extension WeatherMaterialKindLabel on WeatherMaterialKind {
  String get labelKo => switch (this) {
    WeatherMaterialKind.clear => '맑음',
    WeatherMaterialKind.rain => '비',
    WeatherMaterialKind.cloudy => '흐림',
    WeatherMaterialKind.windy => '바람',
    WeatherMaterialKind.cold => '추위',
    WeatherMaterialKind.warm => '온기',
  };

  String get icon => switch (this) {
    WeatherMaterialKind.clear => '☀',
    WeatherMaterialKind.rain => '☂',
    WeatherMaterialKind.cloudy => '☁',
    WeatherMaterialKind.windy => '≈',
    WeatherMaterialKind.cold => '✣',
    WeatherMaterialKind.warm => '◉',
  };
}

extension SurroundingMaterialKindLabel on SurroundingMaterialKind {
  String get labelKo => switch (this) {
    SurroundingMaterialKind.dense => '촘촘한 주변',
    SurroundingMaterialKind.dynamic => '변화가 큰 주변',
    SurroundingMaterialKind.stable => '오래 유지되는 주변',
    SurroundingMaterialKind.sparse => '드문 주변',
  };

  String get shortLabelKo => switch (this) {
    SurroundingMaterialKind.dense => '촘촘함',
    SurroundingMaterialKind.dynamic => '유동적',
    SurroundingMaterialKind.stable => '안정적',
    SurroundingMaterialKind.sparse => '드문 편',
  };
}

extension TimeBandLabel on TimeBand {
  String get labelKo => switch (this) {
    TimeBand.dawn => '새벽',
    TimeBand.morning => '아침',
    TimeBand.afternoon => '낮',
    TimeBand.evening => '저녁',
    TimeBand.night => '밤',
  };
}

extension ObjectKindLabel on ObjectKind {
  String get labelKo => switch (this) {
    ObjectKind.alleyLamp => '골목등',
    ObjectKind.signpost => '표지판',
    ObjectKind.planter => '화분',
    ObjectKind.bench => '벤치',
    ObjectKind.stairs => '계단',
    ObjectKind.tree => '나무',
    ObjectKind.busStop => '정류장',
    ObjectKind.pond => '작은 연못',
    ObjectKind.bridge => '작은 다리',
    ObjectKind.tower => '작은 탑',
  };
}
