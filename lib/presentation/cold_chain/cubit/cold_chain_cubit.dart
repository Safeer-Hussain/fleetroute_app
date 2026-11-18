import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/cold_chain_repository.dart';
import 'cold_chain_state.dart';

class ColdChainCubit extends Cubit<ColdChainState> {
  final ColdChainRepository coldChainRepository;

  ColdChainCubit({required this.coldChainRepository})
    : super(const ColdChainState());

  Future<void> loadExcursions() async {
    emit(state.copyWith(status: ColdChainStatus.loading));
    try {
      final list = await coldChainRepository.getExcursions();
      final metrics = await coldChainRepository.getColdChainAuditMetrics();
      emit(
        state.copyWith(
          status: ColdChainStatus.loaded,
          excursions: list,
          metrics: metrics,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ColdChainStatus.error,
          errorMessage: 'Failed to load cold-chain excursions: $e',
        ),
      );
    }
  }

  void setFilter(ColdChainFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorNotes,
  }) async {
    try {
      await coldChainRepository.acknowledgeExcursion(
        excursionId: excursionId,
        auditorNotes: auditorNotes,
      );
      final list = await coldChainRepository.getExcursions();
      final metrics = await coldChainRepository.getColdChainAuditMetrics();
      emit(
        state.copyWith(
          excursions: list,
          metrics: metrics,
          successMessage:
              'Excursion $excursionId acknowledged with audit note.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to acknowledge excursion: $e'));
    }
  }

  Future<String> exportAuditCsv({String? vehicleId}) async {
    try {
      final csv = await coldChainRepository.exportAuditCsv(
        vehicleId: vehicleId,
      );
      emit(
        state.copyWith(
          exportedCsv: csv,
          successMessage: 'GDP Cold-Chain Audit Report exported successfully.',
        ),
      );
      return csv;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to export audit CSV: $e'));
      rethrow;
    }
  }

  Future<void> recordReading({
    required String vehicleId,
    required String vehicleName,
    required String routeId,
    required double tempC,
    DateTime? timestamp,
  }) async {
    try {
      await coldChainRepository.recordTemperatureReading(
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        routeId: routeId,
        tempC: tempC,
        timestamp: timestamp ?? DateTime.now(),
      );
      await loadExcursions();
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to record temperature reading: $e',
        ),
      );
    }
  }
}
