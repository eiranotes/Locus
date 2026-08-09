import 'package:reality_diorama/src/domain/entities.dart';

final class ConstructionArtStage {
  const ConstructionArtStage({
    required this.stage,
    required this.maxCompletion,
    required this.representativeCompletion,
    required this.assetPath,
  });

  factory ConstructionArtStage.fromJson(Map<String, Object?> json) =>
      ConstructionArtStage(
        stage: json['stage']! as String,
        maxCompletion: (json['maxCompletion']! as num).toDouble(),
        representativeCompletion: (json['representativeCompletion']! as num)
            .toDouble(),
        assetPath: json['assetPath']! as String,
      );

  final String stage;
  final double maxCompletion;
  final double representativeCompletion;
  final String assetPath;
}

final class CraftingArtEntry {
  const CraftingArtEntry({required this.recipeId, required this.construction});

  factory CraftingArtEntry.fromJson(Map<String, Object?> json) =>
      CraftingArtEntry(
        recipeId: json['recipeId']! as String,
        construction: (json['construction']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(ConstructionArtStage.fromJson)
            .toList(growable: false),
      );

  final String recipeId;
  final List<ConstructionArtStage> construction;

  ConstructionArtStage? stageFor(double completion) {
    final normalized = completion.clamp(0, 1).toDouble();
    if (normalized >= 1 || construction.isEmpty) return null;
    return construction.firstWhere(
      (ConstructionArtStage stage) => normalized <= stage.maxCompletion,
      orElse: () => construction.last,
    );
  }
}

final class CraftingArtCatalog {
  const CraftingArtCatalog({required this.entries});

  static const CraftingArtCatalog empty = CraftingArtCatalog(
    entries: <CraftingArtEntry>[],
  );

  factory CraftingArtCatalog.fromJson(Map<String, Object?> json) =>
      CraftingArtCatalog(
        entries: (json['recipes']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(CraftingArtEntry.fromJson)
            .toList(growable: false),
      );

  final List<CraftingArtEntry> entries;

  CraftingArtEntry entryForRecipe(String recipeId) => entries.firstWhere(
    (CraftingArtEntry entry) => entry.recipeId == recipeId,
    orElse: () => throw StateError(
      'Missing crafting art catalog entry for recipe $recipeId',
    ),
  );

  ConstructionArtStage? stageFor(String recipeId, double completion) =>
      entryForRecipe(recipeId).stageFor(completion);

  String? constructionAssetFor(String recipeId, double completion) =>
      stageFor(recipeId, completion)?.assetPath;

  void validateRecipes(List<RecipeDefinition> recipes) {
    final recipeIds = recipes
        .map((RecipeDefinition recipe) => recipe.id)
        .toSet();
    final entryIds = entries
        .map((CraftingArtEntry entry) => entry.recipeId)
        .toSet();
    if (entryIds.length != entries.length ||
        recipeIds.difference(entryIds).isNotEmpty ||
        entryIds.difference(recipeIds).isNotEmpty) {
      throw FormatException(
        'Crafting art catalog must cover every recipe exactly once.',
      );
    }
    for (final entry in entries) {
      if (entry.construction.length != 3) {
        throw FormatException(
          '${entry.recipeId} must define exactly three construction stages.',
        );
      }
      var previousMax = -1.0;
      var previousRepresentative = -1.0;
      final names = <String>{};
      final paths = <String>{};
      for (final stage in entry.construction) {
        if (!names.add(stage.stage) || !paths.add(stage.assetPath)) {
          throw FormatException(
            '${entry.recipeId} construction stages must be distinct.',
          );
        }
        if (stage.maxCompletion <= previousMax ||
            stage.maxCompletion >= 1 ||
            stage.representativeCompletion <= previousRepresentative ||
            stage.representativeCompletion > stage.maxCompletion) {
          throw FormatException(
            '${entry.recipeId} construction completion thresholds are invalid.',
          );
        }
        previousMax = stage.maxCompletion;
        previousRepresentative = stage.representativeCompletion;
      }
      if (!names.containsAll(const <String>{'foundation', 'frame', 'finish'})) {
        throw FormatException(
          '${entry.recipeId} must use foundation, frame, and finish stages.',
        );
      }
    }
  }
}
