import 'dart:math' as math;

import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class CollectionPatternEngine {
  const CollectionPatternEngine();

  static const String schemaVersion = 'collection-patterns-v1';
  static const int maxCombinationPatterns = 6;

  List<CollectedPattern> derive({
    required String sourceRecordId,
    required DateTime capturedAt,
    required TimeBand timeBand,
    required Season season,
    WeatherSnapshot? weatherSnapshot,
    WeatherMaterialKind? weatherKind,
    AmbientFeatures? ambientFeatures,
    SurroundingMaterialKind? surroundingKind,
  }) {
    final hasWeather = weatherSnapshot != null && weatherKind != null;
    final hasSurroundings = ambientFeatures != null && surroundingKind != null;
    if (!hasWeather && !hasSurroundings) {
      return const <CollectedPattern>[];
    }

    final individual = <_PatternSpec>[
      _timePattern(timeBand),
      _seasonPattern(season),
    ];
    final combinations = <_PatternSpec>[];
    _PatternSpec? weatherBase;
    _PatternSpec? surroundingBase;

    if (hasWeather) {
      weatherBase = _weatherBasePattern(weatherKind);
      individual.add(weatherBase);
      final signals = _weatherSignalPatterns(weatherSnapshot);
      individual.addAll(signals);
      if (signals.length == 5) {
        combinations.add(
          _combination(
            patternKey:
                'combination.weather.${signals[0].patternKey}.${signals[1].patternKey}.${signals[3].patternKey}',
            labelKo:
                '기상 직조 · ${signals[0].labelKo} / ${signals[1].labelKo} / ${signals[3].labelKo}',
            descriptionKo: '온도·강수·바람이 동시에 만든 별도의 기상 조합입니다.',
            components: <_PatternSpec>[signals[0], signals[1], signals[3]],
          ),
        );
      }
    }

    if (hasSurroundings) {
      surroundingBase = _surroundingBasePattern(surroundingKind);
      individual.add(surroundingBase);
      final signals = _ambientSignalPatterns(ambientFeatures);
      individual.addAll(signals);
      combinations.add(
        _combination(
          patternKey:
              'combination.ambient.${signals[0].patternKey}.${signals[2].patternKey}.${signals[3].patternKey}',
          labelKo:
              '주변 직조 · ${signals[0].labelKo} / ${signals[2].labelKo} / ${signals[3].labelKo}',
          descriptionKo: '신호 밀도·지속성·변화율이 함께 만든 별도의 주변 조합입니다.',
          components: <_PatternSpec>[signals[0], signals[2], signals[3]],
        ),
      );
    }

    final time = individual.first;
    if (weatherBase != null) {
      combinations.add(
        _combination(
          patternKey:
              'combination.weather_time.${weatherBase.patternKey}.${time.patternKey}',
          labelKo: '${weatherKind!.labelKo} 오는 ${timeBand.labelKo}',
          descriptionKo: '날씨와 시간대가 같은 수집에서 만난 조합 패턴입니다.',
          components: <_PatternSpec>[weatherBase, time],
        ),
      );
    }
    if (surroundingBase != null) {
      combinations.add(
        _combination(
          patternKey:
              'combination.surrounding_time.${surroundingBase.patternKey}.${time.patternKey}',
          labelKo: '${timeBand.labelKo}의 ${surroundingKind!.labelKo}',
          descriptionKo: '주변 신호와 시간대가 같은 수집에서 만난 조합 패턴입니다.',
          components: <_PatternSpec>[surroundingBase, time],
        ),
      );
    }
    if (weatherBase != null && surroundingBase != null) {
      combinations
        ..add(
          _combination(
            patternKey:
                'combination.weather_surrounding.${weatherBase.patternKey}.${surroundingBase.patternKey}',
            labelKo: '${weatherKind!.labelKo} × ${surroundingKind!.labelKo}',
            descriptionKo: '날씨와 주변 신호가 동시에 모여 생긴 교차 패턴입니다.',
            components: <_PatternSpec>[weatherBase, surroundingBase],
          ),
        )
        ..add(
          _combination(
            patternKey:
                'combination.scene.${weatherBase.patternKey}.${time.patternKey}.${surroundingBase.patternKey}',
            labelKo:
                '${weatherKind.labelKo} · ${timeBand.labelKo} · ${surroundingKind.labelKo}',
            descriptionKo: '날씨·시간대·주변 신호 세 가지가 동시에 만든 장면 패턴입니다.',
            components: <_PatternSpec>[weatherBase, time, surroundingBase],
          ),
        );
    }

    final boundedCombinations = combinations
        .take(maxCombinationPatterns)
        .toList(growable: false);
    final specs = <_PatternSpec>[...individual, ...boundedCombinations];
    return specs
        .map(
          (_PatternSpec spec) => CollectedPattern(
            id: '$sourceRecordId::${spec.patternKey}',
            patternKey: spec.patternKey,
            scope: spec.scope,
            family: spec.family,
            labelKo: spec.labelKo,
            descriptionKo: spec.descriptionKo,
            strength: spec.strength.clamp(0.0, 1.0).toDouble(),
            componentKeys: spec.componentKeys,
            capturedAt: capturedAt,
            sourceRecordId: sourceRecordId,
            schemaVersion: schemaVersion,
          ),
        )
        .toList(growable: false);
  }

  _PatternSpec _timePattern(TimeBand band) => _individual(
    patternKey: 'time.${band.name}',
    family: CapturePatternFamily.time,
    labelKo: '${band.labelKo}의 시간',
    descriptionKo: '수집 시각에서 얻은 시간대 패턴입니다.',
    strength: 1,
  );

  _PatternSpec _seasonPattern(Season season) => _individual(
    patternKey: 'season.${season.name}',
    family: CapturePatternFamily.season,
    labelKo: '${_seasonLabel(season)}의 계절',
    descriptionKo: '수집 시점의 계절에서 얻은 패턴입니다.',
    strength: 1,
  );

  _PatternSpec _weatherBasePattern(WeatherMaterialKind kind) => _individual(
    patternKey: 'weather.kind.${kind.name}',
    family: CapturePatternFamily.weather,
    labelKo: '${kind.labelKo} 날씨',
    descriptionKo: '지역 날씨 모델의 대표 유형에서 얻은 패턴입니다.',
    strength: 1,
  );

  List<_PatternSpec> _weatherSignalPatterns(WeatherSnapshot snapshot) =>
      <_PatternSpec>[
        _temperaturePattern(snapshot.apparentTemperatureCelsius),
        _precipitationPattern(snapshot.precipitationRateMmPerHour),
        _cloudPattern(snapshot.cloudCoverPercent),
        _windPattern(snapshot.windSpeedKph),
        _visibilityPattern(snapshot.visibilityMeters),
      ];

  _PatternSpec _temperaturePattern(double value) {
    final (key, label) = switch (value) {
      <= 0 => ('frozen', '얼어붙는 온도'),
      <= 12 => ('cool', '차가운 온도'),
      < 27 => ('mild', '온화한 온도'),
      < 33 => ('warm', '더운 온도'),
      _ => ('hot', '강한 열기'),
    };
    return _individual(
      patternKey: 'weather.temperature.$key',
      family: CapturePatternFamily.weather,
      labelKo: label,
      descriptionKo: '체감온도 구간에서 얻은 개별 패턴입니다.',
      strength: ((value - 18).abs() / 27).clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _precipitationPattern(double value) {
    final (key, label) = switch (value) {
      < 0.05 => ('dry', '마른 공기'),
      < 1 => ('drizzle', '가벼운 빗방울'),
      < 5 => ('steady', '이어지는 비'),
      _ => ('heavy', '거센 강수'),
    };
    return _individual(
      patternKey: 'weather.precipitation.$key',
      family: CapturePatternFamily.weather,
      labelKo: label,
      descriptionKo: '시간당 강수 구간에서 얻은 개별 패턴입니다.',
      strength: math.min(1, value / 8).toDouble(),
    );
  }

  _PatternSpec _cloudPattern(double value) {
    final (key, label) = switch (value) {
      < 20 => ('open', '트인 하늘'),
      < 60 => ('scattered', '갈라진 구름'),
      < 90 => ('layered', '겹친 구름'),
      _ => ('overcast', '가득 찬 구름'),
    };
    return _individual(
      patternKey: 'weather.cloud.$key',
      family: CapturePatternFamily.weather,
      labelKo: label,
      descriptionKo: '구름 양 구간에서 얻은 개별 패턴입니다.',
      strength: (value / 100).clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _windPattern(double value) {
    final (key, label) = switch (value) {
      < 5 => ('still', '멈춘 바람'),
      < 20 => ('breeze', '잔바람'),
      < 40 => ('flowing', '흐르는 바람'),
      _ => ('strong', '강한 바람'),
    };
    return _individual(
      patternKey: 'weather.wind.$key',
      family: CapturePatternFamily.weather,
      labelKo: label,
      descriptionKo: '풍속 구간에서 얻은 개별 패턴입니다.',
      strength: (value / 80).clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _visibilityPattern(double value) {
    final (key, label) = switch (value) {
      < 1500 => ('enclosed', '가까운 안개'),
      < 4000 => ('low', '낮은 시야'),
      < 10000 => ('soft', '부드러운 거리'),
      _ => ('clear', '선명한 시야'),
    };
    return _individual(
      patternKey: 'weather.visibility.$key',
      family: CapturePatternFamily.weather,
      labelKo: label,
      descriptionKo: '가시거리 구간에서 얻은 개별 패턴입니다.',
      strength: (value / 12000).clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _surroundingBasePattern(SurroundingMaterialKind kind) =>
      _individual(
        patternKey: 'surroundings.kind.${kind.name}',
        family: CapturePatternFamily.surroundings,
        labelKo: kind.labelKo,
        descriptionKo: '주변 신호의 대표 유형에서 얻은 패턴입니다.',
        strength: 1,
      );

  List<_PatternSpec> _ambientSignalPatterns(AmbientFeatures features) =>
      <_PatternSpec>[
        _densityPattern(features.uniqueCount),
        _signalPattern(features.medianRssi, features.strongSignalRatio),
        _persistencePattern(features.persistence),
        _churnPattern(features.churn),
        _coveragePattern(features.observationCoverage),
      ];

  _PatternSpec _densityPattern(int value) {
    final (key, label) = switch (value) {
      < 3 => ('sparse', '드문 신호'),
      < 8 => ('scattered', '흩어진 신호'),
      _ => ('dense', '촘촘한 신호'),
    };
    return _individual(
      patternKey: 'ambient.density.$key',
      family: CapturePatternFamily.surroundings,
      labelKo: label,
      descriptionKo: '서로 다른 세션 신호 수에서 얻은 개별 패턴입니다.',
      strength: (value / 12).clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _signalPattern(double medianRssi, double strongRatio) {
    final (key, label) = medianRssi >= -60 || strongRatio >= 0.35
        ? ('near', '가까운 신호 세기')
        : medianRssi >= -75
        ? ('mixed', '섞인 신호 세기')
        : ('distant', '먼 신호 세기');
    return _individual(
      patternKey: 'ambient.signal.$key',
      family: CapturePatternFamily.surroundings,
      labelKo: label,
      descriptionKo: '신호 세기 분포에서 얻은 개별 패턴입니다.',
      strength: strongRatio.clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _persistencePattern(double value) {
    final (key, label) = switch (value) {
      >= 0.65 => ('persistent', '지속되는 반복'),
      >= 0.35 => ('recurring', '되풀이되는 흔적'),
      _ => ('passing', '스쳐 간 흔적'),
    };
    return _individual(
      patternKey: 'ambient.persistence.$key',
      family: CapturePatternFamily.surroundings,
      labelKo: label,
      descriptionKo: '반복 관측 비율에서 얻은 개별 패턴입니다.',
      strength: value.clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _churnPattern(double value) {
    final (key, label) = switch (value) {
      >= 0.6 => ('flowing', '큰 변화'),
      >= 0.3 => ('shifting', '잔잔한 변화'),
      _ => ('still', '고정된 흐름'),
    };
    return _individual(
      patternKey: 'ambient.churn.$key',
      family: CapturePatternFamily.surroundings,
      labelKo: label,
      descriptionKo: '한 번만 관측된 신호 비율에서 얻은 개별 패턴입니다.',
      strength: value.clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _coveragePattern(double value) {
    final (key, label) = switch (value) {
      >= 0.85 => ('clear', '선명한 관측'),
      >= 0.70 => ('steady', '충분한 관측'),
      _ => ('faint', '옅은 관측'),
    };
    return _individual(
      patternKey: 'ambient.coverage.$key',
      family: CapturePatternFamily.surroundings,
      labelKo: label,
      descriptionKo: '스캔 시간 대비 관측 충족도에서 얻은 개별 패턴입니다.',
      strength: value.clamp(0, 1).toDouble(),
    );
  }

  _PatternSpec _individual({
    required String patternKey,
    required CapturePatternFamily family,
    required String labelKo,
    required String descriptionKo,
    required double strength,
  }) => _PatternSpec(
    patternKey: patternKey,
    scope: CapturePatternScope.individual,
    family: family,
    labelKo: labelKo,
    descriptionKo: descriptionKo,
    strength: strength,
    componentKeys: <String>[patternKey],
  );

  _PatternSpec _combination({
    required String patternKey,
    required String labelKo,
    required String descriptionKo,
    required List<_PatternSpec> components,
  }) => _PatternSpec(
    patternKey: patternKey,
    scope: CapturePatternScope.combination,
    family: CapturePatternFamily.combination,
    labelKo: labelKo,
    descriptionKo: descriptionKo,
    strength:
        components.fold<double>(
          0,
          (double sum, value) => sum + value.strength,
        ) /
        components.length,
    componentKeys: components
        .map((_PatternSpec value) => value.patternKey)
        .toList(growable: false),
  );
}

class _PatternSpec {
  const _PatternSpec({
    required this.patternKey,
    required this.scope,
    required this.family,
    required this.labelKo,
    required this.descriptionKo,
    required this.strength,
    required this.componentKeys,
  });

  final String patternKey;
  final CapturePatternScope scope;
  final CapturePatternFamily family;
  final String labelKo;
  final String descriptionKo;
  final double strength;
  final List<String> componentKeys;
}

String _seasonLabel(Season season) => switch (season) {
  Season.spring => '봄',
  Season.summer => '여름',
  Season.autumn => '가을',
  Season.winter => '겨울',
};
