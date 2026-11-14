import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/fleet_repository.dart';

class FleetRepositoryImpl implements FleetRepository {
  final AppDatabase database;
  final ApiClient apiClient;

  FleetRepositoryImpl({required this.database, required this.apiClient});

  @override
  Future<List<Vehicle>> getVehicles() async {
    final db = await database.database;
    final maps = await db.query('vehicles', orderBy: 'id ASC');
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  @override
  Future<Vehicle?> getVehicleById(String id) async {
    final db = await database.database;
    final maps = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Vehicle.fromMap(maps.first);
  }

  @override
  Future<void> updateVehicleLocation(
    String id,
    double lat,
    double lng,
    double speed,
  ) async {
    final db = await database.database;
    await db.update(
      'vehicles',
      {'current_lat': lat, 'current_lng': lng, 'speed_kmh': speed},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Sync via ApiClient
    try {
      await apiClient.dio.post(
        '/telematics/location',
        data: {
          'vehicleId': id,
          'latitude': lat,
          'longitude': lng,
          'speedKmh': speed,
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> updateVehicleTelemetry(Vehicle vehicle) async {
    final db = await database.database;
    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }
}
