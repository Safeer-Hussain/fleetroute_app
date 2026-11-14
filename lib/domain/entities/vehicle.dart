import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String id;
  final String name;
  final String plateNumber;
  final String type; // SEMI_TRUCK, COLD_CHAIN_VAN, ELECTRIC_COURIER
  final String driverName;
  final String driverAvatar;
  final double currentLat;
  final double currentLng;
  final double speedKmh;
  final double headingDeg;
  final double fuelLevel;
  final double batterySoc;
  final double cargoTempC;
  final double targetTempC;
  final String status; // IN_TRANSIT, COLD_CHAIN_TRANSIT, DELAYED, IDLE_DEPOT
  final String assignedRouteId;
  final double routeCompletionPct;
  final bool hasActiveDtc;
  final double tirePressureFl;
  final double tirePressureFr;
  final double tirePressureRl;
  final double tirePressureRr;

  const Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.type,
    required this.driverName,
    required this.driverAvatar,
    required this.currentLat,
    required this.currentLng,
    required this.speedKmh,
    required this.headingDeg,
    required this.fuelLevel,
    required this.batterySoc,
    required this.cargoTempC,
    required this.targetTempC,
    required this.status,
    required this.assignedRouteId,
    required this.routeCompletionPct,
    required this.hasActiveDtc,
    required this.tirePressureFl,
    required this.tirePressureFr,
    required this.tirePressureRl,
    required this.tirePressureRr,
  });

  Vehicle copyWith({
    String? id,
    String? name,
    String? plateNumber,
    String? type,
    String? driverName,
    String? driverAvatar,
    double? currentLat,
    double? currentLng,
    double? speedKmh,
    double? headingDeg,
    double? fuelLevel,
    double? batterySoc,
    double? cargoTempC,
    double? targetTempC,
    String? status,
    String? assignedRouteId,
    double? routeCompletionPct,
    bool? hasActiveDtc,
    double? tirePressureFl,
    double? tirePressureFr,
    double? tirePressureRl,
    double? tirePressureRr,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      driverName: driverName ?? this.driverName,
      driverAvatar: driverAvatar ?? this.driverAvatar,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      speedKmh: speedKmh ?? this.speedKmh,
      headingDeg: headingDeg ?? this.headingDeg,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      batterySoc: batterySoc ?? this.batterySoc,
      cargoTempC: cargoTempC ?? this.cargoTempC,
      targetTempC: targetTempC ?? this.targetTempC,
      status: status ?? this.status,
      assignedRouteId: assignedRouteId ?? this.assignedRouteId,
      routeCompletionPct: routeCompletionPct ?? this.routeCompletionPct,
      hasActiveDtc: hasActiveDtc ?? this.hasActiveDtc,
      tirePressureFl: tirePressureFl ?? this.tirePressureFl,
      tirePressureFr: tirePressureFr ?? this.tirePressureFr,
      tirePressureRl: tirePressureRl ?? this.tirePressureRl,
      tirePressureRr: tirePressureRr ?? this.tirePressureRr,
    );
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      plateNumber: map['plate_number'] as String? ?? '',
      type: map['type'] as String? ?? 'SEMI_TRUCK',
      driverName: map['driver_name'] as String? ?? '',
      driverAvatar:
          map['driver_avatar'] as String? ?? 'assets/images/driver_avatar.png',
      currentLat: (map['current_lat'] as num?)?.toDouble() ?? 0.0,
      currentLng: (map['current_lng'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (map['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      headingDeg: (map['heading_deg'] as num?)?.toDouble() ?? 0.0,
      fuelLevel: (map['fuel_level'] as num?)?.toDouble() ?? 0.0,
      batterySoc: (map['battery_soc'] as num?)?.toDouble() ?? 0.0,
      cargoTempC: (map['cargo_temp_c'] as num?)?.toDouble() ?? 0.0,
      targetTempC: (map['target_temp_c'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'IN_TRANSIT',
      assignedRouteId: map['assigned_route_id'] as String? ?? '',
      routeCompletionPct:
          (map['route_completion_pct'] as num?)?.toDouble() ?? 0.0,
      hasActiveDtc: (map['has_active_dtc'] as int? ?? 0) == 1,
      tirePressureFl: (map['tire_pressure_fl'] as num?)?.toDouble() ?? 34.0,
      tirePressureFr: (map['tire_pressure_fr'] as num?)?.toDouble() ?? 34.0,
      tirePressureRl: (map['tire_pressure_rl'] as num?)?.toDouble() ?? 35.0,
      tirePressureRr: (map['tire_pressure_rr'] as num?)?.toDouble() ?? 35.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'plate_number': plateNumber,
      'type': type,
      'driver_name': driverName,
      'driver_avatar': driverAvatar,
      'current_lat': currentLat,
      'current_lng': currentLng,
      'speed_kmh': speedKmh,
      'heading_deg': headingDeg,
      'fuel_level': fuelLevel,
      'battery_soc': batterySoc,
      'cargo_temp_c': cargoTempC,
      'target_temp_c': targetTempC,
      'status': status,
      'assigned_route_id': assignedRouteId,
      'route_completion_pct': routeCompletionPct,
      'has_active_dtc': hasActiveDtc ? 1 : 0,
      'tire_pressure_fl': tirePressureFl,
      'tire_pressure_fr': tirePressureFr,
      'tire_pressure_rl': tirePressureRl,
      'tire_pressure_rr': tirePressureRr,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    plateNumber,
    type,
    driverName,
    driverAvatar,
    currentLat,
    currentLng,
    speedKmh,
    headingDeg,
    fuelLevel,
    batterySoc,
    cargoTempC,
    targetTempC,
    status,
    assignedRouteId,
    routeCompletionPct,
    hasActiveDtc,
    tirePressureFl,
    tirePressureFr,
    tirePressureRl,
    tirePressureRr,
  ];
}
