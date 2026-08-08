import CoreBluetooth
import CoreLocation
import CoreMotion
import Flutter
import Foundation
import UIKit
import WeatherKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PlatformSensorBridge")
    PlatformSensorBridge.register(with: registrar)
  }
}

final class PlatformSensorBridge: NSObject, FlutterPlugin, CBCentralManagerDelegate {
  private let pedometer = CMPedometer()
  private var centralManager: CBCentralManager?
  private var ambientResult: FlutterResult?
  private var ambientStartedAt: Date?
  private var ambientTimer: Timer?
  private var ambientSamples: [UUID: [(Date, Int)]] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PlatformSensorBridge()
    let steps = FlutterMethodChannel(
      name: "com.eiranotes.reality_diorama/steps",
      binaryMessenger: registrar.messenger()
    )
    let ambient = FlutterMethodChannel(
      name: "com.eiranotes.reality_diorama/ambient",
      binaryMessenger: registrar.messenger()
    )
    let weather = FlutterMethodChannel(
      name: "com.eiranotes.reality_diorama/weather",
      binaryMessenger: registrar.messenger()
    )
    steps.setMethodCallHandler { call, result in
      instance.handleSteps(call, result: result)
    }
    ambient.setMethodCallHandler { call, result in
      instance.handleAmbient(call, result: result)
    }
    weather.setMethodCallHandler { call, result in
      instance.handleWeather(call, result: result)
    }
  }

  private func handleWeather(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "current":
      guard
        let arguments = call.arguments as? [String: Any],
        let latitude = (arguments["latitude"] as? NSNumber)?.doubleValue,
        let longitude = (arguments["longitude"] as? NSNumber)?.doubleValue
      else {
        result(FlutterError(code: "invalid_arguments", message: "Latitude and longitude are required.", details: nil))
        return
      }
      let location = CLLocation(latitude: latitude, longitude: longitude)
      Task { @MainActor in
        do {
          let current = try await WeatherService.shared.weather(for: location, including: .current)
          let cloudCover = current.cloudCover <= 1.0 ? current.cloudCover * 100.0 : current.cloudCover
          let precipitationMillimetersPerHour =
            current.precipitationIntensity.converted(to: .metersPerSecond).value * 3_600_000
          result([
            "temperatureCelsius": current.temperature.converted(to: .celsius).value,
            "apparentTemperatureCelsius": current.apparentTemperature.converted(to: .celsius).value,
            "precipitationIntensity": precipitationMillimetersPerHour,
            "cloudCoverPercent": cloudCover,
            "windSpeedKph": current.wind.speed.converted(to: .kilometersPerHour).value,
            "visibilityMeters": current.visibility.converted(to: .meters).value,
            "weatherCode": 0,
            "conditionKey": String(describing: current.condition),
            "observedAtMillis": Int(current.date.timeIntervalSince1970 * 1000),
            "providerName": "Apple Weather",
          ])
        } catch {
          result(FlutterError(code: "weather_unavailable", message: "Apple Weather is unavailable.", details: String(describing: error)))
        }
      }
    case "attribution":
      Task { @MainActor in
        do {
          let attribution = try await WeatherService.shared.attribution
          result([
            "serviceName": attribution.serviceName,
            "notice": "\(attribution.serviceName) 데이터를 게임용 재료로 변환했습니다.",
            "legalPageURL": attribution.legalPageURL.absoluteString,
            "combinedMarkDarkURL": attribution.combinedMarkDarkURL.absoluteString,
          ])
        } catch {
          result(FlutterError(code: "attribution_unavailable", message: "Weather attribution is unavailable.", details: String(describing: error)))
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSteps(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "getDailySteps" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard CMPedometer.isStepCountingAvailable() else {
      result([String: Int]())
      return
    }
    let arguments = call.arguments as? [String: Any]
    let fromMillis = (arguments?["fromMillis"] as? NSNumber)?.doubleValue
      ?? Date().addingTimeInterval(-6 * 86_400).timeIntervalSince1970 * 1000
    let toMillis = (arguments?["toMillis"] as? NSNumber)?.doubleValue
      ?? Date().timeIntervalSince1970 * 1000
    let from = Date(timeIntervalSince1970: fromMillis / 1000)
    let to = Date(timeIntervalSince1970: toMillis / 1000)
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: from)
    let end = min(to, Date())
    let group = DispatchGroup()
    let lock = NSLock()
    var output: [String: Int] = [:]
    var cursor = start

    while cursor < end {
      let dayStart = cursor
      let dayEnd = min(calendar.date(byAdding: .day, value: 1, to: dayStart) ?? end, end)
      group.enter()
      pedometer.queryPedometerData(from: dayStart, to: dayEnd) { data, _ in
        let steps = max(0, data?.numberOfSteps.intValue ?? 0)
        lock.lock()
        output[self.dayKey(dayStart)] = steps
        lock.unlock()
        group.leave()
      }
      cursor = dayEnd
    }

    group.notify(queue: .main) {
      result(output)
    }
  }

  private func handleAmbient(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "scan" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard ambientResult == nil else {
      result(FlutterError(code: "scan_in_progress", message: "A surroundings scan is already running.", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let requestedDuration = (arguments?["durationMillis"] as? NSNumber)?.intValue ?? 8_000
    let durationMillis = min(15_000, max(2_000, requestedDuration))
    ambientResult = result
    ambientStartedAt = Date()
    ambientSamples.removeAll(keepingCapacity: true)
    centralManager = CBCentralManager(delegate: self, queue: .main)
    ambientTimer = Timer.scheduledTimer(withTimeInterval: Double(durationMillis) / 1000, repeats: false) { [weak self] _ in
      self?.finishAmbientScan()
    }
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    guard ambientResult != nil else { return }
    switch central.state {
    case .poweredOn:
      central.scanForPeripherals(
        withServices: nil,
        options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
      )
    case .unknown, .resetting:
      break
    default:
      finishAmbientScan(errorCode: "bluetooth_unavailable")
    }
  }

  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi RSSI: NSNumber
  ) {
    guard ambientResult != nil else { return }
    ambientSamples[peripheral.identifier, default: []].append((Date(), RSSI.intValue))
  }

  private func finishAmbientScan(errorCode: String? = nil) {
    guard let result = ambientResult else { return }
    ambientResult = nil
    ambientTimer?.invalidate()
    ambientTimer = nil
    centralManager?.stopScan()
    centralManager = nil

    if let errorCode {
      ambientSamples.removeAll(keepingCapacity: false)
      result(FlutterError(code: errorCode, message: "Bluetooth is unavailable.", details: nil))
      return
    }

    let values = ambientSamples.values.flatMap { samples in samples.map { $0.1 } }.sorted()
    let uniqueCount = ambientSamples.count
    let median = values.isEmpty ? -100.0 : Double(values[values.count / 2])
    let strongRatio = values.isEmpty ? 0.0 : Double(values.filter { $0 >= -65 }.count) / Double(values.count)
    let repeating = ambientSamples.values.filter { $0.count >= 2 }.count
    let oneShot = ambientSamples.values.filter { $0.count == 1 }.count
    let persistence = uniqueCount == 0 ? 0.0 : Double(repeating) / Double(uniqueCount)
    let churn = uniqueCount == 0 ? 0.0 : Double(oneShot) / Double(uniqueCount)
    let elapsed = max(1.0, Date().timeIntervalSince(ambientStartedAt ?? Date()))
    let coverage = min(1.0, Double(values.count) / max(1.0, elapsed * 1.5))

    ambientSamples.removeAll(keepingCapacity: false)
    result([
      "uniqueCount": uniqueCount,
      "medianRssi": median,
      "strongSignalRatio": strongRatio,
      "persistence": persistence,
      "churn": churn,
      "observationCoverage": coverage,
    ])
  }

  private func dayKey(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
