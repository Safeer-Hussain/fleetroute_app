import '../../domain/entities/driver_hos_log.dart';

class DriverHosModel extends DriverHosLog {
  const DriverHosModel({
    required super.driverId,
    required super.driverName,
    required super.vehicleId,
    required super.currentStatus,
    required super.drivingSecondsToday,
    required super.onDutySecondsToday,
    required super.secondsUntilBreakRequired,
    required super.breakDurationSeconds,
    required super.lastStatusChange,
  });

  factory DriverHosModel.fromMap(Map<String, dynamic> map) {
    return DriverHosModel(
      driverId: map['driver_id'] as String,
      driverName: map['driver_name'] as String,
      vehicleId: map['vehicle_id'] as String,
      currentStatus: HosDutyStatus.fromCode(map['current_status'] as String),
      drivingSecondsToday: (map['driving_seconds'] as num).toInt(),
      onDutySecondsToday: (map['on_duty_seconds'] as num).toInt(),
      secondsUntilBreakRequired: (map['seconds_until_break'] as num).toInt(),
      breakDurationSeconds:
          (map['break_duration_seconds'] as num?)?.toInt() ?? 0,
      lastStatusChange:
          DateTime.tryParse(map['last_status_change'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory DriverHosModel.fromEntity(DriverHosLog entity) {
    return DriverHosModel(
      driverId: entity.driverId,
      driverName: entity.driverName,
      vehicleId: entity.vehicleId,
      currentStatus: entity.currentStatus,
      drivingSecondsToday: entity.drivingSecondsToday,
      onDutySecondsToday: entity.onDutySecondsToday,
      secondsUntilBreakRequired: entity.secondsUntilBreakRequired,
      breakDurationSeconds: entity.breakDurationSeconds,
      lastStatusChange: entity.lastStatusChange,
    );
  }
}
