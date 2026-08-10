import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:reality_diorama/main.dart' as app;
import 'package:reality_diorama/src/data/database.dart';
import 'package:reality_diorama/src/data/game_repository.dart';
import 'package:reality_diorama/src/diorama/diorama_geometry.dart';
import 'package:reality_diorama/src/diorama/diorama_view.dart';
import 'package:reality_diorama/src/domain/engines/collection_pattern_engine.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/ui/widgets/pixel_pattern_mark.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('schema v2 migrates and restores collected patterns', (
    WidgetTester tester,
  ) async {
    final databasePath = p.join(
      await getDatabasesPath(),
      AppDatabase.demoDatabaseName,
    );
    await deleteDatabase(databasePath);
    final initial = await AppDatabase.open(demoMode: true);
    await initial.database.execute('DROP TABLE collected_patterns');
    await initial.database.execute('PRAGMA user_version = 2');
    await initial.close();

    final capturedAt = DateTime.utc(2026, 8, 10, 12);
    const recordId = 'migration-capture';
    final upgraded = await AppDatabase.open(demoMode: true);
    final repository = GameRepository(upgraded);
    final record = CaptureRecord(
      id: recordId,
      capturedAt: capturedAt,
      timeBand: TimeBand.afternoon,
      season: Season.summer,
      weatherBasis: WeatherBasis.providerCurrentModel,
      sourceVersion: 'migration-test',
      weatherMaterialId: 'migration-weather',
    );
    final weather = WeatherMaterial(
      id: 'migration-weather',
      kind: WeatherMaterialKind.clear,
      timeBand: TimeBand.afternoon,
      season: Season.summer,
      capturedAt: capturedAt,
      sourceRecordId: recordId,
      visualSeed: 1,
      providerName: 'Migration Test',
    );
    final patterns = const CollectionPatternEngine().derive(
      sourceRecordId: recordId,
      capturedAt: capturedAt,
      timeBand: TimeBand.afternoon,
      season: Season.summer,
      weatherKind: WeatherMaterialKind.clear,
      weatherSnapshot: WeatherSnapshot(
        temperatureCelsius: 24,
        apparentTemperatureCelsius: 25,
        precipitationRateMmPerHour: 0,
        cloudCoverPercent: 12,
        windSpeedKph: 8,
        visibilityMeters: 12000,
        weatherCode: 0,
        observedAt: capturedAt,
        basis: WeatherBasis.providerCurrentModel,
        providerName: 'Migration Test',
      ),
    );
    await repository.saveCapture(
      record: record,
      weather: weather,
      patterns: patterns,
    );
    expect(await repository.loadCollectedPatterns(), hasLength(10));
    await upgraded.close();

    final reopened = await AppDatabase.open(demoMode: true);
    expect(
      await GameRepository(reopened).loadCollectedPatterns(),
      hasLength(10),
    );
    await reopened.close();
    await deleteDatabase(databasePath);
  });

  testWidgets('deterministic demo core loop and UI screenshot tour', (
    WidgetTester tester,
  ) async {
    final databasePath = p.join(
      await getDatabasesPath(),
      AppDatabase.demoDatabaseName,
    );
    await deleteDatabase(databasePath);
    await _seedCaptureHistory();

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
    await tester.ensureVisible(find.text('동시 조합'));
    await _waitForUi(tester);
    expect(find.text('개별 패턴'), findsOneWidget);
    expect(find.text('장면 조합'), findsOneWidget);
    expect(find.byType(PixelPatternStamp), findsOneWidget);
    expect(find.byType(PixelWeaveMark), findsNWidgets(2));
    await binding.takeScreenshot('03b-capture-patterns');

    await tester.tap(find.text('이 재료로 만들기'));
    await _waitForUi(tester);
    expect(find.text('만들기'), findsWidgets);
    await binding.takeScreenshot('04-crafting-list');

    await tester.tap(find.text('골목등').first);
    await _waitForUi(tester);
    expect(find.text('날씨 재료'), findsOneWidget);
    await binding.takeScreenshot('05-crafting-detail');

    final makeButton = find.textContaining(RegExp(r'^(만들기|공사 시작)$'));
    expect(makeButton, findsOneWidget);
    await tester.ensureVisible(makeButton);
    await _waitForUi(tester);
    await tester.tap(makeButton);
    await _waitForUi(tester, seconds: 2);
    expect(find.text('물건 완성'), findsOneWidget);
    await binding.takeScreenshot('06-crafting-complete');
    await tester.tap(find.text('내 공간 보기'));
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
    final board = find.byType(DioramaView);
    final boardSize = tester.getSize(board);
    final boardTopLeft = tester.getTopLeft(board);
    final from =
        boardTopLeft +
        DioramaGeometry.logicalToLocal(
          DioramaGeometry.tileTop(0, 0),
          boardSize,
        );
    final to =
        boardTopLeft +
        DioramaGeometry.logicalToLocal(
          DioramaGeometry.tileTop(1, 0),
          boardSize,
        );
    await tester.dragFrom(from, to - from);
    await _waitForUi(tester, seconds: 2);
    expect(
      tester.widget<DioramaView>(board).snapshot.placements.single.column,
      1,
    );
    await binding.takeScreenshot('07-placement');
    await tester.tap(find.text('완료'));
    await _waitForUi(tester);

    await tester.tap(find.text('보관함'));
    await _waitForUi(tester);
    expect(find.widgetWithText(Tab, '기록'), findsOneWidget);
    expect(find.text('31개 기록'), findsOneWidget);
    await binding.takeScreenshot('08-inventory-records');
    await tester.fling(
      find.byType(CustomScrollView).last,
      const Offset(0, -5000),
      1500,
    );
    await _waitForUi(tester);
    expect(
      find.byKey(const ValueKey<String>('load-more-captures')),
      findsOneWidget,
    );
    expect(find.text('24 / 31개 불러옴'), findsOneWidget);
    await binding.takeScreenshot('08b-inventory-records-more');
    await tester.tap(find.byKey(const ValueKey<String>('load-more-captures')));
    await _waitForUi(tester, seconds: 2);
    expect(
      find.byKey(const ValueKey<String>('load-more-captures')),
      findsNothing,
    );
    await binding.takeScreenshot('08c-inventory-records-complete');

    await tester.tap(find.widgetWithText(Tab, '재료'));
    await _waitForUi(tester);
    await binding.takeScreenshot('09-inventory-materials');

    await tester.tap(find.widgetWithText(Tab, '패턴'));
    await _waitForUi(tester);
    expect(find.text('개별 패턴'), findsOneWidget);
    expect(find.text('시간과 계절'), findsOneWidget);
    expect(find.text('날씨'), findsOneWidget);
    expect(find.text('주변'), findsOneWidget);
    expect(find.text('동시 조합'), findsOneWidget);
    expect(find.byType(PatternFamilyMark), findsNWidgets(3));
    expect(find.byType(PixelCaret), findsNWidgets(3));
    await binding.takeScreenshot('09b-inventory-patterns-individual');
    await tester.tap(find.widgetWithText(ExpansionTile, '날씨'));
    await _waitForUi(tester);
    expect(find.text('가득 찬 구름'), findsOneWidget);
    await binding.takeScreenshot('09bb-inventory-patterns-weather-expanded');
    await tester.tap(find.widgetWithText(ExpansionTile, '날씨'));
    await _waitForUi(tester);
    await tester.scrollUntilVisible(
      find.text('장면 조합'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await _waitForUi(tester);
    expect(find.text('장면 조합'), findsOneWidget);
    await binding.takeScreenshot('09c-inventory-patterns-combinations');

    await tester.tap(find.widgetWithText(Tab, '만든 것'));
    await _waitForUi(tester);
    await binding.takeScreenshot('10-inventory-objects');

    await tester.tap(find.text('도감'));
    await _waitForUi(tester);
    expect(find.widgetWithText(Tab, '방문자'), findsOneWidget);
    await binding.takeScreenshot('11-codex-visitors');
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -1050),
    );
    await _waitForUi(tester);
    await binding.takeScreenshot('11b-codex-visitors-expanded');

    await tester.tap(find.widgetWithText(Tab, '만든 것'));
    await _waitForUi(tester);
    await binding.takeScreenshot('12-codex-objects');
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -1050),
    );
    await _waitForUi(tester);
    await binding.takeScreenshot('12b-codex-objects-expanded');

    await tester.tap(find.widgetWithText(Tab, '만드는 법'));
    await _waitForUi(tester);
    await binding.takeScreenshot('13-codex-recipes');
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -1050),
    );
    await _waitForUi(tester);
    await binding.takeScreenshot('13b-codex-recipes-expanded');

    await tester.tap(find.text('내 공간').last);
    await _waitForUi(tester);
    await tester.tap(find.byTooltip('설정'));
    await _waitForUi(tester);
    expect(find.text('설정'), findsOneWidget);
    await binding.takeScreenshot('14-settings');
  });
}

Future<void> _seedCaptureHistory() async {
  final database = await AppDatabase.open(demoMode: true);
  final repository = GameRepository(database);
  final baseTime = DateTime.utc(2026, 7, 1, 12);
  for (var index = 0; index < 30; index += 1) {
    final recordId = 'history-$index';
    final surroundingsId = 'history-surroundings-$index';
    final capturedAt = baseTime.add(Duration(minutes: index));
    final surroundingsKind = SurroundingMaterialKind
        .values[index % SurroundingMaterialKind.values.length];
    await repository.saveCapture(
      record: CaptureRecord(
        id: recordId,
        capturedAt: capturedAt,
        timeBand: TimeBand.afternoon,
        season: Season.summer,
        weatherBasis: WeatherBasis.providerCurrentModel,
        sourceVersion: 'pagination-fixture-v1',
        userPlaceLabel: '지난 기록 ${index + 1}',
        surroundingMaterialId: surroundingsId,
      ),
      surroundings: SurroundingMaterial(
        id: surroundingsId,
        kind: surroundingsKind,
        confidence: 0.72,
        capturedAt: capturedAt,
        sourceRecordId: recordId,
        featureSchemaVersion: 'pagination-fixture-v1',
      ),
    );
  }
  await database.close();
}

Future<void> _waitForUi(WidgetTester tester, {int seconds = 1}) async {
  await tester.pump();
  await tester.pump(Duration(seconds: seconds));
  await tester.pump(const Duration(milliseconds: 250));
}
