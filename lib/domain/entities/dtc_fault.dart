import 'package:equatable/equatable.dart';

class DtcFault extends Equatable {
  final String id;
  final String vehicleId;
  final String code;
  final String title;
  final String severity; // CRITICAL, WARNING, INFO
  final String system;
  final String status; // ACTIVE, CLEARED, SERVICE_SCHEDULED
  final String loggedAt;

  const DtcFault({
    required this.id,
    required this.vehicleId,
    required this.code,
    required this.title,
    required this.severity,
    required this.system,
    required this.status,
    required this.loggedAt,
  });

  DtcFault copyWith({
    String? id,
    String? vehicleId,
    String? code,
    String? title,
    String? severity,
    String? system,
    String? status,
    String? loggedAt,
  }) {
    return DtcFault(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      code: code ?? this.code,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      system: system ?? this.system,
      status: status ?? this.status,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  factory DtcFault.fromMap(Map<String, dynamic> map) {
    return DtcFault(
      id: map['id'] as String? ?? '',
      vehicleId:
          map['vehicle_id'] as String? ?? (map['vehicleId'] as String? ?? ''),
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? '',
      severity: map['severity'] as String? ?? 'INFO',
      system: map['system'] as String? ?? '',
      status: map['status'] as String? ?? 'ACTIVE',
      loggedAt:
          map['logged_at'] as String? ?? (map['loggedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'code': code,
      'title': title,
      'severity': severity,
      'system': system,
      'status': status,
      'logged_at': loggedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    code,
    title,
    severity,
    system,
    status,
    loggedAt,
  ];
}
