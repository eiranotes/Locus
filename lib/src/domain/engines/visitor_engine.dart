import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';
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
  const VisitorEvaluation({required this.visitor, required this.progress});

  final VisitorDefinition visitor;
  final List<RequirementProgress> progress;

  bool get satisfied =>
      progress.isNotEmpty &&
      progress.every((RequirementProgress item) => item.satisfied);

  int get satisfiedCount =>
      progress.where((RequirementProgress item) => item.satisfied).length;
}

/// Keeps the visitor shown as the next goal aligned with the visitor that can
/// actually arrive. New visitors always outrank repeats; repeat candidates are
/// ordered by the oldest last visit so one catalog entry cannot monopolize the
/// scene after every cooldown.
class VisitorSelectionPolicy {
  const VisitorSelectionPolicy();

  VisitorEvaluation? target({
    required List<VisitorEvaluation> evaluations,
    required Iterable<VisitorSighting> sightings,
    required DateTime now,
    required Duration repeatCooldown,
  }) {
    if (evaluations.isEmpty) return null;
    final sightingsByVisitor = <String, VisitorSighting>{
      for (final sighting in sightings) sighting.visitorId: sighting,
    };
    final unseen = _orderedByProgress(
      evaluations
          .where(
            (VisitorEvaluation evaluation) =>
                !sightingsByVisitor.containsKey(evaluation.visitor.id),
          )
          .toList(growable: false),
      evaluations,
    );
    if (unseen.isNotEmpty) return unseen.first;

    final repeatReady =
        evaluations
            .where((VisitorEvaluation evaluation) {
              if (!evaluation.satisfied) return false;
              final previous = sightingsByVisitor[evaluation.visitor.id];
              return previous != null &&
                  now.difference(previous.lastSeenAt) >= repeatCooldown;
            })
            .toList(growable: false)
          ..sort((VisitorEvaluation a, VisitorEvaluation b) {
            final byTime = sightingsByVisitor[a.visitor.id]!.lastSeenAt
                .compareTo(sightingsByVisitor[b.visitor.id]!.lastSeenAt);
            if (byTime != 0) return byTime;
            return _catalogIndex(
              evaluations,
              a,
            ).compareTo(_catalogIndex(evaluations, b));
          });
    if (repeatReady.isNotEmpty) return repeatReady.first;
    return _orderedByProgress(evaluations, evaluations).first;
  }

  VisitorEvaluation? arriving({
    required List<VisitorEvaluation> evaluations,
    required Iterable<VisitorSighting> sightings,
    required DateTime now,
    required Duration repeatCooldown,
  }) {
    final sightingsByVisitor = <String, VisitorSighting>{
      for (final sighting in sightings) sighting.visitorId: sighting,
    };
    final unseenSatisfied = _orderedByProgress(
      evaluations
          .where(
            (VisitorEvaluation evaluation) =>
                evaluation.satisfied &&
                !sightingsByVisitor.containsKey(evaluation.visitor.id),
          )
          .toList(growable: false),
      evaluations,
    );
    if (unseenSatisfied.isNotEmpty) return unseenSatisfied.first;

    final repeatReady =
        evaluations
            .where((VisitorEvaluation evaluation) {
              if (!evaluation.satisfied) return false;
              final previous = sightingsByVisitor[evaluation.visitor.id];
              return previous != null &&
                  now.difference(previous.lastSeenAt) >= repeatCooldown;
            })
            .toList(growable: false)
          ..sort((VisitorEvaluation a, VisitorEvaluation b) {
            final byTime = sightingsByVisitor[a.visitor.id]!.lastSeenAt
                .compareTo(sightingsByVisitor[b.visitor.id]!.lastSeenAt);
            if (byTime != 0) return byTime;
            return _catalogIndex(
              evaluations,
              a,
            ).compareTo(_catalogIndex(evaluations, b));
          });
    return repeatReady.firstOrNull;
  }

  List<VisitorEvaluation> _orderedByProgress(
    List<VisitorEvaluation> candidates,
    List<VisitorEvaluation> catalogOrder,
  ) =>
      candidates.toList(growable: false)
        ..sort((VisitorEvaluation a, VisitorEvaluation b) {
          if (a.satisfied != b.satisfied) return a.satisfied ? -1 : 1;
          final bySatisfied = b.satisfiedCount.compareTo(a.satisfiedCount);
          if (bySatisfied != 0) return bySatisfied;
          final byMissing = (a.progress.length - a.satisfiedCount).compareTo(
            b.progress.length - b.satisfiedCount,
          );
          if (byMissing != 0) return byMissing;
          return _catalogIndex(
            catalogOrder,
            a,
          ).compareTo(_catalogIndex(catalogOrder, b));
        });

  int _catalogIndex(
    List<VisitorEvaluation> evaluations,
    VisitorEvaluation candidate,
  ) => evaluations.indexWhere(
    (VisitorEvaluation item) => item.visitor.id == candidate.visitor.id,
  );
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
    this.atmosphericTraits = AtmosphericTraitCatalog.empty,
  });

  final EnvironmentGrid grid;
  final ConnectionGraph graph;
  final List<Placement> placements;
  final Map<String, CraftedObject> objectsById;
  final Map<String, RecipeDefinition> recipesById;
  final TimeBand timeBand;
  final WeatherMaterialKind? weatherKind;
  final AtmosphericTraitCatalog atmosphericTraits;

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
          return context.recipesById[object.recipeId]?.height ==
              HeightBand.high;
        }).length;
        return _numeric('높은 물건', count, minimum);
      case 'quietZones':
        final count = context.placedObjects.where((CraftedObject object) {
          final trait = object.focusTrait;
          final override =
              trait != null &&
              context.atmosphericTraits
                      .tryDefinitionFor(trait)
                      ?.quietZoneOverride ==
                  true;
          return context.graph.degree(object.id) == 0 || override;
        }).length;
        return _numeric('조용한 구역', count, minimum);
      case 'taggedObjects':
        final tag = requirement.tag ?? '';
        final count = context.placedObjects.where((CraftedObject object) {
          return context.recipesById[object.recipeId]?.tags.contains(tag) ==
              true;
        }).length;
        return _numeric('${_tagLabelKo(tag)} 물건', count, minimum);
      case 'objectTag':
        final match = context.placedObjects.any((CraftedObject object) {
          final tags =
              context.recipesById[object.recipeId]?.tags ?? const <String>{};
          return requirement.anyOf.any(tags.contains);
        });
        return RequirementProgress(
          label: '필요한 종류의 물건',
          current: match ? '있음' : '없음',
          target: requirement.anyOf.map(_tagLabelKo).join(' / '),
          satisfied: match,
        );
      case 'objectKind':
        final match = context.placedObjects.any(
          (CraftedObject object) =>
              requirement.anyOf.contains(object.kind.name),
        );
        return RequirementProgress(
          label: '필요한 물건',
          current: match ? '있음' : '없음',
          target: requirement.anyOf.map(_objectKindLabelKo).join(' / '),
          satisfied: match,
        );
      case 'timeBand':
        final satisfied = requirement.anyOf.contains(context.timeBand.name);
        return RequirementProgress(
          label: '시간대',
          current: context.timeBand.labelKo,
          target: requirement.anyOf.map(_timeBandLabelKo).join(' / '),
          satisfied: satisfied,
        );
      case 'weatherKind':
        final weatherKind = context.weatherKind;
        final satisfied =
            weatherKind != null && requirement.anyOf.contains(weatherKind.name);
        return RequirementProgress(
          label: '현재 날씨',
          current: weatherKind?.labelKo ?? '확인할 수 없음',
          target: requirement.anyOf.map(_weatherKindLabelKo).join(' / '),
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

  String _objectKindLabelKo(String raw) {
    for (final kind in ObjectKind.values) {
      if (kind.name == raw) return kind.labelKo;
    }
    return raw;
  }

  String _timeBandLabelKo(String raw) {
    for (final value in TimeBand.values) {
      if (value.name == raw) return value.labelKo;
    }
    return raw;
  }

  String _weatherKindLabelKo(String raw) {
    for (final value in WeatherMaterialKind.values) {
      if (value.name == raw) return value.labelKo;
    }
    return raw;
  }

  String _tagLabelKo(String raw) => switch (raw) {
    'bird' => '새',
    'direction' => '길잡이',
    'far' => '먼 거리',
    'flower' => '꽃',
    'height' => '높은',
    'home' => '집',
    'hub' => '거점',
    'light' => '불빛',
    'market' => '장터',
    'message' => '소식',
    'nature' => '자연',
    'night' => '밤',
    'path' => '길',
    'shade' => '그늘',
    'sound' => '소리',
    'stable' => '안정',
    'stay' => '머무름',
    'street' => '골목',
    'table' => '탁자',
    'time' => '시간',
    'warm' => '온기',
    'wet' => '물가',
    'wind' => '바람',
    _ => raw,
  };
}
