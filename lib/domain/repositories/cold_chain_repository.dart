import '../entities/temperature_excursion.dart';

abstract class ColdChainRepository {
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool onlyActive = false,
  });

  Future<void> recordTemperatureReading({
    required String vehicleId,
    required String vehicleName,
    required String routeId,
    required double tempC,
    required DateTime timestamp,
  });

  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorNotes,
  });

  Future<String> exportAuditCsv({String? vehicleId});

  Future<Map<String, dynamic>> getColdChainAuditMetrics();
}
