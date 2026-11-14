package com.safeer.fleetroute

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.random.Random

class MainActivity : FlutterActivity() {
    private val controlChannelName = "com.safeer.fleetroute/obd_control"
    private val telemetryChannelName = "com.safeer.fleetroute/obd_telemetry"

    private var eventSink: EventChannel.EventSink? = null
    private val telemetryHandler = Handler(Looper.getMainLooper())
    private var isStreaming = false
    private var activeVehicleId = "VH-101"

    private val telemetryRunnable = object : Runnable {
        override fun run() {
            if (isStreaming && eventSink != null) {
                val baseRpm = 1750 + Random.nextInt(-150, 220)
                val baseSpeed = 68.5 + Random.nextDouble(-5.0, 7.5)
                val coolantTemp = 88.0 + Random.nextDouble(-1.5, 2.0)
                val fuelLevel = (72.0 - Random.nextDouble(0.0, 0.2)).coerceAtLeast(10.0)
                val cargoTemp = (-18.2 + Random.nextDouble(-0.4, 0.5))

                val packet = mapOf(
                    "vehicleId" to activeVehicleId,
                    "engineRpm" to baseRpm,
                    "speedKmh" to Math.round(baseSpeed * 10.0) / 10.0,
                    "coolantTempC" to Math.round(coolantTemp * 10.0) / 10.0,
                    "fuelLevelPercent" to Math.round(fuelLevel * 10.0) / 10.0,
                    "batterySocPercent" to 94.0,
                    "tirePressureFl" to 34.2,
                    "tirePressureFr" to 34.0,
                    "tirePressureRl" to 35.8,
                    "tirePressureRr" to 35.5,
                    "cargoTempC" to Math.round(cargoTemp * 10.0) / 10.0,
                    "dtcStatus" to "NORMAL",
                    "timestamp" to System.currentTimeMillis()
                )
                eventSink?.success(packet)
            }
            if (isStreaming) {
                telemetryHandler.postDelayed(this, 2000L)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controlChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanVehicles" -> {
                        val devices = listOf(
                            mapOf("id" to "VH-101", "name" to "Volvo FH16 Semi - Freight Corridor", "protocol" to "ISO 15765-4 CAN"),
                            mapOf("id" to "VH-102", "name" to "Scania R500 Cold-Chain - Lahore Ring", "protocol" to "J1939 Heavy Duty"),
                            mapOf("id" to "VH-103", "name" to "Mercedes Actros 2645 - M2 Motorway", "protocol" to "ISO 14229 UDS"),
                            mapOf("id" to "VH-104", "name" to "Isuzu NPR 400 Delivery - Urban Core", "protocol" to "ISO 15765-4 CAN")
                        )
                        result.success(devices)
                    }
                    "connectObdAdapter" -> {
                        val vehicleId = call.argument<String>("vehicleId") ?: "VH-101"
                        activeVehicleId = vehicleId
                        result.success(true)
                    }
                    "runDtcDiagnosticScan" -> {
                        val vehicleId = call.argument<String>("vehicleId") ?: activeVehicleId
                        val dtcList = if (vehicleId == "VH-102" || vehicleId == "VH-105") {
                            listOf(
                                mapOf(
                                    "code" to "P0128",
                                    "title" to "Coolant Thermostat Below Regulating Temp",
                                    "severity" to "WARNING",
                                    "system" to "Powertrain Engine Cooling",
                                    "status" to "CONFIRMED_FAULT"
                                ),
                                mapOf(
                                    "code" to "C0034",
                                    "title" to "Right Front Wheel Speed Sensor Range Performance",
                                    "severity" to "WARNING",
                                    "system" to "Chassis Anti-Lock Braking",
                                    "status" to "PENDING_FAULT"
                                )
                            )
                        } else {
                            listOf(
                                mapOf(
                                    "code" to "P0420",
                                    "title" to "Catalyst System Efficiency Below Threshold",
                                    "severity" to "INFO",
                                    "system" to "Exhaust Emission Control",
                                    "status" to "HISTORICAL_LOGGED"
                                )
                            )
                        }
                        result.success(dtcList)
                    }
                    "clearDtcFaultCodes" -> {
                        result.success(mapOf("status" to "CLEARED", "clearedCount" to 2))
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, telemetryChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    isStreaming = true
                    telemetryHandler.removeCallbacks(telemetryRunnable)
                    telemetryHandler.post(telemetryRunnable)
                }

                override fun onCancel(arguments: Any?) {
                    isStreaming = false
                    telemetryHandler.removeCallbacks(telemetryRunnable)
                    eventSink = null
                }
            })
    }

    override fun onDestroy() {
        isStreaming = false
        telemetryHandler.removeCallbacks(telemetryRunnable)
        super.onDestroy()
    }
}
