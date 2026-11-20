import 'package:equatable/equatable.dart';

import '../../../domain/entities/fuel_finder_recommendation.dart';
import '../../../domain/entities/waybill_stop.dart';

enum FuelFinderStatus { initial, loading, loaded, injecting, injected, error }

class FuelFinderState extends Equatable {
  final FuelFinderStatus status;
  final FuelFinderRecommendation? recommendation;
  final double refuelLiters;
  final double corridorToleranceKm;
  final WaybillStop? injectedStop;
  final String? errorMessage;
  final String? statusMessage;

  const FuelFinderState({
    this.status = FuelFinderStatus.initial,
    this.recommendation,
    this.refuelLiters = 300.0,
    this.corridorToleranceKm = 8.0,
    this.injectedStop,
    this.errorMessage,
    this.statusMessage,
  });

  FuelFinderState copyWith({
    FuelFinderStatus? status,
    FuelFinderRecommendation? recommendation,
    double? refuelLiters,
    double? corridorToleranceKm,
    WaybillStop? injectedStop,
    String? errorMessage,
    String? statusMessage,
    bool clearStatusMessage = false,
    bool clearError = false,
  }) {
    return FuelFinderState(
      status: status ?? this.status,
      recommendation: recommendation ?? this.recommendation,
      refuelLiters: refuelLiters ?? this.refuelLiters,
      corridorToleranceKm: corridorToleranceKm ?? this.corridorToleranceKm,
      injectedStop: injectedStop ?? this.injectedStop,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    recommendation,
    refuelLiters,
    corridorToleranceKm,
    injectedStop,
    errorMessage,
    statusMessage,
  ];
}
