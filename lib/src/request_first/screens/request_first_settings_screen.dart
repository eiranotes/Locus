import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class RequestFirstSettingsScreen extends StatelessWidget {
  const RequestFirstSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Text('감각 수집', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const PixelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoLine(
                  icon: Icons.mic_none_outlined,
                  text: '수집 버튼을 누른 동안 4초간 소리를 읽습니다.',
                ),
                _InfoLine(
                  icon: Icons.delete_outline,
                  text: '원음과 녹음 파일은 저장하지 않습니다.',
                ),
                _InfoLine(
                  icon: Icons.analytics_outlined,
                  text: '소리 크기·끊김·반복 같은 특징값만 기기에 남습니다.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('열린 감각', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          PixelCard(
            color: PixelPalette.scene,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final axis in SenseAxis.values)
                  _AxisTag(
                    label: axis.labelKo,
                    unlocked: controller.unlockedAxes.contains(axis),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('데이터', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const PixelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _InfoLine(
                  icon: Icons.phone_iphone,
                  text: '요청·표본·관계·디오라마는 이 기기에 저장됩니다.',
                ),
                _InfoLine(
                  icon: Icons.cloud_off_outlined,
                  text: '계정과 개발자 운영 서버를 사용하지 않습니다.',
                ),
                _InfoLine(
                  icon: Icons.location_off_outlined,
                  text: '새 감각 표본에는 정확한 위치나 이동 경로를 저장하지 않습니다.',
                ),
              ],
            ),
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
                    controller.demoMode
                        ? Icons.science_outlined
                        : Icons.verified_outlined,
                    color: controller.demoMode
                        ? PixelPalette.amber
                        : PixelPalette.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.demoMode ? '결정론 감각 데모 사용 중' : '기기 감각 샘플러 사용',
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
              'Locus · Request-first v7 foundation',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: PixelPalette.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _AxisTag extends StatelessWidget {
  const _AxisTag({required this.label, required this.unlocked});

  final String label;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: unlocked ? PixelPalette.raised : PixelPalette.panel,
        border: Border.all(
          color: unlocked ? PixelPalette.mint : PixelPalette.divider,
        ),
        borderRadius: BorderRadius.circular(PixelRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            unlocked ? Icons.visibility_outlined : Icons.lock_outline,
            size: 15,
            color: unlocked ? PixelPalette.mint : PixelPalette.textMuted,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: unlocked
                  ? PixelPalette.textStrong
                  : PixelPalette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
