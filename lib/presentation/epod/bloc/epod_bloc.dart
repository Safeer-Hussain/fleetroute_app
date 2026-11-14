import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/waybill_stop.dart';
import '../../../domain/repositories/epod_repository.dart';
import 'epod_event.dart';
import 'epod_state.dart';

class EpodBloc extends Bloc<EpodEvent, EpodState> {
  final EpodRepository epodRepository;

  EpodBloc({required this.epodRepository}) : super(const EpodState()) {
    on<LoadWaybillsEvent>(_onLoadWaybills);
    on<FilterWaybillsEvent>(_onFilterWaybills);
    on<SearchWaybillsEvent>(_onSearchWaybills);
    on<SelectWaybillEvent>(_onSelectWaybill);
    on<ClearSelectedWaybillEvent>(_onClearSelectedWaybill);
    on<ConfirmDeliveryEvent>(_onConfirmDelivery);
    on<LogExceptionEvent>(_onLogException);
  }

  Future<void> _onLoadWaybills(
    LoadWaybillsEvent event,
    Emitter<EpodState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final waybills = await epodRepository.getAllWaybills();
      final filtered = _filterAndSearch(
        waybills,
        state.activeFilter,
        state.searchQuery,
      );
      emit(
        state.copyWith(
          waybills: List.unmodifiable(waybills),
          filteredWaybills: List.unmodifiable(filtered),
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onFilterWaybills(FilterWaybillsEvent event, Emitter<EpodState> emit) {
    final filtered = _filterAndSearch(
      state.waybills,
      event.filter,
      state.searchQuery,
    );
    emit(
      state.copyWith(
        activeFilter: event.filter,
        filteredWaybills: List.unmodifiable(filtered),
      ),
    );
  }

  void _onSearchWaybills(SearchWaybillsEvent event, Emitter<EpodState> emit) {
    final filtered = _filterAndSearch(
      state.waybills,
      state.activeFilter,
      event.query,
    );
    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredWaybills: List.unmodifiable(filtered),
      ),
    );
  }

  void _onSelectWaybill(SelectWaybillEvent event, Emitter<EpodState> emit) {
    emit(state.copyWith(selectedWaybill: event.waybill));
  }

  void _onClearSelectedWaybill(
    ClearSelectedWaybillEvent event,
    Emitter<EpodState> emit,
  ) {
    emit(state.copyWith(clearSelectedWaybill: true));
  }

  Future<void> _onConfirmDelivery(
    ConfirmDeliveryEvent event,
    Emitter<EpodState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await epodRepository.confirmDelivery(
        waybillId: event.waybillId,
        recipientName: event.recipientName,
        signatureSvg: event.signatureSvg,
      );

      final waybills = await epodRepository.getAllWaybills();
      final delivered = waybills
          .where((w) => w.id == event.waybillId)
          .firstOrNull;
      final filtered = _filterAndSearch(
        waybills,
        state.activeFilter,
        state.searchQuery,
      );

      emit(
        state.copyWith(
          waybills: List.unmodifiable(waybills),
          filteredWaybills: List.unmodifiable(filtered),
          isSubmitting: false,
          lastDeliveredWaybill: delivered,
          selectedWaybill: delivered,
          statusMessage:
              'ePOD Delivery Confirmed for Waybill ${event.waybillId}. Manifest updated.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
    }
  }

  Future<void> _onLogException(
    LogExceptionEvent event,
    Emitter<EpodState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await epodRepository.logException(
        waybillId: event.waybillId,
        reason: event.reason,
      );

      final waybills = await epodRepository.getAllWaybills();
      final filtered = _filterAndSearch(
        waybills,
        state.activeFilter,
        state.searchQuery,
      );

      emit(
        state.copyWith(
          waybills: List.unmodifiable(waybills),
          filteredWaybills: List.unmodifiable(filtered),
          isSubmitting: false,
          statusMessage:
              'Delivery Exception logged for Waybill ${event.waybillId}.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isSubmitting: false));
    }
  }

  List<WaybillStop> _filterAndSearch(
    List<WaybillStop> list,
    String filter,
    String query,
  ) {
    var result = list;
    if (filter != 'ALL') {
      result = result.where((w) => w.status == filter).toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((w) {
        return w.stopName.toLowerCase().contains(q) ||
            w.id.toLowerCase().contains(q) ||
            w.cargoDescription.toLowerCase().contains(q) ||
            (w.recipientName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return result;
  }
}
