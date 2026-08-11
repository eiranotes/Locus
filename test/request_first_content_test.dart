import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';

void main() {
  Map<String, Object?> read(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

  final visitorDocument = read('assets/content/visitors.json');
  final recipeDocument = read('assets/content/recipes.json');
  final axisDocument = read('assets/content/sense_axes.json');
  final requestDocument = read('assets/content/request_templates.json');
  final relationshipDocument = read('assets/content/relationship_tracks.json');
  final sceneDocument = read('assets/content/scene_objects.json');

  final visitorIds = (visitorDocument['visitors']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map((Map<String, Object?> value) => value['id']! as String)
      .toSet();
  final recipeIds = (recipeDocument['recipes']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map((Map<String, Object?> value) => value['id']! as String)
      .toSet();
  final axes = (axisDocument['axes']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(SenseAxisDefinition.fromJson)
      .toList(growable: false);
  final templates = (requestDocument['templates']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(RequestTemplateDefinition.fromJson)
      .toList(growable: false);
  final tracks = (relationshipDocument['tracks']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(RelationshipTrackDefinition.fromJson)
      .toList(growable: false);
  final sceneObjects = (sceneDocument['objects']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(SceneObjectDefinition.fromJson)
      .toList(growable: false);

  test('request-first content references shipping visitors and scene art', () {
    expect(templates.length, greaterThanOrEqualTo(12));
    expect(tracks, hasLength(3));
    expect(sceneObjects.length, greaterThanOrEqualTo(4));
    for (final template in templates) {
      expect(template.visitorIds, isNotEmpty);
      expect(template.visitorIds.every(visitorIds.contains), isTrue);
      expect(template.constraints, isNotEmpty);
    }
    for (final track in tracks) {
      expect(visitorIds, contains(track.visitorId));
      expect(
        track.milestones.map((value) => value.fulfilledCount).toList(),
        orderedEquals(<int>[1, 3, 6, 10]),
      );
    }
    for (final object in sceneObjects) {
      expect(recipeIds, contains(object.legacyRecipeId));
    }
  });

  test('only initial axes are required by stage-zero templates', () {
    final initiallyUnlocked = axes
        .where((SenseAxisDefinition value) => value.initiallyUnlocked)
        .map((SenseAxisDefinition value) => value.axis)
        .toSet();
    expect(initiallyUnlocked, <SenseAxis>{
      SenseAxis.loudness,
      SenseAxis.intermittency,
      SenseAxis.timeBand,
    });
    for (final template in templates.where(
      (RequestTemplateDefinition value) => value.minimumRelationshipStage == 0,
    )) {
      expect(initiallyUnlocked.containsAll(template.requiredAxes), isTrue);
    }
  });

  test('content identifiers are unique', () {
    expect(
      templates.map((RequestTemplateDefinition value) => value.id).toSet(),
      hasLength(templates.length),
    );
    expect(
      tracks
          .map((RelationshipTrackDefinition value) => value.visitorId)
          .toSet(),
      hasLength(tracks.length),
    );
    expect(
      sceneObjects.map((SceneObjectDefinition value) => value.id).toSet(),
      hasLength(sceneObjects.length),
    );
  });
}
