import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/reality_diorama_app.dart';
import 'package:reality_diorama/src/data/database.dart';
import 'package:reality_diorama/src/data/game_repository.dart';
import 'package:reality_diorama/src/data/legacy_v4_migration.dart';
import 'package:reality_diorama/src/data/request_first_repository.dart';
import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/domain/engines/specimen_matcher.dart';
import 'package:reality_diorama/src/domain/request_first_catalog.dart';
import 'package:reality_diorama/src/platform/ambient_scanner.dart';
import 'package:reality_diorama/src/platform/sense_sampler.dart';
import 'package:reality_diorama/src/platform/step_source.dart';
import 'package:reality_diorama/src/request_first/request_first_app.dart';
import 'package:reality_diorama/src/request_first/request_first_controller.dart';
import 'package:reality_diorama/src/request_first/request_first_scope.dart';
import 'package:reality_diorama/src/services/capture_coordinator.dart';
import 'package:reality_diorama/src/services/location_gateway.dart';
import 'package:reality_diorama/src/services/specimen_capture_coordinator.dart';
import 'package:reality_diorama/src/services/step_sync_service.dart';
import 'package:reality_diorama/src/services/weather_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const demoMode = bool.fromEnvironment('DEMO_MODE');
  const requestFirstMode = bool.fromEnvironment('REQUEST_FIRST_MODE');
  final legacyCatalog = await ContentCatalog.load(rootBundle);
  final database = await AppDatabase.open(demoMode: demoMode);

  if (requestFirstMode) {
    final requestCatalog = await RequestFirstCatalog.load(rootBundle);
    final SenseSampler sampler = demoMode
        ? const DemoSenseSampler()
        : const UnavailableSenseSampler();
    final controller = RequestFirstController(
      repository: RequestFirstRepository(database),
      catalog: requestCatalog,
      legacyCatalog: legacyCatalog,
      captureCoordinator: SpecimenCaptureCoordinator(
        sampler: sampler,
        matcher: SpecimenMatcher(
          minimumConfidence: requestCatalog.balance.minimumCaptureConfidence,
        ),
        captureDuration: Duration(
          seconds: requestCatalog.balance.specimenCaptureSeconds,
        ),
        minimumConfidence: requestCatalog.balance.minimumCaptureConfidence,
      ),
      migration: LegacyV4MigrationService(database),
      demoMode: demoMode,
    );
    await controller.initialize();
    runApp(
      RequestFirstScope(
        controller: controller,
        child: const RequestFirstApp(),
      ),
    );
    return;
  }

  final repository = GameRepository(database);
  final WeatherGateway weatherGateway = demoMode
      ? const DemoWeatherGateway()
      : PlatformWeatherGateway();
  final LocationGateway locationGateway = demoMode
      ? const DemoLocationGateway()
      : const GeolocatorLocationGateway();
  final AmbientScanner ambientScanner = demoMode
      ? const DemoAmbientScanner()
      : const MethodChannelAmbientScanner();
  final StepSource stepSource = demoMode
      ? const DemoStepSource()
      : const MethodChannelStepSource();

  final controller = AppController(
    repository: repository,
    catalog: legacyCatalog,
    demoMode: demoMode,
    captureCoordinator: CaptureCoordinator(
      locationGateway: locationGateway,
      weatherGateway: weatherGateway,
      ambientScanner: ambientScanner,
      catalog: legacyCatalog,
    ),
    stepSyncService: StepSyncService(
      source: stepSource,
      fallbackDailySteps: legacyCatalog.balance.fallbackDailySteps,
    ),
  );
  await controller.initialize();

  runApp(
    AppScope(
      controller: controller,
      child: RealityDioramaApp(demoMode: demoMode),
    ),
  );
}
