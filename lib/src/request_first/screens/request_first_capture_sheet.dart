import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/request_first/request_first_controller.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/request_first/widgets/specimen_mark.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/services/specimen_capture_coordinator.dart';

class RequestFirstCaptureSheet extends StatefulWidget {
  const RequestFirstCaptureSheet({super.key});

  @override
  State<RequestFirstCaptureSheet> createState() =>
      _RequestFirstCaptureSheetState();
}

class _RequestFirstCaptureSheetState extends State<RequestFirstCaptureSheet> {
  bool _capturing = false;
  bool _assigning = false;
  SpecimenCaptureBundle? _bundle;
  RequestFulfillmentOutcome? _outcome;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final focused = controller.focusedRequest;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Material(
      color: PixelPalette.panel,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(PixelRadii.tray),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: screenHeight * 0.92,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: PixelPalette.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _outcome != null
                          ? '마음을 전했습니다'
                          : _bundle == null
                          ? '표본 찾기'
                          : '표본을 건넬 손님',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _capturing || _assigning
                        ? null
                        : () => Navigator.of(context).pop(),
                    tooltip: '닫기',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _outcome != null
                    ? _FulfilledView(outcome: _outcome!)
                    : _capturing
                    ? const _SamplingView()
                    : _bundle == null
                    ? _ReadyView(request: focused)
                    : _ResultView(
                        bundle: _bundle!,
                        controller: controller,
                        assigning: _assigning,
                        onAssign: _assign,
                      ),
              ),
              const SizedBox(height: 14),
              if (_outcome != null)
                PixelButton(
                  label: '내 공간으로',
                  onPressed: () {
                    controller.clearLastFulfillment();
                    Navigator.of(context).pop();
                  },
                  fallbackIcon: Icons.home_outlined,
                  actionAsset: 'place',
                  expand: true,
                )
              else if (!_capturing && _bundle == null)
                PixelButton(
                  label: '4초 표본 수집',
                  onPressed: focused == null || controller.busy
                      ? null
                      : _capture,
                  fallbackIcon: Icons.graphic_eq,
                  actionAsset: 'capture',
                  expand: true,
                )
              else if (!_capturing && _bundle != null)
                PixelButton(
                  label: '기록만 남기기',
                  onPressed: _assigning
                      ? null
                      : () => Navigator.of(context).pop(),
                  fallbackIcon: Icons.bookmark_outline,
                  actionAsset: 'store',
                  tone: PixelButtonTone.quiet,
                  expand: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    final bundle = await RequestFirstScope.read(context).captureSpecimen();
    if (!mounted) return;
    setState(() {
      _capturing = false;
      _bundle = bundle;
    });
  }

  Future<void> _assign(SpecimenMatch match) async {
    if (_assigning) return;
    setState(() => _assigning = true);
    final outcome = await RequestFirstScope.read(context).assignSpecimen(
      specimenId: match.specimenId,
      requestId: match.requestId,
    );
    if (!mounted) return;
    setState(() {
      _assigning = false;
      _outcome = outcome;
    });
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.request});

  final VisitorRequest? request;

  @override
  Widget build(BuildContext context) {
    if (request == null) {
      return const Center(child: Text('현재 열려 있는 요청이 없습니다.'));
    }
    final controller = RequestFirstScope.of(context);
    final visitor = controller.legacyCatalog.visitorById(request!.visitorId);
    return ListView(
      children: <Widget>[
        PixelCard(
          color: PixelPalette.scene,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 64,
                height: 64,
                child: Image.asset(
                  GeneratedArtPaths.visitor(visitor.id),
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${visitor.nameKo}의 부탁',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      request!.promptKo,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const PixelCard(
          color: PixelPalette.raised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _GuideLine(
                icon: Icons.hearing_outlined,
                text: '주변의 소리를 4초간 읽습니다.',
              ),
              SizedBox(height: 10),
              _GuideLine(
                icon: Icons.delete_outline,
                text: '원음은 저장하지 않고 감각 특징만 남깁니다.',
              ),
              SizedBox(height: 10),
              _GuideLine(
                icon: Icons.compare_arrows,
                text: '여러 손님이 원하더라도 한 명에게만 줄 수 있습니다.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '조용히 멈춰 듣거나, 다른 시간과 장소를 찾아도 됩니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: PixelPalette.mint, size: 21),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _SamplingView extends StatelessWidget {
  const _SamplingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 148,
            height: 82,
            child: CustomPaint(painter: _SamplingPainter()),
          ),
          const SizedBox(height: 28),
          Text('소리를 읽는 중', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '4초 뒤 특징만 남고 원음은 사라집니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SamplingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PixelPalette.mint
      ..isAntiAlias = false;
    const heights = <double>[18, 38, 26, 58, 42, 68, 30, 52, 22, 44, 34, 62];
    final step = size.width / heights.length;
    for (var index = 0; index < heights.length; index += 1) {
      final height = heights[index];
      canvas.drawRect(
        Rect.fromLTWH(
          index * step + 2,
          (size.height - height) / 2,
          step * 0.52,
          height,
        ),
        paint..color = index.isEven ? PixelPalette.mint : PixelPalette.amber,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.bundle,
    required this.controller,
    required this.assigning,
    required this.onAssign,
  });

  final SpecimenCaptureBundle bundle;
  final RequestFirstController controller;
  final bool assigning;
  final ValueChanged<SpecimenMatch> onAssign;

  @override
  Widget build(BuildContext context) {
    final compatible = bundle.matches
        .where((SpecimenMatch value) => value.passed)
        .toList(growable: false);
    final sorted = bundle.matches.toList(growable: false)
      ..sort((SpecimenMatch a, SpecimenMatch b) => b.score.compareTo(a.score));
    return ListView(
      children: <Widget>[
        PixelCard(
          color: PixelPalette.scene,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SpecimenMark(specimen: bundle.specimen, height: 150),
              const SizedBox(height: 11),
              Text(
                specimenDescription(bundle.specimen),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '신뢰도 ${(bundle.specimen.confidence * 100).round()}% · 원음 미저장',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(
          compatible.length > 1
              ? '${compatible.length}명의 손님이 이 표본을 원합니다'
              : compatible.length == 1
              ? '한 손님의 부탁과 맞습니다'
              : '이번 요청과 정확히 맞는 표본이 없습니다',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 9),
        for (final match in sorted) ...<Widget>[
          _MatchCard(
            match: match,
            request: controller.requestById(match.requestId),
            controller: controller,
            assigning: assigning,
            onAssign: match.passed ? () => onAssign(match) : null,
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.request,
    required this.controller,
    required this.assigning,
    required this.onAssign,
  });

  final SpecimenMatch match;
  final VisitorRequest? request;
  final RequestFirstController controller;
  final bool assigning;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    if (request == null) return const SizedBox.shrink();
    final visitor = controller.legacyCatalog.visitorById(request!.visitorId);
    final failed = match.breakdown
        .where((ConstraintMatch value) => !value.satisfied)
        .firstOrNull;
    return PixelCard(
      highlighted: match.passed,
      color: match.passed ? PixelPalette.raised : PixelPalette.scene,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(
                  GeneratedArtPaths.visitor(visitor.id),
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(visitor.nameKo, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      _verdictLabel(match),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: match.passed
                            ? PixelPalette.success
                            : PixelPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(match.score * 100).round()}%',
                style: TextStyle(
                  color: match.passed ? PixelPalette.mint : PixelPalette.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (failed != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '${failed.axis?.labelKo ?? '기준'}은 ${failed.target}이 필요합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (onAssign != null) ...<Widget>[
            const SizedBox(height: 11),
            PixelButton(
              label: '${visitor.nameKo}에게 건네기',
              onPressed: assigning ? null : onAssign,
              fallbackIcon: Icons.arrow_forward,
              actionAsset: 'visitor',
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

String _verdictLabel(SpecimenMatch match) => switch (match.verdict) {
  MatchVerdict.match => '부탁과 맞는 표본',
  MatchVerdict.partial => '거의 맞지만 한 감각이 다름',
  MatchVerdict.mismatch => '부탁과 다른 표본',
  MatchVerdict.lowConfidence => '판정 신뢰도가 부족함',
};

class _FulfilledView extends StatelessWidget {
  const _FulfilledView({required this.outcome});

  final RequestFulfillmentOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final controller = RequestFirstScope.of(context);
    final visitor = controller.legacyCatalog.visitorById(
      outcome.request.visitorId,
    );
    return ListView(
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 126,
            height: 126,
            child: Image.asset(
              GeneratedArtPaths.visitor(visitor.id),
              filterQuality: FilterQuality.none,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${visitor.nameKo}이 표본을 받았습니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          '관계 ${outcome.relationship.stage}단계 · 부탁 ${outcome.relationship.fulfilledCount}회 완료',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        if (outcome.unlockedAxes.isNotEmpty)
          PixelCard(
            color: PixelPalette.raised,
            child: Text(
              '새 감각 · ${outcome.unlockedAxes.map((SenseAxis value) => value.labelKo).join(', ')}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (outcome.unlockedAxes.isNotEmpty &&
            outcome.grantedSceneObjects.isNotEmpty)
          const SizedBox(height: 10),
        if (outcome.grantedSceneObjects.isNotEmpty)
          PixelCard(
            color: PixelPalette.raised,
            child: Text(
              '관계 기념물 ${outcome.grantedSceneObjects.length}개가 보관되었습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        if (outcome.unlockedAxes.isEmpty &&
            outcome.grantedSceneObjects.isEmpty)
          const PixelCard(
            color: PixelPalette.scene,
            child: Text('손님이 내 공간에 머물며 다음 부탁을 준비합니다.'),
          ),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
