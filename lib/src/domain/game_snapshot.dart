import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/connection_graph.dart';
import 'package:reality_diorama/src/domain/engines/environment_grid.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';

class DioramaSnapshot {
  const DioramaSnapshot({
    required this.objects,
    required this.placements,
    required this.recipesById,
    required this.weatherMaterialsById,
    required this.environmentGrid,
    required this.connectionGraph,
    required this.timeBand,
    required this.weatherKind,
    required this.visitorEvaluations,
    this.activeVisitorId,
  });

  final List<CraftedObject> objects;
  final List<Placement> placements;
  final Map<String, RecipeDefinition> recipesById;
  final Map<String, WeatherMaterial> weatherMaterialsById;
  final EnvironmentGrid environmentGrid;
  final ConnectionGraph connectionGraph;
  final TimeBand timeBand;
  final WeatherMaterialKind weatherKind;
  final List<VisitorEvaluation> visitorEvaluations;
  final String? activeVisitorId;

  factory DioramaSnapshot.empty() {
    return DioramaSnapshot(
      objects: const <CraftedObject>[],
      placements: const <Placement>[],
      recipesById: const <String, RecipeDefinition>{},
      weatherMaterialsById: const <String, WeatherMaterial>{},
      environmentGrid: EnvironmentGrid(columns: 5, rows: 5),
      connectionGraph: const ConnectionGraph(edges: <ConnectionEdge>[]),
      timeBand: TimeBand.evening,
      weatherKind: WeatherMaterialKind.cloudy,
      visitorEvaluations: const <VisitorEvaluation>[],
    );
  }
}
