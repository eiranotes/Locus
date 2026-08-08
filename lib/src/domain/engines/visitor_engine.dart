import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/connection_graph.dart';
import 'package:reality_diorama/src/domain/engines/environment_grid.dart';

class RequirementProgress {
  const RequirementProgress({
    required this.label,
    required this.current,
    required this.target,
    required this.satisfied,
  });

  final String label;
  final String current;
  final String target;
  final bool satisfied;
}

class VisitorEvaluation {
  const VisitorEvaluation({
    required this.visitor,
    required this.progress,
  });

  final VisitorDefinition visitor;
  final List<RequirementProgress> progress;

  bool get satisfied =>
      progress.isNotEmpty && progress.every((RequirementProgress item) => item.satisfied);

  int get satisfiedCount =>
      progress.where((RequirementProgress item) => item.satisfied).length;
}

class VisitorContext {
  const VisitorContext({
    required this.grid,
    required this.graph,
    required this.placements,
    required this.objectsById,
    required this.recipesById,
    required this.timeBand,
    required this.weatherKind,
  });

  final EnvironmentGrid grid;
  final ConnectionGraph graph;
  final List<Placement> placements;
  final Map<String, CraftedObject> objectsById;
  final Map<String, RecipeDefinition> recipesById;
  final TimeBand timeBand;
  final WeatherMaterialKind? weatherKind;

  Iterable<CraftedObject> get placedObjects sync* {
    for (final placement in placements) {
      final object = objectsById[placement.craftedObjectId];
      if (object != null && object.isComplete) {
        yield object;
      }
    }
  }
}

class VisitorEngine {
  const VisitorEngine();

  VisitorEvaluation evaluate(
    VisitorDefinition definition,
    VisitorContext context,
  ) {
    return VisitorEvaluation(
      visitor: definition,
      progress: definition.requirements
          .map(
            (VisitorRequirement requirement) =>
                _evaluateRequirement(requirement, context),
          )
          .toList(growable: false),
    );
  }

  RequirementProgress _evaluateRequirement(
    VisitorRequirement requirement,
    VisitorContext context,
  ) {
    final minimum = requirement.minimum ?? 1;
    switch (requirement.kind) {
      case 'wetCells':
        return _numeric(
          '젖은 칸',
          context.grid.countWhere((CellEffects cell) => cell.wet > 0),
          minimum,
        );
      case 'lightCells':
        return _numeric(
          '빛이 있는 칸',
          context.grid.countWhere((CellEffects cell) => cell.light > 0),
          minimum,
        );
      case 'warmCells':
        return _numeric(
          '따뜻한 칸',
          context.grid.countWhere((CellEffects cell) => cell.warm > 0),
          minimum,
        );
      case 'coolCells':
        return _numeric(
          '서늘한 칸',
          context.grid.countWhere((CellEffects cell) => cell.cool > 0),
          minimum,
        );
      case 'connectedLights':
        final count = context.placedObjects.where((CraftedObject object) {
          final recipe = context.recipesById[object.recipeId];
          return recipe?.tags.contains('light') == true &&
              context.graph.degree(object.id) > 0;
        }).length;
        return _numeric('연결된 불빛', count, minimum);
      case 'stableConnections':
        return _numeric(
          '유지되는 연결',
          context.graph.countMode(ConnectionMode.stable),
          minimum,
        );
      case 'farConnections':
        return _numeric(
          '먼 연결',
          context.graph.countMode(ConnectionMode.far),
          minimum,
        );
      case 'sequentialConnections':
        return _numeric(
          '순서 연결',
          context.graph.countMode(ConnectionMode.sequential),
          minimum,
        );
      case 'highObjects':
        final count = context.placedObjects.where((CraftedObject object) {
          return context.recipesById[object.recipeId]?.height == HeightBand.high;
        }).length;
        return _numeric('높은 물건', count, minimum);
      case 'quietZones':
        final count = context.placedObjects
            .where((CraftedObject object) => context.graph.degree(object.id) == 0)
            .length;
        return _numeric('조용한 구역', count, minimum);
      case 'taggedObjects':
        final tag = requirement.tag ?? '';
        final count = context.placedObjects.where((CraftedObject object) {
          return context.recipesById[object.recipeId]?.tags.contains(tag) == true;
        }).length;
        return _numeric('$tag 물건', count, minimum);
      case 'objectTag':
        final match = context.placedObjects.any((CraftedObject object) {
          final tags = context.recipesById[object.recipeId]?.tags ?? const <String>{};
          return requirement.anyOf.any(tags.contains);
        });
        return RequirementProgress(
          label: '필요한 종류의 물건',
          current: match ? '있음' : '없음',
          target: requirement.anyOf.join(' / '),
          satisfied: match,
        );
      case 'objectKind':
        final match = context.placedObjects.any(
          (CraftedObject object) => requirement.anyOf.contains(object.kind.name),
        );
        return RequirementProgress(
          label: '필요한 물건',
          current: match ? '있음' : '없음',
          target: requirement.anyOf.join(' / '),
          satisfied: match,
        );
      case 'timeBand':
        final satisfied = requirement.anyOf.contains(context.timeBand.name);
        return RequirementProgress(
          label: '시간대',
          current: context.timeBand.labelKo,
          target: requirement.anyOf.join(' / '),
          satisfied: satisfied,
        );
      case 'weatherKind':
        final weatherKind = context.weatherKind;
        final satisfied =
            weatherKind != null && requirement.anyOf.contains(weatherKind.name);
        return RequirementProgress(
          label: '현재 날씨',
          current: weatherKind?.labelKo ?? '확인할 수 없음',
          target: requirement.anyOf.join(' / '),
          satisfied: satisfied,
        );
      default:
        return RequirementProgress(
          label: requirement.kind,
          current: '지원하지 않음',
          target: '-',
          satisfied: false,
        );
    }
  }

  RequirementProgress _numeric(String label, int current, int target) =>
      RequirementProgress(
        label: label,
        current: '$current',
        target: '$target',
        satisfied: current >= target,
      );
}
