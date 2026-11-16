import 'package:equatable/equatable.dart';

class RestStop extends Equatable {
  final String id;
  final String name;
  final String highway;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final List<String> amenities;
  final int availableTruckBays;
  final bool isVerified;

  const RestStop({
    required this.id,
    required this.name,
    required this.highway,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.amenities,
    required this.availableTruckBays,
    this.isVerified = true,
  });

  RestStop copyWith({
    String? id,
    String? name,
    String? highway,
    double? latitude,
    double? longitude,
    double? distanceKm,
    List<String>? amenities,
    int? availableTruckBays,
    bool? isVerified,
  }) {
    return RestStop(
      id: id ?? this.id,
      name: name ?? this.name,
      highway: highway ?? this.highway,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      amenities: amenities ?? this.amenities,
      availableTruckBays: availableTruckBays ?? this.availableTruckBays,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'highway': highway,
      'latitude': latitude,
      'longitude': longitude,
      'amenities': amenities.join(','),
      'available_truck_bays': availableTruckBays,
    };
  }

  factory RestStop.fromMap(
    Map<String, dynamic> map, {
    double distanceKm = 0.0,
  }) {
    final rawAmenities = map['amenities'] as String? ?? '';
    final amenitiesList = rawAmenities.isEmpty
        ? <String>[]
        : rawAmenities.split(',').map((e) => e.trim()).toList();

    return RestStop(
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

  @override
  List<Object?> get props => [
    id,
    name,
    highway,
    latitude,
    longitude,
    distanceKm,
    amenities,
    availableTruckBays,
    isVerified,
  ];
}
