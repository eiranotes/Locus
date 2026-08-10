import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/pattern_presentation.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '도감',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
          const TabBar(
            tabs: <Widget>[
              Tab(text: '방문자'),
              Tab(text: '만든 것'),
              Tab(text: '만드는 법'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _VisitorsTab(controller: controller),
                _ObjectKindsTab(controller: controller),
                _RecipesTab(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitorsTab extends StatelessWidget {
  const _VisitorsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final seenIds = controller.visitorSightings
        .map((VisitorSighting item) => item.visitorId)
        .toSet();
    final unlockedRecipes = controller.catalog.recipes
        .where(
          (RecipeDefinition recipe) =>
              controller.unlockedRecipeIds.contains(recipe.id),
        )
        .toList(growable: false);
    final groups = _groupByCollection(
      controller.catalog.visitors,
      idOf: (visitor) => visitor.collectionId,
      labelOf: (visitor) => visitor.collectionNameKo,
    );
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _CodexProgressHeader(
            label: '만난 방문자',
            completed: seenIds.length,
            total: controller.catalog.visitors.length,
            supportingText: '패턴에서 방문자 단서를 찾을 수 있습니다.',
          ),
        ),
        for (final group in groups) ...<Widget>[
          SliverToBoxAdapter(
            child: _CollectionHeading(
              label: group.label,
              completed: group.items
                  .where((visitor) => seenIds.contains(visitor.id))
                  .length,
              total: group.items.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: group.items.length,
              itemBuilder: (BuildContext context, int index) {
                final visitor = group.items[index];
                final discovered = seenIds.contains(visitor.id);
                final encounterCount =
                    controller.visitorEncounterCounts[visitor.id] ?? 0;
                final sighting = controller.visitorSightings
                    .where(
                      (VisitorSighting item) => item.visitorId == visitor.id,
                    )
                    .firstOrNull;
                final clue = visitorPatternEvidence(
                  visitor,
                  controller.collectedPatterns,
                ).firstOrNull;
                final recipeGate = const VisitorProgressionPolicy()
                    .missingRecipeGate(
                      visitor,
                      unlockedRecipes,
                      controller.catalog.recipes,
                    );
                final rewardRecipe =
                    visitor.reward.kind == VisitorRewardKind.recipe
                    ? controller.catalog.recipeById(visitor.reward.value)
                    : null;
                return PixelCard(
                  radius: PixelRadii.tile,
                  color: discovered ? PixelPalette.scene : Colors.transparent,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: discovered
                                ? PixelPalette.blue.withValues(alpha: 0.10)
                                : PixelPalette.scene,
                            borderRadius: BorderRadius.circular(
                              PixelRadii.tile,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: discovered
                                ? Image.asset(
                                    GeneratedArtPaths.visitor(visitor.id),
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                  )
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      PixelPalette.textMuted,
                                      BlendMode.srcIn,
                                    ),
                                    child: Opacity(
                                      opacity: 0.32,
                                      child: Image.asset(
                                        GeneratedArtPaths.visitor(visitor.id),
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.none,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        discovered ? visitor.nameKo : '아직 만나지 못함',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        discovered
                            ? visitor.descriptionKo
                            : recipeGate != null
                            ? '선행 만드는 법 · ${recipeGate.nameKo}'
                            : clue == null
                            ? visitor.hintsKo.first
                            : '패턴 단서 · ${compactPatternLabel(clue.pattern)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (discovered) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          '$encounterCount회 방문 · ${_visitorSceneLabel(sighting)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: PixelPalette.visitor),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        discovered && rewardRecipe != null
                            ? '${rewardRecipe.nameKo} 해금'
                            : '첫 만남 보상 · 새 만드는 법',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: PixelPalette.reward,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}

String _visitorSceneLabel(VisitorSighting? sighting) {
  if (sighting == null) return '장면 기록 없음';
  final parts = sighting.variantKey.split('_');
  if (parts.length < 2) return '장면 기록';
  final weather = enumByName(
    WeatherMaterialKind.values,
    parts[0],
    WeatherMaterialKind.cloudy,
  );
  final time = enumByName(TimeBand.values, parts[1], TimeBand.evening);
  return '${weather.labelKo} · ${time.labelKo}';
}

class _ObjectKindsTab extends StatelessWidget {
  const _ObjectKindsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    final madeRecipeIds = controller.craftedObjects
        .map((object) => object.recipeId)
        .toSet();
    final groups = _groupByCollection(
      controller.catalog.recipes,
      idOf: (recipe) => recipe.collectionId,
      labelOf: (recipe) => recipe.collectionNameKo,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
        final singleColumn = constraints.maxWidth < 360 || largeText;
        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _CodexProgressHeader(
                label: '만들어 본 물건',
                completed: madeRecipeIds.length,
                total: controller.catalog.recipes.length,
                supportingText: '보관한 물건은 다시 배치할 수 있습니다.',
              ),
            ),
            for (final group in groups) ...<Widget>[
              SliverToBoxAdapter(
                child: _CollectionHeading(
                  label: group.label,
                  completed: group.items
                      .where((recipe) => madeRecipeIds.contains(recipe.id))
                      .length,
                  total: group.items.length,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: singleColumn ? 1 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: singleColumn ? 196 : 166,
                  ),
                  itemCount: group.items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final recipe = group.items[index];
                    final matchingObjects =
                        controller.craftedObjects
                            .where(
                              (CraftedObject object) =>
                                  object.kind == recipe.kind,
                            )
                            .toList()
                          ..sort((CraftedObject a, CraftedObject b) {
                            final byCreatedAt = a.createdAt.compareTo(
                              b.createdAt,
                            );
                            return byCreatedAt != 0
                                ? byCreatedAt
                                : a.id.compareTo(b.id);
                          });
                    final representative = matchingObjects.firstOrNull;
                    final made = representative != null;
                    final count = matchingObjects.length;
                    return PixelCard(
                      radius: PixelRadii.tile,
                      color: made ? PixelPalette.scene : Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 62,
                            width: double.infinity,
                            child: made
                                ? ObjectVisualPreview(
                                    visual:
                                        ObjectVisualDescriptor.fromCraftedObject(
                                          representative,
                                          timeBand:
                                              weatherById[representative
                                                      .weatherMaterialId]
                                                  ?.timeBand,
                                        ),
                                    constructionAssetPath: controller
                                        .catalog
                                        .craftingArt
                                        .constructionAssetFor(
                                          representative.recipeId,
                                          representative.requiredSteps <= 0
                                              ? 1
                                              : representative.appliedSteps /
                                                    representative
                                                        .requiredSteps,
                                        ),
                                    visualLayerCatalog:
                                        controller.catalog.visualLayers,
                                    atmosphericTraitCatalog:
                                        controller.catalog.atmosphericTraits,
                                    semanticLabel: '${recipe.nameKo} 대표 미리보기',
                                  )
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      PixelPalette.textMuted,
                                      BlendMode.srcIn,
                                    ),
                                    child: Opacity(
                                      opacity: 0.26,
                                      child: ObjectVisualPreview(
                                        visual:
                                            ObjectVisualDescriptor.forRecipe(
                                              recipe,
                                            ),
                                        semanticLabel:
                                            '${recipe.nameKo} 잠긴 실루엣',
                                      ),
                                    ),
                                  ),
                          ),
                          const Spacer(),
                          Text(
                            made ? recipe.nameKo : '미발견 물건',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            made ? '$count개 제작' : '만드는 법 미발견',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
      },
    );
  }
}

class _RecipesTab extends StatelessWidget {
  const _RecipesTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByCollection(
      controller.catalog.recipes,
      idOf: (recipe) => recipe.collectionId,
      labelOf: (recipe) => recipe.collectionNameKo,
    );
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: _CodexProgressHeader(
            label: '찾은 만드는 법',
            completed: controller.unlockedRecipeIds.length,
            total: controller.catalog.recipes.length,
            supportingText: '방문자를 만나 새 만드는 법을 찾습니다.',
          ),
        ),
        for (final group in groups) ...<Widget>[
          SliverToBoxAdapter(
            child: _CollectionHeading(
              label: group.label,
              completed: group.items
                  .where(
                    (recipe) =>
                        controller.unlockedRecipeIds.contains(recipe.id),
                  )
                  .length,
              total: group.items.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount:
                  group.items
                      .where(
                        (recipe) =>
                            controller.unlockedRecipeIds.contains(recipe.id),
                      )
                      .length +
                  (group.items.any(
                        (recipe) =>
                            !controller.unlockedRecipeIds.contains(recipe.id),
                      )
                      ? 1
                      : 0),
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (BuildContext context, int index) {
                final unlockedItems = group.items
                    .where(
                      (recipe) =>
                          controller.unlockedRecipeIds.contains(recipe.id),
                    )
                    .toList(growable: false);
                final lockedCount = group.items.length - unlockedItems.length;
                if (index == unlockedItems.length) {
                  return PixelCard(
                    color: PixelPalette.scene,
                    radius: PixelRadii.tile,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.lock_outline,
                          color: PixelPalette.muted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '잠긴 만드는 법 $lockedCount개',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '방문자를 만나면 열립니다.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final recipe = unlockedItems[index];
                return PixelCard(
                  color: Colors.transparent,
                  radius: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: PixelPalette.mint.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(PixelRadii.tile),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: ObjectVisualPreview(
                            visual: ObjectVisualDescriptor.forRecipe(recipe),
                            semanticLabel: '${recipe.nameKo} 기본 형태',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              recipe.nameKo,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatNumber(recipe.stepCost)}걸음 · 날씨 1개 · 주변 선택',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _CodexProgressHeader extends StatelessWidget {
  const _CodexProgressHeader({
    required this.label,
    required this.completed,
    required this.total,
    required this.supportingText,
  });

  final String label;
  final int completed;
  final int total;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Semantics(
      label: '$label $completed개, 전체 $total개',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '$completed / $total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PixelPalette.amber,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: PixelPalette.scene,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  PixelPalette.amber,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(supportingText, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CollectionHeading extends StatelessWidget {
  const _CollectionHeading({
    required this.label,
    required this.completed,
    required this.total,
  });

  final String label;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(
          '$completed/$total',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: PixelPalette.textMuted),
        ),
      ],
    ),
  );
}

class _CollectionGroup<T> {
  const _CollectionGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<T> items;
}

List<_CollectionGroup<T>> _groupByCollection<T>(
  List<T> items, {
  required String Function(T item) idOf,
  required String Function(T item) labelOf,
}) {
  final groups = <String, _CollectionGroup<T>>{};
  for (final item in items) {
    final id = idOf(item);
    groups
        .putIfAbsent(
          id,
          () => _CollectionGroup<T>(id: id, label: labelOf(item), items: <T>[]),
        )
        .items
        .add(item);
  }
  return groups.values.toList(growable: false);
}
