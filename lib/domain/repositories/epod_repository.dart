import '../entities/waybill_stop.dart';

abstract class EpodRepository {
  Future<List<WaybillStop>> getAllWaybills();
  Future<List<WaybillStop>> getWaybillsByStatus(String status);
  Future<void> confirmDelivery({
    required String waybillId,
    required String recipientName,
    required String signatureSvg,
  });
  Future<void> logException({
    required String waybillId,
    required String reason,
  });
}
