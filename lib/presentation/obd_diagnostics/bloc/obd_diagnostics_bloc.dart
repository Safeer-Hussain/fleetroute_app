import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/obd_telemetry_packet.dart';
import '../../../domain/repositories/obd_repository.dart';
import 'obd_diagnostics_event.dart';
import 'obd_diagnostics_state.dart';

class ObdDiagnosticsBloc
    extends Bloc<ObdDiagnosticsEvent, ObdDiagnosticsState> {
  final ObdRepository obdRepository;
  StreamSubscription<ObdTelemetryPacket>? _telemetrySubscription;

  ObdDiagnosticsBloc({required this.obdRepository})
    : super(const ObdDiagnosticsState()) {
    on<InitializeObdEvent>(_onInitialize);
    on<SelectObdVehicleEvent>(_onSelectVehicle);
    on<RunDtcScanEvent>(_onRunDtcScan);
    on<ClearDtcCodesEvent>(_onClearDtcCodes);
    on<ScheduleWorkshopServiceEvent>(_onScheduleService);
    on<TelemetryReceivedEvent>(_onTelemetryReceived);
  }

  Future<void> _onInitialize(
    InitializeObdEvent event,
    Emitter<ObdDiagnosticsState> emit,
  ) async {
    emit(state.copyWith(isConnecting: true));
    try {
      final devices = await obdRepository.scanDevices();
      final defaultId = devices.isNotEmpty
          ? (devices.first['id'] as String? ?? 'VH-101')
          : 'VH-101';
      await obdRepository.connectVehicle(defaultId);
      final faults = await obdRepository.getActiveFaults(defaultId);

      _telemetrySubscription?.cancel();
      _telemetrySubscription = obdRepository.getTelemetryStream().listen((
        packet,
      ) {
        if (!isClosed) {
          add(TelemetryReceivedEvent(packet));
        }
      });

      emit(
        state.copyWith(
          availableVehicles: List.unmodifiable(devices),
          selectedVehicleId: defaultId,
          activeFaults: List.unmodifiable(faults),
          isConnecting: false,
          statusMessage:
              'OBD-II CAN-bus bridge linked to $defaultId at 500 kbps.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isConnecting: false));
    }
  }

  Future<void> _onSelectVehicle(
    SelectObdVehicleEvent event,
    Emitter<ObdDiagnosticsState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedVehicleId: event.vehicleId,
        isConnecting: true,
        clearStatusMessage: true,
      ),
    );

    await obdRepository.connectVehicle(event.vehicleId);
    final faults = await obdRepository.getActiveFaults(event.vehicleId);

    emit(
      state.copyWith(
        isConnecting: false,
        activeFaults: List.unmodifiable(faults),
        statusMessage: 'CAN-bus switched to vehicle ${event.vehicleId}.',
      ),
    );
  }

  Future<void> _onRunDtcScan(
    RunDtcScanEvent event,
    Emitter<ObdDiagnosticsState> emit,
  ) async {
    emit(state.copyWith(isScanning: true));
    await Future.delayed(const Duration(milliseconds: 700)); // Scan latency
    final faults = await obdRepository.getActiveFaults(event.vehicleId);
    emit(
      state.copyWith(
        activeFaults: List.unmodifiable(faults),
        isScanning: false,
        statusMessage:
            'DTC scan complete: ${faults.length} diagnostic codes retrieved.',
      ),
    );
  }

  Future<void> _onClearDtcCodes(
    ClearDtcCodesEvent event,
    Emitter<ObdDiagnosticsState> emit,
  ) async {
    emit(state.copyWith(isScanning: true));
    final count = await obdRepository.clearFaultCodes(event.vehicleId);
    final faults = await obdRepository.getActiveFaults(event.vehicleId);
    emit(
      state.copyWith(
        activeFaults: List.unmodifiable(faults),
        isScanning: false,
        statusMessage:
            'Cleared $count DTC fault codes on vehicle ${event.vehicleId}. System nominal.',
      ),
    );
  }

  Future<void> _onScheduleService(
    ScheduleWorkshopServiceEvent event,
    Emitter<ObdDiagnosticsState> emit,
  ) async {
    await obdRepository.scheduleService(event.faultId);
    final updated = state.activeFaults.map((f) {
      if (f.id == event.faultId) {
        return f.copyWith(status: 'SERVICE_SCHEDULED');
      }
      return f;
    }).toList();

    emit(
      state.copyWith(
        activeFaults: List.unmodifiable(updated),
        statusMessage:
            'Preventive depot workshop service scheduled for fault ${event.faultId}.',
      ),
    );
  }

  void _onTelemetryReceived(
    TelemetryReceivedEvent event,
    Emitter<ObdDiagnosticsState> emit,
  ) {
    emit(state.copyWith(latestTelemetry: event.packet));
  }

  @override
  Future<void> close() {
    _telemetrySubscription?.cancel();
    return super.close();
  }
}
