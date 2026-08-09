import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/app/theme.dart';
import 'package:reality_diorama/src/ui/widgets/placement_direction_pad.dart';

void main() {
  testWidgets('direction pad keeps 44pt targets and disables invalid moves', (
    WidgetTester tester,
  ) async {
    final moves = <(int, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PlacementDirectionPad(
            canLeft: false,
            canUp: true,
            canDown: true,
            canRight: false,
            onMove: (int dx, int dy) => moves.add((dx, dy)),
          ),
        ),
      ),
    );

    for (final key in <String>[
      'move-left',
      'move-up',
      'move-down',
      'move-right',
    ]) {
      final size = tester.getSize(find.byKey(ValueKey<String>(key)));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('move-left')),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('move-right')),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey<String>('move-up')));
    await tester.tap(find.byKey(const ValueKey<String>('move-down')));
    expect(moves, <(int, int)>[(0, -1), (0, 1)]);
  });
}
