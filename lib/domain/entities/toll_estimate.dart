import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'toll_barrier.dart';

class TollBarrierCrossing extends Equatable {
  final TollBarrier barrier;
  final VehicleAxleTier axleTier;
  final double baseTollFee;
  final double customsFee;
  final double electronicDiscount;
  final double netFee;
  final double distanceFromOriginKm;

  const TollBarrierCrossing({
    required this.barrier,
    required this.axleTier,
    required this.baseTollFee,
    required this.customsFee,
    required this.electronicDiscount,
    required this.netFee,
    required this.distanceFromOriginKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'barrier': barrier.toMap(),
      'axle_tier': axleTier.code,
      'base_toll_fee': baseTollFee,
      'customs_fee': customsFee,
      'electronic_discount': electronicDiscount,
      'net_fee': netFee,
      'distance_from_origin_km': distanceFromOriginKm,
    };
  }

  factory TollBarrierCrossing.fromMap(Map<String, dynamic> map) {
    return TollBarrierCrossing(
      barrier: TollBarrier.fromMap(map['barrier'] as Map<String, dynamic>),
      axleTier: VehicleAxleTier.fromCode(map['axle_tier'] as String? ?? ''),
      baseTollFee: (map['base_toll_fee'] as num?)?.toDouble() ?? 0.0,
      customsFee: (map['customs_fee'] as num?)?.toDouble() ?? 0.0,
      electronicDiscount:
          (map['electronic_discount'] as num?)?.toDouble() ?? 0.0,
      netFee: (map['net_fee'] as num?)?.toDouble() ?? 0.0,
      distanceFromOriginKm:
          (map['distance_from_origin_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    barrier,
    axleTier,
    baseTollFee,
    customsFee,
    electronicDiscount,
    netFee,
    distanceFromOriginKm,
  ];
}

class RouteTollEstimate extends Equatable {
  final String routeId;
  final VehicleAxleTier axleTier;
  final List<TollBarrierCrossing> crossings;
  final double totalTollFees;
  final double totalCustomsFees;
  final double totalElectronicDiscounts;
  final double netTotalFee;
  final bool electronicTagUsed;

  const RouteTollEstimate({
    required this.routeId,
    required this.axleTier,
    required this.crossings,
    required this.totalTollFees,
    required this.totalCustomsFees,
    required this.totalElectronicDiscounts,
    required this.netTotalFee,
    this.electronicTagUsed = true,
  });

  int get highwayTollCount => crossings
      .where((c) => c.barrier.barrierType == TollBarrierType.highwayToll)
      .length;

  int get borderCustomsCount => crossings
      .where((c) => c.barrier.barrierType == TollBarrierType.borderCustoms)
      .length;

  String get formattedTotalFee => 'Rs. ${netTotalFee.toStringAsFixed(0)}';
  String get formattedTollFees => 'Rs. ${totalTollFees.toStringAsFixed(0)}';
  String get formattedCustomsFees =>
      'Rs. ${totalCustomsFees.toStringAsFixed(0)}';
  String get formattedDiscounts =>
      'Rs. ${totalElectronicDiscounts.toStringAsFixed(0)}';

  RouteTollEstimate copyWith({
    String? routeId,
    VehicleAxleTier? axleTier,
    List<TollBarrierCrossing>? crossings,
    double? totalTollFees,
    double? totalCustomsFees,
    double? totalElectronicDiscounts,
    double? netTotalFee,
    bool? electronicTagUsed,
  }) {
    return RouteTollEstimate(
      routeId: routeId ?? this.routeId,
      axleTier: axleTier ?? this.axleTier,
      crossings: crossings ?? this.crossings,
      totalTollFees: totalTollFees ?? this.totalTollFees,
      totalCustomsFees: totalCustomsFees ?? this.totalCustomsFees,
      totalElectronicDiscounts:
          totalElectronicDiscounts ?? this.totalElectronicDiscounts,
      netTotalFee: netTotalFee ?? this.netTotalFee,
      electronicTagUsed: electronicTagUsed ?? this.electronicTagUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'route_id': routeId,
      'axle_tier': axleTier.code,
      'total_toll_fees': totalTollFees,
      'total_customs_fees': totalCustomsFees,
      'total_discounts': totalElectronicDiscounts,
      'net_total_fee': netTotalFee,
      'barriers_json': jsonEncode(crossings.map((c) => c.toMap()).toList()),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory RouteTollEstimate.fromMap(Map<String, dynamic> map) {
    List<TollBarrierCrossing> parsedCrossings = [];
    final jsonStr = map['barriers_json'] as String? ?? '[]';
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      parsedCrossings = decoded
          .map(
            (item) => TollBarrierCrossing.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {}

    return RouteTollEstimate(
      routeId: map['route_id'] as String? ?? '',
      axleTier: VehicleAxleTier.fromCode(map['axle_tier'] as String? ?? ''),
      crossings: parsedCrossings,
      totalTollFees: (map['total_toll_fees'] as num?)?.toDouble() ?? 0.0,
      totalCustomsFees: (map['total_customs_fees'] as num?)?.toDouble() ?? 0.0,
      totalElectronicDiscounts:
          (map['total_discounts'] as num?)?.toDouble() ?? 0.0,
      netTotalFee: (map['net_total_fee'] as num?)?.toDouble() ?? 0.0,
      electronicTagUsed: true,
    );
  }

  @override
  List<Object?> get props => [
    routeId,
    axleTier,
    crossings,
    totalTollFees,
    totalCustomsFees,
    totalElectronicDiscounts,
    netTotalFee,
    electronicTagUsed,
  ];
}
