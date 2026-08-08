import 'dart:math' as math;

import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';

class CellEffects {
  const CellEffects({
    this.wet = 0,
    this.light = 0,
    this.warm = 0,
    this.cool = 0,
    this.wind = 0,
    this.nature = 0,
    this.height = HeightBand.low,
  });

  final int wet;
  final int light;
  final int warm;
  final int cool;
  final int wind;
  final int nature;
  final HeightBand height;

  CellEffects add({
    int wet = 0,
    int light = 0,
    int warm = 0,
    int cool = 0,
    int wind = 0,
    int nature = 0,
    HeightBand? height,
  }) => CellEffects(
    wet: this.wet + wet,
    light: this.light + light,
    warm: this.warm + warm,
    cool: this.cool + cool,
    wind: this.wind + wind,
    nature: this.nature + nature,
    height: height == null
        ? this.height
        : HeightBand.values[math.max(this.height.index, height.index)],
  );
}

class EnvironmentGrid {
  EnvironmentGrid({required this.columns, required this.rows})
    : _cells = List<CellEffects>.filled(
        columns * rows,
        const CellEffects(),
        growable: false,
      );

  final int columns;
  final int rows;
  final List<CellEffects> _cells;

  CellEffects at(int column, int row) => _cells[row * columns + column];

  void addAt(int column, int row, CellEffects effects) {
    if (column < 0 || row < 0 || column >= columns || row >= rows) {
      return;
    }
    final index = row * columns + column;
    _cells[index] = _cells[index].add(
      wet: effects.wet,
      light: effects.light,
      warm: effects.warm,
      cool: effects.cool,
      wind: effects.wind,
      nature: effects.nature,
      height: effects.height,
    );
  }

  int countWhere(bool Function(CellEffects effects) predicate) =>
      _cells.where(predicate).length;

  List<CellEffects> get cells => List<CellEffects>.unmodifiable(_cells);
}

class EnvironmentGridBuilder {
  const EnvironmentGridBuilder({required this.columns, required this.rows});

  final int columns;
  final int rows;

  EnvironmentGrid build({
    required List<Placement> placements,
    required Map<String, CraftedObject> objectsById,
    required Map<String, RecipeDefinition> recipesById,
  }) {
    final grid = EnvironmentGrid(columns: columns, rows: rows);
    final placementEngine = PlacementEngine(columns: columns, rows: rows);

    for (final placement in placements) {
      final object = objectsById[placement.craftedObjectId];
      if (object == null || !object.isComplete) {
        continue;
      }
      final recipe = recipesById[object.recipeId];
      if (recipe == null) {
        continue;
      }

      final occupied = placementEngine.occupiedCells(
        placement: placement,
        footprint: recipe.footprint,
      );
      final base = _baseEffects(recipe);
      final weather = _weatherEffects(object.weatherKind);

      for (final cell in occupied) {
        grid.addAt(cell.column, cell.row, base);
        grid.addAt(cell.column, cell.row, weather);
        for (final offset in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          grid.addAt(
            cell.column + offset.$1,
            cell.row + offset.$2,
            _attenuate(weather),
          );
        }
      }
    }
    return grid;
  }

  CellEffects _baseEffects(RecipeDefinition recipe) => CellEffects(
    wet: recipe.baseEffects['wet'] ?? 0,
    light: recipe.baseEffects['light'] ?? 0,
    warm: recipe.baseEffects['warm'] ?? 0,
    cool: recipe.baseEffects['cool'] ?? 0,
    wind: recipe.baseEffects['wind'] ?? 0,
    nature: recipe.baseEffects['nature'] ?? 0,
    height: recipe.height,
  );

  CellEffects _weatherEffects(WeatherMaterialKind kind) => switch (kind) {
    WeatherMaterialKind.clear => const CellEffects(light: 1, warm: 1),
    WeatherMaterialKind.rain => const CellEffects(wet: 1, cool: 1),
    WeatherMaterialKind.cloudy => const CellEffects(cool: 1),
    WeatherMaterialKind.windy => const CellEffects(wind: 1),
    WeatherMaterialKind.cold => const CellEffects(cool: 2),
    WeatherMaterialKind.warm => const CellEffects(warm: 2),
  };

  CellEffects _attenuate(CellEffects value) => CellEffects(
    wet: value.wet > 0 ? 1 : 0,
    light: value.light > 0 ? 1 : 0,
    warm: value.warm > 0 ? 1 : 0,
    cool: value.cool > 0 ? 1 : 0,
    wind: value.wind > 0 ? 1 : 0,
    nature: value.nature > 0 ? 1 : 0,
  );
}
