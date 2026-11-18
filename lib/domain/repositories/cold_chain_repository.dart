import '../entities/temperature_excursion.dart';
import '../entities/vehicle.dart';

abstract class ColdChainRepository {
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool breachesOnly = false,
  });

  Future<void> logExcursion(TemperatureExcursion excursion);

  Future<void> updateExcursion(TemperatureExcursion excursion);

  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorName,
    required String notes,
  });

  Future<String> exportAuditCsv({String? vehicleId});

  Stream<List<TemperatureExcursion>> watchExcursions();

  Future<TemperatureExcursion?> recordTelemetryTick({
    required Vehicle vehicle,
    required double currentTempC,
    required DateTime timestamp,
  });
}
