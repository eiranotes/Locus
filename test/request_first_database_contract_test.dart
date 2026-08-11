import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('schema v5 contains the request-first atomic data model', () {
    final database = File('lib/src/data/database.dart').readAsStringSync();
    expect(database, contains('static const int schemaVersion = 5'));
    for (final table in <String>[
      'specimens',
      'visitor_requests',
      'specimen_matches',
      'specimen_assignments',
      'visitor_relationships',
      'relationship_events',
      'scene_objects',
      'scene_placements',
      'sense_profile',
    ]) {
      expect(database, contains('CREATE TABLE IF NOT EXISTS $table'));
    }
    expect(database, contains('specimen_id TEXT NOT NULL UNIQUE'));
    expect(database, contains('request_id TEXT NOT NULL UNIQUE'));
  });

  test('assignment repository validates stored match before mutation', () {
    final repository = File(
      'lib/src/data/request_first_repository.dart',
    ).readAsStringSync();
    expect(repository, contains('Future<void> assignSpecimen'));
    expect(repository, contains("'specimen_matches'"));
    expect(repository, contains('Stored specimen match does not satisfy'));
    expect(repository, contains("'specimen_assignments'"));
    expect(repository, contains("'visitor_relationships'"));
    expect(repository, contains("'relationship_events'"));
  });

  test('request-first keepsakes have a validated manual placement path', () {
    final actions = File(
      'lib/src/request_first/request_first_controller_actions.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/src/request_first/screens/request_first_placement_screen.dart',
    ).readAsStringSync();
    expect(actions, contains('validateScenePlacementCandidate'));
    expect(actions, contains('placeOrMoveSceneObject'));
    expect(actions, contains('storeSceneObject'));
    expect(actions, contains('PlacementEngine'));
    expect(screen, contains('PlacementDirectionPad'));
    expect(screen, contains('기념물 배치'));
  });
}
