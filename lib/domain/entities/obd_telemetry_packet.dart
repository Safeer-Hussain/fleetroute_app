import 'package:equatable/equatable.dart';

class ObdTelemetryPacket extends Equatable {
  final String vehicleId;
  final int engineRpm;
  final double speedKmh;
  final double coolantTempC;
  final double fuelLevelPercent;
  final double batterySocPercent;
  final double tirePressureFl;
  final double tirePressureFr;
  final double tirePressureRl;
  final double tirePressureRr;
  final double cargoTempC;
  final String dtcStatus;
  final int timestamp;

  const ObdTelemetryPacket({
    required this.vehicleId,
    required this.engineRpm,
    required this.speedKmh,
    required this.coolantTempC,
    required this.fuelLevelPercent,
    required this.batterySocPercent,
    required this.tirePressureFl,
    required this.tirePressureFr,
    required this.tirePressureRl,
    required this.tirePressureRr,
    required this.cargoTempC,
    required this.dtcStatus,
    required this.timestamp,
  });

  factory ObdTelemetryPacket.fromMap(Map<String, dynamic> map) {
    return ObdTelemetryPacket(
      vehicleId: map['vehicleId'] as String? ?? 'VH-101',
      engineRpm: (map['engineRpm'] as num?)?.toInt() ?? 0,
      speedKmh: (map['speedKmh'] as num?)?.toDouble() ?? 0.0,
      coolantTempC: (map['coolantTempC'] as num?)?.toDouble() ?? 0.0,
      fuelLevelPercent: (map['fuelLevelPercent'] as num?)?.toDouble() ?? 0.0,
      batterySocPercent: (map['batterySocPercent'] as num?)?.toDouble() ?? 0.0,
      tirePressureFl: (map['tirePressureFl'] as num?)?.toDouble() ?? 34.0,
      tirePressureFr: (map['tirePressureFr'] as num?)?.toDouble() ?? 34.0,
      tirePressureRl: (map['tirePressureRl'] as num?)?.toDouble() ?? 35.0,
      tirePressureRr: (map['tirePressureRr'] as num?)?.toDouble() ?? 35.0,
      cargoTempC: (map['cargoTempC'] as num?)?.toDouble() ?? 0.0,
      dtcStatus: map['dtcStatus'] as String? ?? 'NORMAL',
      timestamp:
          (map['timestamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'engineRpm': engineRpm,
      'speedKmh': speedKmh,
      'coolantTempC': coolantTempC,
      'fuelLevelPercent': fuelLevelPercent,
      'batterySocPercent': batterySocPercent,
      'tirePressureFl': tirePressureFl,
      'tirePressureFr': tirePressureFr,
      'tirePressureRl': tirePressureRl,
      'tirePressureRr': tirePressureRr,
      'cargoTempC': cargoTempC,
      'dtcStatus': dtcStatus,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props => [
    vehicleId,
    engineRpm,
    speedKmh,
    coolantTempC,
    fuelLevelPercent,
    batterySocPercent,
    tirePressureFl,
    tirePressureFr,
    tirePressureRl,
    tirePressureRr,
    cargoTempC,
    dtcStatus,
    timestamp,
  ];
}
