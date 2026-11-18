import '../../domain/entities/temperature_excursion.dart';

class TemperatureExcursionModel extends TemperatureExcursion {
  const TemperatureExcursionModel({
    required super.id,
    required super.vehicleId,
    required super.vehicleName,
    required super.driverName,
    required super.routeId,
    required super.startTime,
    super.endTime,
    required super.durationSeconds,
    required super.maxRecordedTempC,
    super.targetTempC = TemperatureExcursion.standardTargetCelsius,
    super.thresholdTempC = TemperatureExcursion.criticalThresholdCelsius,
    required super.severity,
    super.isResolved = false,
    super.resolutionNotes,
    super.acknowledgedBy,
    required super.complianceStatus,
  });

  factory TemperatureExcursionModel.fromMap(Map<String, dynamic> map) {
    final entity = TemperatureExcursion.fromMap(map);
    return TemperatureExcursionModel(
      id: entity.id,
      vehicleId: entity.vehicleId,
      vehicleName: entity.vehicleName,
      driverName: entity.driverName,
      routeId: entity.routeId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      durationSeconds: entity.durationSeconds,
      maxRecordedTempC: entity.maxRecordedTempC,
      targetTempC: entity.targetTempC,
      thresholdTempC: entity.thresholdTempC,
      severity: entity.severity,
      isResolved: entity.isResolved,
      resolutionNotes: entity.resolutionNotes,
      acknowledgedBy: entity.acknowledgedBy,
      complianceStatus: entity.complianceStatus,
    );
  }

  factory TemperatureExcursionModel.fromEntity(TemperatureExcursion entity) {
    return TemperatureExcursionModel(
      id: entity.id,
      vehicleId: entity.vehicleId,
      vehicleName: entity.vehicleName,
      driverName: entity.driverName,
      routeId: entity.routeId,
      startTime: entity.startTime,
      endTime: entity.endTime,
      durationSeconds: entity.durationSeconds,
      maxRecordedTempC: entity.maxRecordedTempC,
      targetTempC: entity.targetTempC,
      thresholdTempC: entity.thresholdTempC,
      severity: entity.severity,
      isResolved: entity.isResolved,
      resolutionNotes: entity.resolutionNotes,
      acknowledgedBy: entity.acknowledgedBy,
      complianceStatus: entity.complianceStatus,
    );
  }
}
