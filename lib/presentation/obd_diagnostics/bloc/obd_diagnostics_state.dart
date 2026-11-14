import 'package:equatable/equatable.dart';

import '../../../domain/entities/dtc_fault.dart';
import '../../../domain/entities/obd_telemetry_packet.dart';

class ObdDiagnosticsState extends Equatable {
  final String selectedVehicleId;
  final List<Map<String, dynamic>> availableVehicles;
  final ObdTelemetryPacket? latestTelemetry;
  final List<DtcFault> activeFaults;
  final bool isScanning;
  final bool isConnecting;
  final String? statusMessage;

  const ObdDiagnosticsState({
    this.selectedVehicleId = 'VH-101',
    this.availableVehicles = const [],
    this.latestTelemetry,
    this.activeFaults = const [],
    this.isScanning = false,
    this.isConnecting = false,
    this.statusMessage,
  });

  ObdDiagnosticsState copyWith({
    String? selectedVehicleId,
    List<Map<String, dynamic>>? availableVehicles,
    ObdTelemetryPacket? latestTelemetry,
    List<DtcFault>? activeFaults,
    bool? isScanning,
    bool? isConnecting,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return ObdDiagnosticsState(
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      latestTelemetry: latestTelemetry ?? this.latestTelemetry,
      activeFaults: activeFaults ?? this.activeFaults,
      isScanning: isScanning ?? this.isScanning,
      isConnecting: isConnecting ?? this.isConnecting,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
    selectedVehicleId,
    availableVehicles,
    latestTelemetry,
    activeFaults,
    isScanning,
    isConnecting,
    statusMessage,
  ];
}
