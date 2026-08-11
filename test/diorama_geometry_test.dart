import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/diorama_geometry.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';

void main() {
  test('isometric cell centers round-trip through the drag projection', () {
    for (var column = 0; column < 5; column += 1) {
      for (var row = 0; row < 5; row += 1) {
        final logical = DioramaGeometry.tileTop(
          column.toDouble(),
          row.toDouble(),
        );
        expect(DioramaGeometry.nearestCell(logical), GridCell(column, row));
      }
    }
  });

  test('letterboxed viewport conversion preserves the logical drag point', () {
    const viewport = Size(430, 360);
    const logical = Offset(206, 167);
    final local = DioramaGeometry.logicalToLocal(logical, viewport);

    expect(
      DioramaGeometry.localToLogical(local, viewport).dx,
      closeTo(206, .01),
    );
    expect(
      DioramaGeometry.localToLogical(local, viewport).dy,
      closeTo(167, .01),
    );
  });

  test('sprite ground point is fixed to the front vertex of its footprint', () {
    const oneCell = Footprint(width: 1, height: 1);
    const twoRows = Footprint(width: 1, height: 2);
    const placement = Placement(
      id: 'placed',
      craftedObjectId: 'object',
      column: 1,
      row: 2,
      rotation: 0,
    );

    expect(
      DioramaGeometry.placementGroundAnchor(placement, oneCell),
      DioramaGeometry.tileTop(
        1,
        2,
      ).translate(0, DioramaGeometry.tileHeight / 2),
    );
    expect(
      DioramaGeometry.placementGroundAnchor(placement, twoRows),
      DioramaGeometry.tileTop(
        1,
        3,
      ).translate(0, DioramaGeometry.tileHeight / 2),
    );
    expect(
      DioramaGeometry.placementGroundAnchor(
        placement.copyWith(rotation: 1),
        twoRows,
      ),
      DioramaGeometry.tileTop(
        2,
        2,
      ).translate(0, DioramaGeometry.tileHeight / 2),
    );
  });

  test('catalog ground point snaps back to the persisted anchor cell', () {
    const footprint = Footprint(width: 1, height: 2);
    for (final rotation in <int>[0, 1, 2, 3]) {
      const placement = Placement(
        id: 'placed',
        craftedObjectId: 'object',
        column: 2,
        row: 1,
        rotation: 0,
      );
      final rotatedPlacement = placement.copyWith(rotation: rotation);
      final ground = DioramaGeometry.placementGroundAnchor(
        rotatedPlacement,
        footprint,
      );

      expect(
        DioramaGeometry.nearestPlacementAnchor(
          ground,
          footprint: footprint,
          rotation: rotation,
        ),
        const GridCell(2, 1),
      );
    }
  });

  test('paint and hit-test order is stable for equal isometric depth', () {
    final source = <Placement>[
      const Placement(
        id: 'b',
        craftedObjectId: 'b',
        column: 2,
        row: 0,
        rotation: 0,
      ),
      const Placement(
        id: 'c',
        craftedObjectId: 'c',
        column: 0,
        row: 1,
        rotation: 0,
      ),
      const Placement(
        id: 'a',
        craftedObjectId: 'a',
        column: 1,
        row: 1,
        rotation: 0,
      ),
    ];
    final placements = DioramaGeometry.orderedPlacements(source);

    expect(placements.map((Placement value) => value.craftedObjectId), <String>[
      'c',
      'b',
      'a',
    ]);

    final selectedFirst = DioramaGeometry.orderedPlacements(
      List<Placement>.unmodifiable(source),
      selectedObjectId: 'c',
    );
    expect(
      selectedFirst.map((Placement value) => value.craftedObjectId),
      <String>['b', 'a', 'c'],
    );
  });

  test('multi-cell paint order follows the front-most occupied vertex', () {
    const long = Footprint(width: 1, height: 2);
    const single = Footprint(width: 1, height: 1);
    final placements = DioramaGeometry.orderedPlacements(
      const <Placement>[
        Placement(
          id: 'single',
          craftedObjectId: 'single',
          column: 1,
          row: 2,
          rotation: 0,
        ),
        Placement(
          id: 'long',
          craftedObjectId: 'long',
          column: 2,
          row: 0,
          rotation: 0,
        ),
      ],
      footprintFor: (Placement placement) =>
          placement.craftedObjectId == 'long' ? long : single,
    );

    expect(placements.map((Placement value) => value.craftedObjectId), <String>[
      'single',
      'long',
    ]);
  });
}
