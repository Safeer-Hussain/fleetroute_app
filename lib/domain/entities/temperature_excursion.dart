import 'package:equatable/equatable.dart';

enum TemperatureExcursionSeverity {
  warning,
  critical,
  nominal;

  String get displayName {
    switch (this) {
      case TemperatureExcursionSeverity.warning:
        return 'WARNING (-15°C to -10°C)';
      case TemperatureExcursionSeverity.critical:
        return 'CRITICAL (> -10°C)';
      case TemperatureExcursionSeverity.nominal:
        return 'NOMINAL';
    }
  }

  String get code {
    switch (this) {
      case TemperatureExcursionSeverity.warning:
        return 'WARNING';
      case TemperatureExcursionSeverity.critical:
        return 'CRITICAL';
      case TemperatureExcursionSeverity.nominal:
        return 'NOMINAL';
    }
  }

  static TemperatureExcursionSeverity fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'CRITICAL':
        return TemperatureExcursionSeverity.critical;
      case 'WARNING':
        return TemperatureExcursionSeverity.warning;
      case 'NOMINAL':
      default:
        return TemperatureExcursionSeverity.nominal;
    }
  }

  static TemperatureExcursionSeverity fromTemperature(double tempC) {
    if (tempC > -10.0) {
      return TemperatureExcursionSeverity.critical;
    } else if (tempC > -15.0) {
      return TemperatureExcursionSeverity.warning;
    } else {
      return TemperatureExcursionSeverity.nominal;
    }
  }
}

class TemperatureExcursion extends Equatable {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String routeId;
  final double recordedTempC;
  final double thresholdTempC;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final TemperatureExcursionSeverity severity;
  final String? notes;
  final bool isAcknowledged;

  const TemperatureExcursion({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.routeId,
    required this.recordedTempC,
    required this.thresholdTempC,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.severity,
    this.notes,
    this.isAcknowledged = false,
  });

  bool get isActive => endTime == null;

  /// Excursions exceeding 5 minutes (300 seconds) violate pharmaceutical GDP guidelines.
  bool get isThresholdBreached => durationSeconds >= 300;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String get formattedTemp => '${recordedTempC.toStringAsFixed(1)} °C';
  String get formattedThreshold => '${thresholdTempC.toStringAsFixed(1)} °C';

  TemperatureExcursion copyWith({
    String? id,
    String? vehicleId,
    String? vehicleName,
    String? routeId,
    double? recordedTempC,
    double? thresholdTempC,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    TemperatureExcursionSeverity? severity,
    String? notes,
    bool? isAcknowledged,
  }) {
    return TemperatureExcursion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      routeId: routeId ?? this.routeId,
      recordedTempC: recordedTempC ?? this.recordedTempC,
      thresholdTempC: thresholdTempC ?? this.thresholdTempC,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'route_id': routeId,
      'recorded_temp_c': recordedTempC,
      'threshold_temp_c': thresholdTempC,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'severity': severity.code,
      'notes': notes,
      'is_acknowledged': isAcknowledged ? 1 : 0,
    };
  }

  factory TemperatureExcursion.fromMap(Map<String, dynamic> map) {
    return TemperatureExcursion(
      id: map['id'] as String? ?? '',
      vehicleId: map['vehicle_id'] as String? ?? '',
      vehicleName: map['vehicle_name'] as String? ?? '',
      routeId: map['route_id'] as String? ?? '',
      recordedTempC: (map['recorded_temp_c'] as num?)?.toDouble() ?? 0.0,
      thresholdTempC: (map['threshold_temp_c'] as num?)?.toDouble() ?? -15.0,
      startTime:
          DateTime.tryParse(map['start_time'] as String? ?? '') ??
          DateTime.now(),
      endTime: map['end_time'] != null
          ? DateTime.tryParse(map['end_time'] as String)
          : null,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      severity: TemperatureExcursionSeverity.fromCode(
        map['severity'] as String? ?? 'WARNING',
      ),
      notes: map['notes'] as String?,
      isAcknowledged: (map['is_acknowledged'] as int? ?? 0) == 1,
    );
  }

  String toCsvRow() {
    final endStr = endTime?.toIso8601String() ?? 'ACTIVE';
    final notesEscaped = (notes ?? 'N/A').replaceAll('"', '""');
    return '$id,$vehicleId,"$vehicleName",$routeId,$recordedTempC,$thresholdTempC,${startTime.toIso8601String()},$endStr,$durationSeconds,${(durationSeconds / 60).toStringAsFixed(1)},${severity.code},${isActive ? "ACTIVE" : "RESOLVED"},${isAcknowledged ? "YES" : "NO"},"$notesEscaped"';
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    vehicleName,
    routeId,
    recordedTempC,
    thresholdTempC,
    startTime,
    endTime,
    durationSeconds,
    severity,
    notes,
    isAcknowledged,
  ];
}
