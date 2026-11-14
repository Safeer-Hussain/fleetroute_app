import 'package:equatable/equatable.dart';

abstract class FleetMapEvent extends Equatable {
  const FleetMapEvent();

  @override
  List<Object?> get props => [];
}

class LoadFleetMapEvent extends FleetMapEvent {}

class SelectVehicleEvent extends FleetMapEvent {
  final String vehicleId;
  const SelectVehicleEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class ClearSelectedVehicleEvent extends FleetMapEvent {}

class ToggleFleetSimulationEvent extends FleetMapEvent {}

class FilterVehiclesEvent extends FleetMapEvent {
  final String filter; // ALL, IN_TRANSIT, COLD_CHAIN, DELAYED, IDLE_DEPOT
  const FilterVehiclesEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class SimulateVehicleMovementStepEvent extends FleetMapEvent {}

class InjectGeofenceBreachEvent extends FleetMapEvent {
  final String vehicleId;
  const InjectGeofenceBreachEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class ClearGeofenceAlertEvent extends FleetMapEvent {}
