import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/entities.dart';

abstract interface class AmbientScanner {
  Future<AmbientFeatures?> scan({required Duration duration});
}

class MethodChannelAmbientScanner implements AmbientScanner {
  const MethodChannelAmbientScanner();

  static const MethodChannel _channel =
      MethodChannel('com.eiranotes.reality_diorama/ambient');

  @override
  Future<AmbientFeatures?> scan({required Duration duration}) async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        'scan',
        <String, Object?>{'durationMillis': duration.inMilliseconds},
      );
      if (result is! Map<Object?, Object?>) {
        return null;
      }
      return AmbientFeatures.fromMap(result);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

class DemoAmbientScanner implements AmbientScanner {
  const DemoAmbientScanner();

  @override
  Future<AmbientFeatures?> scan({required Duration duration}) async {
    await Future<void>.delayed(
      Duration(milliseconds: duration.inMilliseconds.clamp(300, 800).toInt()),
    );
    return const AmbientFeatures(
      uniqueCount: 11,
      medianRssi: -67,
      strongSignalRatio: 0.27,
      persistence: 0.52,
      churn: 0.61,
      observationCoverage: 0.93,
    );
  }
}
