import 'package:equatable/equatable.dart';

enum TemperatureExcursionSeverity {
  normal,
  warning,
  critical;

  String get code {
    switch (this) {
      case TemperatureExcursionSeverity.normal:
        return 'NORMAL';
      case TemperatureExcursionSeverity.warning:
        return 'WARNING';
      case TemperatureExcursionSeverity.critical:
        return 'CRITICAL';
    }
  }

  String get displayName {
    switch (this) {
      case TemperatureExcursionSeverity.normal:
        return 'NORMAL (OPTIMAL)';
      case TemperatureExcursionSeverity.warning:
        return 'ELEVATED WARNING';
      case TemperatureExcursionSeverity.critical:
        return 'CRITICAL BREACH';
    }
  }

  static TemperatureExcursionSeverity fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'CRITICAL':
        return TemperatureExcursionSeverity.critical;
      case 'WARNING':
        return TemperatureExcursionSeverity.warning;
      case 'NORMAL':
      default:
        return TemperatureExcursionSeverity.normal;
    }
  }
}

class TemperatureExcursion extends Equatable {
  static const double criticalThresholdCelsius = -15.0;
  static const double warningThresholdCelsius = -18.0;
  static const double standardTargetCelsius = -20.0;
  static const int breachDurationSecondsThreshold = 300; // 5 minutes

  final String id;
  final String vehicleId;
  final String vehicleName;
  final String driverName;
  final String routeId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final double maxRecordedTempC;
  final double targetTempC;
  final double thresholdTempC;
  final TemperatureExcursionSeverity severity;
  final bool isResolved;
  final String? resolutionNotes;
  final String? acknowledgedBy;
  final String complianceStatus;

  const TemperatureExcursion({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.driverName,
    required this.routeId,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.maxRecordedTempC,
    this.targetTempC = standardTargetCelsius,
    this.thresholdTempC = criticalThresholdCelsius,
    required this.severity,
    this.isResolved = false,
    this.resolutionNotes,
    this.acknowledgedBy,
    required this.complianceStatus,
  });

  bool get isAuditableBreach =>
      durationSeconds >= breachDurationSecondsThreshold &&
      maxRecordedTempC > criticalThresholdCelsius;

  bool get isOngoing => endTime == null && !isResolved;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String get formattedPeakTemp =>
      '${maxRecordedTempC >= 0 ? '+' : ''}${maxRecordedTempC.toStringAsFixed(1)}°C';

  String get formattedTargetTemp => '${targetTempC.toStringAsFixed(1)}°C';

  TemperatureExcursion copyWith({
    String? id,
    String? vehicleId,
    String? vehicleName,
    String? driverName,
    String? routeId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    double? maxRecordedTempC,
    double? targetTempC,
    double? thresholdTempC,
    TemperatureExcursionSeverity? severity,
    bool? isResolved,
    String? resolutionNotes,
    String? acknowledgedBy,
    String? complianceStatus,
  }) {
    return TemperatureExcursion(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      driverName: driverName ?? this.driverName,
      routeId: routeId ?? this.routeId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      maxRecordedTempC: maxRecordedTempC ?? this.maxRecordedTempC,
      targetTempC: targetTempC ?? this.targetTempC,
      thresholdTempC: thresholdTempC ?? this.thresholdTempC,
      severity: severity ?? this.severity,
      isResolved: isResolved ?? this.isResolved,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      complianceStatus: complianceStatus ?? this.complianceStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'vehicle_name': vehicleName,
      'driver_name': driverName,
      'route_id': routeId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'max_recorded_temp_c': maxRecordedTempC,
      'target_temp_c': targetTempC,
      'threshold_temp_c': thresholdTempC,
      'severity': severity.code,
      'is_resolved': isResolved ? 1 : 0,
      'resolution_notes': resolutionNotes,
      'acknowledged_by': acknowledgedBy,
      'compliance_status': complianceStatus,
    };
  }

  factory TemperatureExcursion.fromMap(Map<String, dynamic> map) {
    return TemperatureExcursion(
      id: map['id'] as String? ?? '',
      vehicleId: map['vehicle_id'] as String? ?? '',
      vehicleName: map['vehicle_name'] as String? ?? '',
      driverName: map['driver_name'] as String? ?? '',
      routeId: map['route_id'] as String? ?? '',
      startTime: DateTime.parse(
        map['start_time'] as String? ?? DateTime.now().toIso8601String(),
      ),
      endTime: map['end_time'] != null
          ? DateTime.tryParse(map['end_time'] as String)
          : null,
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      maxRecordedTempC:
          (map['max_recorded_temp_c'] as num?)?.toDouble() ?? -20.0,
      targetTempC: (map['target_temp_c'] as num?)?.toDouble() ?? -20.0,
      thresholdTempC: (map['threshold_temp_c'] as num?)?.toDouble() ?? -15.0,
      severity: TemperatureExcursionSeverity.fromCode(
        map['severity'] as String? ?? 'NORMAL',
      ),
      isResolved: (map['is_resolved'] as int? ?? 0) == 1,
      resolutionNotes: map['resolution_notes'] as String?,
      acknowledgedBy: map['acknowledged_by'] as String?,
      complianceStatus:
          map['compliance_status'] as String? ?? 'COMPLIANT_TRANSIENT',
    );
  }

  String toCsvRow() {
    final cleanNotes = (resolutionNotes ?? '').replaceAll(',', ';');
    final cleanAuditor = (acknowledgedBy ?? 'UNACKNOWLEDGED').replaceAll(
      ',',
      ' ',
    );
    final endStr = endTime?.toIso8601String() ?? 'ONGOING';
    return '$id,$vehicleId,$vehicleName,$driverName,$routeId,${startTime.toIso8601String()},$endStr,$durationSeconds,$maxRecordedTempC,$targetTempC,$thresholdTempC,${severity.code},$isResolved,$complianceStatus,"$cleanAuditor","$cleanNotes"';
  }

  static String generateAuditCsv(List<TemperatureExcursion> excursions) {
    final buffer = StringBuffer();
    buffer.writeln(
      'excursion_id,vehicle_id,vehicle_name,driver_name,route_id,start_time,end_time,duration_seconds,max_temp_c,target_temp_c,threshold_temp_c,severity,is_resolved,compliance_status,acknowledged_by,resolution_notes',
    );
    for (final exc in excursions) {
      buffer.writeln(exc.toCsvRow());
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    vehicleName,
    driverName,
    routeId,
    startTime,
    endTime,
    durationSeconds,
    maxRecordedTempC,
    targetTempC,
    thresholdTempC,
    severity,
    isResolved,
    resolutionNotes,
    acknowledgedBy,
    complianceStatus,
  ];
}
