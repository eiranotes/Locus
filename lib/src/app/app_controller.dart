import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:reality_diorama/src/data/game_repository.dart';
import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/entities.dart';
import 'package:reality_diorama/src/domain/enums.dart';
import 'package:reality_diorama/src/domain/engines/connection_graph.dart';
import 'package:reality_diorama/src/domain/engines/crafting_engine.dart';
import 'package:reality_diorama/src/domain/engines/environment_grid.dart';
import 'package:reality_diorama/src/domain/engines/placement_engine.dart';
import 'package:reality_diorama/src/domain/engines/step_ledger.dart';
import 'package:reality_diorama/src/domain/engines/time_context.dart';
import 'package:reality_diorama/src/domain/engines/visitor_engine.dart';
import 'package:reality_diorama/src/domain/game_snapshot.dart';
import 'package:reality_diorama/src/domain/placement_catalog.dart';
import 'package:reality_diorama/src/services/capture_coordinator.dart';
import 'package:reality_diorama/src/services/step_sync_service.dart';
import 'package:reality_diorama/src/services/weather_gateway.dart';
import 'package:uuid/uuid.dart';

part 'app_controller_actions.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.repository,
    required this.catalog,
    required this.captureCoordinator,
    required this.stepSyncService,
    this.demoMode = false,
    this.uuid = const Uuid(),
  });

  final GameRepository repository;
  final ContentCatalog catalog;
  final CaptureCoordinator captureCoordinator;
  final StepSyncService stepSyncService;
  final bool demoMode;
  final Uuid uuid;

  bool _initialized = false;
  bool _busy = false;
  String? _errorMessage;
  int _navigationIndex = 0;

  List<CaptureRecord> _captures = const <CaptureRecord>[];
  List<WeatherMaterial> _weatherMaterials = const <WeatherMaterial>[];
  List<SurroundingMaterial> _surroundingMaterials =
      const <SurroundingMaterial>[];
  List<CollectedPattern> _collectedPatterns = const <CollectedPattern>[];
  List<StepBucket> _stepBuckets = const <StepBucket>[];
  List<CraftedObject> _craftedObjects = const <CraftedObject>[];
  List<Placement> _placements = const <Placement>[];
  List<VisitorSighting> _visitorSightings = const <VisitorSighting>[];
  Map<String, int> _visitorEncounterCounts = const <String, int>{};
  Set<String> _unlockedRecipeIds = <String>{};
  Set<String> _unlockedRewardKeys = <String>{};
  CapturePreparation? _capturePreparation;
  CaptureBundle? _lastCaptureBundle;
  String? _newVisitorId;
  StepTrackingMode _stepTrackingMode = StepTrackingMode.undecided;

  bool get initialized => _initialized;
  bool get busy => _busy;
  String? get errorMessage => _errorMessage;
  int get navigationIndex => _navigationIndex;
  List<CaptureRecord> get captures =>
      List<CaptureRecord>.unmodifiable(_captures);
  List<WeatherMaterial> get weatherMaterials =>
      List<WeatherMaterial>.unmodifiable(_weatherMaterials);
  List<SurroundingMaterial> get surroundingMaterials =>
      List<SurroundingMaterial>.unmodifiable(_surroundingMaterials);
  List<CollectedPattern> get collectedPatterns =>
      List<CollectedPattern>.unmodifiable(_collectedPatterns);
  List<StepBucket> get stepBuckets =>
      List<StepBucket>.unmodifiable(_stepBuckets);
  List<CraftedObject> get craftedObjects =>
      List<CraftedObject>.unmodifiable(_craftedObjects);
  List<Placement> get placements => List<Placement>.unmodifiable(_placements);
  List<VisitorSighting> get visitorSightings =>
      List<VisitorSighting>.unmodifiable(_visitorSightings);
  Map<String, int> get visitorEncounterCounts =>
      Map<String, int>.unmodifiable(_visitorEncounterCounts);
  Set<String> get unlockedRecipeIds =>
      Set<String>.unmodifiable(_unlockedRecipeIds);
  CapturePreparation? get capturePreparation => _capturePreparation;
  CaptureBundle? get lastCaptureBundle => _lastCaptureBundle;
  String? get newVisitorId => _newVisitorId;
  StepTrackingMode get stepTrackingMode => _stepTrackingMode;
  bool get stepTrackingConfigured =>
      _stepTrackingMode != StepTrackingMode.undecided;
  bool get usesRealSteps => _stepTrackingMode == StepTrackingMode.real;
  int get fallbackDailySteps => stepSyncService.fallbackDailySteps;

  List<WeatherMaterial> get availableWeatherMaterials => _weatherMaterials
      .where((WeatherMaterial material) => material.isAvailable)
      .toList(growable: false);

  List<SurroundingMaterial> get availableSurroundingMaterials =>
      _surroundingMaterials
          .where((SurroundingMaterial material) => material.isAvailable)
          .toList(growable: false);

  List<RecipeDefinition> get unlockedRecipes => catalog.recipes
      .where(
        (RecipeDefinition recipe) => _unlockedRecipeIds.contains(recipe.id),
      )
      .toList(growable: false);

  int get availableSteps => const StepLedger().available(_stepBuckets);

  CraftedObject? get construction {
    for (final object in _craftedObjects) {
      if (object.lifecycle == ObjectLifecycle.building) return object;
    }
    return null;
  }

  int get captureReadyCount {
    final preparation = _capturePreparation;
    if (preparation == null) return 0;
    return <ResourceReadiness>[
      preparation.weatherReadiness,
      preparation.surroundingReadiness,
    ].where((ResourceReadiness value) => value.isReady).length;
  }

  WeatherMaterialKind? get currentWeatherKind =>
      _capturePreparation?.weatherKind;

  WeatherMaterialKind get sceneWeatherKind {
    final current = currentWeatherKind;
    if (current != null) return current;
    if (_weatherMaterials.isNotEmpty) return _weatherMaterials.first.kind;
    return WeatherMaterialKind.cloudy;
  }

  TimeBand get sceneTimeBand => timeBandFor(DateTime.now());

  void notifyChanged() => notifyListeners();

  Future<void> initialize() async {
    if (_initialized) return;
    await _guard(() async {
      await _reloadAll();
      final initialIds = catalog.recipes
          .where((RecipeDefinition recipe) => recipe.initiallyUnlocked)
          .map((RecipeDefinition recipe) => recipe.id)
          .toSet();
      final persisted = await repository.unlockedRecipeIds();
      _unlockedRecipeIds = persisted.isEmpty ? initialIds : persisted
        ..addAll(initialIds);
      await repository.saveUnlockedRecipeIds(_unlockedRecipeIds);
      final rewardRaw = await repository.metadata('unlocked_reward_keys');
      if (rewardRaw != null) {
        _unlockedRewardKeys = (jsonDecode(rewardRaw) as List<Object?>)
            .cast<String>()
            .toSet();
      }
      _stepTrackingMode = enumByName(
        StepTrackingMode.values,
        await repository.metadata('step_tracking_mode') ?? '',
        StepTrackingMode.undecided,
      );
      if (demoMode && _stepTrackingMode == StepTrackingMode.undecided) {
        _stepTrackingMode = StepTrackingMode.real;
        await repository.setMetadata(
          'step_tracking_mode',
          _stepTrackingMode.name,
        );
      }
      if (_stepTrackingMode == StepTrackingMode.undecided &&
          _stepBuckets.isNotEmpty) {
        _stepBuckets = const <StepBucket>[];
        await repository.replaceStepBuckets(_stepBuckets);
      }
      await _syncStepsAndConstruction();
      await _refreshCapturePreparationState(requestLocationPermission: false);
      await _evaluateAndPersistVisitors();
      _initialized = true;
    });
    notifyListeners();
  }

  void setNavigationIndex(int value) {
    if (value == _navigationIndex) return;
    _navigationIndex = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearNewVisitor() {
    _newVisitorId = null;
    notifyListeners();
  }

  Future<void> _refreshCapturePreparationState({
    required bool requestLocationPermission,
  }) async {
    final lastWeather = _weatherMaterials.isEmpty
        ? null
        : _weatherMaterials.first;
    final lastSurrounding = _surroundingMaterials.isEmpty
        ? null
        : _surroundingMaterials.first;
    final lastCoordinate = await repository.lastAmbientCoordinate();
    _capturePreparation = await captureCoordinator.prepare(
      now: DateTime.now(),
      lastWeather: lastWeather,
      lastSurrounding: lastSurrounding,
      lastAmbientCoordinate: lastCoordinate,
      requestLocationPermission: requestLocationPermission,
    );
  }

  Future<void> refreshCapturePreparation({
    bool notify = true,
    bool requestLocationPermission = true,
  }) async {
    await _guard(() async {
      await _refreshCapturePreparationState(
        requestLocationPermission: requestLocationPermission,
      );
      await _evaluateAndPersistVisitors();
    });
    if (notify) notifyListeners();
  }

  Future<void> refreshWorld({bool notify = true}) async {
    await _guard(() async {
      if (stepTrackingConfigured) {
        await _syncStepsAndConstruction();
      }
      await _refreshCapturePreparationState(requestLocationPermission: false);
      await _evaluateAndPersistVisitors();
    });
    if (notify) notifyListeners();
  }

  Future<WeatherAttributionInfo> weatherAttribution() =>
      captureCoordinator.weatherGateway.attribution();

  Future<void> refreshSteps() async {
    await _guard(() async {
      await _syncStepsAndConstruction();
      await _evaluateAndPersistVisitors();
    });
    notifyListeners();
  }

  Future<void> configureStepTracking({required bool useRealSteps}) async {
    await _guard(() async {
      final now = DateTime.now();
      var mode = useRealSteps
          ? StepTrackingMode.real
          : StepTrackingMode.fallback;
      final sourceChanged = mode != _stepTrackingMode;
      final baseline = sourceChanged
          ? stepSyncService.sourceChangeBaseline(_stepBuckets)
          : _stepBuckets;
      var buckets = useRealSteps
          ? await stepSyncService.syncReal(existing: baseline, now: now)
          : stepSyncService.syncFallback(existing: baseline, now: now);
      if (mode == StepTrackingMode.real && buckets.isEmpty) {
        mode = StepTrackingMode.fallback;
        buckets = stepSyncService.syncFallback(existing: baseline, now: now);
      }
      _stepTrackingMode = mode;
      _stepBuckets = buckets;
      await repository.setMetadata('step_tracking_mode', mode.name);
      await repository.replaceStepBuckets(_stepBuckets);
      await _advanceConstruction();
      await _evaluateAndPersistVisitors();
    });
    notifyListeners();
  }
}
