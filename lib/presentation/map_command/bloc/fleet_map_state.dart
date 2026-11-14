import 'package:equatable/equatable.dart';

import '../../../domain/entities/vehicle.dart';

class FleetMapState extends Equatable {
  final List<Vehicle> vehicles;
  final List<Vehicle> filteredVehicles;
  final Vehicle? selectedVehicle;
  final bool isSimulating;
  final String activeFilter; // ALL, IN_TRANSIT, COLD_CHAIN, DELAYED, IDLE_DEPOT
  final String? geofenceAlert;
  final bool isLoading;

  const FleetMapState({
    this.vehicles = const [],
    this.filteredVehicles = const [],
    this.selectedVehicle,
    this.isSimulating = false,
    this.activeFilter = 'ALL',
    this.geofenceAlert,
    this.isLoading = false,
  });

  FleetMapState copyWith({
    List<Vehicle>? vehicles,
    List<Vehicle>? filteredVehicles,
    Vehicle? selectedVehicle,
    bool clearSelectedVehicle = false,
    bool? isSimulating,
    String? activeFilter,
    String? geofenceAlert,
    bool clearGeofenceAlert = false,
    bool? isLoading,
  }) {
    return FleetMapState(
      vehicles: vehicles ?? this.vehicles,
      filteredVehicles: filteredVehicles ?? this.filteredVehicles,
      selectedVehicle: clearSelectedVehicle
          ? null
          : (selectedVehicle ?? this.selectedVehicle),
      isSimulating: isSimulating ?? this.isSimulating,
      activeFilter: activeFilter ?? this.activeFilter,
      geofenceAlert: clearGeofenceAlert
          ? null
          : (geofenceAlert ?? this.geofenceAlert),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
    vehicles,
    filteredVehicles,
    selectedVehicle,
    isSimulating,
    activeFilter,
    geofenceAlert,
    isLoading,
  ];
}
