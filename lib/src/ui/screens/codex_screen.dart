import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/diorama/generated_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
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
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.77,
      ),
      itemCount: controller.catalog.visitors.length,
      itemBuilder: (BuildContext context, int index) {
        final visitor = controller.catalog.visitors[index];
        final discovered = seenIds.contains(visitor.id);
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
                    borderRadius: BorderRadius.circular(PixelRadii.tile),
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
                discovered ? visitor.descriptionKo : visitor.hintsKo.first,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ObjectKindsTab extends StatelessWidget {
  const _ObjectKindsTab({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final weatherById = <String, WeatherMaterial>{
      for (final material in controller.weatherMaterials) material.id: material,
    };
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
        final singleColumn = constraints.maxWidth < 360 || largeText;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: singleColumn ? 1 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: singleColumn ? 196 : 166,
          ),
          itemCount: controller.catalog.recipes.length,
          itemBuilder: (BuildContext context, int index) {
            final recipe = controller.catalog.recipes[index];
            final matchingObjects =
                controller.craftedObjects
                    .where((CraftedObject object) => object.kind == recipe.kind)
                    .toList()
                  ..sort((CraftedObject a, CraftedObject b) {
                    final byCreatedAt = a.createdAt.compareTo(b.createdAt);
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
                            visual: ObjectVisualDescriptor.fromCraftedObject(
                              representative,
                              timeBand:
                                  weatherById[representative.weatherMaterialId]
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
                                            representative.requiredSteps,
                                ),
                            visualLayerCatalog: controller.catalog.visualLayers,
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
                                visual: ObjectVisualDescriptor.forRecipe(
                                  recipe,
                                ),
                                semanticLabel: '${recipe.nameKo} 잠긴 실루엣',
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
                    made ? '$count개 제작' : '만드는 법을 찾아보세요.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      itemCount: controller.catalog.recipes.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        final recipe = controller.catalog.recipes[index];
        final unlocked = controller.unlockedRecipeIds.contains(recipe.id);
        return PixelCard(
          color: Colors.transparent,
          radius: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: unlocked
                      ? PixelPalette.mint.withValues(alpha: 0.10)
                      : PixelPalette.background,
                  borderRadius: BorderRadius.circular(PixelRadii.tile),
                ),
                child: unlocked
                    ? Padding(
                        padding: const EdgeInsets.all(3),
                        child: ObjectVisualPreview(
                          visual: ObjectVisualDescriptor.forRecipe(recipe),
                          semanticLabel: '${recipe.nameKo} 기본 형태',
                        ),
                      )
                    : const Icon(Icons.lock_outline, color: PixelPalette.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      unlocked ? recipe.nameKo : '잠긴 만드는 법',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlocked
                          ? '${recipe.stepCost}걸음 · 날씨 1개 · 주변 선택'
                          : '방문자가 새로운 만드는 법을 남깁니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
