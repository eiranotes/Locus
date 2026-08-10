import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

final class PatternVisualDescriptor {
  PatternVisualDescriptor({
    required this.title,
    required this.summary,
    required List<CapturePatternFamily> componentFamilies,
    required this.componentCount,
  }) : componentFamilies = List<CapturePatternFamily>.unmodifiable(
         componentFamilies,
       );

  final String title;
  final String summary;
  final List<CapturePatternFamily> componentFamilies;
  final int componentCount;
}

PatternVisualDescriptor combinationPatternVisualDescriptor(
  CollectedPattern pattern,
  Map<String, CollectedPattern> patternsByKey,
) => PatternVisualDescriptor(
  title: combinationPatternTitle(pattern),
  summary: combinationPatternSummary(pattern, patternsByKey),
  componentFamilies: pattern.componentKeys
      .map(
        (String key) => _normalizedVisualFamily(
          patternsByKey[key]?.family ?? _familyFromPatternKey(key),
        ),
      )
      .whereType<CapturePatternFamily>()
      .take(3)
      .toList(growable: false),
  componentCount: pattern.componentKeys.length,
);

String combinationPatternTitle(CollectedPattern pattern) {
  final key = pattern.patternKey;
  if (key.startsWith('combination.scene.')) return '장면 조합';
  if (key.startsWith('combination.weather_surrounding.')) return '날씨와 주변';
  if (key.startsWith('combination.weather_time.')) return '날씨와 시간';
  if (key.startsWith('combination.surrounding_time.')) return '주변과 시간';
  if (key.startsWith('combination.weather.')) return '기상 조합';
  if (key.startsWith('combination.ambient.')) return '주변 조합';
  return '조합 패턴';
}

String compactPatternLabel(CollectedPattern pattern) => pattern.labelKo
    .replaceFirst(RegExp(r'의 시간$'), '')
    .replaceFirst(RegExp(r'의 계절$'), '')
    .replaceFirst(RegExp(r' 날씨$'), '');

String combinationPatternSummary(
  CollectedPattern pattern,
  Map<String, CollectedPattern> patternsByKey,
) {
  final labels = pattern.componentKeys
      .map((String key) => patternsByKey[key])
      .whereType<CollectedPattern>()
      .map(compactPatternLabel)
      .toList(growable: false);
  if (labels.isNotEmpty) return labels.join(' · ');
  return pattern.labelKo;
}

List<CollectedPattern> representativeCombinationPatterns(
  List<CollectedPattern> patterns,
) {
  final combinations = patterns
      .where((CollectedPattern value) => value.isCombination)
      .toList(growable: false);
  final selected = <CollectedPattern>[];

  void addFirstWhere(bool Function(CollectedPattern value) test) {
    for (final pattern in combinations) {
      if (test(pattern) && !selected.contains(pattern)) {
        selected.add(pattern);
        return;
      }
    }
  }

  addFirstWhere(
    (CollectedPattern value) =>
        value.patternKey.startsWith('combination.scene.'),
  );
  addFirstWhere(_isWithinChannelCombination);
  for (final pattern in combinations) {
    if (selected.length >= 2) break;
    if (!selected.contains(pattern)) selected.add(pattern);
  }
  return selected.take(2).toList(growable: false);
}

int combinationPatternOrder(CollectedPattern pattern) {
  final key = pattern.patternKey;
  if (key.startsWith('combination.scene.')) return 0;
  if (key.startsWith('combination.weather_surrounding.')) return 1;
  if (key.startsWith('combination.weather_time.')) return 2;
  if (key.startsWith('combination.surrounding_time.')) return 3;
  if (key.startsWith('combination.weather.')) return 4;
  if (key.startsWith('combination.ambient.')) return 5;
  return 6;
}

bool _isWithinChannelCombination(CollectedPattern pattern) {
  final key = pattern.patternKey;
  return key.startsWith('combination.weather.weather.') ||
      key.startsWith('combination.ambient.ambient.');
}

CapturePatternFamily? _familyFromPatternKey(String key) {
  if (key.startsWith('time.') || key.startsWith('season.')) {
    return CapturePatternFamily.time;
  }
  if (key.startsWith('weather.')) return CapturePatternFamily.weather;
  if (key.startsWith('surroundings.') || key.startsWith('ambient.')) {
    return CapturePatternFamily.surroundings;
  }
  return null;
}

CapturePatternFamily? _normalizedVisualFamily(CapturePatternFamily? family) =>
    switch (family) {
      CapturePatternFamily.season => CapturePatternFamily.time,
      CapturePatternFamily.time ||
      CapturePatternFamily.weather ||
      CapturePatternFamily.surroundings => family,
      CapturePatternFamily.combination || null => null,
    };
