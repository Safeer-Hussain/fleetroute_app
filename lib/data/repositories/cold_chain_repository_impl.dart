import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/temperature_excursion.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/cold_chain_repository.dart';
import '../models/temperature_excursion_model.dart';

class ColdChainRepositoryImpl implements ColdChainRepository {
  final AppDatabase database;
  final StreamController<List<TemperatureExcursion>> _streamController =
      StreamController<List<TemperatureExcursion>>.broadcast();

  final Map<String, TemperatureExcursion> _activeExcursions = {};

  ColdChainRepositoryImpl({required this.database});

  @override
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool breachesOnly = false,
  }) async {
    final db = await database.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (vehicleId != null && breachesOnly) {
      whereClause = 'vehicle_id = ? AND duration_seconds >= ? AND max_recorded_temp_c > ?';
      whereArgs = [
        vehicleId,
        TemperatureExcursion.breachDurationSecondsThreshold,
        TemperatureExcursion.criticalThresholdCelsius,
      ];
    } else if (vehicleId != null) {
      whereClause = 'vehicle_id = ?';
      whereArgs = [vehicleId];
    } else if (breachesOnly) {
      whereClause = 'duration_seconds >= ? AND max_recorded_temp_c > ?';
      whereArgs = [
        TemperatureExcursion.breachDurationSecondsThreshold,
        TemperatureExcursion.criticalThresholdCelsius,
      ];
    }

    final maps = await db.query(
      'temperature_excursions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'start_time DESC',
    );

    final list = maps.map((m) => TemperatureExcursionModel.fromMap(m)).toList();
    _streamController.add(list);
    return list;
  }

  @override
  Future<void> logExcursion(TemperatureExcursion excursion) async {
    final db = await database.database;
    await db.insert(
      'temperature_excursions',
      excursion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _refreshStream();
  }

  @override
  Future<void> updateExcursion(TemperatureExcursion excursion) async {
    final db = await database.database;
    await db.update(
      'temperature_excursions',
      excursion.toMap(),
      where: 'id = ?',
      whereArgs: [excursion.id],
    );
    await _refreshStream();
  }

  @override
  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorName,
    required String notes,
  }) async {
    final db = await database.database;
    await db.update(
      'temperature_excursions',
      {
        'acknowledged_by': auditorName,
        'resolution_notes': notes,
        'is_resolved': 1,
      },
      where: 'id = ?',
      whereArgs: [excursionId],
    );
    await _refreshStream();
  }

  @override
  Future<String> exportAuditCsv({String? vehicleId}) async {
    final excursions = await getExcursions(vehicleId: vehicleId);
    return TemperatureExcursion.generateAuditCsv(excursions);
  }

  @override
  Stream<List<TemperatureExcursion>> watchExcursions() {
    // Trigger initial emission asynchronously
    getExcursions();
    return _streamController.stream;
  }

  @override
  Future<TemperatureExcursion?> recordTelemetryTick({
    required Vehicle vehicle,
    required double currentTempC,
    required DateTime timestamp,
  }) async {
    final isCritical =
        currentTempC > TemperatureExcursion.criticalThresholdCelsius;
    final isWarning =
        currentTempC > TemperatureExcursion.warningThresholdCelsius;

    if (isCritical || isWarning) {
      final active = _activeExcursions[vehicle.id];
      if (active == null) {
        // Start new excursion
        final newExcursion = TemperatureExcursion(
          id: 'EXC-${DateTime.now().millisecondsSinceEpoch}',
          vehicleId: vehicle.id,
          vehicleName: vehicle.name,
          driverName: vehicle.driverName,
          routeId: vehicle.assignedRouteId,
          startTime: timestamp,
          endTime: null,
          durationSeconds: 0,
          maxRecordedTempC: currentTempC,
          targetTempC: vehicle.targetTempC,
          thresholdTempC: TemperatureExcursion.criticalThresholdCelsius,
          severity: isCritical
              ? TemperatureExcursionSeverity.critical
              : TemperatureExcursionSeverity.warning,
          isResolved: false,
          complianceStatus: 'COMPLIANT_TRANSIENT',
        );

        _activeExcursions[vehicle.id] = newExcursion;
        await logExcursion(newExcursion);
        return newExcursion;
      } else {
        // Increment and track
        final duration = timestamp.difference(active.startTime).inSeconds;
        final maxTemp = currentTempC > active.maxRecordedTempC
            ? currentTempC
            : active.maxRecordedTempC;

        final isBreach =
            duration >= TemperatureExcursion.breachDurationSecondsThreshold &&
            maxTemp > TemperatureExcursion.criticalThresholdCelsius;

        final updated = active.copyWith(
          durationSeconds: duration,
          maxRecordedTempC: maxTemp,
          severity: isCritical
              ? TemperatureExcursionSeverity.critical
              : TemperatureExcursionSeverity.warning,
          complianceStatus: isBreach
              ? 'EXCURSION_VIOLATION'
              : 'COMPLIANT_TRANSIENT',
        );

        _activeExcursions[vehicle.id] = updated;
        await updateExcursion(updated);
        return updated;
      }
    } else {
      // Temperature returned to safe range
      final active = _activeExcursions.remove(vehicle.id);
      if (active != null) {
        final duration = timestamp.difference(active.startTime).inSeconds;
        final isBreach =
            duration >= TemperatureExcursion.breachDurationSecondsThreshold &&
            active.maxRecordedTempC >
                TemperatureExcursion.criticalThresholdCelsius;

        final resolved = active.copyWith(
          endTime: timestamp,
          durationSeconds: duration,
          isResolved: true,
          resolutionNotes:
              'Cargo reefer temperature normalized to ${currentTempC.toStringAsFixed(1)}°C.',
          complianceStatus: isBreach
              ? 'EXCURSION_VIOLATION'
              : 'COMPLIANT_TRANSIENT',
        );

        await updateExcursion(resolved);
        return resolved;
      }
      return null;
    }
  }

  Future<void> _refreshStream() async {
    final db = await database.database;
    final maps = await db.query(
      'temperature_excursions',
      orderBy: 'start_time DESC',
    );
    final list = maps.map((m) => TemperatureExcursionModel.fromMap(m)).toList();
    _streamController.add(list);
  }

  void dispose() {
    _streamController.close();
  }
}
