import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all collection recipes have a reachable deterministic unlock path', () {
    final recipeDocument =
        jsonDecode(File('assets/content/recipes.json').readAsStringSync())
            as Map<String, Object?>;
    final visitorDocument =
        jsonDecode(File('assets/content/visitors.json').readAsStringSync())
            as Map<String, Object?>;
    final recipes = (recipeDocument['recipes']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final visitors = (visitorDocument['visitors']! as List<Object?>)
        .cast<Map<String, Object?>>();

    expect(recipes, hasLength(28));
    expect(visitors, hasLength(18));
    expect(
      visitors.every(
        (visitor) => (visitor['requirements']! as List<Object?>).length <= 3,
      ),
      isTrue,
    );

    final recipeById = <String, Map<String, Object?>>{
      for (final recipe in recipes) recipe['id']! as String: recipe,
    };
    final reachable = <String>{
      for (final recipe in recipes)
        if (recipe['initiallyUnlocked']! as bool) recipe['id']! as String,
    };

    bool requirementsReachable(Map<String, Object?> visitor) {
      final available = reachable.map((id) => recipeById[id]!).toList();
      for (final requirement
          in (visitor['requirements']! as List<Object?>)
              .cast<Map<String, Object?>>()) {
        final kind = requirement['kind']! as String;
        if (kind == 'objectKind') {
          final kinds = (requirement['anyOf']! as List<Object?>).cast<String>();
          if (!available.any((recipe) => kinds.contains(recipe['kind']))) {
            return false;
          }
        }
        if (kind == 'objectTag' || kind == 'taggedObjects') {
          final tags = kind == 'objectTag'
              ? (requirement['anyOf']! as List<Object?>).cast<String>()
              : <String>[requirement['tag']! as String];
          if (!available.any(
            (recipe) => tags.any(
              (tag) => (recipe['tags']! as List<Object?>).contains(tag),
            ),
          )) {
            return false;
          }
        }
      }
      return true;
    }

    var changed = true;
    while (changed) {
      changed = false;
      for (final visitor in visitors) {
        final reward = visitor['reward']! as Map<String, Object?>;
        if (reward['kind'] != 'recipe' || !requirementsReachable(visitor)) {
          continue;
        }
        changed = reachable.add(reward['value']! as String) || changed;
      }
    }

    expect(reachable, recipeById.keys.toSet());
    final rewarded = <String>{
      for (final visitor in visitors)
        if ((visitor['reward']! as Map<String, Object?>)['kind'] == 'recipe')
          (visitor['reward']! as Map<String, Object?>)['value']! as String,
    };
    expect(
      recipes
          .where((recipe) => !(recipe['initiallyUnlocked']! as bool))
          .every((recipe) => rewarded.contains(recipe['id'])),
      isTrue,
    );
  });
}
