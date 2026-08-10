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

  group('visitor selection policy', () {
    final now = DateTime.utc(2026, 8, 10, 12);
    const cooldown = Duration(hours: 6);

    test('an unseen satisfied visitor outranks a repeat-ready visitor', () {
      final repeat = _evaluation('repeat', satisfied: true);
      final unseen = _evaluation('unseen', satisfied: true);
      final evaluations = <VisitorEvaluation>[repeat, unseen];
      final sightings = <VisitorSighting>[
        _visitorSighting('repeat', now.subtract(const Duration(hours: 8))),
      ];

      final policy = const VisitorSelectionPolicy();
      expect(
        policy
            .target(
              evaluations: evaluations,
              sightings: sightings,
              now: now,
              repeatCooldown: cooldown,
            )
            ?.visitor
            .id,
        'unseen',
      );
      expect(
        policy
            .arriving(
              evaluations: evaluations,
              sightings: sightings,
              now: now,
              repeatCooldown: cooldown,
            )
            ?.visitor
            .id,
        'unseen',
      );
    });

    test('the oldest eligible repeat gets the next scene memory', () {
      final recent = _evaluation('recent', satisfied: true);
      final oldest = _evaluation('oldest', satisfied: true);
      final evaluations = <VisitorEvaluation>[recent, oldest];
      final sightings = <VisitorSighting>[
        _visitorSighting('recent', now.subtract(const Duration(hours: 7))),
        _visitorSighting('oldest', now.subtract(const Duration(hours: 12))),
      ];

      final selected = const VisitorSelectionPolicy().arriving(
        evaluations: evaluations,
        sightings: sightings,
        now: now,
        repeatCooldown: cooldown,
      );

      expect(selected?.visitor.id, 'oldest');
    });

    test('a fully satisfied unseen goal outranks partial progress', () {
      final partial = _evaluation(
        'partial',
        satisfied: false,
        satisfiedCount: 2,
        total: 3,
      );
      final complete = _evaluation('complete', satisfied: true);

      final selected = const VisitorSelectionPolicy().target(
        evaluations: <VisitorEvaluation>[partial, complete],
        sightings: const <VisitorSighting>[],
        now: now,
        repeatCooldown: cooldown,
      );

      expect(selected?.visitor.id, 'complete');
    });
  });

  group('visitor progression policy', () {
    final lamp = testRecipe(
      id: 'lamp',
      kind: ObjectKind.alleyLamp,
      tags: const <String>{'light'},
    );
    final stop = testRecipe(
      id: 'stop',
      kind: ObjectKind.busStop,
      tags: const <String>{'stay', 'path'},
    );
    final visitor = VisitorDefinition(
      id: 'roof-bird',
      nameKo: '지붕 위 새',
      descriptionKo: '테스트',
      hintsKo: const <String>['정류장 지붕이 필요해요'],
      requirements: const <VisitorRequirement>[
        VisitorRequirement(kind: 'objectKind', anyOf: <String>['busStop']),
        VisitorRequirement(kind: 'weatherKind', anyOf: <String>['clear']),
      ],
      reward: const VisitorReward(
        kind: VisitorRewardKind.recipe,
        value: 'bridge',
      ),
    );

    test('locked object gates stay out of actionable visitor goals', () {
      const policy = VisitorProgressionPolicy();

      expect(policy.isActionable(visitor, <RecipeDefinition>[lamp]), isFalse);
      expect(
        policy
            .missingRecipeGate(visitor, <RecipeDefinition>[lamp], [lamp, stop])
            ?.id,
        'stop',
      );
    });

    test('unlocking the required recipe exposes the visitor', () {
      const policy = VisitorProgressionPolicy();
      final evaluation = _evaluation('roof-bird', satisfied: false);
      final gatedEvaluation = VisitorEvaluation(
        visitor: visitor,
        progress: evaluation.progress,
      );

      expect(
        policy.actionableEvaluations(
          evaluations: <VisitorEvaluation>[gatedEvaluation],
          unlockedRecipes: <RecipeDefinition>[lamp, stop],
        ),
        hasLength(1),
      );
    });

    test('an unknown object prerequisite fails closed', () {
      final invalidVisitor = VisitorDefinition(
        id: 'invalid',
        nameKo: '잘못된 방문자',
        descriptionKo: '테스트',
        hintsKo: const <String>['테스트'],
        requirements: const <VisitorRequirement>[
          VisitorRequirement(
            kind: 'objectKind',
            anyOf: <String>['missingKind'],
          ),
        ],
        reward: const VisitorReward(
          kind: VisitorRewardKind.effect,
          value: 'test',
        ),
      );

      expect(
        const VisitorProgressionPolicy().isActionable(
          invalidVisitor,
          <RecipeDefinition>[lamp, stop],
        ),
        isFalse,
      );
    });
  });
}

VisitorEvaluation _evaluation(
  String id, {
  required bool satisfied,
  int satisfiedCount = 1,
  int total = 1,
}) {
  final boundedSatisfiedCount = satisfied
      ? total
      : satisfiedCount.clamp(0, total - 1);
  return VisitorEvaluation(
    visitor: VisitorDefinition(
      id: id,
      nameKo: id,
      descriptionKo: '테스트',
      hintsKo: const <String>['테스트'],
      requirements: const <VisitorRequirement>[],
      reward: const VisitorReward(
        kind: VisitorRewardKind.effect,
        value: 'test',
      ),
    ),
    progress: List<RequirementProgress>.generate(
      total,
      (int index) => RequirementProgress(
        label: '조건 $index',
        current: index < boundedSatisfiedCount ? '1' : '0',
        target: '1',
        satisfied: index < boundedSatisfiedCount,
      ),
    ),
  );
}

VisitorSighting _visitorSighting(String id, DateTime lastSeenAt) =>
    VisitorSighting(
      id: 'sighting-$id',
      visitorId: id,
      firstSeenAt: lastSeenAt.subtract(const Duration(days: 1)),
      lastSeenAt: lastSeenAt,
      variantKey: 'test',
    );
