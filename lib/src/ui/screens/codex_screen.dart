import 'package:flutter/material.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
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
                        : PixelPalette.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      discovered
                          ? _visitorIcon(visitor.id)
                          : Icons.help_outline,
                      color: discovered
                          ? PixelPalette.blue
                          : PixelPalette.muted,
                      size: 54,
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
    final madeKinds = controller.craftedObjects
        .map((CraftedObject value) => value.kind)
        .toSet();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: controller.catalog.recipes.length,
      itemBuilder: (BuildContext context, int index) {
        final recipe = controller.catalog.recipes[index];
        final made = madeKinds.contains(recipe.kind);
        final count = controller.craftedObjects
            .where((CraftedObject object) => object.kind == recipe.kind)
            .length;
        return PixelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                made ? objectIcon(recipe.kind) : Icons.lock_outline,
                color: made ? PixelPalette.mint : PixelPalette.muted,
                size: 34,
              ),
              const Spacer(),
              Text(
                made ? recipe.nameKo : '미발견 물건',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                made ? '$count개 제작' : '만드는 법을 찾아보세요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
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
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (BuildContext context, int index) {
        final recipe = controller.catalog.recipes[index];
        final unlocked = controller.unlockedRecipeIds.contains(recipe.id);
        return PixelCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: unlocked
                      ? PixelPalette.mint.withValues(alpha: 0.10)
                      : PixelPalette.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  unlocked ? objectIcon(recipe.kind) : Icons.lock_outline,
                  color: unlocked ? PixelPalette.mint : PixelPalette.muted,
                ),
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

IconData _visitorIcon(String id) => switch (id) {
  'umbrella_walker' => Icons.umbrella_outlined,
  'night_moth' => Icons.flutter_dash,
  'roof_bird' => Icons.flight,
  'fog_cat' => Icons.pets_outlined,
  'transfer_guest' => Icons.directions_bus_outlined,
  'light_swarm' => Icons.auto_awesome,
  _ => Icons.person_outline,
};
