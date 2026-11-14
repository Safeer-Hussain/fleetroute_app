import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/entities/waybill_stop.dart';
import '../../domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  final AppDatabase database;
  final ApiClient apiClient;

  RouteRepositoryImpl({required this.database, required this.apiClient});

  @override
  Future<List<RoutePlan>> getRoutes() async {
    final db = await database.database;
    final maps = await db.query('routes', orderBy: 'id ASC');
    return maps.map((m) => RoutePlan.fromMap(m)).toList();
  }

  @override
  Future<RoutePlan?> getRouteById(String id) async {
    final db = await database.database;
    final maps = await db.query(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RoutePlan.fromMap(maps.first);
  }

  @override
  Future<List<WaybillStop>> getStopsForRoute(String routeId) async {
    final db = await database.database;
    final maps = await db.query(
      'waybill_stops',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'sequence_order ASC',
    );
    return maps.map((m) => WaybillStop.fromMap(m)).toList();
  }

  @override
  Future<void> saveOptimizedSequence(
    String routeId,
    List<WaybillStop> stops,
    double newDistanceKm,
    double fuelSavedLiters,
    int minutesSaved,
  ) async {
    final db = await database.database;
    final batch = db.batch();

    // Update stops sequence order
    for (int i = 0; i < stops.length; i++) {
      batch.update(
        'waybill_stops',
        {'sequence_order': i + 1},
        where: 'id = ?',
        whereArgs: [stops[i].id],
      );
    }

    // Update route details
    batch.update(
      'routes',
      {
        'optimized_distance_km': newDistanceKm,
        'fuel_saved_liters': fuelSavedLiters,
        'minutes_saved': minutesSaved,
        'is_optimized': 1,
      },
      where: 'id = ?',
      whereArgs: [routeId],
    );

    await batch.commit(noResult: true);

    try {
      await apiClient.dio.post(
        '/routes/optimize',
        data: {
          'routeId': routeId,
          'stopIds': stops.map((s) => s.id).toList(),
          'optimizedDistanceKm': newDistanceKm,
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> createRoute(RoutePlan route, List<WaybillStop> stops) async {
    final db = await database.database;
    final batch = db.batch();

    batch.insert('routes', route.toMap());
    for (final s in stops) {
      batch.insert('waybill_stops', s.toMap());
    }

    await batch.commit(noResult: true);

    try {
      await apiClient.dio.post(
        '/routes/create',
        data: {
          'route': route.toMap(),
          'stops': stops.map((s) => s.toMap()).toList(),
        },
      );
    } catch (_) {}
  }
}
