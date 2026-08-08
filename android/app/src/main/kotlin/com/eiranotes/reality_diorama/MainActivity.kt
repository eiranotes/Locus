package com.eiranotes.reality_diorama

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max
import kotlin.math.min

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeScanCallback: ScanCallback? = null
    private var activeScanner: android.bluetooth.le.BluetoothLeScanner? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.eiranotes.reality_diorama/steps",
        ).setMethodCallHandler(::handleSteps)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.eiranotes.reality_diorama/ambient",
        ).setMethodCallHandler(::handleAmbient)
    }

    private fun handleSteps(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "getDailySteps") {
            result.notImplemented()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACTIVITY_RECOGNITION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_required", "Activity Recognition permission is required.", null)
            return
        }

        val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val counter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (counter == null) {
            result.success(emptyMap<String, Int>())
            return
        }

        var completed = false
        lateinit var listener: SensorEventListener
        val timeout = Runnable {
            if (!completed) {
                completed = true
                sensorManager.unregisterListener(listener)
                result.success(emptyMap<String, Int>())
            }
        }
        listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (completed) return
                completed = true
                mainHandler.removeCallbacks(timeout)
                sensorManager.unregisterListener(this)
                val totalSinceBoot = event.values.firstOrNull()?.toInt() ?: 0
                val value = currentDaySteps(totalSinceBoot)
                if (value == null) {
                    result.success(emptyMap<String, Int>())
                } else {
                    result.success(mapOf(dayKey(System.currentTimeMillis()) to value))
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }
        sensorManager.registerListener(listener, counter, SensorManager.SENSOR_DELAY_NORMAL)
        mainHandler.postDelayed(timeout, 2_500)
    }

    private fun currentDaySteps(totalSinceBoot: Int): Int? {
        val prefs = getSharedPreferences("step_ledger", Context.MODE_PRIVATE)
        val bootCount = try {
            Settings.Global.getInt(contentResolver, Settings.Global.BOOT_COUNT)
        } catch (_: Exception) {
            0
        }
        val key = dayKey(System.currentTimeMillis())
        val storedDay = prefs.getString("day_key", null)
        val storedBoot = prefs.getInt("boot_count", Int.MIN_VALUE)
        val storedBaseline = prefs.getInt("baseline_total", totalSinceBoot)
        val storedCarried = prefs.getInt("carried_steps", 0)
        val storedLast = prefs.getInt("last_computed", 0)

        if (storedDay != key) {
            prefs.edit()
                .clear()
                .putString("day_key", key)
                .putInt("boot_count", bootCount)
                .putInt("baseline_total", totalSinceBoot)
                .putInt("carried_steps", 0)
                .putInt("last_computed", 0)
                .apply()
            return 0
        }

        if (storedBoot != bootCount || totalSinceBoot < storedBaseline) {
            val carried = max(storedCarried, storedLast)
            prefs.edit()
                .putInt("boot_count", bootCount)
                .putInt("baseline_total", totalSinceBoot)
                .putInt("carried_steps", carried)
                .putInt("last_computed", carried)
                .apply()
            return carried
        }

        val computed = max(storedLast, storedCarried + max(0, totalSinceBoot - storedBaseline))
        prefs.edit().putInt("last_computed", computed).apply()
        return computed
    }

    private fun handleAmbient(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "scan") {
            result.notImplemented()
            return
        }
        if (activeScanCallback != null) {
            result.error("scan_in_progress", "A surroundings scan is already running.", null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_required", "Bluetooth Scan permission is required.", null)
            return
        }

        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager.adapter
        val scanner = adapter?.bluetoothLeScanner
        if (adapter == null || !adapter.isEnabled || scanner == null) {
            result.error("bluetooth_unavailable", "Bluetooth is unavailable or disabled.", null)
            return
        }

        val durationMillis = (call.argument<Number>("durationMillis")?.toLong() ?: 8_000L)
            .coerceIn(2_000L, 15_000L)
        val startedAt = System.currentTimeMillis()
        val samples = mutableMapOf<String, MutableList<Pair<Long, Int>>>()
        var observationCount = 0

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                val now = System.currentTimeMillis()
                val sessionKey = scanResult.device.address.hashCode().toString()
                samples.getOrPut(sessionKey) { mutableListOf() }.add(now to scanResult.rssi)
                observationCount += 1
            }

            override fun onBatchScanResults(results: MutableList<ScanResult>) {
                results.forEach { onScanResult(0, it) }
            }

            override fun onScanFailed(errorCode: Int) {
                finishAmbientScan(scanner, this, result, startedAt, durationMillis, samples, observationCount)
            }
        }
        activeScanCallback = callback
        activeScanner = scanner
        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .setReportDelay(0)
            .build()
        try {
            scanner.startScan(null, settings, callback)
        } catch (_: SecurityException) {
            activeScanCallback = null
            activeScanner = null
            result.error("permission_required", "Bluetooth Scan permission is required.", null)
            return
        } catch (_: IllegalStateException) {
            activeScanCallback = null
            activeScanner = null
            result.error("bluetooth_unavailable", "Bluetooth scanning could not start.", null)
            return
        }
        mainHandler.postDelayed({
            finishAmbientScan(scanner, callback, result, startedAt, durationMillis, samples, observationCount)
        }, durationMillis)
    }

    private fun finishAmbientScan(
        scanner: android.bluetooth.le.BluetoothLeScanner,
        callback: ScanCallback,
        result: MethodChannel.Result,
        startedAt: Long,
        durationMillis: Long,
        samples: Map<String, List<Pair<Long, Int>>>,
        observationCount: Int,
    ) {
        if (activeScanCallback !== callback) return
        activeScanCallback = null
        activeScanner = null
        try {
            scanner.stopScan(callback)
        } catch (_: SecurityException) {
        }

        val unique = samples.size
        val allRssi = samples.values.flatten().map { it.second }.sorted()
        val median = if (allRssi.isEmpty()) -100.0 else allRssi[allRssi.size / 2].toDouble()
        val strongRatio = if (allRssi.isEmpty()) 0.0 else allRssi.count { it >= -65 }.toDouble() / allRssi.size
        val repeating = samples.values.count { it.size >= 2 }
        val oneShot = samples.values.count { it.size == 1 }
        val persistence = if (unique == 0) 0.0 else repeating.toDouble() / unique
        val churn = if (unique == 0) 0.0 else oneShot.toDouble() / unique
        val elapsed = max(1L, System.currentTimeMillis() - startedAt)
        val expected = max(1.0, elapsed / 1_000.0 * 1.5)
        val coverage = min(1.0, observationCount / expected)

        result.success(
            mapOf(
                "uniqueCount" to unique,
                "medianRssi" to median,
                "strongSignalRatio" to strongRatio,
                "persistence" to persistence,
                "churn" to churn,
                "observationCoverage" to coverage,
            ),
        )
    }

    override fun onDestroy() {
        val callback = activeScanCallback
        val scanner = activeScanner
        if (callback != null && scanner != null) {
            try {
                scanner.stopScan(callback)
            } catch (_: SecurityException) {
            }
        }
        activeScanCallback = null
        activeScanner = null
        mainHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun dayKey(timestampMillis: Long): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        formatter.timeZone = TimeZone.getDefault()
        return formatter.format(Date(timestampMillis))
    }
}
