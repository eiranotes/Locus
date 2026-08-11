import AVFoundation
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
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PlatformSensorBridge") else {
      assertionFailure("PlatformSensorBridge registrar is unavailable.")
      return
    }
    PlatformSensorBridge.register(with: registrar)
    SenseSamplerBridge.register(with: registrar)
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

final class SenseSamplerBridge: NSObject {
  private let audioEngine = AVAudioEngine()
  private let sampleLock = NSLock()
  private var pendingResult: FlutterResult?
  private var finishWorkItem: DispatchWorkItem?
  private var tapInstalled = false
  private var requestedDurationSeconds = 4.0
  private var sampleRate = 16_000.0
  private var envelope: [Double] = []
  private var zeroCrossingCount = 0
  private var sampleCount = 0
  private var clippedSampleCount = 0
  private var previousSample: Float = 0
  private var hasPreviousSample = false

  override init() {
    super.init()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SenseSamplerBridge()
    let channel = FlutterMethodChannel(
      name: "com.eiranotes.reality_diorama/sense",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "sampleAudio" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard pendingResult == nil else {
      result(FlutterError(code: "sample_in_progress", message: "A sensory sample is already running.", details: nil))
      return
    }
    let session = AVAudioSession.sharedInstance()
    guard session.recordPermission == .granted else {
      result(FlutterError(code: "permission_required", message: "Microphone permission is required.", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    let requestedMillis = (arguments?["durationMillis"] as? NSNumber)?.intValue ?? 4_000
    let durationMillis = min(10_000, max(1_000, requestedMillis))
    pendingResult = result
    requestedDurationSeconds = Double(durationMillis) / 1_000
    resetSamples()

    do {
      try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
      try session.setActive(true)
      let input = audioEngine.inputNode
      let format = input.outputFormat(forBus: 0)
      guard format.sampleRate > 0, format.channelCount > 0 else {
        finish(errorCode: "audio_unavailable", message: "Audio input is unavailable.")
        return
      }
      sampleRate = format.sampleRate
      input.installTap(onBus: 0, bufferSize: 1_024, format: format) { [weak self] buffer, _ in
        self?.consume(buffer)
      }
      tapInstalled = true
      audioEngine.prepare()
      try audioEngine.start()
      let workItem = DispatchWorkItem { [weak self] in
        self?.finish()
      }
      finishWorkItem = workItem
      DispatchQueue.main.asyncAfter(
        deadline: .now() + requestedDurationSeconds,
        execute: workItem
      )
    } catch {
      finish(
        errorCode: "audio_unavailable",
        message: "Audio sampling could not start.",
        details: String(describing: error)
      )
    }
  }

  private func consume(_ buffer: AVAudioPCMBuffer) {
    guard
      let channel = buffer.floatChannelData?.pointee,
      buffer.frameLength > 0
    else { return }
    let count = Int(buffer.frameLength)
    var squareSum = 0.0
    var localZeroCrossings = 0
    var localClipped = 0
    var localPrevious = previousSample
    var localHasPrevious = hasPreviousSample
    for index in 0..<count {
      let sample = channel[index]
      squareSum += Double(sample * sample)
      if abs(sample) >= 0.98 { localClipped += 1 }
      if localHasPrevious,
        (sample >= 0 && localPrevious < 0) || (sample < 0 && localPrevious >= 0)
      {
        localZeroCrossings += 1
      }
      localPrevious = sample
      localHasPrevious = true
    }
    let rms = sqrt(squareSum / Double(count))
    sampleLock.lock()
    envelope.append(rms)
    zeroCrossingCount += localZeroCrossings
    clippedSampleCount += localClipped
    sampleCount += count
    previousSample = localPrevious
    hasPreviousSample = localHasPrevious
    sampleLock.unlock()
  }

  @objc private func applicationWillResignActive() {
    finish(errorCode: "interrupted", message: "Audio sampling was interrupted.")
  }

  private func finish(
    errorCode: String? = nil,
    message: String? = nil,
    details: String? = nil
  ) {
    if !Thread.isMainThread {
      DispatchQueue.main.async { [weak self] in
        self?.finish(errorCode: errorCode, message: message, details: details)
      }
      return
    }
    guard let result = pendingResult else { return }
    pendingResult = nil
    finishWorkItem?.cancel()
    finishWorkItem = nil
    if tapInstalled {
      audioEngine.inputNode.removeTap(onBus: 0)
      tapInstalled = false
    }
    audioEngine.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])

    if let errorCode {
      resetSamples()
      result(FlutterError(code: errorCode, message: message, details: details))
      return
    }

    let snapshot = sampleSnapshot()
    guard snapshot.envelope.count >= 4, snapshot.sampleCount > 0 else {
      resetSamples()
      result(FlutterError(code: "insufficient_audio", message: "Not enough audio was observed.", details: nil))
      return
    }
    let features = deriveFeatures(snapshot)
    resetSamples()
    result([
      "schemaVersion": "audio-features-v1",
      "loudness": features.loudness,
      "intermittency": features.intermittency,
      "rhythmicity": features.rhythmicity,
      "dynamicRange": features.dynamicRange,
      "spectralBrightness": features.spectralBrightness,
      "confidence": features.confidence,
    ])
  }

  private func sampleSnapshot() -> AudioSampleSnapshot {
    sampleLock.lock()
    defer { sampleLock.unlock() }
    return AudioSampleSnapshot(
      envelope: envelope,
      zeroCrossingCount: zeroCrossingCount,
      sampleCount: sampleCount,
      clippedSampleCount: clippedSampleCount,
      sampleRate: sampleRate,
      durationSeconds: requestedDurationSeconds
    )
  }

  private func resetSamples() {
    sampleLock.lock()
    envelope.removeAll(keepingCapacity: true)
    zeroCrossingCount = 0
    sampleCount = 0
    clippedSampleCount = 0
    previousSample = 0
    hasPreviousSample = false
    sampleLock.unlock()
  }

  private func deriveFeatures(_ snapshot: AudioSampleSnapshot) -> AudioFeatures {
    let sorted = snapshot.envelope.sorted()
    let meanRms = snapshot.envelope.reduce(0, +) / Double(snapshot.envelope.count)
    let decibels = 20 * log10(max(meanRms, 0.000_001))
    let loudness = clamp((decibels + 60) / 50)
    let median = percentile(sorted, fraction: 0.50)
    let inactiveThreshold = max(0.002, median * 0.45)
    let inactive = snapshot.envelope.filter { $0 < inactiveThreshold }.count
    var transitions = 0
    for index in 1..<snapshot.envelope.count {
      let previousActive = snapshot.envelope[index - 1] >= inactiveThreshold
      let currentActive = snapshot.envelope[index] >= inactiveThreshold
      if previousActive != currentActive { transitions += 1 }
    }
    let inactiveRatio = Double(inactive) / Double(snapshot.envelope.count)
    let transitionRatio = Double(transitions) / Double(max(1, snapshot.envelope.count - 1))
    let intermittency = clamp(inactiveRatio * 0.65 + min(1, transitionRatio * 2) * 0.35)
    let p10 = percentile(sorted, fraction: 0.10)
    let p90 = percentile(sorted, fraction: 0.90)
    let dynamicRange = clamp((p90 - p10) / max(p90, 0.01))
    let rhythmicity = envelopeRhythmicity(snapshot.envelope)
    let zeroCrossingRate = Double(snapshot.zeroCrossingCount) / Double(snapshot.sampleCount)
    let spectralBrightness = clamp(zeroCrossingRate / 0.18)
    let expectedSamples = max(1, snapshot.sampleRate * snapshot.durationSeconds)
    let coverage = min(1, Double(snapshot.sampleCount) / expectedSamples)
    let clippedRatio = Double(snapshot.clippedSampleCount) / Double(snapshot.sampleCount)
    let confidence = clamp(coverage * (1 - min(0.55, clippedRatio * 5)))
    return AudioFeatures(
      loudness: loudness,
      intermittency: intermittency,
      rhythmicity: rhythmicity,
      dynamicRange: dynamicRange,
      spectralBrightness: spectralBrightness,
      confidence: confidence
    )
  }

  private func envelopeRhythmicity(_ values: [Double]) -> Double {
    guard values.count >= 8 else { return 0 }
    let mean = values.reduce(0, +) / Double(values.count)
    let centered = values.map { $0 - mean }
    let energy = centered.reduce(0) { $0 + $1 * $1 }
    guard energy > 0.000_000_1 else { return 0 }
    let maximumLag = min(20, values.count / 2)
    var best = 0.0
    if maximumLag >= 2 {
      for lag in 2...maximumLag {
        var correlation = 0.0
        for index in lag..<centered.count {
          correlation += centered[index] * centered[index - lag]
        }
        best = max(best, correlation / energy)
      }
    }
    return clamp(best * 1.6)
  }

  private func percentile(_ sorted: [Double], fraction: Double) -> Double {
    guard !sorted.isEmpty else { return 0 }
    let position = min(sorted.count - 1, max(0, Int((Double(sorted.count - 1) * fraction).rounded())))
    return sorted[position]
  }

  private func clamp(_ value: Double) -> Double {
    min(1, max(0, value))
  }
}

private struct AudioSampleSnapshot {
  let envelope: [Double]
  let zeroCrossingCount: Int
  let sampleCount: Int
  let clippedSampleCount: Int
  let sampleRate: Double
  let durationSeconds: Double
}

private struct AudioFeatures {
  let loudness: Double
  let intermittency: Double
  let rhythmicity: Double
  let dynamicRange: Double
  let spectralBrightness: Double
  let confidence: Double
}
