import '../entities/route_plan.dart';
import '../entities/waybill_stop.dart';

abstract class RouteRepository {
  Future<List<RoutePlan>> getRoutes();
  Future<RoutePlan?> getRouteById(String id);
  Future<List<WaybillStop>> getStopsForRoute(String routeId);
  Future<void> saveOptimizedSequence(
    String routeId,
    List<WaybillStop> stops,
    double newDistanceKm,
    double fuelSavedLiters,
    int minutesSaved,
  );
  Future<void> createRoute(RoutePlan route, List<WaybillStop> stops);
}
