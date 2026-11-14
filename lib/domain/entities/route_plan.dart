import 'package:equatable/equatable.dart';

class RoutePlan extends Equatable {
  final String id;
  final String name;
  final String vehicleId;
  final String originName;
  final double originLat;
  final double originLng;
  final String destinationName;
  final double destinationLat;
  final double destinationLng;
  final double totalDistanceKm;
  final double optimizedDistanceKm;
  final double fuelSavedLiters;
  final int minutesSaved;
  final bool isOptimized;
  final String status; // ACTIVE, COMPLETED, PLANNED

  const RoutePlan({
    required this.id,
    required this.name,
    required this.vehicleId,
    required this.originName,
    required this.originLat,
    required this.originLng,
    required this.destinationName,
    required this.destinationLat,
    required this.destinationLng,
    required this.totalDistanceKm,
    required this.optimizedDistanceKm,
    required this.fuelSavedLiters,
    required this.minutesSaved,
    required this.isOptimized,
    required this.status,
  });

  RoutePlan copyWith({
    String? id,
    String? name,
    String? vehicleId,
    String? originName,
    double? originLat,
    double? originLng,
    String? destinationName,
    double? destinationLat,
    double? destinationLng,
    double? totalDistanceKm,
    double? optimizedDistanceKm,
    double? fuelSavedLiters,
    int? minutesSaved,
    bool? isOptimized,
    String? status,
  }) {
    return RoutePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      vehicleId: vehicleId ?? this.vehicleId,
      originName: originName ?? this.originName,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationName: destinationName ?? this.destinationName,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      optimizedDistanceKm: optimizedDistanceKm ?? this.optimizedDistanceKm,
      fuelSavedLiters: fuelSavedLiters ?? this.fuelSavedLiters,
      minutesSaved: minutesSaved ?? this.minutesSaved,
      isOptimized: isOptimized ?? this.isOptimized,
      status: status ?? this.status,
    );
  }

  factory RoutePlan.fromMap(Map<String, dynamic> map) {
    return RoutePlan(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      vehicleId: map['vehicle_id'] as String? ?? '',
      originName: map['origin_name'] as String? ?? '',
      originLat: (map['origin_lat'] as num?)?.toDouble() ?? 0.0,
      originLng: (map['origin_lng'] as num?)?.toDouble() ?? 0.0,
      destinationName: map['destination_name'] as String? ?? '',
      destinationLat: (map['destination_lat'] as num?)?.toDouble() ?? 0.0,
      destinationLng: (map['destination_lng'] as num?)?.toDouble() ?? 0.0,
      totalDistanceKm: (map['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      optimizedDistanceKm:
          (map['optimized_distance_km'] as num?)?.toDouble() ?? 0.0,
      fuelSavedLiters: (map['fuel_saved_liters'] as num?)?.toDouble() ?? 0.0,
      minutesSaved: (map['minutes_saved'] as num?)?.toInt() ?? 0,
      isOptimized: (map['is_optimized'] as int? ?? 0) == 1,
      status: map['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'vehicle_id': vehicleId,
      'origin_name': originName,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_name': destinationName,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'total_distance_km': totalDistanceKm,
      'optimized_distance_km': optimizedDistanceKm,
      'fuel_saved_liters': fuelSavedLiters,
      'minutes_saved': minutesSaved,
      'is_optimized': isOptimized ? 1 : 0,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    vehicleId,
    originName,
    originLat,
    originLng,
    destinationName,
    destinationLat,
    destinationLng,
    totalDistanceKm,
    optimizedDistanceKm,
    fuelSavedLiters,
    minutesSaved,
    isOptimized,
    status,
  ];
}
