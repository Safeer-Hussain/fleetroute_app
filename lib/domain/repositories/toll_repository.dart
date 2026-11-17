import '../entities/route_plan.dart';
import '../entities/toll_barrier.dart';
import '../entities/toll_estimate.dart';
import '../entities/waybill_stop.dart';

abstract class TollRepository {
  Future<List<TollBarrier>> getAllTollBarriers();

  Future<RouteTollEstimate> estimateRouteToll({
    required RoutePlan route,
    required List<WaybillStop> stops,
    required VehicleAxleTier axleTier,
    bool useElectronicTag = true,
  });

  Future<void> saveRouteTollEstimate(RouteTollEstimate estimate);

  Future<RouteTollEstimate?> getSavedRouteTollEstimate(String routeId);
}
