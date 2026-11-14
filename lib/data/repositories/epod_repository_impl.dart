import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/waybill_stop.dart';
import '../../domain/repositories/epod_repository.dart';

class EpodRepositoryImpl implements EpodRepository {
  final AppDatabase database;
  final ApiClient apiClient;

  EpodRepositoryImpl({required this.database, required this.apiClient});

  @override
  Future<List<WaybillStop>> getAllWaybills() async {
    final db = await database.database;
    final maps = await db.query('waybill_stops', orderBy: 'sequence_order ASC');
    return maps.map((m) => WaybillStop.fromMap(m)).toList();
  }

  @override
  Future<List<WaybillStop>> getWaybillsByStatus(String status) async {
    final db = await database.database;
    if (status == 'ALL') {
      return getAllWaybills();
    }
    final maps = await db.query(
      'waybill_stops',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'sequence_order ASC',
    );
    return maps.map((m) => WaybillStop.fromMap(m)).toList();
  }

  @override
  Future<void> confirmDelivery({
    required String waybillId,
    required String recipientName,
    required String signatureSvg,
  }) async {
    final db = await database.database;
    final deliveredAt = DateTime.now().toIso8601String();

    await db.update(
      'waybill_stops',
      {
        'status': 'DELIVERED',
        'recipient_name': recipientName,
        'recipient_signature_svg': signatureSvg,
        'delivered_at': deliveredAt,
      },
      where: 'id = ?',
      whereArgs: [waybillId],
    );

    try {
      await apiClient.dio.post(
        '/epod/confirm',
        data: {
          'waybillId': waybillId,
          'recipientName': recipientName,
          'signatureSvg': signatureSvg,
          'timestamp': deliveredAt,
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> logException({
    required String waybillId,
    required String reason,
  }) async {
    final db = await database.database;
    await db.update(
      'waybill_stops',
      {'status': 'EXCEPTION', 'exception_reason': reason},
      where: 'id = ?',
      whereArgs: [waybillId],
    );

    try {
      await apiClient.dio.post(
        '/epod/exception',
        data: {'waybillId': waybillId, 'exceptionReason': reason},
      );
    } catch (_) {}
  }
}
