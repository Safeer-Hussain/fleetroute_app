import 'package:equatable/equatable.dart';

import 'fuel_station.dart';

class FuelFinderRecommendation extends Equatable {
  final String routeId;
  final List<FuelStation> corridorStations;
  final FuelStation? recommendedStation;
  final double baselineMarketPrice;
  final double defaultRefuelLiters;
  final double totalEstimatedSavings;
  final double detourDistanceKm;

  const FuelFinderRecommendation({
    required this.routeId,
    required this.corridorStations,
    this.recommendedStation,
    this.baselineMarketPrice = 278.00,
    this.defaultRefuelLiters = 300.0,
    this.totalEstimatedSavings = 0.0,
    this.detourDistanceKm = 0.0,
  });

  bool get hasRecommendation => recommendedStation != null;

  FuelFinderRecommendation copyWith({
    String? routeId,
    List<FuelStation>? corridorStations,
    FuelStation? recommendedStation,
    double? baselineMarketPrice,
    double? defaultRefuelLiters,
    double? totalEstimatedSavings,
    double? detourDistanceKm,
  }) {
    return FuelFinderRecommendation(
      routeId: routeId ?? this.routeId,
      corridorStations: corridorStations ?? this.corridorStations,
      recommendedStation: recommendedStation ?? this.recommendedStation,
      baselineMarketPrice: baselineMarketPrice ?? this.baselineMarketPrice,
      defaultRefuelLiters: defaultRefuelLiters ?? this.defaultRefuelLiters,
      totalEstimatedSavings:
          totalEstimatedSavings ?? this.totalEstimatedSavings,
      detourDistanceKm: detourDistanceKm ?? this.detourDistanceKm,
    );
  }

  @override
  List<Object?> get props => [
    routeId,
    corridorStations,
    recommendedStation,
    baselineMarketPrice,
    defaultRefuelLiters,
    totalEstimatedSavings,
    detourDistanceKm,
  ];
}
