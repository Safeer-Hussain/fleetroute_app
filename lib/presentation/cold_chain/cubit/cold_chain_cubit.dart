import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/vehicle.dart';
import '../../../domain/repositories/cold_chain_repository.dart';
import 'cold_chain_state.dart';

class ColdChainCubit extends Cubit<ColdChainState> {
  final ColdChainRepository coldChainRepository;
  StreamSubscription? _subscription;

  ColdChainCubit({required this.coldChainRepository})
    : super(const ColdChainState()) {
    _subscription = coldChainRepository.watchExcursions().listen((list) {
      emit(state.copyWith(allExcursions: list));
    });
  }

  Future<void> loadExcursions({String? vehicleId}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await coldChainRepository.getExcursions(
        vehicleId: vehicleId,
      );
      emit(state.copyWith(isLoading: false, allExcursions: list));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load temperature excursions: $e',
        ),
      );
    }
  }

  void setFilter(ColdChainFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorName,
    required String notes,
  }) async {
    try {
      await coldChainRepository.acknowledgeExcursion(
        excursionId: excursionId,
        auditorName: auditorName,
        notes: notes,
      );
      final updated = await coldChainRepository.getExcursions();
      emit(
        state.copyWith(
          allExcursions: updated,
          statusMessage:
              'Excursion $excursionId signed and archived by $auditorName.',
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
          statusMessage:
              'QA Audit CSV generated (${state.allExcursions.length} records).',
        ),
      );
      return csv;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to export audit report: $e'));
      return '';
    }
  }

  Future<void> simulateTemperatureReading({
    required Vehicle vehicle,
    required double tempCelsius,
    required DateTime timestamp,
  }) async {
    try {
      await coldChainRepository.recordTelemetryTick(
        vehicle: vehicle,
        currentTempC: tempCelsius,
        timestamp: timestamp,
      );
      final list = await coldChainRepository.getExcursions();
      emit(state.copyWith(allExcursions: list));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to record temperature reading: $e',
        ),
      );
    }
  }

  void clearStatus() {
    emit(state.copyWith(clearStatusMessage: true, clearExportedCsv: true));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
