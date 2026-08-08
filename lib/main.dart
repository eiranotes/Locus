import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reality_diorama/src/app/app_controller.dart';
import 'package:reality_diorama/src/app/app_scope.dart';
import 'package:reality_diorama/src/app/reality_diorama_app.dart';
import 'package:reality_diorama/src/data/database.dart';
import 'package:reality_diorama/src/data/game_repository.dart';
import 'package:reality_diorama/src/domain/content_catalog.dart';
import 'package:reality_diorama/src/platform/ambient_scanner.dart';
import 'package:reality_diorama/src/platform/step_source.dart';
import 'package:reality_diorama/src/services/capture_coordinator.dart';
import 'package:reality_diorama/src/services/location_gateway.dart';
import 'package:reality_diorama/src/services/step_sync_service.dart';
import 'package:reality_diorama/src/services/weather_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const demoMode = bool.fromEnvironment('DEMO_MODE');
  final catalog = await ContentCatalog.load(rootBundle);
  final database = await AppDatabase.open();
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
  final StepSource stepSource =
      demoMode ? const DemoStepSource() : const MethodChannelStepSource();

  final controller = AppController(
    repository: repository,
    catalog: catalog,
    captureCoordinator: CaptureCoordinator(
      locationGateway: locationGateway,
      weatherGateway: weatherGateway,
      ambientScanner: ambientScanner,
      catalog: catalog,
    ),
    stepSyncService: StepSyncService(
      source: stepSource,
      fallbackDailySteps: catalog.balance.fallbackDailySteps,
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
