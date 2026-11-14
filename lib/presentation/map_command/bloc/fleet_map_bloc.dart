import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/fleet_repository.dart';
import 'fleet_map_event.dart';
import 'fleet_map_state.dart';

class FleetMapBloc extends Bloc<FleetMapEvent, FleetMapState> {
  final FleetRepository fleetRepository;
  Timer? _simulationTimer;

  FleetMapBloc({required this.fleetRepository}) : super(const FleetMapState()) {
    on<LoadFleetMapEvent>(_onLoadFleetMap);
    on<SelectVehicleEvent>(_onSelectVehicle);
    on<ClearSelectedVehicleEvent>(_onClearSelectedVehicle);
    on<ToggleFleetSimulationEvent>(_onToggleSimulation);
    on<SimulateVehicleMovementStepEvent>(_onSimulationStep);
    on<FilterVehiclesEvent>(_onFilterVehicles);
    on<InjectGeofenceBreachEvent>(_onInjectGeofenceBreach);
    on<ClearGeofenceAlertEvent>(_onClearGeofenceAlert);
  }

  Future<void> _onLoadFleetMap(
    LoadFleetMapEvent event,
    Emitter<FleetMapState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final vehicles = await fleetRepository.getVehicles();
      final filtered = _applyFilter(vehicles, state.activeFilter);
      Vehicle? selected = state.selectedVehicle;
      if (selected != null) {
        final found = vehicles.where((v) => v.id == selected!.id).toList();
        if (found.isNotEmpty) selected = found.first;
      }
      emit(
        state.copyWith(
          vehicles: List.unmodifiable(vehicles),
          filteredVehicles: List.unmodifiable(filtered),
          selectedVehicle: selected,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onSelectVehicle(SelectVehicleEvent event, Emitter<FleetMapState> emit) {
    final matches = state.vehicles
        .where((v) => v.id == event.vehicleId)
        .toList();
    if (matches.isNotEmpty) {
      emit(state.copyWith(selectedVehicle: matches.first));
    }
  }

  void _onClearSelectedVehicle(
    ClearSelectedVehicleEvent event,
    Emitter<FleetMapState> emit,
  ) {
    emit(state.copyWith(clearSelectedVehicle: true));
  }

  void _onToggleSimulation(
    ToggleFleetSimulationEvent event,
    Emitter<FleetMapState> emit,
  ) {
    final newSimulating = !state.isSimulating;
    _simulationTimer?.cancel();

    if (newSimulating) {
      _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        add(SimulateVehicleMovementStepEvent());
      });
    }

    emit(state.copyWith(isSimulating: newSimulating));
  }

  Future<void> _onSimulationStep(
    SimulateVehicleMovementStepEvent event,
    Emitter<FleetMapState> emit,
  ) async {
    final rand = Random();
    final updatedList = <Vehicle>[];
    String? alert = state.geofenceAlert;

    final depotCoord = const LatLng(
      AppConstants.depotLat,
      AppConstants.depotLng,
    );
    final distanceCalc = const Distance();

    for (final v in state.vehicles) {
      if (v.status == 'IDLE_DEPOT') {
        updatedList.add(v);
        continue;
      }

      // Slightly perturb lat and lng along trajectory
      final deltaLat = (rand.nextDouble() * 0.0016 - 0.0008);
      final deltaLng = (rand.nextDouble() * 0.0016 - 0.0008);
      final newLat = v.currentLat + deltaLat;
      final newLng = v.currentLng + deltaLng;
      final newSpeed = (v.speedKmh + (rand.nextDouble() * 4 - 2)).clamp(
        20.0,
        95.0,
      );

      // Check geofence radius
      final currentCoord = LatLng(newLat, newLng);
      final distKm = distanceCalc.as(
        LengthUnit.Kilometer,
        depotCoord,
        currentCoord,
      );

      if (distKm > AppConstants.geofenceRadiusKm * 3.5 && alert == null) {
        alert =
            'Geofence Perimeter Alert: Vehicle ${v.id} (${v.name}) crossed the 15km outer regional freight boundary.';
      }

      final updated = v.copyWith(
        currentLat: newLat,
        currentLng: newLng,
        speedKmh: double.parse(newSpeed.toStringAsFixed(1)),
        routeCompletionPct: (v.routeCompletionPct + 0.2).clamp(0.0, 100.0),
      );

      updatedList.add(updated);
      fleetRepository.updateVehicleLocation(v.id, newLat, newLng, newSpeed);
    }

    final filtered = _applyFilter(updatedList, state.activeFilter);
    Vehicle? selected = state.selectedVehicle;
    if (selected != null) {
      final found = updatedList.where((v) => v.id == selected!.id).toList();
      if (found.isNotEmpty) selected = found.first;
    }

    emit(
      state.copyWith(
        vehicles: List.unmodifiable(updatedList),
        filteredVehicles: List.unmodifiable(filtered),
        selectedVehicle: selected,
        geofenceAlert: alert,
      ),
    );
  }

  void _onFilterVehicles(
    FilterVehiclesEvent event,
    Emitter<FleetMapState> emit,
  ) {
    final filtered = _applyFilter(state.vehicles, event.filter);
    emit(
      state.copyWith(
        activeFilter: event.filter,
        filteredVehicles: List.unmodifiable(filtered),
      ),
    );
  }

  void _onInjectGeofenceBreach(
    InjectGeofenceBreachEvent event,
    Emitter<FleetMapState> emit,
  ) {
    emit(
      state.copyWith(
        geofenceAlert:
            'Simulated Geofence Breach: Vehicle ${event.vehicleId} unauthorized corridor exit detected near Ring Road Interchange.',
      ),
    );
  }

  void _onClearGeofenceAlert(
    ClearGeofenceAlertEvent event,
    Emitter<FleetMapState> emit,
  ) {
    emit(state.copyWith(clearGeofenceAlert: true));
  }

  List<Vehicle> _applyFilter(List<Vehicle> list, String filter) {
    switch (filter) {
      case 'IN_TRANSIT':
        return list.where((v) => v.status == 'IN_TRANSIT').toList();
      case 'COLD_CHAIN':
        return list.where((v) => v.status == 'COLD_CHAIN_TRANSIT').toList();
      case 'DELAYED':
        return list.where((v) => v.status == 'DELAYED').toList();
      case 'IDLE_DEPOT':
        return list.where((v) => v.status == 'IDLE_DEPOT').toList();
      case 'ALL':
      default:
        return list;
    }
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    return super.close();
  }
}
