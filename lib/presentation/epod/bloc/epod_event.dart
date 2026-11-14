import 'package:equatable/equatable.dart';

import '../../../domain/entities/waybill_stop.dart';

abstract class EpodEvent extends Equatable {
  const EpodEvent();

  @override
  List<Object?> get props => [];
}

class LoadWaybillsEvent extends EpodEvent {}

class FilterWaybillsEvent extends EpodEvent {
  final String filter; // ALL, OUT_FOR_DELIVERY, DELIVERED, EXCEPTION
  const FilterWaybillsEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class SearchWaybillsEvent extends EpodEvent {
  final String query;
  const SearchWaybillsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectWaybillEvent extends EpodEvent {
  final WaybillStop waybill;
  const SelectWaybillEvent(this.waybill);

  @override
  List<Object?> get props => [waybill];
}

class ClearSelectedWaybillEvent extends EpodEvent {}

class ConfirmDeliveryEvent extends EpodEvent {
  final String waybillId;
  final String recipientName;
  final String signatureSvg;

  const ConfirmDeliveryEvent({
    required this.waybillId,
    required this.recipientName,
    required this.signatureSvg,
  });

  @override
  List<Object?> get props => [waybillId, recipientName, signatureSvg];
}

class LogExceptionEvent extends EpodEvent {
  final String waybillId;
  final String reason;

  const LogExceptionEvent({required this.waybillId, required this.reason});

  @override
  List<Object?> get props => [waybillId, reason];
}
