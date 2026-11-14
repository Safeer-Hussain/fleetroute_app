import '../entities/vehicle.dart';

abstract class FleetRepository {
  Future<List<Vehicle>> getVehicles();
  Future<Vehicle?> getVehicleById(String id);
  Future<void> updateVehicleLocation(
    String id,
    double lat,
    double lng,
    double speed,
  );
  Future<void> updateVehicleTelemetry(Vehicle vehicle);
}
