import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/diorama/diorama_geometry.dart';
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
}
