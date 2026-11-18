import 'dart:math' as math;

import '../../core/database/app_database.dart';
import '../../domain/entities/temperature_excursion.dart';
import '../../domain/repositories/cold_chain_repository.dart';
import '../models/temperature_excursion_model.dart';

class ColdChainRepositoryImpl implements ColdChainRepository {
  final AppDatabase database;
  static const double excursionThresholdTempC = -15.0;

  ColdChainRepositoryImpl({required this.database});

  @override
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool onlyActive = false,
  }) async {
    final db = await database.database;
    String whereClause = '';
    final whereArgs = <dynamic>[];

    if (vehicleId != null && onlyActive) {
      whereClause = 'vehicle_id = ? AND end_time IS NULL';
      whereArgs.addAll([vehicleId]);
    } else if (vehicleId != null) {
      whereClause = 'vehicle_id = ?';
      whereArgs.add(vehicleId);
    } else if (onlyActive) {
      whereClause = 'end_time IS NULL';
    }

    final maps = await db.query(
      'temperature_excursions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_time DESC',
    );

    return maps.map((m) => TemperatureExcursionModel.fromMap(m)).toList();
  }

  @override
  Future<void> recordTemperatureReading({
    required String vehicleId,
    required String vehicleName,
    required String routeId,
    required double tempC,
    required DateTime timestamp,
  }) async {
    final db = await database.database;

    // Check for an currently active excursion for this vehicle
    final activeMaps = await db.query(
      'temperature_excursions',
      where: 'vehicle_id = ? AND end_time IS NULL',
      whereArgs: [vehicleId],
      limit: 1,
    );

    if (tempC > excursionThresholdTempC) {
      // Temperature is in excursion breach territory
      if (activeMaps.isNotEmpty) {
        final existing = TemperatureExcursionModel.fromMap(activeMaps.first);
        final elapsed = timestamp.difference(existing.startTime).inSeconds;
        final maxTemp = math.max(existing.recordedTempC, tempC);
        final severity = TemperatureExcursionSeverity.fromTemperature(maxTemp);

        await db.update(
          'temperature_excursions',
          {
            'recorded_temp_c': maxTemp,
            'duration_seconds': math.max(existing.durationSeconds, elapsed),
            'severity': severity.code,
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      } else {
        // Start a brand new excursion
        final newId = 'EXC-${DateTime.now().millisecondsSinceEpoch}';
        final severity = TemperatureExcursionSeverity.fromTemperature(tempC);

        final newExcursion = TemperatureExcursion(
          id: newId,
          vehicleId: vehicleId,
          vehicleName: vehicleName,
          routeId: routeId,
          recordedTempC: tempC,
          thresholdTempC: excursionThresholdTempC,
          startTime: timestamp,
          endTime: null,
          durationSeconds: 0,
          severity: severity,
          isAcknowledged: false,
        );

        await db.insert('temperature_excursions', newExcursion.toMap());
      }
    } else {
      // Temperature returned to nominal (<= -15.0°C)
      if (activeMaps.isNotEmpty) {
        final existing = TemperatureExcursionModel.fromMap(activeMaps.first);
        final elapsed = timestamp.difference(existing.startTime).inSeconds;
        final duration = math.max(existing.durationSeconds, elapsed);

        await db.update(
          'temperature_excursions',
          {
            'end_time': timestamp.toIso8601String(),
            'duration_seconds': duration,
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
      }
    }
  }

  @override
  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorNotes,
  }) async {
    final db = await database.database;
    await db.update(
      'temperature_excursions',
      {'is_acknowledged': 1, 'notes': auditorNotes},
      where: 'id = ?',
      whereArgs: [excursionId],
    );
  }

  @override
  Future<String> exportAuditCsv({String? vehicleId}) async {
    final excursions = await getExcursions(vehicleId: vehicleId);
    final buffer = StringBuffer();
    buffer.writeln(
      'Excursion ID,Vehicle ID,Vehicle Name,Route ID,Peak Temp (°C),Threshold (°C),Start Time,End Time,Duration (s),Duration (min),Severity,Status,Acknowledged,Auditor Notes',
    );

    for (final exc in excursions) {
      buffer.writeln(exc.toCsvRow());
    }

    return buffer.toString();
  }

  @override
  Future<Map<String, dynamic>> getColdChainAuditMetrics() async {
    final all = await getExcursions();
    final active = all.where((e) => e.isActive).toList();
    final breached = all.where((e) => e.isThresholdBreached).toList();
    final acknowledged = all.where((e) => e.isAcknowledged).toList();

    int totalDurationSeconds = 0;
    for (final e in all) {
      totalDurationSeconds += e.durationSeconds;
    }

    final complianceScore = all.isEmpty
        ? 100.0
        : (((all.length - breached.length) / all.length) * 100).clamp(
            0.0,
            100.0,
          );

    return {
      'total_excursions': all.length,
      'active_excursions': active.length,
      'breached_excursions': breached.length,
      'acknowledged_excursions': acknowledged.length,
      'total_excursion_seconds': totalDurationSeconds,
      'compliance_score': complianceScore,
    };
  }
}
