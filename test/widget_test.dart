import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_card.dart';

void main() {
  testWidgets('basic Flutter smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Locus'))),
    );
    expect(find.text('Locus'), findsOneWidget);
  });

  testWidgets('pixel card provides Material for list tile ink', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PixelCard(
            child: SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('주변까지 함께 수집'),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('주변까지 함께 수집'), findsOneWidget);
  });
}
