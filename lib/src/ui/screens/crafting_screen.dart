import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/crafting_art_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({
    this.preselectedWeatherId,
    this.preselectedSurroundingId,
    super.key,
  });

  final String? preselectedWeatherId;
  final String? preselectedSurroundingId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('만들기')),
      body: controller.unlockedRecipes.isEmpty
          ? const Center(child: Text('열린 만드는 법이 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: controller.unlockedRecipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final recipe = controller.unlockedRecipes[index];
                return PixelCard(
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => CraftingDetailScreen(
                        recipe: recipe,
                        preselectedWeatherId: preselectedWeatherId,
                        preselectedSurroundingId: preselectedSurroundingId,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: PixelPalette.mint.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
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
                              recipe.descriptionKo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.directions_walk,
                                  size: 16,
                                  color: PixelPalette.mint,
                                ),
                                const SizedBox(width: 4),
                                Text('${recipe.stepCost}걸음'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: PixelPalette.muted,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class CraftingDetailScreen extends StatefulWidget {
  const CraftingDetailScreen({
    required this.recipe,
    this.preselectedWeatherId,
    this.preselectedSurroundingId,
    super.key,
  });

  final RecipeDefinition recipe;
  final String? preselectedWeatherId;
  final String? preselectedSurroundingId;

  @override
  State<CraftingDetailScreen> createState() => _CraftingDetailScreenState();
}

class _CraftingDetailScreenState extends State<CraftingDetailScreen> {
  String? _weatherId;
  String? _surroundingId;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    _weatherId ??= _findPreferred(
      controller.availableWeatherMaterials.map(
        (WeatherMaterial value) => value.id,
      ),
      widget.preselectedWeatherId,
    );
    _surroundingId ??= _findPreferred(
      controller.availableSurroundingMaterials.map(
        (SurroundingMaterial value) => value.id,
      ),
      widget.preselectedSurroundingId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final weather = controller.availableWeatherMaterials
        .where((WeatherMaterial item) => item.id == _weatherId)
        .firstOrNull;
    final surroundings = controller.availableSurroundingMaterials
        .where((SurroundingMaterial item) => item.id == _surroundingId)
        .firstOrNull;
    final canSubmit =
        weather != null && !_submitting && controller.construction == null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.nameKo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _ObjectPreview(
            recipe: widget.recipe,
            weather: weather,
            surroundings: surroundings,
            availableSteps: controller.availableSteps,
            constructionStage: controller.catalog.craftingArt.stageFor(
              widget.recipe.id,
              _projectedCompletion(controller.availableSteps),
            ),
          ),
          const SizedBox(height: 14),
          Text('날씨 재료', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (controller.availableWeatherMaterials.isEmpty)
            const PixelCard(child: Text('사용 가능한 날씨 재료가 없습니다. 먼저 수집해 주세요.'))
          else
            _WeatherPicker(
              materials: controller.availableWeatherMaterials,
              selectedId: _weatherId,
              onSelected: (String id) => setState(() => _weatherId = id),
            ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '주변 재료 · 선택',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: _surroundingId == null
                    ? null
                    : () => setState(() => _surroundingId = null),
                child: const Text('사용 안 함'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.availableSurroundingMaterials.isEmpty)
            const PixelCard(child: Text('주변 재료 없이 기본 인접 기능으로 만들 수 있습니다.'))
          else
            _SurroundingPicker(
              materials: controller.availableSurroundingMaterials,
              selectedId: _surroundingId,
              onSelected: (String id) => setState(() => _surroundingId = id),
            ),
          const SizedBox(height: 18),
          PixelCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.directions_walk, color: PixelPalette.mint),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '필요한 걸음',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${widget.recipe.stepCost}걸음',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '보유 ${controller.availableSteps}',
                  style: TextStyle(
                    color: controller.availableSteps >= widget.recipe.stepCost
                        ? PixelPalette.success
                        : PixelPalette.amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (controller.construction != null) ...<Widget>[
            const SizedBox(height: 12),
            const Text(
              '진행 중인 공사가 있어 새 물건을 시작할 수 없습니다.',
              style: TextStyle(color: PixelPalette.amber),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: canSubmit
                ? () => _craft(controller, weather, surroundings)
                : null,
            icon: const Icon(Icons.handyman_outlined),
            label: Text(
              controller.availableSteps >= widget.recipe.stepCost
                  ? '만들기'
                  : '공사 시작',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.availableSteps >= widget.recipe.stepCost
                ? '완성된 물건은 빈 칸에 자동으로 놓이며 언제든 이동할 수 있습니다.'
                : '현재 걸음을 먼저 쓰고, 남은 걸음은 이후 동기화될 때 채워집니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _craft(
    AppController controller,
    WeatherMaterial weather,
    SurroundingMaterial? surroundings,
  ) async {
    setState(() => _submitting = true);
    try {
      if (!controller.stepTrackingConfigured) {
        if (controller.demoMode) {
          await controller.configureStepTracking(useRealSteps: true);
        } else {
          final status = await Permission.activityRecognition.request();
          await controller.configureStepTracking(
            useRealSteps: status.isGranted,
          );
        }
      } else if (controller.usesRealSteps) {
        await controller.refreshSteps();
      }
      final object = await controller.craft(
        recipe: widget.recipe,
        weather: weather,
        surroundings: surroundings,
      );
      if (!mounted || object == null) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(object.isComplete ? '물건 완성' : '공사 시작'),
          content: Text(
            object.isComplete
                ? '${widget.recipe.nameKo}을 내 공간에 놓았습니다.'
                : '${object.remainingSteps}걸음을 더 모으면 완성됩니다.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  double _projectedCompletion(int availableSteps) {
    if (widget.recipe.stepCost <= 0) return 1;
    return (availableSteps / widget.recipe.stepCost).clamp(0, 1).toDouble();
  }
}

class _ObjectPreview extends StatelessWidget {
  const _ObjectPreview({
    required this.recipe,
    required this.weather,
    required this.surroundings,
    required this.availableSteps,
    required this.constructionStage,
  });

  final RecipeDefinition recipe;
  final WeatherMaterial? weather;
  final SurroundingMaterial? surroundings;
  final int availableSteps;
  final ConstructionArtStage? constructionStage;

  @override
  Widget build(BuildContext context) {
    final completion = recipe.stepCost <= 0
        ? 1.0
        : (availableSteps / recipe.stepCost).clamp(0, 1).toDouble();
    final visual = weather == null
        ? ObjectVisualDescriptor.forRecipe(recipe, completion: completion)
        : ObjectVisualDescriptor.forCraftingPreview(
            recipe: recipe,
            weather: weather!,
            surrounding: surroundings,
            completion: completion,
          );
    return PixelCard(
      child: Column(
        children: <Widget>[
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: PixelPalette.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ObjectVisualPreview(
                visual: visual,
                constructionAssetPath: constructionStage?.assetPath,
                semanticLabel: '${recipe.nameKo} 제작 미리보기',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(recipe.nameKo, style: Theme.of(context).textTheme.headlineSmall),
          if (constructionStage != null) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 7,
                    color: PixelPalette.amber,
                    backgroundColor: PixelPalette.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '예상 ${_constructionStageLabel(constructionStage!.stage)}',
                  style: const TextStyle(
                    color: PixelPalette.amber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 5),
          Text(
            recipe.descriptionKo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _WeatherPicker extends StatelessWidget {
  const _WeatherPicker({
    required this.materials,
    required this.selectedId,
    required this.onSelected,
  });

  final List<WeatherMaterial> materials;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final material = materials[index];
          final selected = material.id == selectedId;
          return SizedBox(
            width: 136,
            child: PixelCard(
              highlighted: selected,
              selected: selected,
              semanticLabel: '${material.kind.labelKo} 날씨 재료',
              padding: const EdgeInsets.all(10),
              onTap: () => onSelected(material.id),
              child: Row(
                children: <Widget>[
                  MaterialOrb.weather(material.kind),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(material.kind.labelKo),
                        Text(
                          material.timeBand.labelKo,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SurroundingPicker extends StatelessWidget {
  const _SurroundingPicker({
    required this.materials,
    required this.selectedId,
    required this.onSelected,
  });

  final List<SurroundingMaterial> materials;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final material = materials[index];
          final selected = material.id == selectedId;
          return SizedBox(
            width: 150,
            child: PixelCard(
              highlighted: selected,
              selected: selected,
              semanticLabel: '${material.kind.shortLabelKo} 주변 재료',
              padding: const EdgeInsets.all(10),
              onTap: () => onSelected(material.id),
              child: Row(
                children: <Widget>[
                  MaterialOrb.surroundings(material.kind),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      material.kind.shortLabelKo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String? _findPreferred(Iterable<String> ids, String? preferred) {
  final list = ids.toList(growable: false);
  if (preferred != null && list.contains(preferred)) {
    return preferred;
  }
  return list.isEmpty ? null : list.first;
}

String _constructionStageLabel(String stage) => switch (stage) {
  'foundation' => '기초 단계',
  'frame' => '골조 단계',
  'finish' => '마감 단계',
  _ => '공사 단계',
};

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
