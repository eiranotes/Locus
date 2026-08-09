import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/connection_graph.dart';
import 'package:reality_diorama/src/domain/engines/environment_grid.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/domain/visual_layer_catalog.dart';
import 'package:reality_diorama/src/domain/atmospheric_trait_catalog.dart';

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
    required this.placementCatalog,
    this.visualLayerCatalog = VisualLayerCatalog.empty,
    this.atmosphericTraitCatalog = AtmosphericTraitCatalog.empty,
    this.activeVisitorId,
    this.editorOverlay,
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
  final PlacementCatalog placementCatalog;
  final VisualLayerCatalog visualLayerCatalog;
  final AtmosphericTraitCatalog atmosphericTraitCatalog;
  final String? activeVisitorId;
  final DioramaEditorOverlay? editorOverlay;

  DioramaSnapshot withEditorOverlay(DioramaEditorOverlay overlay) =>
      DioramaSnapshot(
        objects: objects,
        placements: placements,
        recipesById: recipesById,
        weatherMaterialsById: weatherMaterialsById,
        environmentGrid: environmentGrid,
        connectionGraph: connectionGraph,
        timeBand: timeBand,
        weatherKind: weatherKind,
        visitorEvaluations: visitorEvaluations,
        placementCatalog: placementCatalog,
        visualLayerCatalog: visualLayerCatalog,
        atmosphericTraitCatalog: atmosphericTraitCatalog,
        activeVisitorId: activeVisitorId,
        editorOverlay: overlay,
      );

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
      placementCatalog: PlacementCatalog.empty,
    );
  }
}

String? sceneVisitorIdFor({
  required Iterable<VisitorSighting> sightings,
  String? arrivingVisitorId,
}) {
  if (arrivingVisitorId != null) return arrivingVisitorId;

  VisitorSighting? latest;
  for (final sighting in sightings) {
    if (latest == null ||
        sighting.lastSeenAt.isAfter(latest.lastSeenAt) ||
        (sighting.lastSeenAt.isAtSameMomentAs(latest.lastSeenAt) &&
            sighting.visitorId.compareTo(latest.visitorId) < 0)) {
      latest = sighting;
    }
  }
  return latest?.visitorId;
}

final class DioramaEditorOverlay {
  const DioramaEditorOverlay({
    required this.selectedObjectId,
    required this.selectedCells,
    required this.validAnchorCells,
  });

  final String selectedObjectId;
  final Set<GridCell> selectedCells;
  final Set<GridCell> validAnchorCells;
}
