import 'package:reality_diorama/src/domain/entities.dart';

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

  Set<GridCell> occupiedCells({
    required Placement placement,
    required Footprint footprint,
  }) {
    final rotated = placement.rotation.isOdd;
    final width = rotated ? footprint.height : footprint.width;
    final height = rotated ? footprint.width : footprint.height;
    return <GridCell>{
      for (var dx = 0; dx < width; dx += 1)
        for (var dy = 0; dy < height; dy += 1)
          GridCell(placement.column + dx, placement.row + dy),
    };
  }

  PlacementValidation validate({
    required Placement candidate,
    required RecipeDefinition recipe,
    required List<Placement> existing,
    required Map<String, RecipeDefinition> recipeByObjectId,
  }) {
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
}
