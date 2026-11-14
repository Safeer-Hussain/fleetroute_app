import 'package:equatable/equatable.dart';

class WaybillStop extends Equatable {
  final String id;
  final String routeId;
  final int sequenceOrder;
  final String stopName;
  final double latitude;
  final double longitude;
  final String cargoDescription;
  final double weightKg;
  final String
  priority; // URGENT_COLD_CHAIN, SCHEDULED_FREIGHT, STANDARD_PARCEL
  final String status; // PENDING, OUT_FOR_DELIVERY, DELIVERED, EXCEPTION
  final String? recipientName;
  final String? recipientSignatureSvg;
  final String? deliveredAt;
  final String? exceptionReason;

  const WaybillStop({
    required this.id,
    required this.routeId,
    required this.sequenceOrder,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.cargoDescription,
    required this.weightKg,
    required this.priority,
    required this.status,
    this.recipientName,
    this.recipientSignatureSvg,
    this.deliveredAt,
    this.exceptionReason,
  });

  WaybillStop copyWith({
    String? id,
    String? routeId,
    int? sequenceOrder,
    String? stopName,
    double? latitude,
    double? longitude,
    String? cargoDescription,
    double? weightKg,
    String? priority,
    String? status,
    String? recipientName,
    String? recipientSignatureSvg,
    String? deliveredAt,
    String? exceptionReason,
  }) {
    return WaybillStop(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      stopName: stopName ?? this.stopName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      weightKg: weightKg ?? this.weightKg,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recipientName: recipientName ?? this.recipientName,
      recipientSignatureSvg:
          recipientSignatureSvg ?? this.recipientSignatureSvg,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      exceptionReason: exceptionReason ?? this.exceptionReason,
    );
  }

  factory WaybillStop.fromMap(Map<String, dynamic> map) {
    return WaybillStop(
      id: map['id'] as String? ?? '',
      routeId: map['route_id'] as String? ?? '',
      sequenceOrder: (map['sequence_order'] as num?)?.toInt() ?? 0,
      stopName: map['stop_name'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      cargoDescription: map['cargo_description'] as String? ?? '',
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      priority: map['priority'] as String? ?? 'STANDARD_PARCEL',
      status: map['status'] as String? ?? 'PENDING',
      recipientName: map['recipient_name'] as String?,
      recipientSignatureSvg: map['recipient_signature_svg'] as String?,
      deliveredAt: map['delivered_at'] as String?,
      exceptionReason: map['exception_reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'sequence_order': sequenceOrder,
      'stop_name': stopName,
      'latitude': latitude,
      'longitude': longitude,
      'cargo_description': cargoDescription,
      'weight_kg': weightKg,
      'priority': priority,
      'status': status,
      'recipient_name': recipientName,
      'recipient_signature_svg': recipientSignatureSvg,
      'delivered_at': deliveredAt,
      'exception_reason': exceptionReason,
    };
  }

  @override
  List<Object?> get props => [
    id,
    routeId,
    sequenceOrder,
    stopName,
    latitude,
    longitude,
    cargoDescription,
    weightKg,
    priority,
    status,
    recipientName,
    recipientSignatureSvg,
    deliveredAt,
    exceptionReason,
  ];
}
