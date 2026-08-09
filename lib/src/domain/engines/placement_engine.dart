import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';

class GridCell {
  const GridCell(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is GridCell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);
}

class PlacementValidation {
  const PlacementValidation({required this.valid, this.message});

  final bool valid;
  final String? message;
}

class PlacementEngine {
  const PlacementEngine({required this.columns, required this.rows});

  final int columns;
  final int rows;

  Footprint rotatedFootprint({
    required Footprint footprint,
    required int rotation,
  }) {
    final rotated = normalizeQuarterTurns(rotation).isOdd;
    return Footprint(
      width: rotated ? footprint.height : footprint.width,
      height: rotated ? footprint.width : footprint.height,
    );
  }

  Set<GridCell> occupiedCells({
    required Placement placement,
    required Footprint footprint,
  }) {
    final rotated = rotatedFootprint(
      footprint: footprint,
      rotation: placement.rotation,
    );
    return <GridCell>{
      for (var dx = 0; dx < rotated.width; dx += 1)
        for (var dy = 0; dy < rotated.height; dy += 1)
          GridCell(placement.column + dx, placement.row + dy),
    };
  }

  PlacementValidation validate({
    required Placement candidate,
    required RecipeDefinition recipe,
    required List<Placement> existing,
    required Map<String, RecipeDefinition> recipeByObjectId,
    Set<int> allowedRotations = const <int>{0, 1, 2, 3},
  }) {
    if (!allowedRotations.contains(normalizeQuarterTurns(candidate.rotation))) {
      return const PlacementValidation(
        valid: false,
        message: '이 물건이 지원하지 않는 방향입니다.',
      );
    }
    final cells = occupiedCells(
      placement: candidate,
      footprint: recipe.footprint,
    );
    if (cells.any(
      (GridCell cell) =>
          cell.column < 0 ||
          cell.row < 0 ||
          cell.column >= columns ||
          cell.row >= rows,
    )) {
      return const PlacementValidation(valid: false, message: '배치판 밖입니다.');
    }

    final occupied = <GridCell>{};
    for (final placement in existing) {
      if (placement.id == candidate.id) {
        continue;
      }
      final otherRecipe = recipeByObjectId[placement.craftedObjectId];
      if (otherRecipe == null) {
        continue;
      }
      occupied.addAll(
        occupiedCells(placement: placement, footprint: otherRecipe.footprint),
      );
    }

    if (cells.any(occupied.contains)) {
      return const PlacementValidation(valid: false, message: '다른 물건과 겹칩니다.');
    }
    return const PlacementValidation(valid: true);
  }

  Set<GridCell> validAnchors({
    required Placement candidate,
    required RecipeDefinition recipe,
    required List<Placement> existing,
    required Map<String, RecipeDefinition> recipeByObjectId,
    Set<int> allowedRotations = const <int>{0, 1, 2, 3},
  }) {
    return <GridCell>{
      for (var column = 0; column < columns; column += 1)
        for (var row = 0; row < rows; row += 1)
          if (validate(
            candidate: candidate.copyWith(column: column, row: row),
            recipe: recipe,
            existing: existing,
            recipeByObjectId: recipeByObjectId,
            allowedRotations: allowedRotations,
          ).valid)
            GridCell(column, row),
    };
  }

  GridCell? firstValidAnchor({
    required Placement candidate,
    required RecipeDefinition recipe,
    required List<Placement> existing,
    required Map<String, RecipeDefinition> recipeByObjectId,
    Set<int> allowedRotations = const <int>{0, 1, 2, 3},
  }) {
    final anchors = validAnchors(
      candidate: candidate,
      recipe: recipe,
      existing: existing,
      recipeByObjectId: recipeByObjectId,
      allowedRotations: allowedRotations,
    );
    for (var row = 0; row < rows; row += 1) {
      for (var column = 0; column < columns; column += 1) {
        final cell = GridCell(column, row);
        if (anchors.contains(cell)) return cell;
      }
    }
    return null;
  }
}
