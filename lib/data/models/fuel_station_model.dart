import 'dart:convert';

import '../../domain/entities/fuel_station.dart';

class FuelStationModel extends FuelStation {
  const FuelStationModel({
    required super.id,
    required super.name,
    required super.highway,
    required super.latitude,
    required super.longitude,
    required super.brand,
    required super.dieselPricePerLiter,
    required super.baselineMarketPrice,
    required super.amenities,
    required super.hasDedicatedTruckBays,
    super.distanceToCorridorKm,
    super.distanceAlongRouteKm,
  });

  factory FuelStationModel.fromMap(Map<String, dynamic> map) {
    List<String> amenitiesList = [];
    final amenitiesRaw = map['amenities'];
    if (amenitiesRaw is String && amenitiesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(amenitiesRaw);
        if (decoded is List) {
          amenitiesList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        amenitiesList = amenitiesRaw.split(',').map((e) => e.trim()).toList();
      }
    } else if (amenitiesRaw is List) {
      amenitiesList = amenitiesRaw.map((e) => e.toString()).toList();
    }

    return FuelStationModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      highway: map['highway'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      brand: map['brand'] as String? ?? '',
      dieselPricePerLiter: (map['diesel_price'] as num?)?.toDouble() ?? 0.0,
      baselineMarketPrice: (map['baseline_price'] as num?)?.toDouble() ?? 278.0,
      amenities: amenitiesList,
      hasDedicatedTruckBays: (map['has_truck_bays'] as int? ?? 1) == 1,
      distanceToCorridorKm:
          (map['distance_to_corridor_km'] as num?)?.toDouble() ?? 0.0,
      distanceAlongRouteKm:
          (map['distance_along_route_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'highway': highway,
      'latitude': latitude,
      'longitude': longitude,
      'brand': brand,
      'diesel_price': dieselPricePerLiter,
      'baseline_price': baselineMarketPrice,
      'amenities': jsonEncode(amenities),
      'has_truck_bays': hasDedicatedTruckBays ? 1 : 0,
    };
  }

  factory FuelStationModel.fromEntity(FuelStation entity) {
    return FuelStationModel(
      id: entity.id,
      name: entity.name,
      highway: entity.highway,
      latitude: entity.latitude,
      longitude: entity.longitude,
      brand: entity.brand,
      dieselPricePerLiter: entity.dieselPricePerLiter,
      baselineMarketPrice: entity.baselineMarketPrice,
      amenities: entity.amenities,
      hasDedicatedTruckBays: entity.hasDedicatedTruckBays,
      distanceToCorridorKm: entity.distanceToCorridorKm,
      distanceAlongRouteKm: entity.distanceAlongRouteKm,
    );
  }
}
