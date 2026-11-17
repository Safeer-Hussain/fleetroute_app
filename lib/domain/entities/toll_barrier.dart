import 'package:equatable/equatable.dart';

enum TollBarrierType {
  highwayToll,
  borderCustoms;

  String get displayName {
    switch (this) {
      case TollBarrierType.highwayToll:
        return 'HIGHWAY TOLL PLAZA';
      case TollBarrierType.borderCustoms:
        return 'BORDER CUSTOMS POST';
    }
  }

  String get code {
    switch (this) {
      case TollBarrierType.highwayToll:
        return 'HIGHWAY_TOLL';
      case TollBarrierType.borderCustoms:
        return 'BORDER_CUSTOMS';
    }
  }

  static TollBarrierType fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'BORDER_CUSTOMS':
      case 'CUSTOMS':
        return TollBarrierType.borderCustoms;
      case 'HIGHWAY_TOLL':
      case 'TOLL':
      default:
        return TollBarrierType.highwayToll;
    }
  }
}

enum VehicleAxleTier {
  twoAxle,
  threeAxle,
  fourAxlePlus;

  String get displayName {
    switch (this) {
      case VehicleAxleTier.twoAxle:
        return '2-Axle (Light Courier / EV)';
      case VehicleAxleTier.threeAxle:
        return '3-Axle (Medium Rigid / Cold-Chain)';
      case VehicleAxleTier.fourAxlePlus:
        return '4-Axle+ (Heavy Semi-Truck)';
    }
  }

  String get shortLabel {
    switch (this) {
      case VehicleAxleTier.twoAxle:
        return '2-AXLE';
      case VehicleAxleTier.threeAxle:
        return '3-AXLE';
      case VehicleAxleTier.fourAxlePlus:
        return '4-AXLE+';
    }
  }

  String get code {
    switch (this) {
      case VehicleAxleTier.twoAxle:
        return 'TWO_AXLE';
      case VehicleAxleTier.threeAxle:
        return 'THREE_AXLE';
      case VehicleAxleTier.fourAxlePlus:
        return 'FOUR_AXLE_PLUS';
    }
  }

  static VehicleAxleTier fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'TWO_AXLE':
      case '2_AXLE':
      case '2-AXLE':
      case 'ELECTRIC_COURIER':
        return VehicleAxleTier.twoAxle;
      case 'THREE_AXLE':
      case '3_AXLE':
      case '3-AXLE':
      case 'COLD_CHAIN_VAN':
        return VehicleAxleTier.threeAxle;
      case 'FOUR_AXLE_PLUS':
      case '4_AXLE':
      case '4-AXLE':
      case 'SEMI_TRUCK':
      default:
        return VehicleAxleTier.fourAxlePlus;
    }
  }

  static VehicleAxleTier fromVehicleType(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'ELECTRIC_COURIER':
        return VehicleAxleTier.twoAxle;
      case 'COLD_CHAIN_VAN':
        return VehicleAxleTier.threeAxle;
      case 'SEMI_TRUCK':
      default:
        return VehicleAxleTier.fourAxlePlus;
    }
  }
}

class TollBarrier extends Equatable {
  final String id;
  final String name;
  final String highway;
  final double latitude;
  final double longitude;
  final TollBarrierType barrierType;
  final double feeTwoAxle;
  final double feeThreeAxle;
  final double feeFourAxlePlus;
  final double customsClearanceFee;
  final bool acceptsElectronicToll;

  const TollBarrier({
    required this.id,
    required this.name,
    required this.highway,
    required this.latitude,
    required this.longitude,
    required this.barrierType,
    required this.feeTwoAxle,
    required this.feeThreeAxle,
    required this.feeFourAxlePlus,
    required this.customsClearanceFee,
    required this.acceptsElectronicToll,
  });

  double getFeeForAxle(VehicleAxleTier tier) {
    switch (tier) {
      case VehicleAxleTier.twoAxle:
        return feeTwoAxle;
      case VehicleAxleTier.threeAxle:
        return feeThreeAxle;
      case VehicleAxleTier.fourAxlePlus:
        return feeFourAxlePlus;
    }
  }

  TollBarrier copyWith({
    String? id,
    String? name,
    String? highway,
    double? latitude,
    double? longitude,
    TollBarrierType? barrierType,
    double? feeTwoAxle,
    double? feeThreeAxle,
    double? feeFourAxlePlus,
    double? customsClearanceFee,
    bool? acceptsElectronicToll,
  }) {
    return TollBarrier(
      id: id ?? this.id,
      name: name ?? this.name,
      highway: highway ?? this.highway,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      barrierType: barrierType ?? this.barrierType,
      feeTwoAxle: feeTwoAxle ?? this.feeTwoAxle,
      feeThreeAxle: feeThreeAxle ?? this.feeThreeAxle,
      feeFourAxlePlus: feeFourAxlePlus ?? this.feeFourAxlePlus,
      customsClearanceFee: customsClearanceFee ?? this.customsClearanceFee,
      acceptsElectronicToll:
          acceptsElectronicToll ?? this.acceptsElectronicToll,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'highway': highway,
      'latitude': latitude,
      'longitude': longitude,
      'barrier_type': barrierType.code,
      'fee_two_axle': feeTwoAxle,
      'fee_three_axle': feeThreeAxle,
      'fee_four_axle_plus': feeFourAxlePlus,
      'customs_clearance_fee': customsClearanceFee,
      'accepts_electronic_toll': acceptsElectronicToll ? 1 : 0,
    };
  }

  factory TollBarrier.fromMap(Map<String, dynamic> map) {
    return TollBarrier(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      highway: map['highway'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      barrierType: TollBarrierType.fromCode(
        map['barrier_type'] as String? ?? 'HIGHWAY_TOLL',
      ),
      feeTwoAxle: (map['fee_two_axle'] as num?)?.toDouble() ?? 0.0,
      feeThreeAxle: (map['fee_three_axle'] as num?)?.toDouble() ?? 0.0,
      feeFourAxlePlus: (map['fee_four_axle_plus'] as num?)?.toDouble() ?? 0.0,
      customsClearanceFee:
          (map['customs_clearance_fee'] as num?)?.toDouble() ?? 0.0,
      acceptsElectronicToll: (map['accepts_electronic_toll'] as int? ?? 1) == 1,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    highway,
    latitude,
    longitude,
    barrierType,
    feeTwoAxle,
    feeThreeAxle,
    feeFourAxlePlus,
    customsClearanceFee,
    acceptsElectronicToll,
  ];
}
