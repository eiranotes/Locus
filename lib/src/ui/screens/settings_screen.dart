import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/services/weather_gateway.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.demoMode, super.key});

  final bool demoMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<WeatherAttributionInfo>? _weatherAttribution;
  bool _changingStepSource = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _weatherAttribution ??= AppScope.read(context).weatherAttribution();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text('걸음과 작업량', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _StepSourceCard(
            controller: controller,
            busy: _changingStepSource,
            onUseRealSteps: () => _useRealSteps(controller),
            onUseFallback: () => _useFallbackSteps(controller),
          ),
          const SizedBox(height: 20),
          Text('데이터와 개인정보', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          PixelCard(
            radius: PixelRadii.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _InfoLine(
                  icon: Icons.phone_iphone,
                  text: '기록은 이 기기에 저장됩니다.',
                ),
                const _InfoLine(
                  icon: Icons.bluetooth,
                  text: '주변 읽기 8초 · 기기 식별 정보 저장 안 함',
                ),
                const _InfoLine(
                  icon: Icons.location_on_outlined,
                  text: '공유 화면은 정확한 좌표를 숨깁니다.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('날씨 정보', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<WeatherAttributionInfo>(
            future: _weatherAttribution,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<WeatherAttributionInfo> snapshot,
                ) {
                  final attribution = snapshot.data;
                  final markUri = attribution?.combinedMarkDarkUri;
                  final legalUri = attribution?.legalPageUri;
                  return PixelCard(
                    radius: PixelRadii.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (markUri != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Image.network(
                              markUri.toString(),
                              height: 24,
                              errorBuilder: (_, __, ___) => Text(
                                attribution?.serviceName ?? '날씨 제공자',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          )
                        else
                          Text(
                            attribution?.serviceName ??
                                (snapshot.hasError
                                    ? '날씨 제공자 정보를 불러오지 못함'
                                    : '날씨 제공자 확인 중'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        const SizedBox(height: 6),
                        Text(
                          attribution?.notice ?? '지역 날씨 모델을 게임 재료로 사용합니다.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (legalUri != null) ...<Widget>[
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () => _openExternal(legalUri),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('날씨 출처 및 법적 고지'),
                          ),
                        ],
                      ],
                    ),
                  );
                },
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: PixelPalette.scene,
              borderRadius: BorderRadius.circular(PixelRadii.tile),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(
                    widget.demoMode
                        ? Icons.science_outlined
                        : Icons.verified_outlined,
                    color: widget.demoMode
                        ? PixelPalette.amber
                        : PixelPalette.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.demoMode ? '오프라인 데모' : '기기 센서 사용',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (kDebugMode) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              'Locus · Prototype 0.1.0',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _useRealSteps(AppController controller) async {
    if (_changingStepSource) {
      return;
    }
    setState(() => _changingStepSource = true);
    try {
      if (controller.demoMode) {
        await controller.configureStepTracking(useRealSteps: true);
        return;
      }
      var status = await Permission.activityRecognition.status;
      if (!status.isGranted) {
        status = await Permission.activityRecognition.request();
      }
      if (status.isGranted) {
        await controller.configureStepTracking(useRealSteps: true);
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('걸음 권한이 없어 설정을 유지합니다.')));
      }
    } finally {
      if (mounted) {
        setState(() => _changingStepSource = false);
      }
    }
  }

  Future<void> _useFallbackSteps(AppController controller) async {
    if (_changingStepSource) {
      return;
    }
    setState(() => _changingStepSource = true);
    try {
      await controller.configureStepTracking(useRealSteps: false);
    } finally {
      if (mounted) {
        setState(() => _changingStepSource = false);
      }
    }
  }

  Future<void> _openExternal(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
    }
  }
}

class _StepSourceCard extends StatelessWidget {
  const _StepSourceCard({
    required this.controller,
    required this.busy,
    required this.onUseRealSteps,
    required this.onUseFallback,
  });

  final AppController controller;
  final bool busy;
  final VoidCallback onUseRealSteps;
  final VoidCallback onUseFallback;

  @override
  Widget build(BuildContext context) {
    final mode = controller.stepTrackingMode;
    final (title, description, icon) = switch (mode) {
      StepTrackingMode.real => (
        '기기 걸음',
        '사용 가능 ${formatNumber(controller.availableSteps)}걸음',
        Icons.directions_walk,
      ),
      StepTrackingMode.fallback => (
        '기본 작업량',
        '하루 ${formatNumber(controller.fallbackDailySteps)}걸음',
        Icons.construction_outlined,
      ),
      StepTrackingMode.undecided => (
        '걸음 설정 필요',
        '실제 걸음 또는 기본 작업량을 선택하세요.',
        Icons.directions_walk_outlined,
      ),
    };

    return PixelCard(
      radius: PixelRadii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: PixelPalette.textBody),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (mode != StepTrackingMode.real)
            SizedBox(
              width: double.infinity,
              child: PixelButton(
                onPressed: busy ? null : onUseRealSteps,
                fallbackIcon: Icons.directions_walk,
                expand: true,
                label: '실제 걸음 사용',
              ),
            ),
          if (mode == StepTrackingMode.undecided) ...<Widget>[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: busy ? null : onUseFallback,
                child: const Text('권한 없이 기본 작업량 사용'),
              ),
            ),
          ],
          if (mode == StepTrackingMode.real) ...<Widget>[
            const SizedBox(height: 6),
            TextButton(
              onPressed: busy ? null : onUseFallback,
              child: const Text('기본 작업량으로 전환'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: PixelPalette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
