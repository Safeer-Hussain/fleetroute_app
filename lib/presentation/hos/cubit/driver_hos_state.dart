import 'package:equatable/equatable.dart';

import '../../../domain/entities/driver_hos_log.dart';
import '../../../domain/entities/rest_stop.dart';

enum DriverHosViewStatus { initial, loading, loaded, error }

class DriverHosState extends Equatable {
  final DriverHosViewStatus status;
  final DriverHosLog? hosLog;
  final List<RestStop> nearestRestStops;
  final RestStop? selectedRestStop;
  final bool isSimulatingDrive;
  final String? errorMessage;
  final String? userNotice;

  const DriverHosState({
    this.status = DriverHosViewStatus.initial,
    this.hosLog,
    this.nearestRestStops = const [],
    this.selectedRestStop,
    this.isSimulatingDrive = false,
    this.errorMessage,
    this.userNotice,
  });

  HosDutyStatus get currentDutyStatus =>
      hosLog?.currentStatus ?? HosDutyStatus.offDuty;

  HosWarningState get warningState =>
      hosLog?.warningState ?? HosWarningState.normal;

  DriverHosState copyWith({
    DriverHosViewStatus? status,
    DriverHosLog? hosLog,
    List<RestStop>? nearestRestStops,
    RestStop? selectedRestStop,
    bool? isSimulatingDrive,
    String? errorMessage,
    String? userNotice,
    bool clearNotice = false,
  }) {
    return DriverHosState(
      status: status ?? this.status,
      hosLog: hosLog ?? this.hosLog,
      nearestRestStops: nearestRestStops ?? this.nearestRestStops,
      selectedRestStop: selectedRestStop ?? this.selectedRestStop,
      isSimulatingDrive: isSimulatingDrive ?? this.isSimulatingDrive,
      errorMessage: errorMessage ?? this.errorMessage,
      userNotice: clearNotice ? null : (userNotice ?? this.userNotice),
    );
  }

  @override
  List<Object?> get props => [
    status,
    hosLog,
    nearestRestStops,
    selectedRestStop,
    isSimulatingDrive,
    errorMessage,
    userNotice,
  ];
}
