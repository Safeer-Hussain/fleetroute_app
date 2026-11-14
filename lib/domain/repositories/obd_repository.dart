import '../entities/dtc_fault.dart';
import '../entities/obd_telemetry_packet.dart';

abstract class ObdRepository {
  Future<List<Map<String, dynamic>>> scanDevices();
  Future<bool> connectVehicle(String vehicleId);
  Future<List<DtcFault>> getActiveFaults(String vehicleId);
  Future<int> clearFaultCodes(String vehicleId);
  Future<void> scheduleService(String faultId);
  Stream<ObdTelemetryPacket> getTelemetryStream();
}
