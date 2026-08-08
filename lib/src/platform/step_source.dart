import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/engines/time_context.dart';

abstract interface class StepSource {
  Future<Map<String, int>> dailySteps({
    required DateTime from,
    required DateTime to,
  });
}

class MethodChannelStepSource implements StepSource {
  const MethodChannelStepSource();

  static const MethodChannel _channel = MethodChannel(
    'com.eiranotes.reality_diorama/steps',
  );

  @override
  Future<Map<String, int>> dailySteps({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final result = await _channel
          .invokeMethod<Object?>('getDailySteps', <String, Object?>{
            'fromMillis': from.millisecondsSinceEpoch,
            'toMillis': to.millisecondsSinceEpoch,
          });
      if (result is! Map<Object?, Object?>) {
        return <String, int>{};
      }
      return result.map<String, int>(
        (Object? key, Object? value) =>
            MapEntry<String, int>(key.toString(), (value as num).toInt()),
      );
    } on PlatformException {
      return <String, int>{};
    } on MissingPluginException {
      return <String, int>{};
    }
  }
}

class DemoStepSource implements StepSource {
  const DemoStepSource({this.todaySteps = 4275});

  final int todaySteps;

  @override
  Future<Map<String, int>> dailySteps({
    required DateTime from,
    required DateTime to,
  }) async {
    return <String, int>{dayKey(to): todaySteps};
  }
}
