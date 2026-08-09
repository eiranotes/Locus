import 'package:reality_diorama/src/domain/entities.dart';

/// Authoring-time contract for how a recipe appears and rotates in placement.
///
/// Recipes own gameplay data. This catalog owns editor-facing direction and
/// artwork variants so future objects can add bespoke directional sprites
/// without changing placement UI code.
final class PlacementCatalog {
  const PlacementCatalog({required this.directions, required this.entries});

  static const PlacementCatalog empty = PlacementCatalog(
    directions: <PlacementDirection>[],
    entries: <PlacementCatalogEntry>[],
  );

  final List<PlacementDirection> directions;
  final List<PlacementCatalogEntry> entries;

  PlacementCatalogEntry entryForRecipe(String recipeId) => entries.firstWhere(
    (PlacementCatalogEntry entry) => entry.recipeId == recipeId,
    orElse: () => throw StateError(
      'Missing placement catalog entry for recipe $recipeId',
    ),
  );

  PlacementDirection directionFor(int rotation) {
    final normalized = normalizeQuarterTurns(rotation);
    return directions.firstWhere(
      (PlacementDirection direction) => direction.rotation == normalized,
      orElse: () => throw StateError(
        'Missing placement direction for rotation $normalized',
      ),
    );
  }

  factory PlacementCatalog.fromJson(Map<String, Object?> json) {
    final catalog = PlacementCatalog(
      directions: (json['directions']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(PlacementDirection.fromJson)
          .toList(growable: false),
      entries: (json['entries']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(PlacementCatalogEntry.fromJson)
          .toList(growable: false),
    );
    catalog._validate();
    return catalog;
  }

  void validateRecipes(Iterable<RecipeDefinition> recipes) {
    final recipeIds = recipes
        .map((RecipeDefinition recipe) => recipe.id)
        .toSet();
    final entryIds = entries
        .map((PlacementCatalogEntry entry) => entry.recipeId)
        .toSet();
    if (recipeIds.length != entries.length ||
        recipeIds.difference(entryIds).isNotEmpty ||
        entryIds.difference(recipeIds).isNotEmpty) {
      throw FormatException(
        'Placement catalog must cover recipes exactly: '
        'missing=${recipeIds.difference(entryIds)}, '
        'extra=${entryIds.difference(recipeIds)}',
      );
    }
  }

  void _validate() {
    final rotations = directions
        .map((PlacementDirection direction) => direction.rotation)
        .toSet();
    if (directions.length != 4 ||
        !rotations.containsAll(const <int>{0, 1, 2, 3})) {
      throw const FormatException(
        'Placement catalog must define four unique quarter-turn directions',
      );
    }
    final entryIds = entries
        .map((PlacementCatalogEntry entry) => entry.recipeId)
        .toSet();
    if (entryIds.length != entries.length) {
      throw const FormatException('Duplicate placement catalog recipe id');
    }
    for (final entry in entries) {
      final entryRotations = entry.visuals
          .map((PlacementVisualVariant visual) => visual.rotation)
          .toSet();
      if (entry.visuals.length != 4 || !entryRotations.containsAll(rotations)) {
        throw FormatException(
          '${entry.recipeId} must define one visual for every direction',
        );
      }
    }
  }
}

final class PlacementCatalogEntry {
  const PlacementCatalogEntry({required this.recipeId, required this.visuals});

  final String recipeId;
  final List<PlacementVisualVariant> visuals;

  Set<int> get allowedRotations =>
      visuals.map((PlacementVisualVariant visual) => visual.rotation).toSet();

  PlacementVisualVariant visualFor(int rotation) {
    final normalized = normalizeQuarterTurns(rotation);
    return visuals.firstWhere(
      (PlacementVisualVariant visual) => visual.rotation == normalized,
      orElse: () => throw StateError(
        'Recipe $recipeId does not support rotation $normalized',
      ),
    );
  }

  int nextRotation(int current) {
    final rotations = allowedRotations.toList()..sort();
    final normalized = normalizeQuarterTurns(current);
    for (final rotation in rotations) {
      if (rotation > normalized) return rotation;
    }
    return rotations.first;
  }

  factory PlacementCatalogEntry.fromJson(Map<String, Object?> json) =>
      PlacementCatalogEntry(
        recipeId: json['recipeId']! as String,
        visuals: (json['visuals']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .map(PlacementVisualVariant.fromJson)
            .toList(growable: false),
      );
}

final class PlacementVisualVariant {
  const PlacementVisualVariant({
    required this.rotation,
    required this.assetPath,
    required this.mirrorX,
  });

  final int rotation;
  final String assetPath;
  final bool mirrorX;

  factory PlacementVisualVariant.fromJson(Map<String, Object?> json) =>
      PlacementVisualVariant(
        rotation: normalizeQuarterTurns(json['rotation']! as int),
        assetPath: json['assetPath']! as String,
        mirrorX: json['mirrorX'] as bool? ?? false,
      );
}

final class PlacementDirection {
  const PlacementDirection({
    required this.rotation,
    required this.labelKo,
    required this.shortLabelKo,
  });

  final int rotation;
  final String labelKo;
  final String shortLabelKo;

  factory PlacementDirection.fromJson(Map<String, Object?> json) =>
      PlacementDirection(
        rotation: normalizeQuarterTurns(json['rotation']! as int),
        labelKo: json['labelKo']! as String,
        shortLabelKo: json['shortLabelKo']! as String,
      );
}

int normalizeQuarterTurns(int rotation) => ((rotation % 4) + 4) % 4;
