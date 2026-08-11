import 'package:flutter/services.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class SenseSampleResult {
  const SenseSampleResult({
    required this.channels,
    required this.features,
    required this.confidence,
    required this.schemaVersion,
  });

  final Set<SenseChannel> channels;
  final SenseVector features;
  final double confidence;
  final String schemaVersion;
}

abstract interface class SenseSampler {
  Future<SenseSampleResult> sample({
    required Set<SenseChannel> channels,
    required Duration duration,
  });
}

class MethodChannelSenseSampler implements SenseSampler {
  const MethodChannelSenseSampler();

  static const MethodChannel _channel = MethodChannel(
    'com.eiranotes.reality_diorama/sense',
  );

  @override
  Future<SenseSampleResult> sample({
    required Set<SenseChannel> channels,
    required Duration duration,
  }) async {
    if (!channels.contains(SenseChannel.audio)) {
      throw ArgumentError('The first request-first sampler requires audio.');
    }
    try {
      final raw = await _channel.invokeMethod<Object?>('sampleAudio', <String, Object?>{
        'durationMillis': duration.inMilliseconds.clamp(1000, 10000),
      });
      if (raw is! Map<Object?, Object?>) {
        throw StateError('The native sense sampler returned no feature map.');
      }
      double feature(String key) =>
          ((raw[key] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0).toDouble();
      final confidence = feature('confidence');
      return SenseSampleResult(
        channels: const <SenseChannel>{SenseChannel.audio},
        features: SenseVector(<SenseAxis, double>{
          SenseAxis.loudness: feature('loudness'),
          SenseAxis.intermittency: feature('intermittency'),
          SenseAxis.rhythmicity: feature('rhythmicity'),
          SenseAxis.dynamicRange: feature('dynamicRange'),
          SenseAxis.spectralBrightness: feature('spectralBrightness'),
        }),
        confidence: confidence,
        schemaVersion: raw['schemaVersion'] as String? ?? 'audio-features-v1',
      );
    } on PlatformException catch (error) {
      throw StateError(error.message ?? '감각 표본을 읽지 못했습니다.');
    } on MissingPluginException {
      throw StateError('이 빌드에는 감각 샘플러가 연결되지 않았습니다.');
    }
  }
}

class UnavailableSenseSampler implements SenseSampler {
  const UnavailableSenseSampler();

  @override
  Future<SenseSampleResult> sample({
    required Set<SenseChannel> channels,
    required Duration duration,
  }) {
    throw StateError('Sense sampling is not available on this build.');
  }
}

class DemoSenseSampler implements SenseSampler {
  const DemoSenseSampler({this.variant = 0});

  final int variant;

  @override
  Future<SenseSampleResult> sample({
    required Set<SenseChannel> channels,
    required Duration duration,
  }) async {
    await Future<void>.delayed(
      Duration(milliseconds: duration.inMilliseconds.clamp(50, 300).toInt()),
    );
    final variants = <SenseVector>[
      SenseVector(<SenseAxis, double>{
        SenseAxis.loudness: 0.18,
        SenseAxis.intermittency: 0.28,
        SenseAxis.rhythmicity: 0.72,
        SenseAxis.dynamicRange: 0.22,
        SenseAxis.spectralBrightness: 0.38,
      }),
      SenseVector(<SenseAxis, double>{
        SenseAxis.loudness: 0.76,
        SenseAxis.intermittency: 0.64,
        SenseAxis.rhythmicity: 0.31,
        SenseAxis.dynamicRange: 0.82,
        SenseAxis.spectralBrightness: 0.66,
      }),
    ];
    return SenseSampleResult(
      channels: Set<SenseChannel>.unmodifiable(channels),
      features: variants[variant.abs() % variants.length],
      confidence: 0.92,
      schemaVersion: 'audio-features-demo-v1',
    );
  }
}
