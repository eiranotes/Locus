import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/domain/crafting_art_catalog.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/visual_layer_catalog.dart';
import 'package:reality_diorama/src/ui/number_format.dart';
import 'package:reality_diorama/src/ui/widgets/material_visuals.dart';
import 'package:reality_diorama/src/ui/widgets/atmospheric_trait_chips.dart';
import 'package:reality_diorama/src/ui/widgets/object_visual_preview.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_button.dart';

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
    final selectedWeather = controller.availableWeatherMaterials
        .where((WeatherMaterial value) => value.id == preselectedWeatherId)
        .firstOrNull;
    final selectedSurroundings = controller.availableSurroundingMaterials
        .where(
          (SurroundingMaterial value) => value.id == preselectedSurroundingId,
        )
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('만들기')),
      body: controller.unlockedRecipes.isEmpty
          ? const Center(child: Text('열린 만드는 법이 없습니다.'))
          : Column(
              children: <Widget>[
                _CraftingContextStrip(
                  availableSteps: controller.availableSteps,
                  weather: selectedWeather,
                  surroundings: selectedSurroundings,
                  weatherCount: controller.availableWeatherMaterials.length,
                  surroundingCount:
                      controller.availableSurroundingMaterials.length,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    itemCount: controller.unlockedRecipes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (BuildContext context, int index) {
                      final recipe = controller.unlockedRecipes[index];
                      return _RecipeRow(
                        recipe: recipe,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                CraftingDetailScreen(
                                  recipe: recipe,
                                  preselectedWeatherId: preselectedWeatherId,
                                  preselectedSurroundingId:
                                      preselectedSurroundingId,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CraftingContextStrip extends StatelessWidget {
  const _CraftingContextStrip({
    required this.availableSteps,
    required this.weather,
    required this.surroundings,
    required this.weatherCount,
    required this.surroundingCount,
  });

  final int availableSteps;
  final WeatherMaterial? weather;
  final SurroundingMaterial? surroundings;
  final int weatherCount;
  final int surroundingCount;

  @override
  Widget build(BuildContext context) {
    final weatherLabel = weather == null
        ? '날씨 재료 ${formatNumber(weatherCount)}개'
        : '날씨 ${weather!.kind.labelKo}';
    final surroundingsLabel = surroundings == null
        ? '주변 재료 ${formatNumber(surroundingCount)}개'
        : '주변 ${surroundings!.kind.shortLabelKo}';
    return Semantics(
      container: true,
      label:
          '보유 ${formatNumber(availableSteps)}걸음, $weatherLabel, $surroundingsLabel',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: PixelPalette.scene,
          border: Border(bottom: BorderSide(color: PixelPalette.divider)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              _CraftingContextItem(
                icon: Icons.directions_walk,
                label: '보유 ${formatNumber(availableSteps)}걸음',
                color: PixelPalette.mint,
              ),
              _CraftingContextItem(
                icon: weather == null
                    ? Icons.cloud_outlined
                    : weatherIcon(weather!.kind),
                label: weatherLabel,
                color: weather == null
                    ? PixelPalette.muted
                    : weatherColor(weather!.kind),
              ),
              _CraftingContextItem(
                icon: Icons.radar,
                label: surroundingsLabel,
                color: surroundings == null
                    ? PixelPalette.muted
                    : PixelPalette.violet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CraftingContextItem extends StatelessWidget {
  const _CraftingContextItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe, required this.onTap});

  final RecipeDefinition recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${recipe.nameKo}, ${formatNumber(recipe.stepCost)}걸음',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PixelRadii.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: PixelPalette.scene,
                    borderRadius: BorderRadius.circular(PixelRadii.tile),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ObjectVisualPreview(
                    visual: ObjectVisualDescriptor.forRecipe(recipe),
                    semanticLabel: '${recipe.nameKo} 기본 형태',
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
                      const SizedBox(height: 3),
                      Text(
                        recipe.descriptionKo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatNumber(recipe.stepCost)}걸음',
                        style: const TextStyle(
                          color: PixelPalette.reward,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: PixelPalette.textMuted),
              ],
            ),
          ),
        ),
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
  AtmosphericTrait? _focusTrait;
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
    final supportedTraits =
        weather?.atmosphericTraits
            .where((trait) {
              if (!widget.recipe.traitAffinities.contains(trait)) return false;
              return trait != AtmosphericTrait.strongWind ||
                  surroundings == null ||
                  (surroundings.kind != SurroundingMaterialKind.dynamic &&
                      surroundings.kind != SurroundingMaterialKind.stable);
            })
            .toList(growable: false) ??
        const <AtmosphericTrait>[];
    final focusTrait = supportedTraits.contains(_focusTrait)
        ? _focusTrait
        : null;
    final canSubmit =
        weather != null && !_submitting && controller.construction == null;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final pinAction =
        MediaQuery.sizeOf(context).height >= 700 && textScale <= 1.3;
    final actionPanel = _CraftingActionPanel(
      requiredSteps: widget.recipe.stepCost,
      availableSteps: controller.availableSteps,
      constructionInProgress: controller.construction != null,
      pinned: pinAction,
      onPressed: canSubmit
          ? () => _craft(controller, weather, surroundings, focusTrait)
          : null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.nameKo)),
      bottomNavigationBar: pinAction ? actionPanel : null,
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
            visualLayerCatalog: controller.catalog.visualLayers,
            atmosphericTraitCatalog: controller.catalog.atmosphericTraits,
            focusTrait: focusTrait,
          ),
          const SizedBox(height: 14),
          Text('날씨 재료', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (controller.availableWeatherMaterials.isEmpty)
            const PixelCard(child: Text('날씨를 먼저 수집해 주세요.'))
          else
            _WeatherPicker(
              materials: controller.availableWeatherMaterials,
              catalog: controller.catalog.atmosphericTraits,
              selectedId: _weatherId,
              onSelected: (String id) => setState(() {
                _weatherId = id;
                _focusTrait = null;
              }),
            ),
          if (weather != null) ...<Widget>[
            const SizedBox(height: 18),
            Text(
              '남길 흔적 · 하나 선택',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _TraitFocusPicker(
              traits: supportedTraits,
              selected: focusTrait,
              catalog: controller.catalog.atmosphericTraits,
              onSelected: (AtmosphericTrait? value) =>
                  setState(() => _focusTrait = value),
            ),
          ],
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
                    : () => setState(() {
                        _surroundingId = null;
                        _focusTrait = null;
                      }),
                child: const Text('사용 안 함'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.availableSurroundingMaterials.isEmpty)
            const PixelCard(child: Text('선택 없이도 만들 수 있습니다.'))
          else
            _SurroundingPicker(
              materials: controller.availableSurroundingMaterials,
              selectedId: _surroundingId,
              onSelected: (String id) => setState(() {
                _surroundingId = id;
                _focusTrait = null;
              }),
            ),
          if (!pinAction) ...<Widget>[const SizedBox(height: 18), actionPanel],
        ],
      ),
    );
  }

  Future<void> _craft(
    AppController controller,
    WeatherMaterial weather,
    SurroundingMaterial? surroundings,
    AtmosphericTrait? focusTrait,
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
        focusTrait: focusTrait,
      );
      if (!mounted || object == null) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(object.isComplete ? '물건 완성' : '공사 시작'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 160,
                height: 140,
                child: ObjectVisualPreview(
                  visual: ObjectVisualDescriptor.fromCraftedObject(object),
                  visualLayerCatalog: controller.catalog.visualLayers,
                  atmosphericTraitCatalog: controller.catalog.atmosphericTraits,
                  semanticLabel: '${widget.recipe.nameKo} 제작 결과',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                object.isComplete
                    ? '${widget.recipe.nameKo}을 내 공간에 놓았습니다.'
                    : '${formatNumber(object.remainingSteps)}걸음을 더 모으면 완성됩니다.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('내 공간 보기'),
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

class _CraftingActionPanel extends StatelessWidget {
  const _CraftingActionPanel({
    required this.requiredSteps,
    required this.availableSteps,
    required this.constructionInProgress,
    required this.pinned,
    required this.onPressed,
  });

  final int requiredSteps;
  final int availableSteps;
  final bool constructionInProgress;
  final bool pinned;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final canComplete = availableSteps >= requiredSteps;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(pinned ? 16 : 4, 12, pinned ? 16 : 4, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.directions_walk, color: PixelPalette.mint),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 4,
                  children: <Widget>[
                    Text(
                      '필요 ${formatNumber(requiredSteps)}걸음',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '보유 ${formatNumber(availableSteps)}걸음',
                      style: TextStyle(
                        color: canComplete
                            ? PixelPalette.success
                            : PixelPalette.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (constructionInProgress) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              '진행 중인 공사를 먼저 마쳐 주세요.',
              style: TextStyle(color: PixelPalette.amber),
            ),
          ],
          const SizedBox(height: 10),
          PixelButton(
            onPressed: onPressed,
            actionAsset: 'craft',
            fallbackIcon: Icons.handyman_outlined,
            expand: true,
            label: canComplete ? '만들기' : '공사 시작',
          ),
          const SizedBox(height: 8),
          Text(
            canComplete ? '완성 후 빈 칸에 자동 배치' : '남은 걸음은 다음 동기화 때 반영',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: pinned ? PixelPalette.raised : Colors.transparent,
        border: const Border(top: BorderSide(color: PixelPalette.divider)),
      ),
      child: content,
    );
    return pinned
        ? SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 4),
            child: panel,
          )
        : panel;
  }
}

class _ObjectPreview extends StatelessWidget {
  const _ObjectPreview({
    required this.recipe,
    required this.weather,
    required this.surroundings,
    required this.availableSteps,
    required this.constructionStage,
    required this.visualLayerCatalog,
    required this.atmosphericTraitCatalog,
    required this.focusTrait,
  });

  final RecipeDefinition recipe;
  final WeatherMaterial? weather;
  final SurroundingMaterial? surroundings;
  final int availableSteps;
  final ConstructionArtStage? constructionStage;
  final VisualLayerCatalog visualLayerCatalog;
  final AtmosphericTraitCatalog atmosphericTraitCatalog;
  final AtmosphericTrait? focusTrait;

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
            focusTrait: focusTrait,
            completion: completion,
          );
    return Column(
      children: <Widget>[
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: PixelPalette.scene,
            borderRadius: BorderRadius.circular(PixelRadii.scene),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ObjectVisualPreview(
              visual: visual,
              constructionAssetPath: constructionStage?.assetPath,
              visualLayerCatalog: visualLayerCatalog,
              atmosphericTraitCatalog: atmosphericTraitCatalog,
              semanticLabel: '${recipe.nameKo} 제작 미리보기',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          focusTrait == null
              ? recipe.nameKo
              : '${atmosphericTraitCatalog.definitionFor(focusTrait!).namePrefixKo} ${recipe.nameKo}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (focusTrait != null) ...<Widget>[
          const SizedBox(height: 8),
          AtmosphericTraitChips(
            traits: <AtmosphericTrait>[focusTrait!],
            catalog: atmosphericTraitCatalog,
            showEffects: true,
          ),
        ],
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
    );
  }
}

class _WeatherPicker extends StatelessWidget {
  const _WeatherPicker({
    required this.materials,
    required this.catalog,
    required this.selectedId,
    required this.onSelected,
  });

  final List<WeatherMaterial> materials;
  final AtmosphericTraitCatalog catalog;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final material = materials[index];
          final selected = material.id == selectedId;
          return SizedBox(
            width: 156,
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
                        if (material.atmosphericTraits.isNotEmpty)
                          Text(
                            atmosphericTraitSummary(
                              material.atmosphericTraits,
                              catalog,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
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

class _TraitFocusPicker extends StatelessWidget {
  const _TraitFocusPicker({
    required this.traits,
    required this.selected,
    required this.catalog,
    required this.onSelected,
  });

  final List<AtmosphericTrait> traits;
  final AtmosphericTrait? selected;
  final AtmosphericTraitCatalog catalog;
  final ValueChanged<AtmosphericTrait?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ChoiceChip(
          label: const Text('기본 형태'),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final trait in traits)
          ChoiceChip(
            label: Text(catalog.definitionFor(trait).labelKo),
            selected: selected == trait,
            onSelected: (_) => onSelected(trait),
          ),
      ],
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
