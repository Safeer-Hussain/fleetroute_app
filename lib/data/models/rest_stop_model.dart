import '../../domain/entities/rest_stop.dart';

class RestStopModel extends RestStop {
  const RestStopModel({
    required super.id,
    required super.name,
    required super.highway,
    required super.latitude,
    required super.longitude,
    required super.distanceKm,
    required super.amenities,
    required super.availableTruckBays,
    super.isVerified = true,
  });

  factory RestStopModel.fromMap(
    Map<String, dynamic> map, {
    double distanceKm = 0.0,
  }) {
    final rawAmenities = map['amenities'] as String? ?? '';
    final amenitiesList = rawAmenities.isEmpty
        ? <String>[]
        : rawAmenities.split(',').map((e) => e.trim()).toList();

    return RestStopModel(
      id: map['id'] as String,
      name: map['name'] as String,
      highway: map['highway'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      distanceKm: distanceKm,
      amenities: amenitiesList,
      availableTruckBays: (map['available_truck_bays'] as num?)?.toInt() ?? 0,
      isVerified: true,
    );
  }

  factory RestStopModel.fromEntity(RestStop entity) {
    return RestStopModel(
      id: entity.id,
      name: entity.name,
      highway: entity.highway,
      latitude: entity.latitude,
      longitude: entity.longitude,
      distanceKm: entity.distanceKm,
      amenities: entity.amenities,
      availableTruckBays: entity.availableTruckBays,
      isVerified: entity.isVerified,
    );
  }
}
