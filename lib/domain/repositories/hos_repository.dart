import '../entities/driver_hos_log.dart';
import '../entities/rest_stop.dart';

abstract class HosRepository {
  Future<DriverHosLog> getDriverHosLog(String driverId);
  Future<void> updateDutyStatus(String driverId, HosDutyStatus newStatus);
  Future<void> logDrivingSecondsTick(String driverId, int deltaSeconds);
  Future<void> resetBreakTimer(String driverId);
  Future<List<RestStop>> getNearestRestStops({
    required double currentLat,
    required double currentLng,
  });
  Stream<DriverHosLog> watchDriverHosLog(String driverId);
}
