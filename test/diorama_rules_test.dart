import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/engines/connection_graph.dart';
import 'package:reality_diorama/src/domain/engines/environment_grid.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/domain/enums.dart';

import 'test_fixtures.dart';

void main() {
  test('rainy connected lamps satisfy the umbrella visitor rules', () {
    final recipe = testRecipe(
      id: 'lamp',
      effects: const <String, int>{'light': 1},
      tags: const <String>{'light'},
    );
    final first = testObject(id: 'first', recipeId: recipe.id);
    final second = testObject(id: 'second', recipeId: recipe.id);
    final objects = <String, CraftedObject>{first.id: first, second.id: second};
    final placements = <Placement>[
      const Placement(
        id: 'p1',
        craftedObjectId: 'first',
        column: 1,
        row: 1,
        rotation: 0,
      ),
      const Placement(
        id: 'p2',
        craftedObjectId: 'second',
        column: 2,
        row: 1,
        rotation: 0,
      ),
    ];
    final grid = const EnvironmentGridBuilder(columns: 5, rows: 5).build(
      placements: placements,
      objectsById: objects,
      recipesById: <String, RecipeDefinition>{recipe.id: recipe},
    );
    final graph = const ConnectionGraphBuilder().build(
      placements: placements,
      objectsById: objects,
    );
    final visitor = VisitorDefinition(
      id: 'umbrella',
      nameKo: '우산 산책자',
      descriptionKo: '테스트',
      hintsKo: const <String>[],
      requirements: const <VisitorRequirement>[
        VisitorRequirement(kind: 'wetCells', minimum: 3),
        VisitorRequirement(kind: 'connectedLights', minimum: 2),
        VisitorRequirement(
          kind: 'timeBand',
          anyOf: <String>['evening', 'night'],
        ),
      ],
      reward: const VisitorReward(
        kind: VisitorRewardKind.recipe,
        value: 'bus-stop',
      ),
    );
    final result = const VisitorEngine().evaluate(
      visitor,
      VisitorContext(
        grid: grid,
        graph: graph,
        placements: placements,
        objectsById: objects,
        recipesById: <String, RecipeDefinition>{recipe.id: recipe},
        timeBand: TimeBand.evening,
        weatherKind: WeatherMaterialKind.rain,
      ),
    );
    expect(
      grid.countWhere((CellEffects cell) => cell.wet > 0),
      greaterThanOrEqualTo(3),
    );
    expect(graph.degree(first.id), greaterThan(0));
    expect(result.satisfied, isTrue);
  });

  test('undirected connection keys do not collapse unrelated object ids', () {
    final recipe = testRecipe();
    CraftedObject object(String id) => testObject(
      id: id,
      recipeId: recipe.id,
      surroundingKind: SurroundingMaterialKind.dense,
    );
    final objects = <String, CraftedObject>{
      for (final id in <String>['a', 'b', 'c']) id: object(id),
    };
    final placements = <Placement>[
      const Placement(
        id: 'pa',
        craftedObjectId: 'a',
        column: 0,
        row: 0,
        rotation: 0,
      ),
      const Placement(
        id: 'pb',
        craftedObjectId: 'b',
        column: 1,
        row: 0,
        rotation: 0,
      ),
      const Placement(
        id: 'pc',
        craftedObjectId: 'c',
        column: 0,
        row: 1,
        rotation: 0,
      ),
    ];
    final graph = const ConnectionGraphBuilder().build(
      placements: placements,
      objectsById: objects,
    );
    expect(graph.edges.length, 3);
  });
  test(
    'weather requirements fail closed when current weather is unavailable',
    () {
      final recipe = testRecipe();
      final object = testObject(id: 'weather-object', recipeId: recipe.id);
      final placement = const Placement(
        id: 'weather-placement',
        craftedObjectId: 'weather-object',
        column: 1,
        row: 1,
        rotation: 0,
      );
      final visitor = VisitorDefinition(
        id: 'weather-visitor',
        nameKo: '날씨 방문자',
        descriptionKo: '테스트',
        hintsKo: const <String>[],
        requirements: const <VisitorRequirement>[
          VisitorRequirement(kind: 'weatherKind', anyOf: <String>['clear']),
        ],
        reward: const VisitorReward(
          kind: VisitorRewardKind.effect,
          value: 'test',
        ),
      );
      final result = const VisitorEngine().evaluate(
        visitor,
        VisitorContext(
          grid: EnvironmentGrid(columns: 5, rows: 5),
          graph: ConnectionGraph(edges: <ConnectionEdge>[]),
          placements: <Placement>[placement],
          objectsById: <String, CraftedObject>{'weather-object': object},
          recipesById: <String, RecipeDefinition>{'alley-lamp': recipe},
          timeBand: TimeBand.afternoon,
          weatherKind: null,
        ),
      );

      expect(result.satisfied, isFalse);
      expect(result.progress.single.current, '확인할 수 없음');
    },
  );
}
