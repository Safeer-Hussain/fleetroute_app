import 'package:equatable/equatable.dart';

import '../../../domain/entities/toll_barrier.dart';
import '../../../domain/entities/toll_estimate.dart';

enum TollEstimatorStatus { initial, loading, loaded, error }

class TollEstimatorState extends Equatable {
  final TollEstimatorStatus status;
  final RouteTollEstimate? estimate;
  final VehicleAxleTier selectedAxleTier;
  final bool useElectronicTag;
  final String? errorMessage;

  const TollEstimatorState({
    this.status = TollEstimatorStatus.initial,
    this.estimate,
    this.selectedAxleTier = VehicleAxleTier.fourAxlePlus,
    this.useElectronicTag = true,
    this.errorMessage,
  });

  TollEstimatorState copyWith({
    TollEstimatorStatus? status,
    RouteTollEstimate? estimate,
    VehicleAxleTier? selectedAxleTier,
    bool? useElectronicTag,
    String? errorMessage,
  }) {
    return TollEstimatorState(
      status: status ?? this.status,
      estimate: estimate ?? this.estimate,
      selectedAxleTier: selectedAxleTier ?? this.selectedAxleTier,
      useElectronicTag: useElectronicTag ?? this.useElectronicTag,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    estimate,
    selectedAxleTier,
    useElectronicTag,
    errorMessage,
  ];
}
