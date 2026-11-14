import 'package:equatable/equatable.dart';

import '../../../domain/entities/obd_telemetry_packet.dart';

abstract class ObdDiagnosticsEvent extends Equatable {
  const ObdDiagnosticsEvent();

  @override
  List<Object?> get props => [];
}

class InitializeObdEvent extends ObdDiagnosticsEvent {}

class SelectObdVehicleEvent extends ObdDiagnosticsEvent {
  final String vehicleId;
  const SelectObdVehicleEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class RunDtcScanEvent extends ObdDiagnosticsEvent {
  final String vehicleId;
  const RunDtcScanEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class ClearDtcCodesEvent extends ObdDiagnosticsEvent {
  final String vehicleId;
  const ClearDtcCodesEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class ScheduleWorkshopServiceEvent extends ObdDiagnosticsEvent {
  final String faultId;
  const ScheduleWorkshopServiceEvent(this.faultId);

  @override
  List<Object?> get props => [faultId];
}

class TelemetryReceivedEvent extends ObdDiagnosticsEvent {
  final ObdTelemetryPacket packet;
  const TelemetryReceivedEvent(this.packet);

  @override
  List<Object?> get props => [packet];
}
