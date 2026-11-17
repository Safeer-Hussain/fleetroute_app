import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/route_plan.dart';
import '../../../domain/entities/toll_barrier.dart';
import '../../../domain/entities/waybill_stop.dart';
import '../../../domain/repositories/toll_repository.dart';
import 'toll_estimator_state.dart';

class TollEstimatorCubit extends Cubit<TollEstimatorState> {
  final TollRepository tollRepository;

  TollEstimatorCubit({required this.tollRepository})
    : super(const TollEstimatorState());

  RoutePlan? _currentRoute;
  List<WaybillStop> _currentStops = [];

  RoutePlan? get currentRoute => _currentRoute;
  List<WaybillStop> get currentStops => _currentStops;

  Future<void> calculateEstimate({
    required RoutePlan route,
    required List<WaybillStop> stops,
    VehicleAxleTier? axleTier,
    bool? useElectronicTag,
  }) async {
    _currentRoute = route;
    _currentStops = stops;

    final effectiveAxle = axleTier ?? state.selectedAxleTier;
    final effectiveTag = useElectronicTag ?? state.useElectronicTag;

    emit(
      state.copyWith(
        status: TollEstimatorStatus.loading,
        selectedAxleTier: effectiveAxle,
        useElectronicTag: effectiveTag,
      ),
    );

    try {
      final estimate = await tollRepository.estimateRouteToll(
        route: route,
        stops: stops,
        axleTier: effectiveAxle,
        useElectronicTag: effectiveTag,
      );

      emit(
        state.copyWith(
          status: TollEstimatorStatus.loaded,
          estimate: estimate,
          selectedAxleTier: effectiveAxle,
          useElectronicTag: effectiveTag,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TollEstimatorStatus.error,
          errorMessage: 'Failed to estimate route tolls: $e',
        ),
      );
    }
  }

  Future<void> setAxleTier(VehicleAxleTier tier) async {
    if (tier == state.selectedAxleTier) return;
    if (_currentRoute != null) {
      await calculateEstimate(
        route: _currentRoute!,
        stops: _currentStops,
        axleTier: tier,
      );
    } else {
      emit(state.copyWith(selectedAxleTier: tier));
    }
  }

  Future<void> toggleElectronicTag(bool enabled) async {
    if (enabled == state.useElectronicTag) return;
    if (_currentRoute != null) {
      await calculateEstimate(
        route: _currentRoute!,
        stops: _currentStops,
        useElectronicTag: enabled,
      );
    } else {
      emit(state.copyWith(useElectronicTag: enabled));
    }
  }
}
