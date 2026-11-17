import '../../domain/entities/toll_estimate.dart';

class RouteTollEstimateModel extends RouteTollEstimate {
  const RouteTollEstimateModel({
    required super.routeId,
    required super.axleTier,
    required super.crossings,
    required super.totalTollFees,
    required super.totalCustomsFees,
    required super.totalElectronicDiscounts,
    required super.netTotalFee,
    super.electronicTagUsed,
  });

  factory RouteTollEstimateModel.fromMap(Map<String, dynamic> map) {
    final estimate = RouteTollEstimate.fromMap(map);
    return RouteTollEstimateModel(
      routeId: estimate.routeId,
      axleTier: estimate.axleTier,
      crossings: estimate.crossings,
      totalTollFees: estimate.totalTollFees,
      totalCustomsFees: estimate.totalCustomsFees,
      totalElectronicDiscounts: estimate.totalElectronicDiscounts,
      netTotalFee: estimate.netTotalFee,
      electronicTagUsed: estimate.electronicTagUsed,
    );
  }

  factory RouteTollEstimateModel.fromEntity(RouteTollEstimate entity) {
    return RouteTollEstimateModel(
      routeId: entity.routeId,
      axleTier: entity.axleTier,
      crossings: entity.crossings,
      totalTollFees: entity.totalTollFees,
      totalCustomsFees: entity.totalCustomsFees,
      totalElectronicDiscounts: entity.totalElectronicDiscounts,
      netTotalFee: entity.netTotalFee,
      electronicTagUsed: entity.electronicTagUsed,
    );
  }
}
