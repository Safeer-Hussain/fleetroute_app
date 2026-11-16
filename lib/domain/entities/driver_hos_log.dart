import 'package:equatable/equatable.dart';

enum HosDutyStatus {
  driving,
  onDuty,
  sleeperBerth,
  offDuty;

  String get displayName {
    switch (this) {
      case HosDutyStatus.driving:
        return 'DRIVING';
      case HosDutyStatus.onDuty:
        return 'ON DUTY';
      case HosDutyStatus.sleeperBerth:
        return 'SLEEPER BERTH';
      case HosDutyStatus.offDuty:
        return 'OFF DUTY';
    }
  }

  String get code {
    switch (this) {
      case HosDutyStatus.driving:
        return 'DRIVING';
      case HosDutyStatus.onDuty:
        return 'ON_DUTY';
      case HosDutyStatus.sleeperBerth:
        return 'SLEEPER_BERTH';
      case HosDutyStatus.offDuty:
        return 'OFF_DUTY';
    }
  }

  static HosDutyStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'DRIVING':
        return HosDutyStatus.driving;
      case 'ON_DUTY':
        return HosDutyStatus.onDuty;
      case 'SLEEPER_BERTH':
        return HosDutyStatus.sleeperBerth;
      case 'OFF_DUTY':
      default:
        return HosDutyStatus.offDuty;
    }
  }
}

enum HosWarningState {
  normal,
  warning,
  violation;

  String get label {
    switch (this) {
      case HosWarningState.normal:
        return 'COMPLIANT';
      case HosWarningState.warning:
        return 'BREAK REQUIRED SOON';
      case HosWarningState.violation:
        return 'HOS VIOLATION';
    }
  }
}

class DriverHosLog extends Equatable {
  // FMCSA / Transport Rules (in seconds):
  // Max driving hours in shift: 11h = 39,600s
  // Mandatory 30-min break before: 8h = 28,800s consecutive driving
  // Max on-duty window in shift: 14h = 50,400s
  static const int maxDrivingSeconds = 11 * 3600; // 39600s
  static const int maxConsecutiveSecondsBeforeBreak = 8 * 3600; // 28800s
  static const int maxOnDutySeconds = 14 * 3600; // 50400s
  static const int mandatoryBreakSeconds = 30 * 60; // 1800s (30 mins)

  final String driverId;
  final String driverName;
  final String vehicleId;
  final HosDutyStatus currentStatus;
  final int drivingSecondsToday;
  final int onDutySecondsToday;
  final int secondsUntilBreakRequired;
  final int breakDurationSeconds;
  final DateTime lastStatusChange;

  const DriverHosLog({
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.currentStatus,
    required this.drivingSecondsToday,
    required this.onDutySecondsToday,
    required this.secondsUntilBreakRequired,
    required this.breakDurationSeconds,
    required this.lastStatusChange,
  });

  int get drivingSecondsRemaining {
    final remaining = maxDrivingSeconds - drivingSecondsToday;
    return remaining > 0 ? remaining : 0;
  }

  int get onDutySecondsRemaining {
    final remaining = maxOnDutySeconds - onDutySecondsToday;
    return remaining > 0 ? remaining : 0;
  }

  double get drivingProgressPct {
    return (drivingSecondsToday / maxDrivingSeconds).clamp(0.0, 1.0);
  }

  double get breakCountdownProgressPct {
    final elapsed =
        maxConsecutiveSecondsBeforeBreak - secondsUntilBreakRequired;
    return (elapsed / maxConsecutiveSecondsBeforeBreak).clamp(0.0, 1.0);
  }

  HosWarningState get warningState {
    if (drivingSecondsToday >= maxDrivingSeconds ||
        secondsUntilBreakRequired <= 0) {
      return HosWarningState.violation;
    }
    // Warning when <= 1 hour left until break or >= 10 hours driving
    if (secondsUntilBreakRequired <= 3600 ||
        drivingSecondsToday >= (10 * 3600)) {
      return HosWarningState.warning;
    }
    return HosWarningState.normal;
  }

  String formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get drivingRemainingFormatted =>
      formatSeconds(drivingSecondsRemaining);
  String get breakCountdownFormatted =>
      formatSeconds(secondsUntilBreakRequired);
  String get drivingConsumedFormatted => formatSeconds(drivingSecondsToday);
  String get onDutyConsumedFormatted => formatSeconds(onDutySecondsToday);

  DriverHosLog copyWith({
    String? driverId,
    String? driverName,
    String? vehicleId,
    HosDutyStatus? currentStatus,
    int? drivingSecondsToday,
    int? onDutySecondsToday,
    int? secondsUntilBreakRequired,
    int? breakDurationSeconds,
    DateTime? lastStatusChange,
  }) {
    return DriverHosLog(
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      currentStatus: currentStatus ?? this.currentStatus,
      drivingSecondsToday: drivingSecondsToday ?? this.drivingSecondsToday,
      onDutySecondsToday: onDutySecondsToday ?? this.onDutySecondsToday,
      secondsUntilBreakRequired:
          secondsUntilBreakRequired ?? this.secondsUntilBreakRequired,
      breakDurationSeconds: breakDurationSeconds ?? this.breakDurationSeconds,
      lastStatusChange: lastStatusChange ?? this.lastStatusChange,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'driver_name': driverName,
      'vehicle_id': vehicleId,
      'current_status': currentStatus.code,
      'driving_seconds': drivingSecondsToday,
      'on_duty_seconds': onDutySecondsToday,
      'seconds_until_break': secondsUntilBreakRequired,
      'break_duration_seconds': breakDurationSeconds,
      'last_status_change': lastStatusChange.toIso8601String(),
    };
  }

  factory DriverHosLog.fromMap(Map<String, dynamic> map) {
    return DriverHosLog(
      driverId: map['driver_id'] as String,
      driverName: map['driver_name'] as String,
      vehicleId: map['vehicle_id'] as String,
      currentStatus: HosDutyStatus.fromCode(map['current_status'] as String),
      drivingSecondsToday: (map['driving_seconds'] as num).toInt(),
      onDutySecondsToday: (map['on_duty_seconds'] as num).toInt(),
      secondsUntilBreakRequired: (map['seconds_until_break'] as num).toInt(),
      breakDurationSeconds:
          (map['break_duration_seconds'] as num?)?.toInt() ?? 0,
      lastStatusChange:
          DateTime.tryParse(map['last_status_change'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    driverId,
    driverName,
    vehicleId,
    currentStatus,
    drivingSecondsToday,
    onDutySecondsToday,
    secondsUntilBreakRequired,
    breakDurationSeconds,
    lastStatusChange,
  ];
}
