import '../../domain/entities/toll_barrier.dart';

class TollBarrierModel extends TollBarrier {
  const TollBarrierModel({
    required super.id,
    required super.name,
    required super.highway,
    required super.latitude,
    required super.longitude,
    required super.barrierType,
    required super.feeTwoAxle,
    required super.feeThreeAxle,
    required super.feeFourAxlePlus,
    required super.customsClearanceFee,
    required super.acceptsElectronicToll,
  });

  factory TollBarrierModel.fromMap(Map<String, dynamic> map) {
    return TollBarrierModel(
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

  factory TollBarrierModel.fromEntity(TollBarrier entity) {
    return TollBarrierModel(
      id: entity.id,
      name: entity.name,
      highway: entity.highway,
      latitude: entity.latitude,
      longitude: entity.longitude,
      barrierType: entity.barrierType,
      feeTwoAxle: entity.feeTwoAxle,
      feeThreeAxle: entity.feeThreeAxle,
      feeFourAxlePlus: entity.feeFourAxlePlus,
      customsClearanceFee: entity.customsClearanceFee,
      acceptsElectronicToll: entity.acceptsElectronicToll,
    );
  }
}
