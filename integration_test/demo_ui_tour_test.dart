import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:reality_diorama/main.dart' as app;
import 'package:reality_diorama/src/data/database.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deterministic demo core loop and UI screenshot tour', (
    WidgetTester tester,
  ) async {
    final databasePath = p.join(
      await getDatabasesPath(),
      AppDatabase.demoDatabaseName,
    );
    await deleteDatabase(databasePath);

    await app.main();
    await _waitForUi(tester, seconds: 4);
    expect(find.text('내 공간'), findsWidgets);
    await binding.takeScreenshot('01-home');

    await tester.tap(find.bySemanticsLabel('수집'));
    await _waitForUi(tester, seconds: 2);
    expect(find.text('지금 수집'), findsOneWidget);
    expect(find.text('수집 시작'), findsOneWidget);
    await binding.takeScreenshot('02-capture-ready');

    await tester.tap(find.text('수집 시작'));
    await _waitForUi(tester, seconds: 2);
    expect(find.text('수집 완료'), findsOneWidget);
    expect(find.text('이 재료로 만들기'), findsOneWidget);
    await binding.takeScreenshot('03-capture-result');

    await tester.tap(find.text('이 재료로 만들기'));
    await _waitForUi(tester);
    expect(find.text('만들기'), findsWidgets);
    await binding.takeScreenshot('04-crafting-list');

    await tester.tap(find.text('골목등').first);
    await _waitForUi(tester);
    expect(find.text('날씨 재료'), findsOneWidget);
    await binding.takeScreenshot('05-crafting-detail');

    final detailList = find.byType(ListView).last;
    await tester.drag(detailList, const Offset(0, -1200));
    await _waitForUi(tester);
    await tester.drag(detailList, const Offset(0, -1200));
    await _waitForUi(tester);
    final makeButton = find.textContaining(RegExp(r'^(만들기|공사 시작)$'));
    expect(makeButton, findsOneWidget);
    await tester.tap(makeButton);
    await _waitForUi(tester, seconds: 2);
    expect(find.text('물건 완성'), findsOneWidget);
    await binding.takeScreenshot('06-crafting-complete');
    await tester.tap(find.text('확인'));
    await _waitForUi(tester);

    if (find.text('새 방문자').evaluate().isNotEmpty) {
      await binding.takeScreenshot('06b-visitor-arrival');
      await tester.tap(find.text('계속 꾸미기'));
      await _waitForUi(tester);
    }

    expect(find.text('배치 편집'), findsOneWidget);
    await tester.tap(find.text('배치 편집'));
    await _waitForUi(tester);
    expect(find.text('배치 편집'), findsOneWidget);
    await binding.takeScreenshot('07-placement');
    await tester.tap(find.text('완료'));
    await _waitForUi(tester);

    await tester.tap(find.text('보관함'));
    await _waitForUi(tester);
    expect(find.widgetWithText(Tab, '기록'), findsOneWidget);
    await binding.takeScreenshot('08-inventory-records');

    await tester.tap(find.widgetWithText(Tab, '재료'));
    await _waitForUi(tester);
    await binding.takeScreenshot('09-inventory-materials');

    await tester.tap(find.widgetWithText(Tab, '만든 것'));
    await _waitForUi(tester);
    await binding.takeScreenshot('10-inventory-objects');

    await tester.tap(find.text('도감'));
    await _waitForUi(tester);
    expect(find.widgetWithText(Tab, '방문자'), findsOneWidget);
    await binding.takeScreenshot('11-codex-visitors');

    await tester.tap(find.widgetWithText(Tab, '만든 것'));
    await _waitForUi(tester);
    await binding.takeScreenshot('12-codex-objects');

    await tester.tap(find.widgetWithText(Tab, '만드는 법'));
    await _waitForUi(tester);
    await binding.takeScreenshot('13-codex-recipes');

    await tester.tap(find.text('내 공간').last);
    await _waitForUi(tester);
    await tester.tap(find.byTooltip('설정'));
    await _waitForUi(tester);
    expect(find.text('설정과 정보'), findsOneWidget);
    await binding.takeScreenshot('14-settings');
  });
}

Future<void> _waitForUi(WidgetTester tester, {int seconds = 1}) async {
  await tester.pump();
  await tester.pump(Duration(seconds: seconds));
  await tester.pump(const Duration(milliseconds: 250));
}
