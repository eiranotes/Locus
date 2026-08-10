import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
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

  test('active precipitation spreads diagonally from one anchor', () {
    final traitCatalog = AtmosphericTraitCatalog.fromJson(
      jsonDecode(
            File('assets/content/atmospheric_traits.json').readAsStringSync(),
          )
          as Map<String, Object?>,
    );
    final recipe = testRecipe();
    final object = testObject(
      weatherKind: WeatherMaterialKind.rain,
      focusTrait: AtmosphericTrait.activePrecipitation,
    );
    final grid =
        EnvironmentGridBuilder(
          columns: 5,
          rows: 5,
          atmosphericTraits: traitCatalog,
        ).build(
          placements: const <Placement>[
            Placement(
              id: 'rain-placement',
              craftedObjectId: 'object-1',
              column: 1,
              row: 1,
              rotation: 0,
            ),
          ],
          objectsById: <String, CraftedObject>{object.id: object},
          recipesById: <String, RecipeDefinition>{recipe.id: recipe},
        );

    expect(grid.at(0, 0).wet, 1);
    expect(grid.at(2, 0).wet, 1);
    expect(grid.at(0, 2).wet, 1);
    expect(grid.at(2, 2).wet, 1);
    expect(grid.at(3, 1).wet, 0);
  });

  test('strong-wind focus extends a sparse connection by one cell', () {
    final traitCatalog = AtmosphericTraitCatalog.fromJson(
      jsonDecode(
            File('assets/content/atmospheric_traits.json').readAsStringSync(),
          )
          as Map<String, Object?>,
    );
    final focused = testObject(
      id: 'wind-a',
      surroundingKind: SurroundingMaterialKind.sparse,
      focusTrait: AtmosphericTrait.strongWind,
    );
    final other = testObject(
      id: 'wind-b',
      surroundingKind: SurroundingMaterialKind.sparse,
    );
    final graph = ConnectionGraphBuilder(atmosphericTraits: traitCatalog).build(
      placements: const <Placement>[
        Placement(
          id: 'wind-pa',
          craftedObjectId: 'wind-a',
          column: 1,
          row: 1,
          rotation: 0,
        ),
        Placement(
          id: 'wind-pb',
          craftedObjectId: 'wind-b',
          column: 2,
          row: 1,
          rotation: 0,
        ),
      ],
      objectsById: <String, CraftedObject>{
        focused.id: focused,
        other.id: other,
      },
    );

    expect(graph.countMode(ConnectionMode.far), 1);
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

  test('visitor requirements expose Korean labels instead of internal ids', () {
    final recipe = testRecipe(
      id: 'fountain',
      kind: ObjectKind.fountain,
      tags: const <String>{'stay'},
    );
    final object = testObject(
      id: 'fountain-object',
      recipeId: recipe.id,
      kind: ObjectKind.fountain,
    );
    const placement = Placement(
      id: 'fountain-placement',
      craftedObjectId: 'fountain-object',
      column: 1,
      row: 1,
      rotation: 0,
    );
    final visitor = VisitorDefinition(
      id: 'localized-visitor',
      nameKo: '표시 테스트',
      descriptionKo: '테스트',
      hintsKo: const <String>[],
      requirements: const <VisitorRequirement>[
        VisitorRequirement(kind: 'objectKind', anyOf: <String>['fountain']),
        VisitorRequirement(kind: 'objectTag', anyOf: <String>['stay']),
        VisitorRequirement(kind: 'timeBand', anyOf: <String>['night']),
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
        graph: const ConnectionGraph(edges: <ConnectionEdge>[]),
        placements: const <Placement>[placement],
        objectsById: <String, CraftedObject>{object.id: object},
        recipesById: <String, RecipeDefinition>{recipe.id: recipe},
        timeBand: TimeBand.afternoon,
        weatherKind: WeatherMaterialKind.rain,
      ),
    );

    expect(result.progress.map((item) => item.target), <String>[
      '작은 분수',
      '머무름',
      '밤',
      '맑음',
    ]);
  });
}
