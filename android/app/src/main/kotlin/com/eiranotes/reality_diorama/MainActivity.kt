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
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
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
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activeScanCallback: ScanCallback? = null
    private var activeScanner: android.bluetooth.le.BluetoothLeScanner? = null
    @Volatile private var activeAudioRecord: AudioRecord? = null
    @Volatile private var activeSenseResult: MethodChannel.Result? = null
    private var senseThread: Thread? = null

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.eiranotes.reality_diorama/sense",
        ).setMethodCallHandler(::handleSense)
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

    private fun handleSense(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "sampleAudio") {
            result.notImplemented()
            return
        }
        if (activeSenseResult != null) {
            result.error("sample_in_progress", "A sensory sample is already running.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission_required", "Microphone permission is required.", null)
            return
        }

        val durationMillis = (call.argument<Number>("durationMillis")?.toLong() ?: 4_000L)
            .coerceIn(1_000L, 10_000L)
        val sampleRate = 16_000
        val minimumBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minimumBuffer <= 0) {
            result.error("audio_unavailable", "Audio input is unavailable.", null)
            return
        }
        val bufferSize = max(minimumBuffer, 4_096)
        val audioRecord = try {
            AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                        .build(),
                )
                .setBufferSizeInBytes(bufferSize)
                .build()
        } catch (_: SecurityException) {
            result.error("permission_required", "Microphone permission is required.", null)
            return
        } catch (error: IllegalArgumentException) {
            result.error("audio_unavailable", "Audio input could not be configured.", error.toString())
            return
        }
        if (audioRecord.state != AudioRecord.STATE_INITIALIZED) {
            audioRecord.release()
            result.error("audio_unavailable", "Audio input could not be initialized.", null)
            return
        }

        activeSenseResult = result
        activeAudioRecord = audioRecord
        val worker = Thread({
            Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
            val envelope = mutableListOf<Double>()
            var zeroCrossings = 0
            var samplesRead = 0
            var clippedSamples = 0
            var previousSample = 0
            var hasPrevious = false
            val buffer = ShortArray(bufferSize / 2)
            val startedAt = SystemClock.elapsedRealtime()
            val endAt = startedAt + durationMillis
            try {
                audioRecord.startRecording()
                while (
                    activeSenseResult === result &&
                    !Thread.currentThread().isInterrupted &&
                    SystemClock.elapsedRealtime() < endAt
                ) {
                    val count = audioRecord.read(
                        buffer,
                        0,
                        buffer.size,
                        AudioRecord.READ_BLOCKING,
                    )
                    if (count <= 0) continue
                    var squareSum = 0.0
                    for (index in 0 until count) {
                        val sample = buffer[index].toInt()
                        val normalized = sample / 32_768.0
                        squareSum += normalized * normalized
                        if (abs(sample) >= 32_100) clippedSamples += 1
                        if (hasPrevious &&
                            ((sample >= 0 && previousSample < 0) ||
                                (sample < 0 && previousSample >= 0))
                        ) {
                            zeroCrossings += 1
                        }
                        previousSample = sample
                        hasPrevious = true
                    }
                    envelope += sqrt(squareSum / count)
                    samplesRead += count
                }
                val snapshot = AudioSampleSnapshot(
                    envelope = envelope,
                    zeroCrossingCount = zeroCrossings,
                    sampleCount = samplesRead,
                    clippedSampleCount = clippedSamples,
                    sampleRate = sampleRate.toDouble(),
                    durationSeconds = durationMillis / 1_000.0,
                )
                completeSenseSample(result, audioRecord, snapshot, null)
            } catch (error: Exception) {
                completeSenseSample(result, audioRecord, null, error)
            }
        }, "LocusSenseSampler")
        senseThread = worker
        worker.start()
    }

    private fun completeSenseSample(
        callback: MethodChannel.Result,
        audioRecord: AudioRecord,
        snapshot: AudioSampleSnapshot?,
        error: Exception?,
    ) {
        try {
            if (audioRecord.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                audioRecord.stop()
            }
        } catch (_: IllegalStateException) {
        }
        audioRecord.release()
        mainHandler.post {
            if (activeSenseResult !== callback) return@post
            activeSenseResult = null
            activeAudioRecord = null
            senseThread = null
            if (error != null) {
                callback.error("audio_unavailable", "Audio sampling failed.", error.toString())
                return@post
            }
            if (snapshot == null || snapshot.envelope.size < 4 || snapshot.sampleCount <= 0) {
                callback.error("insufficient_audio", "Not enough audio was observed.", null)
                return@post
            }
            callback.success(deriveAudioFeatures(snapshot))
        }
    }

    private fun deriveAudioFeatures(snapshot: AudioSampleSnapshot): Map<String, Any> {
        val sorted = snapshot.envelope.sorted()
        val meanRms = snapshot.envelope.average()
        val decibels = 20 * log10(max(meanRms, 0.000_001))
        val loudness = clamp01((decibels + 60) / 50)
        val median = percentile(sorted, 0.50)
        val inactiveThreshold = max(0.002, median * 0.45)
        val inactiveRatio = snapshot.envelope.count { it < inactiveThreshold }.toDouble() /
            snapshot.envelope.size
        var transitions = 0
        for (index in 1 until snapshot.envelope.size) {
            val previousActive = snapshot.envelope[index - 1] >= inactiveThreshold
            val currentActive = snapshot.envelope[index] >= inactiveThreshold
            if (previousActive != currentActive) transitions += 1
        }
        val transitionRatio = transitions.toDouble() / max(1, snapshot.envelope.size - 1)
        val intermittency = clamp01(inactiveRatio * 0.65 + min(1.0, transitionRatio * 2) * 0.35)
        val p10 = percentile(sorted, 0.10)
        val p90 = percentile(sorted, 0.90)
        val dynamicRange = clamp01((p90 - p10) / max(p90, 0.01))
        val rhythmicity = envelopeRhythmicity(snapshot.envelope)
        val zeroCrossingRate = snapshot.zeroCrossingCount.toDouble() / snapshot.sampleCount
        val spectralBrightness = clamp01(zeroCrossingRate / 0.18)
        val expectedSamples = max(1.0, snapshot.sampleRate * snapshot.durationSeconds)
        val coverage = min(1.0, snapshot.sampleCount / expectedSamples)
        val clippedRatio = snapshot.clippedSampleCount.toDouble() / snapshot.sampleCount
        val confidence = clamp01(coverage * (1 - min(0.55, clippedRatio * 5)))
        return mapOf(
            "schemaVersion" to "audio-features-v1",
            "loudness" to loudness,
            "intermittency" to intermittency,
            "rhythmicity" to rhythmicity,
            "dynamicRange" to dynamicRange,
            "spectralBrightness" to spectralBrightness,
            "confidence" to confidence,
        )
    }

    private fun envelopeRhythmicity(values: List<Double>): Double {
        if (values.size < 8) return 0.0
        val mean = values.average()
        val centered = values.map { it - mean }
        val energy = centered.sumOf { it * it }
        if (energy <= 0.000_000_1) return 0.0
        val maximumLag = min(20, values.size / 2)
        var best = 0.0
        for (lag in 2..maximumLag) {
            var correlation = 0.0
            for (index in lag until centered.size) {
                correlation += centered[index] * centered[index - lag]
            }
            best = max(best, correlation / energy)
        }
        return clamp01(best * 1.6)
    }

    private fun percentile(sorted: List<Double>, fraction: Double): Double {
        if (sorted.isEmpty()) return 0.0
        val position = (fraction * (sorted.size - 1)).toInt().coerceIn(0, sorted.size - 1)
        return sorted[position]
    }

    private fun clamp01(value: Double): Double = value.coerceIn(0.0, 1.0)

    private fun stopActiveSense(errorCode: String, message: String) {
        val result = activeSenseResult ?: return
        activeSenseResult = null
        val record = activeAudioRecord
        activeAudioRecord = null
        senseThread?.interrupt()
        senseThread = null
        try {
            if (record?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                record.stop()
            }
        } catch (_: IllegalStateException) {
        }
        result.error(errorCode, message, null)
    }

    override fun onPause() {
        if (!isChangingConfigurations) {
            stopActiveSense("interrupted", "Audio sampling was interrupted.")
        }
        super.onPause()
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
        stopActiveSense("interrupted", "Audio sampling was interrupted.")
        mainHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun dayKey(timestampMillis: Long): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        formatter.timeZone = TimeZone.getDefault()
        return formatter.format(Date(timestampMillis))
    }
}

private data class AudioSampleSnapshot(
    val envelope: List<Double>,
    val zeroCrossingCount: Int,
    val sampleCount: Int,
    val clippedSampleCount: Int,
    val sampleRate: Double,
    val durationSeconds: Double,
)
