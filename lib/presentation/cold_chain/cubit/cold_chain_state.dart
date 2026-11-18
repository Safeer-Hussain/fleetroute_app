import 'package:equatable/equatable.dart';

import '../../../domain/entities/temperature_excursion.dart';

enum ColdChainStatus { initial, loading, loaded, error }

enum ColdChainFilter { all, activeBreaches, resolved }

class ColdChainState extends Equatable {
  final ColdChainStatus status;
  final List<TemperatureExcursion> excursions;
  final Map<String, dynamic> metrics;
  final ColdChainFilter filter;
  final String? exportedCsv;
  final String? errorMessage;
  final String? successMessage;

  const ColdChainState({
    this.status = ColdChainStatus.initial,
    this.excursions = const [],
    this.metrics = const {},
    this.filter = ColdChainFilter.all,
    this.exportedCsv,
    this.errorMessage,
    this.successMessage,
  });

  List<TemperatureExcursion> get filteredExcursions {
    switch (filter) {
      case ColdChainFilter.activeBreaches:
        return excursions
            .where((e) => e.isActive || e.isThresholdBreached)
            .toList();
      case ColdChainFilter.resolved:
        return excursions.where((e) => !e.isActive).toList();
      case ColdChainFilter.all:
        return excursions;
    }
  }

  ColdChainState copyWith({
    ColdChainStatus? status,
    List<TemperatureExcursion>? excursions,
    Map<String, dynamic>? metrics,
    ColdChainFilter? filter,
    String? exportedCsv,
    String? errorMessage,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ColdChainState(
      status: status ?? this.status,
      excursions: excursions ?? this.excursions,
      metrics: metrics ?? this.metrics,
      filter: filter ?? this.filter,
      exportedCsv: exportedCsv ?? this.exportedCsv,
      errorMessage: errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    excursions,
    metrics,
    filter,
    exportedCsv,
    errorMessage,
    successMessage,
  ];
}
