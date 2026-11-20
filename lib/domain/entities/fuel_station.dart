import 'package:equatable/equatable.dart';

class FuelStation extends Equatable {
  final String id;
  final String name;
  final String highway;
  final double latitude;
  final double longitude;
  final String brand;
  final double dieselPricePerLiter;
  final double baselineMarketPrice;
  final List<String> amenities;
  final bool hasDedicatedTruckBays;
  final double distanceToCorridorKm;
  final double distanceAlongRouteKm;

  const FuelStation({
    required this.id,
    required this.name,
    required this.highway,
    required this.latitude,
    required this.longitude,
    required this.brand,
    required this.dieselPricePerLiter,
    required this.baselineMarketPrice,
    required this.amenities,
    required this.hasDedicatedTruckBays,
    this.distanceToCorridorKm = 0.0,
    this.distanceAlongRouteKm = 0.0,
  });

  double get priceSavingsPerLiter =>
      (baselineMarketPrice - dieselPricePerLiter).clamp(0.0, 500.0);

  double calculateEstimatedSavings(double refuelLiters) {
    if (refuelLiters <= 0) return 0.0;
    return priceSavingsPerLiter * refuelLiters;
  }

  String get formattedPrice =>
      'Rs. ${dieselPricePerLiter.toStringAsFixed(2)}/L';

  String get formattedSavings =>
      'Rs. ${priceSavingsPerLiter.toStringAsFixed(2)}/L savings';

  FuelStation copyWith({
    String? id,
    String? name,
    String? highway,
    double? latitude,
    double? longitude,
    String? brand,
    double? dieselPricePerLiter,
    double? baselineMarketPrice,
    List<String>? amenities,
    bool? hasDedicatedTruckBays,
    double? distanceToCorridorKm,
    double? distanceAlongRouteKm,
  }) {
    return FuelStation(
      id: id ?? this.id,
      name: name ?? this.name,
      highway: highway ?? this.highway,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      brand: brand ?? this.brand,
      dieselPricePerLiter: dieselPricePerLiter ?? this.dieselPricePerLiter,
      baselineMarketPrice: baselineMarketPrice ?? this.baselineMarketPrice,
      amenities: amenities ?? this.amenities,
      hasDedicatedTruckBays:
          hasDedicatedTruckBays ?? this.hasDedicatedTruckBays,
      distanceToCorridorKm: distanceToCorridorKm ?? this.distanceToCorridorKm,
      distanceAlongRouteKm: distanceAlongRouteKm ?? this.distanceAlongRouteKm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    highway,
    latitude,
    longitude,
    brand,
    dieselPricePerLiter,
    baselineMarketPrice,
    amenities,
    hasDedicatedTruckBays,
    distanceToCorridorKm,
    distanceAlongRouteKm,
  ];
}
