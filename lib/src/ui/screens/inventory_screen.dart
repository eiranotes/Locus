import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/pattern_presentation.dart';
import 'package:reality_diorama/src/ui/screens/crafting_screen.dart';
import 'package:reality_diorama/src/ui/screens/placement_editor_screen.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';
import 'package:reality_diorama/src/ui/widgets/atmospheric_trait_chips.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_pattern_mark.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          Builder(
            builder: (BuildContext context) {
              final tabController = DefaultTabController.of(context);
              return AnimatedBuilder(
                animation: tabController,
                builder: (BuildContext context, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '보관함',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      Text(
                        _countLabel(controller, tabController.index),
                        key: const ValueKey<String>('inventory-tab-count'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const TabBar(
            tabs: <Widget>[
              Tab(text: '기록'),
              Tab(text: '재료'),
              Tab(text: '패턴'),
              Tab(text: '만든 것'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _RecordsTab(controller: controller),
                _MaterialsTab(controller: controller),
                _PatternsTab(controller: controller),
                _ObjectsTab(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.captures.isEmpty) {
      return const _EmptyState(
        icon: Icons.photo_library_outlined,
        title: '아직 수집 기록이 없습니다',
        body: '준비된 날씨를 수집하면 이곳에 출처가 남습니다.',
      );
    }
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    final surroundingById = <String, SurroundingMaterial>{
      for (final material in controller.surroundingMaterials)
        material.id: material,
    };
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
        final singleColumn = constraints.maxWidth < 360 || largeText;
        return CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: singleColumn ? 1 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: singleColumn ? 1.10 : 0.83,
                ),
                itemCount: controller.captures.length,
                itemBuilder: (BuildContext context, int index) {
                  final record = controller.captures[index];
                  return _RecordCard(
                    record: record,
                    weather: record.weatherMaterialId == null
                        ? null
                        : weatherById[record.weatherMaterialId],
                    surroundings: record.surroundingMaterialId == null
                        ? null
                        : surroundingById[record.surroundingMaterialId],
                  );
                },
              ),
            ),
            if (controller.hasMoreCaptures)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${formatNumber(controller.captures.length)} / '
                        '${formatNumber(controller.captureRecordTotal)}개 불러옴',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      PixelButton(
                        key: const ValueKey<String>('load-more-captures'),
                        label: controller.loadingMoreCaptures
                            ? '기록 불러오는 중'
                            : '이전 기록 더 보기',
                        onPressed:
                            controller.loadingMoreCaptures || controller.busy
                            ? null
                            : controller.loadMoreCaptures,
                        tone: PixelButtonTone.quiet,
                        fallbackIcon: Icons.expand_more,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 94)),
          ],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.weather,
    required this.surroundings,
  });

  final CaptureRecord record;
  final WeatherMaterial? weather;
  final SurroundingMaterial? surroundings;

  @override
  Widget build(BuildContext context) {
    final kind = weather?.kind ?? WeatherMaterialKind.cloudy;
    final accent = weatherColor(kind);
    return PixelCard(
      radius: PixelRadii.tile,
      color: PixelPalette.scene,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(PixelRadii.tile),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RecordStampPainter(
                        accent: accent,
                        seed: record.capturedAt.millisecondsSinceEpoch,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(weatherIcon(kind), color: accent, size: 42),
                  ),
                  if (surroundings != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Icon(
                        surroundingIcon(surroundings!.kind),
                        color: PixelPalette.violet,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            record.userPlaceLabel ?? '현재 지역',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            '${_time(record.capturedAt)} · ${record.timeBand.labelKo}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 5),
          Text(
            weather == null ? '기록만 저장됨' : weather!.kind.labelKo,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final weather = controller.weatherMaterials;
    final surroundings = controller.surroundingMaterials;
    if (weather.isEmpty && surroundings.isEmpty) {
      return const _EmptyState(
        icon: Icons.blur_circular,
        title: '보관된 재료가 없습니다',
        body: '수집한 재료는 사용하기 전까지 이곳에 남습니다.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: <Widget>[
        Text('날씨', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final material in weather) ...<Widget>[
          _WeatherMaterialRow(material: material),
          const Divider(),
        ],
        const SizedBox(height: 14),
        Text('주변', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (surroundings.isEmpty)
          const PixelCard(child: Text('주변 재료는 선택 수집입니다.'))
        else
          for (final material in surroundings) ...<Widget>[
            _SurroundingMaterialRow(material: material),
            const Divider(),
          ],
      ],
    );
  }
}

class _WeatherMaterialRow extends StatelessWidget {
  const _WeatherMaterialRow({required this.material});

  final WeatherMaterial material;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      color: Colors.transparent,
      radius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: <Widget>[
          MaterialOrb.weather(material.kind),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${material.kind.labelKo} · ${material.timeBand.labelKo}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  material.isAvailable ? '사용 가능' : '제작에 사용됨',
                  style: TextStyle(
                    color: material.isAvailable
                        ? PixelPalette.success
                        : PixelPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          if (material.isAvailable)
            IconButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      RecipeListScreen(preselectedWeatherId: material.id),
                ),
              ),
              tooltip: '이 재료로 만들기',
              icon: const Icon(Icons.handyman_outlined),
            ),
        ],
      ),
    );
  }
}

class _SurroundingMaterialRow extends StatelessWidget {
  const _SurroundingMaterialRow({required this.material});

  final SurroundingMaterial material;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      color: Colors.transparent,
      radius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: <Widget>[
          MaterialOrb.surroundings(material.kind),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  material.kind.labelKo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  material.isAvailable
                      ? '사용 가능 · 신뢰도 ${(material.confidence * 100).round()}%'
                      : '제작에 사용됨',
                  style: TextStyle(
                    color: material.isAvailable
                        ? PixelPalette.success
                        : PixelPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternsTab extends StatelessWidget {
  const _PatternsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.collectedPatterns.isEmpty) {
      return const _EmptyState(
        visual: PixelPatternStamp(size: 52, color: PixelPalette.muted),
        title: '아직 수집한 패턴이 없습니다',
        body: '날씨와 주변 정보를 수집하면 각 정보와 동시 조합이 여기에 남습니다.',
      );
    }
    final grouped = <String, List<CollectedPattern>>{};
    for (final pattern in controller.collectedPatterns) {
      grouped
          .putIfAbsent(pattern.patternKey, () => <CollectedPattern>[])
          .add(pattern);
    }
    final summaries = grouped.values.map((List<CollectedPattern> values) {
      final latest = values.reduce(
        (CollectedPattern left, CollectedPattern right) =>
            left.capturedAt.isAfter(right.capturedAt) ? left : right,
      );
      return _PatternSummary(latest: latest, collectedCount: values.length);
    }).toList();
    final latestPatternsByKey = <String, CollectedPattern>{
      for (final summary in summaries)
        summary.latest.patternKey: summary.latest,
    };
    List<_PatternSummary> individualGroup(
      bool Function(CapturePatternFamily family) includes,
    ) =>
        summaries
            .where(
              (_PatternSummary value) =>
                  !value.latest.isCombination && includes(value.latest.family),
            )
            .toList()
          ..sort(
            (_PatternSummary a, _PatternSummary b) =>
                a.latest.labelKo.compareTo(b.latest.labelKo),
          );
    final timeAndSeason = individualGroup(
      (CapturePatternFamily family) =>
          family == CapturePatternFamily.time ||
          family == CapturePatternFamily.season,
    );
    final weather = individualGroup(
      (CapturePatternFamily family) => family == CapturePatternFamily.weather,
    );
    final surroundings = individualGroup(
      (CapturePatternFamily family) =>
          family == CapturePatternFamily.surroundings,
    );
    final individualCount =
        timeAndSeason.length + weather.length + surroundings.length;
    final combinations =
        summaries
            .where((_PatternSummary value) => value.latest.isCombination)
            .toList()
          ..sort((_PatternSummary a, _PatternSummary b) {
            final order = combinationPatternOrder(
              a.latest,
            ).compareTo(combinationPatternOrder(b.latest));
            if (order != 0) return order;
            return a.latest.patternKey.compareTo(b.latest.patternKey);
          });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      children: <Widget>[
        _PatternSectionHeading(
          title: '개별 패턴',
          count: individualCount,
          body: '시간·날씨 기록은 방문자 조건을 읽는 비소모 단서',
        ),
        const SizedBox(height: 10),
        PixelCard(
          color: PixelPalette.scene,
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              _IndividualPatternGroup(
                title: '시간과 계절',
                family: CapturePatternFamily.time,
                patterns: timeAndSeason,
                visitors: controller.catalog.visitors,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: PixelRule(),
              ),
              _IndividualPatternGroup(
                title: '날씨',
                family: CapturePatternFamily.weather,
                patterns: weather,
                visitors: controller.catalog.visitors,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: PixelRule(),
              ),
              _IndividualPatternGroup(
                title: '주변',
                family: CapturePatternFamily.surroundings,
                patterns: surroundings,
                visitors: controller.catalog.visitors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _PatternSectionHeading(
          title: '동시 조합',
          count: combinations.length,
          body: '같은 순간에 모인 정보가 만든 별도 수집물',
        ),
        const SizedBox(height: 10),
        PixelCard(
          color: PixelPalette.scene,
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (
                var index = 0;
                index < combinations.length;
                index += 1
              ) ...<Widget>[
                _CombinationInventoryRow(
                  summary: combinations[index],
                  patternsByKey: latestPatternsByKey,
                ),
                if (index != combinations.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: PixelRule(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PatternSectionHeading extends StatelessWidget {
  const _PatternSectionHeading({
    required this.title,
    required this.count,
    required this.body,
  });

  final String title;
  final int count;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${formatNumber(count)}종',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _IndividualPatternGroup extends StatefulWidget {
  const _IndividualPatternGroup({
    required this.title,
    required this.family,
    required this.patterns,
    required this.visitors,
  });

  final String title;
  final CapturePatternFamily family;
  final List<_PatternSummary> patterns;
  final List<VisitorDefinition> visitors;

  @override
  State<_IndividualPatternGroup> createState() =>
      _IndividualPatternGroupState();
}

class _IndividualPatternGroupState extends State<_IndividualPatternGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(48, 0, 12, 8),
        backgroundColor: PixelPalette.raised,
        collapsedBackgroundColor: Colors.transparent,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: PatternFamilyMark(family: widget.family),
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${formatNumber(widget.patterns.length)}종',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: PixelCaret(expanded: _expanded),
        onExpansionChanged: (bool value) {
          setState(() => _expanded = value);
        },
        children: <Widget>[
          for (
            var index = 0;
            index < widget.patterns.length;
            index += 1
          ) ...<Widget>[
            _CompactIndividualPatternRow(
              summary: widget.patterns[index],
              visitors: widget.visitors,
            ),
            if (index != widget.patterns.length - 1) const PixelRule(),
          ],
        ],
      ),
    );
  }
}

class _CompactIndividualPatternRow extends StatelessWidget {
  const _CompactIndividualPatternRow({
    required this.summary,
    required this.visitors,
  });

  final _PatternSummary summary;
  final List<VisitorDefinition> visitors;

  @override
  Widget build(BuildContext context) {
    final pattern = summary.latest;
    final clueCount = visitorClueCountForPattern(pattern, visitors);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              compactPatternLabel(pattern),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${clueCount > 0 ? '방문자 $clueCount명 · ' : ''}${formatNumber(summary.collectedCount)}회',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CombinationInventoryRow extends StatelessWidget {
  const _CombinationInventoryRow({
    required this.summary,
    required this.patternsByKey,
  });

  final _PatternSummary summary;
  final Map<String, CollectedPattern> patternsByKey;

  @override
  Widget build(BuildContext context) {
    final pattern = summary.latest;
    final visual = combinationPatternVisualDescriptor(pattern, patternsByKey);
    final collectionCount = formatNumber(summary.collectedCount);
    return Semantics(
      container: true,
      label:
          '${visual.title}, ${visual.summary}, ${visual.componentCount}개 정보, $collectionCount회 수집',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: PixelWeaveMark(
                  families: visual.componentFamilies,
                  size: 24,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      visual.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visual.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${visual.componentCount}개 정보 · $collectionCount회 수집',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: PixelPalette.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternSummary {
  const _PatternSummary({required this.latest, required this.collectedCount});

  final CollectedPattern latest;
  final int collectedCount;
}

class _ObjectsTab extends StatelessWidget {
  const _ObjectsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.craftedObjects.isEmpty) {
      return const _EmptyState(
        icon: Icons.handyman_outlined,
        title: '아직 만든 물건이 없습니다',
        body: '날씨 재료와 걸음을 사용해 첫 물건을 만들어 보세요.',
      );
    }
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: controller.craftedObjects.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        final object = controller.craftedObjects[index];
        final recipe = controller.catalog.recipeById(object.recipeId);
        final focusDefinition = object.focusTrait == null
            ? null
            : controller.catalog.atmosphericTraits.definitionFor(
                object.focusTrait!,
              );
        final displayName = focusDefinition == null
            ? recipe.nameKo
            : '${focusDefinition.namePrefixKo} ${recipe.nameKo}';
        return PixelCard(
          color: Colors.transparent,
          radius: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: weatherColor(
                    object.weatherKind,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(PixelRadii.tile),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ObjectVisualPreview(
                    key: ValueKey<String>(object.id),
                    visual: ObjectVisualDescriptor.fromCraftedObject(
                      object,
                      timeBand: weatherById[object.weatherMaterialId]?.timeBand,
                    ),
                    constructionAssetPath: controller.catalog.craftingArt
                        .constructionAssetFor(
                          object.recipeId,
                          object.requiredSteps <= 0
                              ? 1
                              : object.appliedSteps / object.requiredSteps,
                        ),
                    visualLayerCatalog: controller.catalog.visualLayers,
                    atmosphericTraitCatalog:
                        controller.catalog.atmosphericTraits,
                    semanticLabel: '$displayName 미리보기',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      object.isComplete
                          ? object.lifecycle == ObjectLifecycle.placed
                                ? '내 공간에 배치됨'
                                : '보관 중'
                          : '${formatNumber(object.remainingSteps)}걸음 남음',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (object.focusTrait != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        atmosphericTraitSummary(<AtmosphericTrait>[
                          object.focusTrait!,
                        ], controller.catalog.atmosphericTraits),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (!object.isComplete) ...<Widget>[
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                        value: object.appliedSteps / object.requiredSteps,
                        color: PixelPalette.mint,
                        backgroundColor: PixelPalette.line,
                      ),
                    ],
                  ],
                ),
              ),
              if (object.isComplete)
                IconButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          PlacementEditorScreen(initialObjectId: object.id),
                    ),
                  ),
                  tooltip: object.lifecycle == ObjectLifecycle.placed
                      ? '배치 편집'
                      : '배치하기',
                  icon: const Icon(Icons.grid_view_outlined),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecordStampPainter extends CustomPainter {
  const _RecordStampPainter({required this.accent, required this.seed});

  final Color accent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..color = accent.withValues(alpha: 0.14);
    for (var index = 0; index < 18; index += 1) {
      final x = ((seed ~/ (index + 3) + index * 31) % 100) / 100 * size.width;
      final y = ((seed ~/ (index + 7) + index * 47) % 100) / 100 * size.height;
      final unit = index.isEven ? 3.0 : 2.0;
      canvas.drawRect(Rect.fromLTWH(x, y, unit, unit), paint);
    }
    final line = Paint()
      ..isAntiAlias = false
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.25);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.75,
        height: size.height * 0.55,
      ),
      0.3,
      4.3,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(_RecordStampPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.seed != seed;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.icon,
    this.visual,
    required this.title,
    required this.body,
  }) : assert(icon != null || visual != null);

  final IconData? icon;
  final Widget? visual;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            visual ?? Icon(icon, size: 52, color: PixelPalette.muted),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _time(DateTime date) {
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _countLabel(
  AppController controller,
  int tabIndex,
) => switch (tabIndex) {
  1 =>
    '${formatNumber(controller.weatherMaterials.length + controller.surroundingMaterials.length)}개 재료',
  2 =>
    '${formatNumber(controller.collectedPatterns.map((CollectedPattern value) => value.patternKey).toSet().length)}종 패턴',
  3 => '${formatNumber(controller.craftedObjects.length)}개 물건',
  _ => '${formatNumber(controller.captureRecordTotal)}개 기록',
};
