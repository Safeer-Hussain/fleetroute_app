import 'dart:async';
import 'dart:math' as math;

import '../../core/database/app_database.dart';
import '../../domain/entities/driver_hos_log.dart';
import '../../domain/entities/rest_stop.dart';
import '../../domain/repositories/hos_repository.dart';
import '../models/driver_hos_model.dart';
import '../models/rest_stop_model.dart';

class HosRepositoryImpl implements HosRepository {
  final AppDatabase database;
  final StreamController<DriverHosLog> _hosStreamController =
      StreamController<DriverHosLog>.broadcast();

  HosRepositoryImpl({required this.database});

  @override
  Future<DriverHosLog> getDriverHosLog(String driverId) async {
    final db = await database.database;
    final maps = await db.query(
      'driver_hos_records',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DriverHosModel.fromMap(maps.first);
    }

    // Fallback: load first record if specific ID not found
    final all = await db.query('driver_hos_records', limit: 1);
    if (all.isNotEmpty) {
      return DriverHosModel.fromMap(all.first);
    }

    // Default emergency record
    return DriverHosLog(
      driverId: driverId,
      driverName: 'Assigned Driver',
      vehicleId: 'VH-101',
      currentStatus: HosDutyStatus.driving,
      drivingSecondsToday: 24300,
      onDutySecondsToday: 27000,
      secondsUntilBreakRequired: 4500,
      breakDurationSeconds: 0,
      lastStatusChange: DateTime.now(),
    );
  }

  @override
  Future<void> updateDutyStatus(
    String driverId,
    HosDutyStatus newStatus,
  ) async {
    final current = await getDriverHosLog(driverId);
    final now = DateTime.now();

    final updated = current.copyWith(
      currentStatus: newStatus,
      lastStatusChange: now,
    );

    final db = await database.database;
    await db.update(
      'driver_hos_records',
      {
        'current_status': newStatus.code,
        'last_status_change': now.toIso8601String(),
      },
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );

    _hosStreamController.add(updated);
  }

  @override
  Future<void> logDrivingSecondsTick(String driverId, int deltaSeconds) async {
    final current = await getDriverHosLog(driverId);
    int newDrivingSeconds = current.drivingSecondsToday;
    int newOnDutySeconds = current.onDutySecondsToday;
    int newBreakCountdown = current.secondsUntilBreakRequired;
    int newBreakDuration = current.breakDurationSeconds;

    switch (current.currentStatus) {
      case HosDutyStatus.driving:
        newDrivingSeconds += deltaSeconds;
        newOnDutySeconds += deltaSeconds;
        newBreakCountdown = math.max(0, newBreakCountdown - deltaSeconds);
        break;
      case HosDutyStatus.onDuty:
        newOnDutySeconds += deltaSeconds;
        break;
      case HosDutyStatus.sleeperBerth:
      case HosDutyStatus.offDuty:
        newBreakDuration += deltaSeconds;
        // If 30 consecutive minutes of rest achieved, reset break countdown
        if (newBreakDuration >= DriverHosLog.mandatoryBreakSeconds) {
          newBreakCountdown = DriverHosLog.maxConsecutiveSecondsBeforeBreak;
        }
        break;
    }

    final updated = current.copyWith(
      drivingSecondsToday: newDrivingSeconds,
      onDutySecondsToday: newOnDutySeconds,
      secondsUntilBreakRequired: newBreakCountdown,
      breakDurationSeconds: newBreakDuration,
    );

    final db = await database.database;
    await db.update(
      'driver_hos_records',
      {
        'driving_seconds': newDrivingSeconds,
        'on_duty_seconds': newOnDutySeconds,
        'seconds_until_break': newBreakCountdown,
        'break_duration_seconds': newBreakDuration,
      },
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );

    _hosStreamController.add(updated);
  }

  @override
  Future<void> resetBreakTimer(String driverId) async {
    final current = await getDriverHosLog(driverId);
    final updated = current.copyWith(
      secondsUntilBreakRequired: DriverHosLog.maxConsecutiveSecondsBeforeBreak,
      breakDurationSeconds: 0,
      currentStatus: HosDutyStatus.offDuty,
      lastStatusChange: DateTime.now(),
    );

    final db = await database.database;
    await db.update(
      'driver_hos_records',
      {
        'seconds_until_break': DriverHosLog.maxConsecutiveSecondsBeforeBreak,
        'break_duration_seconds': 0,
        'current_status': HosDutyStatus.offDuty.code,
        'last_status_change': DateTime.now().toIso8601String(),
      },
      where: 'driver_id = ?',
      whereArgs: [driverId],
    );

    _hosStreamController.add(updated);
  }

  @override
  Future<List<RestStop>> getNearestRestStops({
    required double currentLat,
    required double currentLng,
  }) async {
    final db = await database.database;
    final maps = await db.query('rest_stops');

    final stops = maps.map((m) {
      final lat = (m['latitude'] as num).toDouble();
      final lng = (m['longitude'] as num).toDouble();
      final dist = _calculateDistanceKm(currentLat, currentLng, lat, lng);
      return RestStopModel.fromMap(m, distanceKm: dist);
    }).toList();

    stops.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return stops;
  }

  @override
  Stream<DriverHosLog> watchDriverHosLog(String driverId) {
    return _hosStreamController.stream.where((log) => log.driverId == driverId);
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  void dispose() {
    _hosStreamController.close();
  }
}
