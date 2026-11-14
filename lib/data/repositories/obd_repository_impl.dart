import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/platform/native_obd_bridge.dart';
import '../../domain/entities/dtc_fault.dart';
import '../../domain/entities/obd_telemetry_packet.dart';
import '../../domain/repositories/obd_repository.dart';

class ObdRepositoryImpl implements ObdRepository {
  final AppDatabase database;
  final ApiClient apiClient;
  final NativeObdBridge nativeBridge;

  ObdRepositoryImpl({
    required this.database,
    required this.apiClient,
    required this.nativeBridge,
  });

  @override
  Future<List<Map<String, dynamic>>> scanDevices() async {
    return await nativeBridge.scanVehicles();
  }

  @override
  Future<bool> connectVehicle(String vehicleId) async {
    final success = await nativeBridge.connectObdAdapter(vehicleId);
    try {
      await apiClient.dio.post('/obd/connect', data: {'vehicleId': vehicleId});
    } catch (_) {}
    return success;
  }

  @override
  Future<List<DtcFault>> getActiveFaults(String vehicleId) async {
    final db = await database.database;
    final maps = await db.query(
      'dtc_faults',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
    );

    if (maps.isNotEmpty) {
      return maps.map((m) => DtcFault.fromMap(m)).toList();
    }

    // Fallback to bridge scan
    final faults = await nativeBridge.runDtcDiagnosticScan(vehicleId);
    for (final f in faults) {
      await db.insert('dtc_faults', f.toMap());
    }
    return faults;
  }

  @override
  Future<int> clearFaultCodes(String vehicleId) async {
    final count = await nativeBridge.clearDtcFaultCodes(vehicleId);
    final db = await database.database;

    await db.update(
      'dtc_faults',
      {'status': 'CLEARED'},
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
    );

    await db.update(
      'vehicles',
      {'has_active_dtc': 0},
      where: 'id = ?',
      whereArgs: [vehicleId],
    );

    try {
      await apiClient.dio.post(
        '/obd/clear-dtc',
        data: {'vehicleId': vehicleId, 'clearedCount': count},
      );
    } catch (_) {}

    return count;
  }

  @override
  Future<void> scheduleService(String faultId) async {
    final db = await database.database;
    await db.update(
      'dtc_faults',
      {'status': 'SERVICE_SCHEDULED'},
      where: 'id = ?',
      whereArgs: [faultId],
    );

    try {
      await apiClient.dio.post(
        '/obd/schedule-service',
        data: {'faultId': faultId},
      );
    } catch (_) {}
  }

  @override
  Stream<ObdTelemetryPacket> getTelemetryStream() {
    return nativeBridge.getTelemetryStream();
  }
}
