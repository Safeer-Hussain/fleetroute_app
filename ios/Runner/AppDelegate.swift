import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var eventSink: FlutterEventSink?
  private var timer: Timer?
  private var activeVehicleId: String = "VH-101"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let binaryMessenger = engineBridge.pluginRegistry.registrar(forPlugin: "FleetRouteObdPlugin").messenger()

    let controlChannel = FlutterMethodChannel(name: "com.safeer.fleetroute/obd_control", binaryMessenger: binaryMessenger)
    controlChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "scanVehicles":
        let devices: [[String: Any]] = [
          ["id": "VH-101", "name": "Volvo FH16 Semi - Freight Corridor", "protocol": "ISO 15765-4 CAN"],
          ["id": "VH-102", "name": "Scania R500 Cold-Chain - Lahore Ring", "protocol": "J1939 Heavy Duty"],
          ["id": "VH-103", "name": "Mercedes Actros 2645 - M2 Motorway", "protocol": "ISO 14229 UDS"],
          ["id": "VH-104", "name": "Isuzu NPR 400 Delivery - Urban Core", "protocol": "ISO 15765-4 CAN"]
        ]
        result(devices)
      case "connectObdAdapter":
        if let args = call.arguments as? [String: Any], let vehicleId = args["vehicleId"] as? String {
          self.activeVehicleId = vehicleId
        }
        result(true)
      case "runDtcDiagnosticScan":
        let dtcList: [[String: Any]] = [
          [
            "code": "P0128",
            "title": "Coolant Thermostat Below Regulating Temp",
            "severity": "WARNING",
            "system": "Powertrain Engine Cooling",
            "status": "CONFIRMED_FAULT"
          ],
          [
            "code": "C0034",
            "title": "Right Front Wheel Speed Sensor Range Performance",
            "severity": "WARNING",
            "system": "Chassis Anti-Lock Braking",
            "status": "PENDING_FAULT"
          ]
        ]
        result(dtcList)
      case "clearDtcFaultCodes":
        result(["status": "CLEARED", "clearedCount": 2])
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let telemetryChannel = FlutterEventChannel(name: "com.safeer.fleetroute/obd_telemetry", binaryMessenger: binaryMessenger)
    telemetryChannel.setStreamHandler(self)
  }
}

extension AppDelegate: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
      guard let self = self, let sink = self.eventSink else { return }
      let packet: [String: Any] = [
        "vehicleId": self.activeVehicleId,
        "engineRpm": Int.random(in: 1650...1900),
        "speedKmh": Double(round(10 * Double.random(in: 64.0...75.0)) / 10),
        "coolantTempC": Double(round(10 * Double.random(in: 87.0...91.0)) / 10),
        "fuelLevelPercent": 71.5,
        "batterySocPercent": 94.0,
        "tirePressureFl": 34.2,
        "tirePressureFr": 34.0,
        "tirePressureRl": 35.8,
        "tirePressureRr": 35.5,
        "cargoTempC": -18.2,
        "dtcStatus": "NORMAL",
        "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
      ]
      sink(packet)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.timer?.invalidate()
    self.timer = nil
    self.eventSink = nil
    return nil
  }
}
