import '../entities/fuel_finder_recommendation.dart';
import '../entities/fuel_station.dart';
import '../entities/route_plan.dart';
import '../entities/waybill_stop.dart';

abstract class FuelStationRepository {
  Future<List<FuelStation>> getAllFuelStations();

  Future<FuelFinderRecommendation> findOptimalCorridorFuelStop({
    required RoutePlan route,
    required List<WaybillStop> stops,
    double corridorToleranceKm = 8.0,
    double refuelLiters = 300.0,
  });

  Future<WaybillStop> injectFuelStopWaypoint({
    required String routeId,
    required FuelStation station,
    required double refuelLiters,
  });
}
