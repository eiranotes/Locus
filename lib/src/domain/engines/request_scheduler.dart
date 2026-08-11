import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/local_game_day.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';

class RequestScheduleResult {
  const RequestScheduleResult({
    required this.activeRequests,
    required this.issuedRequests,
    required this.expiredRequests,
  });

  final List<VisitorRequest> activeRequests;
  final List<VisitorRequest> issuedRequests;
  final List<VisitorRequest> expiredRequests;
}

class RequestScheduler {
  const RequestScheduler({required this.balance});

  static const String schemaVersion = 'request-first-v1';

  final RequestFirstBalance balance;

  RequestScheduleResult ensureSlots({
    required DateTime now,
    required Iterable<VisitorRequest> requests,
    required List<RequestTemplateDefinition> templates,
    required Map<String, VisitorRelationship> relationships,
    required Set<SenseAxis> unlockedAxes,
    required int slotCount,
    required int historySpecimenCount,
    required String Function() idFactory,
  }) {
    final expired = <VisitorRequest>[];
    final active = <VisitorRequest>[];
    for (final request in requests) {
      final shouldExpire =
          request.isActive &&
          request.expiresAt != null &&
          !request.expiresAt!.isAfter(now);
      if (shouldExpire) {
        expired.add(request.copyWith(status: VisitorRequestStatus.expired));
      } else if (request.isActive) {
        active.add(request);
      }
    }
    active.sort(
      (VisitorRequest a, VisitorRequest b) =>
          a.slotIndex.compareTo(b.slotIndex),
    );

    final occupiedSlots = active
        .map((VisitorRequest request) => request.slotIndex)
        .toSet();
    final activeVisitors = active
        .map((VisitorRequest request) => request.visitorId)
        .toSet();
    final templateById = <String, RequestTemplateDefinition>{
      for (final template in templates) template.id: template,
    };
    final usedRecently = requests
        .where(
          (VisitorRequest request) =>
              now.difference(request.issuedAt) < const Duration(days: 7),
        )
        .map((VisitorRequest request) => request.templateId)
        .toSet();
    final issued = <VisitorRequest>[];
    final dayKey = LocalGameDay(
      boundaryHour: balance.gameDayBoundaryHour,
    ).keyFor(now);

    for (var slot = 0; slot < slotCount; slot += 1) {
      if (occupiedSlots.contains(slot)) continue;
      final anchor = active.isEmpty ? null : active.first;
      final anchorTemplate = anchor == null
          ? null
          : templateById[anchor.templateId];
      final selection = _selectTemplate(
        dayKey: dayKey,
        slot: slot,
        templates: templates,
        relationships: relationships,
        unlockedAxes: unlockedAxes,
        activeVisitors: activeVisitors,
        usedRecently: usedRecently,
        historySpecimenCount: historySpecimenCount,
        anchorTemplate: anchorTemplate,
      );
      if (selection == null) continue;
      final visitorId = _selectVisitor(
        dayKey: dayKey,
        slot: slot,
        template: selection,
        relationships: relationships,
        activeVisitors: activeVisitors,
      );
      if (visitorId == null) continue;
      final request = VisitorRequest(
        id: idFactory(),
        visitorId: visitorId,
        templateId: selection.id,
        promptKo: selection.promptKo,
        issuedAt: now,
        expiresAt: now.add(Duration(hours: balance.requestLifetimeHours)),
        slotIndex: slot,
        status: VisitorRequestStatus.active,
        constraints: selection.constraints,
        difficulty: selection.difficulty,
        historyComparison: selection.historyComparison,
        requestSchemaVersion: schemaVersion,
      );
      issued.add(request);
      active.add(request);
      occupiedSlots.add(slot);
      activeVisitors.add(visitorId);
      usedRecently.add(selection.id);
    }

    active.sort(
      (VisitorRequest a, VisitorRequest b) =>
          a.slotIndex.compareTo(b.slotIndex),
    );
    return RequestScheduleResult(
      activeRequests: List<VisitorRequest>.unmodifiable(active),
      issuedRequests: List<VisitorRequest>.unmodifiable(issued),
      expiredRequests: List<VisitorRequest>.unmodifiable(expired),
    );
  }

  RequestTemplateDefinition? _selectTemplate({
    required String dayKey,
    required int slot,
    required List<RequestTemplateDefinition> templates,
    required Map<String, VisitorRelationship> relationships,
    required Set<SenseAxis> unlockedAxes,
    required Set<String> activeVisitors,
    required Set<String> usedRecently,
    required int historySpecimenCount,
    required RequestTemplateDefinition? anchorTemplate,
  }) {
    final candidates = templates.where((RequestTemplateDefinition template) {
      if (!unlockedAxes.containsAll(template.requiredAxes)) return false;
      if (template.historyComparison != HistoryComparison.none &&
          historySpecimenCount < balance.historyRequestMinimumSpecimens) {
        return false;
      }
      if (template.visitorIds.every(activeVisitors.contains)) return false;
      return template.visitorIds.any((String visitorId) {
        final stage = relationships[visitorId]?.stage ?? 0;
        return stage >= template.minimumRelationshipStage;
      });
    }).toList(growable: false);
    if (candidates.isEmpty) return null;

    var preferred = candidates
        .where((RequestTemplateDefinition value) => !usedRecently.contains(value.id))
        .toList(growable: false);
    if (preferred.isEmpty) preferred = candidates;

    if (anchorTemplate != null &&
        _fraction('$dayKey:overlap:$slot') < balance.overlapPairRate) {
      final overlapping = preferred.where((RequestTemplateDefinition value) {
        return value.overlapTags.intersection(anchorTemplate.overlapTags).isNotEmpty;
      }).toList(growable: false);
      if (overlapping.isNotEmpty) preferred = overlapping;
    }

    final desiredTier =
        _fraction('$dayKey:tier:$slot') < balance.everydayRequestRatio
        ? RequestAccessTier.everyday
        : RequestAccessTier.outing;
    final tierMatches = preferred
        .where((RequestTemplateDefinition value) => value.accessTier == desiredTier)
        .toList(growable: false);
    if (tierMatches.isNotEmpty) preferred = tierMatches;

    preferred.sort(
      (RequestTemplateDefinition a, RequestTemplateDefinition b) =>
          a.id.compareTo(b.id),
    );
    return preferred[_stableHash('$dayKey:template:$slot') % preferred.length];
  }

  String? _selectVisitor({
    required String dayKey,
    required int slot,
    required RequestTemplateDefinition template,
    required Map<String, VisitorRelationship> relationships,
    required Set<String> activeVisitors,
  }) {
    final candidates = template.visitorIds.where((String visitorId) {
      if (activeVisitors.contains(visitorId)) return false;
      final stage = relationships[visitorId]?.stage ?? 0;
      return stage >= template.minimumRelationshipStage;
    }).toList(growable: false)
      ..sort();
    if (candidates.isEmpty) return null;
    return candidates[_stableHash('$dayKey:visitor:$slot:${template.id}') % candidates.length];
  }

  double _fraction(String input) => (_stableHash(input) % 10000) / 10000;

  int _stableHash(String input) {
    var value = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      value ^= unit;
      value = (value * 0x01000193) & 0x7fffffff;
    }
    return value;
  }
}
