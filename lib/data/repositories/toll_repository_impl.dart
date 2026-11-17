import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/entities/toll_barrier.dart';
import '../../domain/entities/toll_estimate.dart';
import '../../domain/entities/waybill_stop.dart';
import '../../domain/repositories/toll_repository.dart';
import '../models/toll_barrier_model.dart';
import '../models/toll_estimate_model.dart';

class TollRepositoryImpl implements TollRepository {
  final AppDatabase database;
  final double corridorToleranceKm;

  TollRepositoryImpl({required this.database, this.corridorToleranceKm = 8.0});

  @override
  Future<List<TollBarrier>> getAllTollBarriers() async {
    final db = await database.database;
    final maps = await db.query('toll_barriers');
    return maps.map((m) => TollBarrierModel.fromMap(m)).toList();
  }

  @override
  Future<RouteTollEstimate> estimateRouteToll({
    required RoutePlan route,
    required List<WaybillStop> stops,
    required VehicleAxleTier axleTier,
    bool useElectronicTag = true,
  }) async {
    final allBarriers = await getAllTollBarriers();

    // 1. Build ordered waypoints: origin -> sorted stops -> destination
    final waypoints = <_Waypoint>[];
    waypoints.add(
      _Waypoint(
        lat: route.originLat,
        lng: route.originLng,
        label: route.originName,
      ),
    );

    final sortedStops = List<WaybillStop>.from(stops)
      ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    for (final stop in sortedStops) {
      waypoints.add(
        _Waypoint(
          lat: stop.latitude,
          lng: stop.longitude,
          label: stop.stopName,
        ),
      );
    }

    waypoints.add(
      _Waypoint(
        lat: route.destinationLat,
        lng: route.destinationLng,
        label: route.destinationName,
      ),
    );

    // 2. Build segments with cumulative distances
    final segments = <_RouteSegment>[];
    double cumulativeKm = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final segDist = _calculateDistanceKm(
        start.lat,
        start.lng,
        end.lat,
        end.lng,
      );
      segments.add(
        _RouteSegment(
          start: start,
          end: end,
          startDistKm: cumulativeKm,
          lengthKm: segDist,
        ),
      );
      cumulativeKm += segDist;
    }

    // 3. For each barrier, find minimum distance to any segment
    final crossings = <TollBarrierCrossing>[];

    for (final barrier in allBarriers) {
      double minBarrierDist = double.infinity;
      double closestAlongRouteKm = 0.0;

      for (final segment in segments) {
        final (dist, alongDist) = _distanceToSegment(
          barrierLat: barrier.latitude,
          barrierLng: barrier.longitude,
          segment: segment,
        );

        if (dist < minBarrierDist) {
          minBarrierDist = dist;
          closestAlongRouteKm = alongDist;
        }
      }

      if (minBarrierDist <= corridorToleranceKm) {
        final baseFee = barrier.getFeeForAxle(axleTier);
        final customsFee = barrier.barrierType == TollBarrierType.borderCustoms
            ? barrier.customsClearanceFee
            : 0.0;
        final discount = (useElectronicTag && barrier.acceptsElectronicToll)
            ? (baseFee * 0.05)
            : 0.0;
        final netFee = (baseFee - discount) + customsFee;

        crossings.add(
          TollBarrierCrossing(
            barrier: barrier,
            axleTier: axleTier,
            baseTollFee: baseFee,
            customsFee: customsFee,
            electronicDiscount: discount,
            netFee: netFee,
            distanceFromOriginKm: closestAlongRouteKm,
          ),
        );
      }
    }

    // 4. Sort crossings sequentially along the corridor
    crossings.sort(
      (a, b) => a.distanceFromOriginKm.compareTo(b.distanceFromOriginKm),
    );

    double totalToll = 0.0;
    double totalCustoms = 0.0;
    double totalDiscounts = 0.0;
    double netTotal = 0.0;

    for (final c in crossings) {
      totalToll += c.baseTollFee;
      totalCustoms += c.customsFee;
      totalDiscounts += c.electronicDiscount;
      netTotal += c.netFee;
    }

    final estimate = RouteTollEstimate(
      routeId: route.id,
      axleTier: axleTier,
      crossings: crossings,
      totalTollFees: totalToll,
      totalCustomsFees: totalCustoms,
      totalElectronicDiscounts: totalDiscounts,
      netTotalFee: netTotal,
      electronicTagUsed: useElectronicTag,
    );

    await saveRouteTollEstimate(estimate);
    return estimate;
  }

  @override
  Future<void> saveRouteTollEstimate(RouteTollEstimate estimate) async {
    final db = await database.database;
    await db.insert(
      'route_toll_estimates',
      estimate.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<RouteTollEstimate?> getSavedRouteTollEstimate(String routeId) async {
    final db = await database.database;
    final maps = await db.query(
      'route_toll_estimates',
      where: 'route_id = ?',
      whereArgs: [routeId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return RouteTollEstimateModel.fromMap(maps.first);
    }
    return null;
  }

  (double dist, double alongDist) _distanceToSegment({
    required double barrierLat,
    required double barrierLng,
    required _RouteSegment segment,
  }) {
    final lat1 = segment.start.lat;
    final lng1 = segment.start.lng;
    final lat2 = segment.end.lat;
    final lng2 = segment.end.lng;

    const degToRad = 0.017453292519943295;
    final cosLat = math.cos(lat1 * degToRad);

    final dx = (lng2 - lng1) * cosLat;
    final dy = lat2 - lat1;

    final px = (barrierLng - lng1) * cosLat;
    final py = barrierLat - lat1;

    final lengthSq = dx * dx + dy * dy;

    double t = 0.0;
    if (lengthSq > 1e-12) {
      t = ((px * dx) + (py * dy)) / lengthSq;
      t = t.clamp(0.0, 1.0);
    }

    final closestLat = lat1 + t * (lat2 - lat1);
    final closestLng = lng1 + t * (lng2 - lng1);

    final dist = _calculateDistanceKm(
      barrierLat,
      barrierLng,
      closestLat,
      closestLng,
    );
    final alongDist = segment.startDistKm + (t * segment.lengthKm);

    return (dist, alongDist);
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}

class _Waypoint {
  final double lat;
  final double lng;
  final String label;

  const _Waypoint({required this.lat, required this.lng, required this.label});
}

class _RouteSegment {
  final _Waypoint start;
  final _Waypoint end;
  final double startDistKm;
  final double lengthKm;

  const _RouteSegment({
    required this.start,
    required this.end,
    required this.startDistKm,
    required this.lengthKm,
  });
}
