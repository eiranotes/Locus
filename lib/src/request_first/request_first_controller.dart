import 'package:flutter/foundation.dart';
import 'package:reality_diorama/src/data/legacy_v4_migration.dart';
import 'package:reality_diorama/src/data/request_first_repository.dart';
import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/engines/relationship_engine.dart';
import 'package:reality_diorama/src/domain/engines/request_scheduler.dart';
import 'package:reality_diorama/src/domain/engines/seeded_visuals.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';
import 'package:reality_diorama/src/domain/request_first_scene_adapter.dart';
import 'package:reality_diorama/src/services/specimen_capture_coordinator.dart';
import 'package:uuid/uuid.dart';

class RequestFulfillmentOutcome {
  const RequestFulfillmentOutcome({
    required this.assignment,
    required this.request,
    required this.relationship,
    required this.events,
    required this.grantedSceneObjects,
    required this.grantedScenePlacements,
    required this.unlockedAxes,
  });

  final SpecimenAssignment assignment;
  final VisitorRequest request;
  final VisitorRelationship relationship;
  final List<RelationshipEvent> events;
  final List<SceneObject> grantedSceneObjects;
  final List<ScenePlacement> grantedScenePlacements;
  final Set<SenseAxis> unlockedAxes;
}

class RequestFirstController extends ChangeNotifier {
  RequestFirstController({
    required this.repository,
    required this.catalog,
    required this.legacyCatalog,
    required this.captureCoordinator,
    required this.migration,
    this.demoMode = false,
    this.uuid = const Uuid(),
  });

  static const int specimenPageSize = 24;

  final RequestFirstRepository repository;
  final RequestFirstCatalog catalog;
  final ContentCatalog legacyCatalog;
  final SpecimenCaptureCoordinator captureCoordinator;
  final LegacyV4MigrationService migration;
  final bool demoMode;
  final Uuid uuid;

  bool _initialized = false;
  bool _busy = false;
  String? _errorMessage;
  int _navigationIndex = 0;
  List<Specimen> _specimens = const <Specimen>[];
  int _specimenTotal = 0;
  bool _loadingMoreSpecimens = false;
  List<VisitorRequest> _requests = const <VisitorRequest>[];
  List<SpecimenAssignment> _assignments = const <SpecimenAssignment>[];
  Map<String, VisitorRelationship> _relationships =
      const <String, VisitorRelationship>{};
  Set<SenseAxis> _unlockedAxes = const <SenseAxis>{};
  List<RelationshipEvent> _relationshipEvents =
      const <RelationshipEvent>[];
  List<SceneObject> _sceneObjects = const <SceneObject>[];
  List<ScenePlacement> _scenePlacements = const <ScenePlacement>[];
  String? _focusedRequestId;
  SpecimenCaptureBundle? _lastCapture;
  RequestFulfillmentOutcome? _lastFulfillment;

  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  int get navigationIndex => _navigationIndex;
  List<Specimen> get specimens => List<Specimen>.unmodifiable(_specimens);
  int get specimenTotal => _specimenTotal;
  bool get loadingMoreSpecimens => _loadingMoreSpecimens;
  bool get hasMoreSpecimens => _specimens.length < _specimenTotal;
  List<VisitorRequest> get requests =>
      List<VisitorRequest>.unmodifiable(_requests);
  List<SpecimenAssignment> get assignments =>
      List<SpecimenAssignment>.unmodifiable(_assignments);
  Map<String, VisitorRelationship> get relationships =>
      Map<String, VisitorRelationship>.unmodifiable(_relationships);
  Set<SenseAxis> get unlockedAxes => Set<SenseAxis>.unmodifiable(_unlockedAxes);
  List<RelationshipEvent> get relationshipEvents =>
      List<RelationshipEvent>.unmodifiable(_relationshipEvents);
  List<SceneObject> get sceneObjects =>
      List<SceneObject>.unmodifiable(_sceneObjects);
  List<ScenePlacement> get scenePlacements =>
      List<ScenePlacement>.unmodifiable(_scenePlacements);
  String? get focusedRequestId => _focusedRequestId;
  SpecimenCaptureBundle? get lastCapture => _lastCapture;
  RequestFulfillmentOutcome? get lastFulfillment => _lastFulfillment;

  List<VisitorRequest> get activeRequests {
    final values = _requests
        .where((VisitorRequest value) => value.isActive)
        .toList(growable: false)
      ..sort(
        (VisitorRequest a, VisitorRequest b) =>
            a.slotIndex.compareTo(b.slotIndex),
      );
    return values;
  }

  VisitorRequest? get focusedRequest {
    final active = activeRequests;
    for (final request in active) {
      if (request.id == _focusedRequestId) return request;
    }
    return active.isEmpty ? null : active.first;
  }

  int get residentCount => _relationships.values
      .where((VisitorRelationship value) => value.stage >= 1)
      .length;

  DioramaSnapshot get sceneSnapshot => const RequestFirstSceneAdapter().build(
    now: DateTime.now(),
    sceneObjects: _sceneObjects,
    scenePlacements: _scenePlacements,
    relationships: _relationships,
    requestCatalog: catalog,
    legacyCatalog: legacyCatalog,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    await _guard(() async {
      await migration.run();
      await repository.seedUnlockedAxes(catalog.initiallyUnlockedAxes);
      await _reloadAll();
      await _ensureRequests(DateTime.now());
      _initialized = true;
    });
    notifyListeners();
  }

  Future<void> refreshWorld() async {
    await _guard(() async {
      await _reloadAll();
      await _ensureRequests(DateTime.now());
    });
    notifyListeners();
  }

  void setNavigationIndex(int value) {
    if (value == _navigationIndex) return;
    _navigationIndex = value;
    notifyListeners();
  }

  void focusRequest(String requestId) {
    if (!activeRequests.any((VisitorRequest value) => value.id == requestId)) {
      return;
    }
    if (_focusedRequestId == requestId) return;
    _focusedRequestId = requestId;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearLastFulfillment() {
    _lastFulfillment = null;
    notifyListeners();
  }

  Future<SpecimenCaptureBundle?> captureSpecimen() async {
    if (_busy) return null;
    SpecimenCaptureBundle? output;
    await _guard(() async {
      final active = activeRequests;
      if (active.isEmpty) {
        throw StateError('지금 받을 수 있는 손님의 요청이 없습니다.');
      }
      final references = <String, Specimen>{
        for (final specimen in _specimens) specimen.id: specimen,
      };
      final bundle = await captureCoordinator.capture(
        now: DateTime.now(),
        activeRequests: active,
        referenceSpecimensById: references,
      );
      await repository.saveSpecimenCapture(
        record: bundle.record,
        specimen: bundle.specimen,
        matches: bundle.matches,
      );
      _specimens = <Specimen>[
        bundle.specimen,
        ..._specimens.where((Specimen value) => value.id != bundle.specimen.id),
      ];
      _specimenTotal += 1;
      _lastCapture = bundle;
      output = bundle;
    });
    notifyListeners();
    return output;
  }

  Future<RequestFulfillmentOutcome?> assignSpecimen({
    required String specimenId,
    required String requestId,
  }) async {
    if (_busy) return null;
    RequestFulfillmentOutcome? output;
    await _guard(() async {
      final specimen = _specimens
          .where((Specimen value) => value.id == specimenId)
          .firstOrNull;
      final request = _requests
          .where((VisitorRequest value) => value.id == requestId)
          .firstOrNull;
      if (specimen == null || request == null || !request.isActive) {
        throw StateError('표본이나 활성 요청을 찾을 수 없습니다.');
      }
      final matches = _lastCapture?.specimen.id == specimenId
          ? _lastCapture!.matches
          : await repository.loadMatchesForSpecimen(specimenId);
      final match = matches
          .where((SpecimenMatch value) => value.requestId == requestId)
          .firstOrNull;
      if (match == null || !match.passed) {
        throw StateError('이 표본은 선택한 요청을 충족하지 않습니다.');
      }
      final now = DateTime.now();
      final relationshipResolution = const RelationshipEngine().fulfill(
        visitorId: request.visitorId,
        requestId: request.id,
        specimenId: specimen.id,
        matchScore: match.score,
        now: now,
        current: _relationships[request.visitorId],
        track: catalog.trackForVisitor(request.visitorId),
        idFactory: uuid.v4,
      );
      final rawSceneObjects = relationshipResolution.grantedSceneObjectIds
          .map(
            (String definitionId) => SceneObject(
              id: uuid.v4(),
              definitionId: definitionId,
              origin: SceneObjectOrigin.relationshipReward,
              sourceVisitorId: request.visitorId,
              sourceRequestId: request.id,
              visualSeed: stableSeed(<Object?>[
                request.visitorId,
                request.id,
                definitionId,
                specimen.previewSeed,
              ]),
              generatorVersion: 'relationship-keepsake-v1',
              variantKey: 'base',
              lifecycle: SceneObjectLifecycle.stored,
              createdAt: now,
            ),
          )
          .toList(growable: false);
      final rewardPlacement = _autoPlaceRewards(rawSceneObjects);
      final assignment = SpecimenAssignment(
        id: uuid.v4(),
        specimenId: specimen.id,
        requestId: request.id,
        visitorId: request.visitorId,
        assignedAt: now,
        acceptedScore: match.score,
      );
      final fulfilled = request.copyWith(
        status: VisitorRequestStatus.fulfilled,
        completedAt: now,
      );
      await repository.assignSpecimen(
        assignment: assignment,
        fulfilledRequest: fulfilled,
        relationship: relationshipResolution.relationship,
        events: relationshipResolution.events,
        unlockedAxes: relationshipResolution.unlockedAxes,
        grantedSceneObjects: rewardPlacement.objects,
        grantedScenePlacements: rewardPlacement.placements,
      );

      _assignments = <SpecimenAssignment>[assignment, ..._assignments];
      _requests = _replaceById(
        _requests,
        fulfilled,
        (VisitorRequest value) => value.id,
      );
      _relationships = <String, VisitorRelationship>{
        ..._relationships,
        request.visitorId: relationshipResolution.relationship,
      };
      _relationshipEvents = <RelationshipEvent>[
        ...relationshipResolution.events.reversed,
        ..._relationshipEvents,
      ];
      _unlockedAxes = <SenseAxis>{
        ..._unlockedAxes,
        ...relationshipResolution.unlockedAxes,
      };
      _sceneObjects = <SceneObject>[
        ...rewardPlacement.objects,
        ..._sceneObjects,
      ];
      _scenePlacements = <ScenePlacement>[
        ...rewardPlacement.placements,
        ..._scenePlacements,
      ];
      final outcome = RequestFulfillmentOutcome(
        assignment: assignment,
        request: fulfilled,
        relationship: relationshipResolution.relationship,
        events: relationshipResolution.events,
        grantedSceneObjects: rewardPlacement.objects,
        grantedScenePlacements: rewardPlacement.placements,
        unlockedAxes: relationshipResolution.unlockedAxes,
      );
      _lastFulfillment = outcome;
      output = outcome;
      await _ensureRequests(now);
    });
    notifyListeners();
    return output;
  }

  Future<void> loadMoreSpecimens() async {
    if (_busy || _loadingMoreSpecimens || !hasMoreSpecimens) return;
    _loadingMoreSpecimens = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await repository.loadSpecimens(
        limit: specimenPageSize,
        offset: _specimens.length,
      );
      final ids = _specimens.map((Specimen value) => value.id).toSet();
      _specimens = <Specimen>[
        ..._specimens,
        ...page.where((Specimen value) => ids.add(value.id)),
      ];
      _specimenTotal = await repository.specimenCount();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _loadingMoreSpecimens = false;
      notifyListeners();
    }
  }

  SpecimenAssignment? assignmentForSpecimen(String specimenId) => _assignments
      .where((SpecimenAssignment value) => value.specimenId == specimenId)
      .firstOrNull;

  VisitorRequest? requestById(String requestId) => _requests
      .where((VisitorRequest value) => value.id == requestId)
      .firstOrNull;

  VisitorRequest? activeRequestForVisitor(String visitorId) => activeRequests
      .where((VisitorRequest value) => value.visitorId == visitorId)
      .firstOrNull;

  Future<void> _ensureRequests(DateTime now) async {
    final schedule = RequestScheduler(balance: catalog.balance).ensureSlots(
      now: now,
      requests: _requests,
      templates: catalog.templates,
      relationships: _relationships,
      unlockedAxes: _unlockedAxes,
      slotCount: _assignments.isEmpty
          ? catalog.balance.tutorialRequestSlots
          : catalog.balance.requestSlots,
      historySpecimenIds: _assignments
          .map((SpecimenAssignment value) => value.specimenId)
          .toList(growable: false),
      idFactory: uuid.v4,
    );
    if (schedule.issuedRequests.isNotEmpty ||
        schedule.expiredRequests.isNotEmpty) {
      await repository.saveRequestSchedule(
        issued: schedule.issuedRequests,
        expired: schedule.expiredRequests,
      );
      final byId = <String, VisitorRequest>{
        for (final request in _requests) request.id: request,
        for (final request in schedule.expiredRequests) request.id: request,
        for (final request in schedule.issuedRequests) request.id: request,
      };
      _requests = byId.values.toList(growable: false)
        ..sort(
          (VisitorRequest a, VisitorRequest b) =>
              b.issuedAt.compareTo(a.issuedAt),
        );
    }
    final active = activeRequests;
    if (!active.any((VisitorRequest value) => value.id == _focusedRequestId)) {
      _focusedRequestId = active.isEmpty ? null : active.first.id;
    }
  }

  ({List<SceneObject> objects, List<ScenePlacement> placements})
  _autoPlaceRewards(List<SceneObject> rewards) {
    if (rewards.isEmpty) {
      return (objects: const <SceneObject>[], placements: const <ScenePlacement>[]);
    }
    final objects = <SceneObject>[];
    final placements = <ScenePlacement>[];
    final workingObjects = <SceneObject>[..._sceneObjects];
    final workingPlacements = <ScenePlacement>[..._scenePlacements];
    final engine = PlacementEngine(
      columns: catalog.balance.gridColumns,
      rows: catalog.balance.gridRows,
    );

    for (final reward in rewards) {
      var next = reward;
      if (workingPlacements.length < catalog.balance.activeObjectLimit) {
        final recipeId = _legacyRecipeId(reward);
        final recipe = _tryRecipe(recipeId);
        if (recipe != null) {
          final candidateId = uuid.v4();
          final existing = workingPlacements
              .map(
                (ScenePlacement value) => Placement(
                  id: value.id,
                  craftedObjectId: value.sceneObjectId,
                  column: value.column,
                  row: value.row,
                  rotation: value.rotation,
                ),
              )
              .toList(growable: false);
          final recipesByObjectId = <String, RecipeDefinition>{};
          for (final object in <SceneObject>[...workingObjects, reward]) {
            final definition = _tryRecipe(_legacyRecipeId(object));
            if (definition != null) recipesByObjectId[object.id] = definition;
          }
          final placementEntry = legacyCatalog.placement.entryForRecipe(recipe.id);
          final anchor = engine.firstValidAnchor(
            candidate: Placement(
              id: candidateId,
              craftedObjectId: reward.id,
              column: 0,
              row: 0,
              rotation: 0,
            ),
            recipe: recipe,
            existing: existing,
            recipeByObjectId: recipesByObjectId,
            allowedRotations: placementEntry.allowedRotations,
          );
          if (anchor != null) {
            next = reward.copyWith(lifecycle: SceneObjectLifecycle.placed);
            final placement = ScenePlacement(
              id: candidateId,
              sceneObjectId: reward.id,
              column: anchor.column,
              row: anchor.row,
              rotation: 0,
            );
            placements.add(placement);
            workingPlacements.add(placement);
          }
        }
      }
      objects.add(next);
      workingObjects.add(next);
    }
    return (
      objects: List<SceneObject>.unmodifiable(objects),
      placements: List<ScenePlacement>.unmodifiable(placements),
    );
  }

  String _legacyRecipeId(SceneObject object) {
    if (object.origin != SceneObjectOrigin.relationshipReward) {
      return object.definitionId;
    }
    try {
      return catalog.sceneObjectById(object.definitionId).legacyRecipeId;
    } on StateError {
      return object.definitionId;
    }
  }

  RecipeDefinition? _tryRecipe(String id) {
    for (final recipe in legacyCatalog.recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  Future<void> _reloadAll() async {
    _specimenTotal = await repository.specimenCount();
    _specimens = await repository.loadSpecimens(limit: specimenPageSize);
    _requests = await repository.loadRequests();
    _assignments = await repository.loadAssignments();
    _relationships = await repository.loadRelationships();
    _unlockedAxes = await repository.loadUnlockedAxes();
    _relationshipEvents = await repository.loadRelationshipEvents();
    _sceneObjects = await repository.loadSceneObjects();
    _scenePlacements = await repository.loadScenePlacements();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _busy = false;
    }
  }
}

List<T> _replaceById<T>(
  List<T> source,
  T value,
  String Function(T value) idOf,
) {
  final id = idOf(value);
  final output = <T>[];
  var replaced = false;
  for (final item in source) {
    if (idOf(item) == id) {
      output.add(value);
      replaced = true;
    } else {
      output.add(item);
    }
  }
  if (!replaced) output.insert(0, value);
  return output;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
