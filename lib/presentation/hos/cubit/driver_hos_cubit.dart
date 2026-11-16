import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/driver_hos_log.dart';
import '../../../domain/entities/rest_stop.dart';
import '../../../domain/repositories/hos_repository.dart';
import 'driver_hos_state.dart';

class DriverHosCubit extends Cubit<DriverHosState> {
  final HosRepository hosRepository;
  Timer? _simulationTimer;
  StreamSubscription<DriverHosLog>? _logSubscription;
  String _activeDriverId = 'DRV-101';
  double _lastKnownLat = 31.5204;
  double _lastKnownLng = 74.3587;

  double get lastKnownLat => _lastKnownLat;
  double get lastKnownLng => _lastKnownLng;

  DriverHosCubit({required this.hosRepository}) : super(const DriverHosState());

  Future<void> loadHos({
    String driverId = 'DRV-101',
    double lat = 31.5204,
    double lng = 74.3587,
  }) async {
    _activeDriverId = driverId;
    _lastKnownLat = lat;
    _lastKnownLng = lng;

    emit(state.copyWith(status: DriverHosViewStatus.loading));

    try {
      final log = await hosRepository.getDriverHosLog(driverId);
      final restStops = await hosRepository.getNearestRestStops(
        currentLat: lat,
        currentLng: lng,
      );

      _logSubscription?.cancel();
      _logSubscription = hosRepository.watchDriverHosLog(driverId).listen((
        updatedLog,
      ) {
        emit(state.copyWith(hosLog: updatedLog));
      });

      emit(
        state.copyWith(
          status: DriverHosViewStatus.loaded,
          hosLog: log,
          nearestRestStops: restStops,
          selectedRestStop: restStops.isNotEmpty ? restStops.first : null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DriverHosViewStatus.error,
          errorMessage: 'Failed to load driver HOS telemetry: $e',
        ),
      );
    }
  }

  Future<void> changeDutyStatus(HosDutyStatus newStatus) async {
    final currentLog = state.hosLog;
    if (currentLog == null) return;

    try {
      await hosRepository.updateDutyStatus(_activeDriverId, newStatus);
      final updated = currentLog.copyWith(
        currentStatus: newStatus,
        lastStatusChange: DateTime.now(),
      );

      String? notice;
      if (newStatus == HosDutyStatus.driving) {
        notice = 'Duty status switched to DRIVING. Active HOS clock running.';
      } else if (newStatus == HosDutyStatus.sleeperBerth) {
        notice = 'Duty status switched to SLEEPER BERTH. Rest timer active.';
      } else if (newStatus == HosDutyStatus.offDuty) {
        notice = 'Duty status switched to OFF DUTY.';
      } else {
        notice = 'Duty status switched to ON DUTY (Not Driving).';
      }

      emit(state.copyWith(hosLog: updated, userNotice: notice));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Unable to update duty status: $e'));
    }
  }

  Future<void> tickSimulation({int deltaSeconds = 60}) async {
    final currentLog = state.hosLog;
    if (currentLog == null) return;

    await hosRepository.logDrivingSecondsTick(_activeDriverId, deltaSeconds);
    final fresh = await hosRepository.getDriverHosLog(_activeDriverId);

    String? warningNotice;
    if (fresh.warningState == HosWarningState.warning) {
      warningNotice = 'FMCSA Warning: Approaching 8-hour consecutive drive threshold. Plan rest stop.';
    } else if (fresh.warningState == HosWarningState.violation) {
      warningNotice = 'CRITICAL HOS VIOLATION: Maximum driving limit or mandatory rest exceeded.';
    }

    emit(
      state.copyWith(
        hosLog: fresh,
        userNotice: warningNotice ?? state.userNotice,
      ),
    );
  }

  void toggleDriveSimulation() {
    if (state.isSimulatingDrive) {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      emit(state.copyWith(isSimulatingDrive: false));
    } else {
      emit(state.copyWith(isSimulatingDrive: true));
      _simulationTimer?.cancel();
      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Accelerate simulation: each 1 second equals 60 seconds (1 min) of elapsed driving
        tickSimulation(deltaSeconds: 60);
      });
    }
  }

  Future<void> takeMandatoryBreak() async {
    final currentLog = state.hosLog;
    if (currentLog == null) return;

    try {
      await hosRepository.resetBreakTimer(_activeDriverId);
      final refreshed = await hosRepository.getDriverHosLog(_activeDriverId);
      emit(
        state.copyWith(
          hosLog: refreshed,
          userNotice: 'Mandatory 30-minute rest logged. Consecutive drive clock reset to 8h 00m.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to log mandatory break: $e'));
    }
  }

  void selectRestStop(RestStop stop) {
    emit(state.copyWith(selectedRestStop: stop));
  }

  void clearNotice() {
    emit(state.copyWith(clearNotice: true));
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    _logSubscription?.cancel();
    return super.close();
  }
}
