import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/local_game_day.dart';

void main() {
  const gameDay = LocalGameDay(boundaryHour: 4);

  test('03:59 belongs to the previous local game day', () {
    expect(gameDay.keyFor(DateTime(2026, 8, 11, 3, 59)), '2026-08-10');
  });

  test('04:00 starts the new local game day', () {
    expect(gameDay.keyFor(DateTime(2026, 8, 11, 4)), '2026-08-11');
  });
}
