import 'package:equatable/equatable.dart';

import '../../../domain/entities/waybill_stop.dart';

class EpodState extends Equatable {
  final List<WaybillStop> waybills;
  final List<WaybillStop> filteredWaybills;
  final WaybillStop? selectedWaybill;
  final String activeFilter; // ALL, OUT_FOR_DELIVERY, DELIVERED, EXCEPTION
  final String searchQuery;
  final bool isLoading;
  final bool isSubmitting;
  final WaybillStop? lastDeliveredWaybill;
  final String? statusMessage;

  const EpodState({
    this.waybills = const [],
    this.filteredWaybills = const [],
    this.selectedWaybill,
    this.activeFilter = 'ALL',
    this.searchQuery = '',
    this.isLoading = false,
    this.isSubmitting = false,
    this.lastDeliveredWaybill,
    this.statusMessage,
  });

  EpodState copyWith({
    List<WaybillStop>? waybills,
    List<WaybillStop>? filteredWaybills,
    WaybillStop? selectedWaybill,
    bool clearSelectedWaybill = false,
    String? activeFilter,
    String? searchQuery,
    bool? isLoading,
    bool? isSubmitting,
    WaybillStop? lastDeliveredWaybill,
    bool clearLastDelivered = false,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return EpodState(
      waybills: waybills ?? this.waybills,
      filteredWaybills: filteredWaybills ?? this.filteredWaybills,
      selectedWaybill: clearSelectedWaybill
          ? null
          : (selectedWaybill ?? this.selectedWaybill),
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastDeliveredWaybill: clearLastDelivered
          ? null
          : (lastDeliveredWaybill ?? this.lastDeliveredWaybill),
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
    waybills,
    filteredWaybills,
    selectedWaybill,
    activeFilter,
    searchQuery,
    isLoading,
    isSubmitting,
    lastDeliveredWaybill,
    statusMessage,
  ];
}
