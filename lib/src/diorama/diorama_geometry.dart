import 'dart:math' as math;
import 'dart:ui';

import 'package:reality_diorama/src/domain/engines/placement_engine.dart';

abstract final class DioramaGeometry {
  static const double logicalSize = 360;
  static const double tileWidth = 52;
  static const double tileHeight = 26;
  static const Offset origin = Offset(180, 128);

  static Offset tileTop(double column, double row) => Offset(
    origin.dx + (column - row) * tileWidth / 2,
    origin.dy + (column + row) * tileHeight / 2,
  );

  static double scaleFor(Size viewport) =>
      math.min(viewport.width / logicalSize, viewport.height / logicalSize);

  static Offset viewportOffset(Size viewport) {
    final scale = scaleFor(viewport);
    return Offset(
      (viewport.width - logicalSize * scale) / 2,
      (viewport.height - logicalSize * scale) / 2,
    );
  }

  static Offset localToLogical(Offset local, Size viewport) {
    final scale = scaleFor(viewport);
    return (local - viewportOffset(viewport)) / scale;
  }

  static Offset logicalToLocal(Offset logical, Size viewport) =>
      viewportOffset(viewport) + logical * scaleFor(viewport);

  static GridCell nearestCell(Offset logical) {
    final projectedColumn = (logical.dx - origin.dx) / (tileWidth / 2);
    final projectedRow = (logical.dy - origin.dy) / (tileHeight / 2);
    return GridCell(
      ((projectedColumn + projectedRow) / 2).round(),
      ((projectedRow - projectedColumn) / 2).round(),
    );
  }

  static bool contains(GridCell cell, {int columns = 5, int rows = 5}) =>
      cell.column >= 0 &&
      cell.row >= 0 &&
      cell.column < columns &&
      cell.row < rows;
}
