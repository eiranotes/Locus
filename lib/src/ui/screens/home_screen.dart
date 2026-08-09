import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/ui/screens/crafting_screen.dart';
import 'package:reality_diorama/src/ui/screens/placement_editor_screen.dart';
import 'package:reality_diorama/src/ui/screens/settings_screen.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.demoMode, super.key});
  final bool demoMode;

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
      onRefresh: () async {
        if (controller.stepTrackingConfigured) {
          await controller.refreshSteps();
        }
        await controller.refreshCapturePreparation();
      },
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: PixelPalette.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: PixelPalette.line),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: DioramaView(
                            snapshot: controller.dioramaSnapshot,
                            semanticLabel: _sceneSemanticLabel(controller),
                          ),
                        ),
                        if (target != null)
                          Positioned(
                            left: 10,
                            right: 10,
                            top: 10,
                            child: _VisitorGoal(evaluation: target),
                          ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: FilledButton.tonalIcon(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) =>
                                    const PlacementEditorScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.grid_view_outlined,
                              size: 18,
                            ),
                            label: const Text('배치 편집'),
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
          icon: const Icon(Icons.more_horiz),
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
      label: '${_formatNumber(availableSteps)}걸음, 수집 준비 $readyCount개',
      container: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: PixelPalette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PixelPalette.line),
        ),
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
              _formatNumber(availableSteps),
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
  const _VisitorGoal({required this.evaluation});

  final VisitorEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final missing = evaluation.progress
        .where((RequirementProgress item) => !item.satisfied)
        .firstOrNull;
    return Material(
      color: PixelPalette.surface.withValues(alpha: 0.94),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: evaluation.satisfiedCount > 0
              ? PixelPalette.mint
              : PixelPalette.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PixelPalette.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
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
                          '다음 방문자 · ${evaluation.visitor.nameKo}',
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
                        ? '조건을 모두 완성했습니다.'
                        : '${missing.label} ${missing.current}/${missing.target}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: PixelPalette.muted),
          ],
        ),
      ),
    );
  }
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
                '${object.remainingSteps}걸음 남음',
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
          Icon(
            canCraft ? Icons.handyman_outlined : Icons.cloud_download_outlined,
            color: canCraft ? PixelPalette.mint : PixelPalette.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  canCraft ? '지금 만들 수 있는 물건 보기' : '먼저 날씨를 수집해 주세요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  canCraft
                      ? '보관한 재료와 걸음으로 동네 물건을 만듭니다.'
                      : '준비된 날씨는 수집할 때까지 사라지지 않습니다.',
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
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      backgroundColor: PixelPalette.background,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('새 방문자', style: Theme.of(context).textTheme.bodyMedium),
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('계속 꾸미기'),
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

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index += 1) {
    final remaining = text.length - index;
    buffer.write(text[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
