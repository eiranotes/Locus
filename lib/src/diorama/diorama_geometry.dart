import 'dart:math' as math;
import 'dart:ui';

import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';

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

  /// The front-most point of a rotated footprint where a normalized sprite's
  /// bottom-center pixel touches the isometric platform.
  ///
  /// Placement persistence continues to store the footprint's top-left anchor
  /// cell. Rendering uses this derived point so 1x1 and multi-cell art share
  /// the exact same grid contract.
  static Offset placementGroundAnchor(
    Placement placement,
    Footprint footprint,
  ) {
    final rotated = normalizeQuarterTurns(placement.rotation).isOdd;
    final width = rotated ? footprint.height : footprint.width;
    final height = rotated ? footprint.width : footprint.height;
    final frontCell = GridCell(
      placement.column + width - 1,
      placement.row + height - 1,
    );
    return tileTop(
      frontCell.column.toDouble(),
      frontCell.row.toDouble(),
    ).translate(0, tileHeight / 2);
  }

  /// Inverse projection used when a catalog sprite's ground point is directly
  /// under the pointer. The result is always the persisted anchor cell.
  static GridCell nearestPlacementAnchor(
    Offset groundAnchor, {
    required Footprint footprint,
    required int rotation,
  }) {
    final rotated = normalizeQuarterTurns(rotation).isOdd;
    final width = rotated ? footprint.height : footprint.width;
    final height = rotated ? footprint.width : footprint.height;
    final frontOffset =
        tileTop((width - 1).toDouble(), (height - 1).toDouble()) -
        tileTop(0, 0) +
        const Offset(0, tileHeight / 2);
    return nearestCell(groundAnchor - frontOffset);
  }

  /// Shared painter and hit-test order for overlapping isometric sprites.
  static int comparePlacementPaintOrder(Placement a, Placement b) {
    final depth = (a.column + a.row).compareTo(b.column + b.row);
    if (depth != 0) return depth;
    final row = a.row.compareTo(b.row);
    if (row != 0) return row;
    final column = a.column.compareTo(b.column);
    if (column != 0) return column;
    return a.craftedObjectId.compareTo(b.craftedObjectId);
  }

  /// Returns one mutable order shared by painting and hit testing.
  static List<Placement> orderedPlacements(
    Iterable<Placement> placements, {
    String? selectedObjectId,
    Footprint? Function(Placement placement)? footprintFor,
  }) {
    final ordered = placements.toList(growable: true)
      ..sort((Placement a, Placement b) {
        final aFootprint = footprintFor?.call(a);
        final bFootprint = footprintFor?.call(b);
        if (aFootprint != null && bFootprint != null) {
          final aAnchor = placementGroundAnchor(a, aFootprint);
          final bAnchor = placementGroundAnchor(b, bFootprint);
          final depth = aAnchor.dy.compareTo(bAnchor.dy);
          if (depth != 0) return depth;
          final horizontal = aAnchor.dx.compareTo(bAnchor.dx);
          if (horizontal != 0) return horizontal;
        }
        return comparePlacementPaintOrder(a, b);
      });
    if (selectedObjectId == null) return ordered;
    final index = ordered.indexWhere(
      (Placement value) => value.craftedObjectId == selectedObjectId,
    );
    if (index >= 0 && index != ordered.length - 1) {
      ordered.add(ordered.removeAt(index));
    }
    return ordered;
  }

  static bool contains(GridCell cell, {int columns = 5, int rows = 5}) =>
      cell.column >= 0 &&
      cell.row >= 0 &&
      cell.column < columns &&
      cell.row < rows;
}
