import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';

class ConnectionEdge {
  const ConnectionEdge({
    required this.fromObjectId,
    required this.toObjectId,
    required this.mode,
    required this.directed,
  });

  final String fromObjectId;
  final String toObjectId;
  final ConnectionMode mode;
  final bool directed;
}

class ConnectionGraph {
  const ConnectionGraph({required this.edges});

  final List<ConnectionEdge> edges;

  int degree(String objectId) => edges.where((ConnectionEdge edge) {
    return edge.fromObjectId == objectId || edge.toObjectId == objectId;
  }).length;

  int countMode(ConnectionMode mode) =>
      edges.where((ConnectionEdge edge) => edge.mode == mode).length;
}

class ConnectionGraphBuilder {
  const ConnectionGraphBuilder();

  ConnectionGraph build({
    required List<Placement> placements,
    required Map<String, CraftedObject> objectsById,
  }) {
    final candidates = placements
        .where((Placement placement) {
          final object = objectsById[placement.craftedObjectId];
          return object != null && object.isComplete;
        })
        .toList(growable: false);

    final edges = <ConnectionEdge>[];
    final keys = <String>{};

    for (final placement in candidates) {
      final object = objectsById[placement.craftedObjectId]!;
      final others = candidates
          .where(
            (Placement candidate) =>
                candidate.craftedObjectId != placement.craftedObjectId,
          )
          .toList(growable: false);
      if (others.isEmpty) {
        continue;
      }

      final mode = _modeFor(object.surroundingKind);
      switch (mode) {
        case ConnectionMode.adjacent:
          for (final other in others.where(
            (Placement other) => _distance(placement, other) <= 1,
          )) {
            _addEdge(
              edges,
              keys,
              from: placement.craftedObjectId,
              to: other.craftedObjectId,
              mode: mode,
              directed: false,
            );
          }
          break;
        case ConnectionMode.dense:
          for (final other in others.where(
            (Placement other) => _distance(placement, other) <= 2,
          )) {
            _addEdge(
              edges,
              keys,
              from: placement.craftedObjectId,
              to: other.craftedObjectId,
              mode: mode,
              directed: false,
            );
          }
          break;
        case ConnectionMode.sequential:
          final ordered = List<Placement>.of(others)
            ..sort((Placement a, Placement b) {
              final aOrder = a.row * 10 + a.column;
              final bOrder = b.row * 10 + b.column;
              return aOrder.compareTo(bOrder);
            });
          final sourceOrder = placement.row * 10 + placement.column;
          final next = ordered.where((Placement item) {
            return item.row * 10 + item.column > sourceOrder;
          }).firstOrNull;
          final target = next ?? ordered.first;
          _addEdge(
            edges,
            keys,
            from: placement.craftedObjectId,
            to: target.craftedObjectId,
            mode: mode,
            directed: true,
          );
          break;
        case ConnectionMode.stable:
          final nearest = _nearest(placement, others);
          _addEdge(
            edges,
            keys,
            from: placement.craftedObjectId,
            to: nearest.craftedObjectId,
            mode: mode,
            directed: false,
          );
          break;
        case ConnectionMode.far:
          final eligible = others
              .where((Placement other) => _distance(placement, other) >= 2)
              .toList(growable: false);
          if (eligible.isEmpty) {
            continue;
          }
          final target = eligible.reduce((Placement a, Placement b) {
            return _distance(placement, a) >= _distance(placement, b) ? a : b;
          });
          _addEdge(
            edges,
            keys,
            from: placement.craftedObjectId,
            to: target.craftedObjectId,
            mode: mode,
            directed: false,
          );
          break;
      }
    }

    return ConnectionGraph(edges: List<ConnectionEdge>.unmodifiable(edges));
  }

  ConnectionMode _modeFor(SurroundingMaterialKind? kind) => switch (kind) {
    null => ConnectionMode.adjacent,
    SurroundingMaterialKind.dense => ConnectionMode.dense,
    SurroundingMaterialKind.dynamic => ConnectionMode.sequential,
    SurroundingMaterialKind.stable => ConnectionMode.stable,
    SurroundingMaterialKind.sparse => ConnectionMode.far,
  };

  int _distance(Placement a, Placement b) =>
      (a.column - b.column).abs() + (a.row - b.row).abs();

  Placement _nearest(Placement source, List<Placement> others) =>
      others.reduce((Placement a, Placement b) {
        return _distance(source, a) <= _distance(source, b) ? a : b;
      });

  void _addEdge(
    List<ConnectionEdge> edges,
    Set<String> keys, {
    required String from,
    required String to,
    required ConnectionMode mode,
    required bool directed,
  }) {
    if (from == to) {
      return;
    }
    final endpoints = <String>[from, to]..sort();
    final canonical = directed
        ? '$from>$to:${mode.name}'
        : '${endpoints[0]}:${endpoints[1]}:${mode.name}';
    if (!keys.add(canonical)) {
      return;
    }
    edges.add(
      ConnectionEdge(
        fromObjectId: from,
        toObjectId: to,
        mode: mode,
        directed: directed,
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
