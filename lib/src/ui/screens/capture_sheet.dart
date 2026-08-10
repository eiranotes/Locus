import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/services/capture_coordinator.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/pattern_presentation.dart';
import 'package:reality_diorama/src/ui/screens/crafting_screen.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/atmospheric_trait_chips.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_pattern_mark.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_surface.dart';

class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key});

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  bool _loadingPreparation = true;
  bool _includeSurroundings = true;
  bool _capturing = false;
  CaptureBundle? _result;
  VisitorDefinition? _targetAtCapture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final controller = AppScope.read(context);
    await controller.refreshCapturePreparation();
    if (mounted) {
      setState(() => _loadingPreparation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final preparation = controller.capturePreparation;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Material(
      color: PixelPalette.panel,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(PixelRadii.tray),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: screenHeight * 0.90,
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
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _result == null ? '지금 수집' : '수집 완료',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _capturing
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: '닫기',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loadingPreparation
                    ? const Center(child: CircularProgressIndicator())
                    : _capturing
                    ? _CaptureProgress(
                        scansSurroundings:
                            _includeSurroundings &&
                            preparation?.surroundingReadiness.isReady == true,
                      )
                    : _result == null
                    ? _PreparationView(
                        preparation: preparation,
                        availableSteps: controller.availableSteps,
                        includeSurroundings: _includeSurroundings,
                        onSurroundingsChanged: (bool value) {
                          setState(() => _includeSurroundings = value);
                        },
                      )
                    : _ResultView(
                        bundle: _result!,
                        targetVisitor: _targetAtCapture,
                        allCollectedPatterns: controller.collectedPatterns,
                      ),
              ),
              const SizedBox(height: 14),
              if (!_capturing && _result == null)
                PixelButton(
                  onPressed:
                      preparation == null ||
                          (!preparation.weatherReadiness.isReady &&
                              !preparation.surroundingReadiness.isReady)
                      ? null
                      : () => _capture(preparation),
                  actionAsset: 'capture',
                  fallbackIcon: Icons.sensors_outlined,
                  expand: true,
                  label: '수집 시작',
                ),
              if (!_capturing && _result != null) ...<Widget>[
                PixelButton(
                  onPressed: _result!.weatherMaterial == null
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => RecipeListScreen(
                              preselectedWeatherId:
                                  _result!.weatherMaterial?.id,
                              preselectedSurroundingId:
                                  _result!.surroundingMaterial?.id,
                            ),
                          ),
                        ),
                  actionAsset: 'craft',
                  fallbackIcon: Icons.handyman_outlined,
                  expand: true,
                  label: '이 재료로 만들기',
                ),
                const SizedBox(height: 8),
                PixelButton(
                  onPressed: () => Navigator.of(context).pop(),
                  actionAsset: 'store',
                  fallbackIcon: Icons.inventory_2_outlined,
                  tone: PixelButtonTone.quiet,
                  expand: true,
                  label: '나중에 만들기',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capture(CapturePreparation preparation) async {
    final controller = AppScope.read(context);
    var include =
        _includeSurroundings && preparation.surroundingReadiness.isReady;
    if (include && !controller.demoMode) {
      include = await _requestBluetoothPermission();
    }
    if (!mounted) {
      return;
    }
    setState(() => _capturing = true);
    _targetAtCapture = controller.targetVisitor?.visitor;
    final bundle = await controller.performCapture(
      includeSurroundings: include,
    );
    if (!mounted) {
      return;
    }
    if (bundle != null) {
      final assets = <String>[
        if (bundle.weatherMaterial != null)
          GeneratedArtPaths.weatherMaterial(bundle.weatherMaterial!.kind),
        if (bundle.surroundingMaterial != null)
          GeneratedArtPaths.surroundingMaterial(
            bundle.surroundingMaterial!.kind,
          ),
      ];
      await Future.wait(
        assets.map((String path) => precacheImage(AssetImage(path), context)),
      );
      if (!mounted) return;
    }
    setState(() {
      _capturing = false;
      _result = bundle;
    });
  }

  Future<bool> _requestBluetoothPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      return scan.isGranted && connect.isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return false;
  }
}

class _PreparationView extends StatelessWidget {
  const _PreparationView({
    required this.preparation,
    required this.availableSteps,
    required this.includeSurroundings,
    required this.onSurroundingsChanged,
  });

  final CapturePreparation? preparation;
  final int availableSteps;
  final bool includeSurroundings;
  final ValueChanged<bool> onSurroundingsChanged;

  @override
  Widget build(BuildContext context) {
    final value = preparation;
    if (value == null) {
      return const Center(child: Text('수집 준비 상태를 확인하지 못했습니다.'));
    }
    final traitCatalog = AppScope.of(context).catalog.atmosphericTraits;
    return ListView(
      children: <Widget>[
        _CaptureSection(
          tone: PixelPalette.scene,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ReadinessRow(
                actionAsset: 'weather',
                icon: value.weatherKind == null
                    ? Icons.cloud_off_outlined
                    : weatherIcon(value.weatherKind!),
                iconColor: value.weatherKind == null
                    ? PixelPalette.muted
                    : weatherColor(value.weatherKind!),
                title: '날씨',
                value: value.weatherKind == null
                    ? '현재 날씨를 사용할 수 없음'
                    : '${value.weatherKind!.labelKo} · ${value.timeBand.labelKo}',
                readiness: value.weatherReadiness,
              ),
              if (value.atmosphericTraits.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                AtmosphericTraitChips(
                  traits: value.atmosphericTraits,
                  catalog: traitCatalog,
                  showEffects: true,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '지역 날씨 모델 · 현장 측정 아님',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CaptureSection(
          tone: PixelPalette.raised,
          child: Column(
            children: <Widget>[
              _ReadinessRow(
                actionAsset: 'surroundings',
                icon: Icons.radar,
                iconColor: PixelPalette.violet,
                title: '주변',
                value: '8초 읽기',
                readiness: value.surroundingReadiness,
              ),
              if (value.surroundingReadiness.isReady) ...<Widget>[
                const Divider(height: 20, color: PixelPalette.line),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: includeSurroundings,
                  onChanged: onSurroundingsChanged,
                  title: const Text('주변까지 함께 수집'),
                  subtitle: const Text('기기 식별 정보는 저장하지 않음'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: <Widget>[
              const Icon(Icons.directions_walk, color: PixelPalette.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '사용 가능한 걸음',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatNumber(availableSteps)}걸음',
                      style: const TextStyle(
                        color: PixelPalette.textStrong,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '준비된 재료는 자동 보관됩니다.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CaptureSection extends StatelessWidget {
  const _CaptureSection({required this.child, required this.tone});

  final Widget child;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tone,
      shape: const PixelCutBorder(color: PixelPalette.divider, cut: 6),
      clipBehavior: Clip.hardEdge,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    this.actionAsset,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.readiness,
  });

  final IconData icon;
  final String? actionAsset;
  final Color iconColor;
  final String title;
  final String value;
  final ResourceReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (actionAsset == null)
          Icon(icon, color: iconColor, size: 28)
        else
          Image.asset(
            GeneratedArtPaths.action(actionAsset!),
            width: 30,
            height: 30,
            filterQuality: FilterQuality.none,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(value),
              const SizedBox(height: 5),
              Text(
                readiness.isReady ? '준비됨' : readiness.message ?? '아직 준비 중',
                style: TextStyle(
                  color: readiness.isReady
                      ? PixelPalette.success
                      : PixelPalette.muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CaptureProgress extends StatelessWidget {
  const _CaptureProgress({required this.scansSurroundings});

  final bool scansSurroundings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 112,
            height: 112,
            child: CircularProgressIndicator(
              strokeWidth: 7,
              color: scansSurroundings
                  ? PixelPalette.violet
                  : PixelPalette.mint,
              backgroundColor: PixelPalette.line,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            scansSurroundings ? '주변 읽는 중' : '날씨 저장 중',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            scansSurroundings ? '화면을 켠 채 기다려 주세요.' : '잠시만 기다려 주세요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.bundle,
    required this.targetVisitor,
    required this.allCollectedPatterns,
  });

  final CaptureBundle bundle;
  final VisitorDefinition? targetVisitor;
  final List<CollectedPattern> allCollectedPatterns;

  @override
  Widget build(BuildContext context) {
    final traitCatalog = AppScope.of(context).catalog.atmosphericTraits;
    return ListView(
      children: <Widget>[
        if (bundle.weatherMaterial != null)
          _CaptureSection(
            tone: PixelPalette.scene,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    MaterialOrb.weather(bundle.weatherMaterial!.kind),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '날씨 재료',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${bundle.weatherMaterial!.kind.labelKo} · '
                            '${bundle.weatherMaterial!.timeBand.labelKo}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${bundle.weatherMaterial!.providerName} 지역 모델',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (bundle
                    .weatherMaterial!
                    .atmosphericTraits
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  AtmosphericTraitChips(
                    traits: bundle.weatherMaterial!.atmosphericTraits,
                    catalog: traitCatalog,
                    showEffects: true,
                  ),
                ],
              ],
            ),
          ),
        if (bundle.weatherMaterial != null &&
            bundle.surroundingMaterial != null)
          const SizedBox(height: 10),
        if (bundle.surroundingMaterial != null)
          _CaptureSection(
            tone: PixelPalette.raised,
            child: Row(
              children: <Widget>[
                MaterialOrb.surroundings(bundle.surroundingMaterial!.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '주변 재료',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bundle.surroundingMaterial!.kind.labelKo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '신뢰도 ${(bundle.surroundingMaterial!.confidence * 100).round()}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (bundle.weatherMaterial == null &&
            bundle.surroundingMaterial == null)
          const PixelCard(child: Text('새 재료 없음 · 기록만 저장')),
        if (bundle.patterns.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _CollectedPatternsSection(
            patterns: bundle.patterns,
            allCollectedPatterns: allCollectedPatterns,
            targetVisitor: targetVisitor,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          '${bundle.record.userPlaceLabel ?? '현재 지역'} · '
          '${bundle.record.timeBand.labelKo}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CollectedPatternsSection extends StatelessWidget {
  const _CollectedPatternsSection({
    required this.patterns,
    required this.allCollectedPatterns,
    required this.targetVisitor,
  });

  final List<CollectedPattern> patterns;
  final List<CollectedPattern> allCollectedPatterns;
  final VisitorDefinition? targetVisitor;

  @override
  Widget build(BuildContext context) {
    final individual = patterns
        .where((CollectedPattern value) => !value.isCombination)
        .toList(growable: false);
    final combinations = patterns
        .where((CollectedPattern value) => value.isCombination)
        .toList(growable: false);
    final patternsByKey = <String, CollectedPattern>{
      for (final pattern in patterns) pattern.patternKey: pattern,
    };
    final representatives = representativeCombinationPatterns(patterns);
    final countsByKey = <String, int>{};
    for (final pattern in allCollectedPatterns) {
      countsByKey.update(
        pattern.patternKey,
        (int value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final newCount = patterns.where((CollectedPattern pattern) {
      return countsByKey[pattern.patternKey] == 1;
    }).length;
    final repeatedCount = patterns.length - newCount;
    final targetEvidence = targetVisitor == null
        ? const <VisitorPatternEvidence>[]
        : visitorPatternEvidence(targetVisitor!, patterns);
    final timeAndSeasonCount = individual
        .where(
          (CollectedPattern value) =>
              value.family == CapturePatternFamily.time ||
              value.family == CapturePatternFamily.season,
        )
        .length;
    final weatherCount = individual
        .where(
          (CollectedPattern value) =>
              value.family == CapturePatternFamily.weather,
        )
        .length;
    final surroundingsCount = individual
        .where(
          (CollectedPattern value) =>
              value.family == CapturePatternFamily.surroundings,
        )
        .length;
    return _CaptureSection(
      tone: PixelPalette.scene,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const PixelPatternStamp(size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '수집 패턴',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '신규 $newCount · 반복 $repeatedCount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PatternResultSummary(
            title: '개별 패턴',
            count: individual.length,
            summary:
                '시간·계절 $timeAndSeasonCount · 날씨 $weatherCount · 주변 $surroundingsCount',
          ),
          if (combinations.isNotEmpty) ...<Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: PixelRule(),
            ),
            _PatternResultSummary(
              title: '동시 조합',
              count: combinations.length,
              summary: '같은 순간에 모인 정보',
            ),
            const SizedBox(height: 11),
            for (
              var index = 0;
              index < representatives.length;
              index += 1
            ) ...<Widget>[
              _CombinationPatternRow(
                pattern: representatives[index],
                patternsByKey: patternsByKey,
              ),
              if (index != representatives.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: PixelRule(),
                ),
            ],
            if (combinations.length > representatives.length) ...<Widget>[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '나머지 ${combinations.length - representatives.length}개 · 보관함에서 확인',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
          if (targetEvidence.isNotEmpty) ...<Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: PixelRule(),
            ),
            _PatternResultSummary(
              title: '${targetVisitor!.nameKo} 단서',
              count: targetEvidence.length,
              summary:
                  '${targetEvidence.map((VisitorPatternEvidence item) => compactPatternLabel(item.pattern)).join(' · ')} · 비소모 단서',
            ),
          ],
        ],
      ),
    );
  }
}

class _PatternResultSummary extends StatelessWidget {
  const _PatternResultSummary({
    required this.title,
    required this.count,
    required this.summary,
  });

  final String title;
  final int count;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 3),
              Text(summary, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: PixelPalette.textBody,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CombinationPatternRow extends StatelessWidget {
  const _CombinationPatternRow({
    required this.pattern,
    required this.patternsByKey,
  });

  final CollectedPattern pattern;
  final Map<String, CollectedPattern> patternsByKey;

  @override
  Widget build(BuildContext context) {
    final visual = combinationPatternVisualDescriptor(pattern, patternsByKey);
    return Semantics(
      container: true,
      label: '${visual.title}, ${visual.summary}, ${visual.componentCount}개 정보',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: PixelWeaveMark(
                families: visual.componentFamilies,
                size: 20,
                animate: true,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    visual.title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    visual.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${visual.componentCount}개',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: PixelPalette.amber),
            ),
          ],
        ),
      ),
    );
  }
}
