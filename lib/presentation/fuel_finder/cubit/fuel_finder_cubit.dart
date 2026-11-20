import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/fuel_station.dart';
import '../../../domain/entities/route_plan.dart';
import '../../../domain/entities/waybill_stop.dart';
import '../../../domain/repositories/fuel_station_repository.dart';
import 'fuel_finder_state.dart';

class FuelFinderCubit extends Cubit<FuelFinderState> {
  final FuelStationRepository fuelStationRepository;

  FuelFinderCubit({required this.fuelStationRepository})
    : super(const FuelFinderState());

  Future<void> calculateRecommendation({
    required RoutePlan route,
    required List<WaybillStop> stops,
    double? customLiters,
    double? customToleranceKm,
  }) async {
    final liters = customLiters ?? state.refuelLiters;
    final toleranceKm = customToleranceKm ?? state.corridorToleranceKm;

    emit(
      state.copyWith(
        status: FuelFinderStatus.loading,
        refuelLiters: liters,
        corridorToleranceKm: toleranceKm,
        clearStatusMessage: true,
        clearError: true,
      ),
    );

    try {
      final recommendation = await fuelStationRepository
          .findOptimalCorridorFuelStop(
            route: route,
            stops: stops,
            corridorToleranceKm: toleranceKm,
            refuelLiters: liters,
          );

      emit(
        state.copyWith(
          status: FuelFinderStatus.loaded,
          recommendation: recommendation,
          refuelLiters: liters,
          corridorToleranceKm: toleranceKm,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FuelFinderStatus.error,
          errorMessage: 'Corridor fuel optimization error: ${e.toString()}',
        ),
      );
    }
  }

  void updateRefuelLiters({
    required double liters,
    required RoutePlan route,
    required List<WaybillStop> stops,
  }) {
    calculateRecommendation(route: route, stops: stops, customLiters: liters);
  }

  void updateCorridorTolerance({
    required double toleranceKm,
    required RoutePlan route,
    required List<WaybillStop> stops,
  }) {
    calculateRecommendation(
      route: route,
      stops: stops,
      customToleranceKm: toleranceKm,
    );
  }

  Future<void> injectFuelStopWaypoint({
    required String routeId,
    required FuelStation station,
    VoidCallback? onInjected,
  }) async {
    emit(state.copyWith(status: FuelFinderStatus.injecting));
    try {
      final newStop = await fuelStationRepository.injectFuelStopWaypoint(
        routeId: routeId,
        station: station,
        refuelLiters: state.refuelLiters,
      );

      emit(
        state.copyWith(
          status: FuelFinderStatus.injected,
          injectedStop: newStop,
          statusMessage:
              'Injected Refuel Waypoint: ${station.name} into Route Stops sequence.',
        ),
      );

      onInjected?.call();
    } catch (e) {
      emit(
        state.copyWith(
          status: FuelFinderStatus.error,
          errorMessage: 'Failed to inject fuel waypoint: ${e.toString()}',
        ),
      );
    }
  }

  void clearStatusMessage() {
    emit(state.copyWith(clearStatusMessage: true));
  }
}
