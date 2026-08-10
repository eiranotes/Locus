import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/pattern_presentation.dart';
import 'package:reality_diorama/src/ui/screens/crafting_screen.dart';
import 'package:reality_diorama/src/ui/screens/placement_editor_screen.dart';
import 'package:reality_diorama/src/ui/screens/settings_screen.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_surface.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.demoMode,
    required this.onCapture,
    super.key,
  });
  final bool demoMode;
  final VoidCallback onCapture;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _presentedVisitor;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    _scheduleVisitorDialog(controller);
    final target = controller.targetVisitor;
    final construction = controller.construction;

    return RefreshIndicator(
      onRefresh: controller.refreshWorld,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            sliver: SliverList.list(
              children: <Widget>[
                _Header(
                  availableSteps: controller.availableSteps,
                  readyCount: controller.captureReadyCount,
                  onSettings: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          SettingsScreen(demoMode: widget.demoMode),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 0.88,
                  child: Material(
                    color: PixelPalette.scene,
                    shape: const PixelCutBorder(
                      color: PixelPalette.divider,
                      width: 2,
                      cut: 8,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: DioramaView(
                            snapshot: controller.dioramaSnapshot,
                            borderRadius: BorderRadius.zero,
                            semanticLabel: _sceneSemanticLabel(controller),
                          ),
                        ),
                        if (target != null)
                          Positioned(
                            left: 10,
                            right: 10,
                            top: 10,
                            child: _VisitorGoal(
                              evaluation: target,
                              collectedPatterns: controller.collectedPatterns,
                              discovered: controller.visitorSightings.any(
                                (VisitorSighting sighting) =>
                                    sighting.visitorId == target.visitor.id,
                              ),
                              repeatWait: controller.visitorRepeatWait(
                                target.visitor.id,
                              ),
                              rewardRecipeName:
                                  target.visitor.reward.kind ==
                                      VisitorRewardKind.recipe
                                  ? controller.catalog
                                        .recipeById(target.visitor.reward.value)
                                        .nameKo
                                  : null,
                            ),
                          ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Badge(
                            isLabelVisible: controller.captureReadyCount > 0,
                            label: Text('${controller.captureReadyCount}'),
                            backgroundColor: PixelPalette.reward,
                            textColor: PixelPalette.actionInk,
                            child: PixelButton(
                              onPressed: widget.onCapture,
                              actionAsset: 'capture',
                              fallbackIcon: Icons.sensors_outlined,
                              label: '수집',
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: PixelButton(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    const PlacementEditorScreen(),
                              ),
                            ),
                            actionAsset: 'place',
                            fallbackIcon: Icons.grid_view_outlined,
                            tone: PixelButtonTone.secondary,
                            label: '배치 편집',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (construction != null)
                  _ConstructionCard(object: construction)
                else
                  _CraftPrompt(
                    canCraft: controller.availableWeatherMaterials.isNotEmpty,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const RecipeListScreen(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleVisitorDialog(AppController controller) {
    final visitorId = controller.newVisitorId;
    if (visitorId == null || visitorId == _presentedVisitor) {
      return;
    }
    _presentedVisitor = visitorId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final visitor = controller.catalog.visitorById(visitorId);
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) =>
            _VisitorArrivalDialog(visitor: visitor, controller: controller),
      );
      controller.clearNewVisitor();
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.availableSteps,
    required this.readyCount,
    required this.onSettings,
  });

  final int availableSteps;
  final int readyCount;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text('내 공간', style: Theme.of(context).textTheme.headlineLarge),
        ),
        _ResourceStrip(availableSteps: availableSteps, readyCount: readyCount),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onSettings,
          tooltip: '설정',
          icon: Image.asset(
            GeneratedArtPaths.action('settings'),
            width: 24,
            height: 24,
            filterQuality: FilterQuality.none,
          ),
        ),
      ],
    );
  }
}

class _ResourceStrip extends StatelessWidget {
  const _ResourceStrip({
    required this.availableSteps,
    required this.readyCount,
  });

  final int availableSteps;
  final int readyCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${formatNumber(availableSteps)}걸음, 수집 준비 $readyCount개',
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.directions_walk,
              color: PixelPalette.mint,
              size: 18,
            ),
            const SizedBox(width: 5),
            Text(
              formatNumber(availableSteps),
              style: const TextStyle(
                color: PixelPalette.cream,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 9),
              color: PixelPalette.line,
            ),
            Icon(
              Icons.inventory_outlined,
              color: readyCount > 0 ? PixelPalette.amber : PixelPalette.muted,
              size: 18,
            ),
            const SizedBox(width: 5),
            Text(
              '$readyCount',
              style: const TextStyle(
                color: PixelPalette.cream,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitorGoal extends StatelessWidget {
  const _VisitorGoal({
    required this.evaluation,
    required this.collectedPatterns,
    required this.discovered,
    required this.repeatWait,
    this.rewardRecipeName,
  });

  final VisitorEvaluation evaluation;
  final List<CollectedPattern> collectedPatterns;
  final bool discovered;
  final Duration? repeatWait;
  final String? rewardRecipeName;

  @override
  Widget build(BuildContext context) {
    final missing = evaluation.progress
        .where((RequirementProgress item) => !item.satisfied)
        .firstOrNull;
    final missingIndex = missing == null
        ? -1
        : evaluation.progress.indexOf(missing);
    final clue = visitorPatternEvidence(evaluation.visitor, collectedPatterns)
        .where((VisitorPatternEvidence item) {
          return item.requirementIndex == missingIndex;
        })
        .firstOrNull;
    return Material(
      color: PixelPalette.surface.withValues(alpha: 0.94),
      shape: const PixelCutBorder(color: PixelPalette.divider, cut: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PixelPalette.blue.withValues(alpha: 0.12),
                border: Border.all(color: PixelPalette.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  GeneratedArtPaths.visitor(evaluation.visitor.id),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${discovered ? '다시 올 방문자' : '다음 방문자'} · ${evaluation.visitor.nameKo}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '${evaluation.satisfiedCount}/${evaluation.progress.length}',
                        style: const TextStyle(
                          color: PixelPalette.mint,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    missing == null
                        ? '조건 완성'
                        : _visitorRequirementSummary(missing),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    repeatWait != null && repeatWait! > Duration.zero
                        ? _repeatWaitLabel(repeatWait!)
                        : clue != null
                        ? '패턴 단서 · ${compactPatternLabel(clue.pattern)}'
                        : discovered
                        ? '조건을 유지하면 다시 옵니다.'
                        : rewardRecipeName == null
                        ? '조건을 맞추면 찾아옵니다.'
                        : '첫 만남 보상 · $rewardRecipeName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: clue != null
                          ? PixelPalette.weather
                          : PixelPalette.reward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _repeatWaitLabel(Duration duration) {
  final minutes = duration.inMinutes.clamp(1, 24 * 60);
  if (minutes < 60) return '$minutes분 뒤 장면 기록 가능';
  return '${(minutes + 59) ~/ 60}시간 뒤 장면 기록 가능';
}

String _visitorRequirementSummary(RequirementProgress progress) {
  if (progress.current == '있음' || progress.current == '없음') {
    return '${progress.target} · ${progress.current}';
  }
  return '${progress.label} ${progress.current}/${progress.target}';
}

class _ConstructionCard extends StatelessWidget {
  const _ConstructionCard({required this.object});

  final CraftedObject object;

  @override
  Widget build(BuildContext context) {
    final progress = object.requiredSteps == 0
        ? 0.0
        : object.appliedSteps / object.requiredSteps;
    return PixelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.construction, color: PixelPalette.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${object.kind.labelKo} 만드는 중',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${formatNumber(object.remainingSteps)}걸음 남음',
                style: const TextStyle(color: PixelPalette.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0).toDouble(),
            minHeight: 7,
            borderRadius: BorderRadius.circular(9),
            backgroundColor: PixelPalette.line,
            color: PixelPalette.mint,
          ),
        ],
      ),
    );
  }
}

class _CraftPrompt extends StatelessWidget {
  const _CraftPrompt({required this.canCraft, required this.onTap});

  final bool canCraft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      onTap: onTap,
      highlighted: canCraft,
      child: Row(
        children: <Widget>[
          Image.asset(
            GeneratedArtPaths.action(canCraft ? 'craft' : 'weather'),
            width: 30,
            height: 30,
            filterQuality: FilterQuality.none,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  canCraft ? '물건 만들기' : '날씨 수집 필요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  canCraft ? '재료와 걸음 준비됨' : '주변 수집은 선택',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: PixelPalette.muted),
        ],
      ),
    );
  }
}

class _VisitorArrivalDialog extends StatelessWidget {
  const _VisitorArrivalDialog({
    required this.visitor,
    required this.controller,
  });

  final VisitorDefinition visitor;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final rewardRecipe = visitor.reward.kind == VisitorRewardKind.recipe
        ? controller.catalog.recipeById(visitor.reward.value)
        : null;
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: PixelPalette.background,
      shape: const PixelCutBorder(
        color: PixelPalette.divider,
        width: 2,
        cut: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Image.asset(
                  GeneratedArtPaths.action('visitor'),
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 8),
                Text('새 방문자', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              visitor.nameKo,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.4,
              child: DioramaView(snapshot: controller.dioramaSnapshot),
            ),
            const SizedBox(height: 14),
            Text(visitor.descriptionKo),
            if (rewardRecipe != null) ...<Widget>[
              const SizedBox(height: 10),
              PixelCard(
                color: PixelPalette.scene,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      GeneratedArtPaths.action('codex'),
                      width: 30,
                      height: 30,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '새 만드는 법 · ${rewardRecipe.nameKo}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PixelButton(
              onPressed: () => Navigator.of(context).pop(),
              actionAsset: 'place',
              expand: true,
              label: '계속 꾸미기',
            ),
          ],
        ),
      ),
    );
  }
}

String _sceneSemanticLabel(AppController controller) {
  final snapshot = controller.dioramaSnapshot;
  final placedNames = snapshot.placements
      .map((Placement placement) {
        final object = snapshot.objects
            .where(
              (CraftedObject candidate) =>
                  candidate.id == placement.craftedObjectId,
            )
            .firstOrNull;
        return object?.kind.labelKo;
      })
      .whereType<String>()
      .toList(growable: false);
  final visitorName = snapshot.activeVisitorId == null
      ? null
      : controller.catalog.visitorById(snapshot.activeVisitorId!).nameKo;
  final objectSummary = placedNames.isEmpty
      ? '놓인 물건 없음'
      : '놓인 물건 ${placedNames.length}개, ${placedNames.join(', ')}';
  final visitorSummary = visitorName == null
      ? '머무는 방문자 없음'
      : '머무는 방문자 $visitorName';
  return '5 곱하기 5 동네 디오라마, ${snapshot.timeBand.labelKo}, '
      '${snapshot.weatherKind.labelKo}, $objectSummary, $visitorSummary';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
