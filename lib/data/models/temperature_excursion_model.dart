import '../../domain/entities/temperature_excursion.dart';

class TemperatureExcursionModel extends TemperatureExcursion {
  const TemperatureExcursionModel({
    required super.id,
    required super.vehicleId,
    required super.vehicleName,
    required super.routeId,
    required super.recordedTempC,
    required super.thresholdTempC,
    required super.startTime,
    super.endTime,
    required super.durationSeconds,
    required super.severity,
    super.notes,
    super.isAcknowledged,
  });

  factory TemperatureExcursionModel.fromMap(Map<String, dynamic> map) {
    final entity = TemperatureExcursion.fromMap(map);
    return TemperatureExcursionModel(
      id: entity.id,
      vehicleId: entity.vehicleId,
      vehicleName: entity.vehicleName,
      routeId: entity.routeId,
      recordedTempC: entity.recordedTempC,
      thresholdTempC: entity.thresholdTempC,
      startTime: entity.startTime,
      endTime: entity.endTime,
      durationSeconds: entity.durationSeconds,
      severity: entity.severity,
      notes: entity.notes,
      isAcknowledged: entity.isAcknowledged,
    );
  }

  factory TemperatureExcursionModel.fromEntity(TemperatureExcursion entity) {
    return TemperatureExcursionModel(
      id: entity.id,
      vehicleId: entity.vehicleId,
      vehicleName: entity.vehicleName,
      routeId: entity.routeId,
      recordedTempC: entity.recordedTempC,
      thresholdTempC: entity.thresholdTempC,
      startTime: entity.startTime,
      endTime: entity.endTime,
      durationSeconds: entity.durationSeconds,
      severity: entity.severity,
      notes: entity.notes,
      isAcknowledged: entity.isAcknowledged,
    );
  }
}
