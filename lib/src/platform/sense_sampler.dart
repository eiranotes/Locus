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
