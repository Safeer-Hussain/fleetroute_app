import 'package:equatable/equatable.dart';

import '../../../domain/entities/temperature_excursion.dart';

enum ColdChainFilter {
  all,
  breachesOnly,
  unresolvedOnly;

  String get displayName {
    switch (this) {
      case ColdChainFilter.all:
        return 'All Excursions';
      case ColdChainFilter.breachesOnly:
        return 'Critical Breaches (>5m)';
      case ColdChainFilter.unresolvedOnly:
        return 'Unresolved / Active';
    }
  }
}

class ColdChainState extends Equatable {
  final List<TemperatureExcursion> allExcursions;
  final ColdChainFilter filter;
  final bool isLoading;
  final String? statusMessage;
  final String? errorMessage;
  final String? exportedCsv;

  const ColdChainState({
    this.allExcursions = const [],
    this.filter = ColdChainFilter.all,
    this.isLoading = false,
    this.statusMessage,
    this.errorMessage,
    this.exportedCsv,
  });

  List<TemperatureExcursion> get filteredExcursions {
    switch (filter) {
      case ColdChainFilter.breachesOnly:
        return allExcursions.where((e) => e.isAuditableBreach).toList();
      case ColdChainFilter.unresolvedOnly:
        return allExcursions.where((e) => !e.isResolved).toList();
      case ColdChainFilter.all:
        return allExcursions;
    }
  }

  int get totalExcursions => allExcursions.length;
  int get criticalBreachCount =>
      allExcursions.where((e) => e.isAuditableBreach).length;
  int get compliantTransientCount =>
      allExcursions.where((e) => !e.isAuditableBreach).length;
  int get unresolvedCount => allExcursions.where((e) => !e.isResolved).length;

  ColdChainState copyWith({
    List<TemperatureExcursion>? allExcursions,
    ColdChainFilter? filter,
    bool? isLoading,
    String? statusMessage,
    String? errorMessage,
    String? exportedCsv,
    bool clearStatusMessage = false,
    bool clearExportedCsv = false,
  }) {
    return ColdChainState(
      allExcursions: allExcursions ?? this.allExcursions,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      errorMessage: errorMessage,
      exportedCsv: clearExportedCsv ? null : (exportedCsv ?? this.exportedCsv),
    );
  }

  @override
  List<Object?> get props => [
    allExcursions,
    filter,
    isLoading,
    statusMessage,
    errorMessage,
    exportedCsv,
  ];
}
