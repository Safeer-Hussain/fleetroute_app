import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/fuel_finder_recommendation.dart';
import '../../domain/entities/fuel_station.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/entities/waybill_stop.dart';
import '../../domain/repositories/fuel_station_repository.dart';
import '../models/fuel_station_model.dart';

class FuelStationRepositoryImpl implements FuelStationRepository {
  final AppDatabase appDatabase;

  FuelStationRepositoryImpl({required this.appDatabase});

  @override
  Future<List<FuelStation>> getAllFuelStations() async {
    final db = await appDatabase.database;
    final maps = await db.query('fuel_stations', orderBy: 'diesel_price ASC');
    return maps.map((m) => FuelStationModel.fromMap(m)).toList();
  }

  @override
  Future<FuelFinderRecommendation> findOptimalCorridorFuelStop({
    required RoutePlan route,
    required List<WaybillStop> stops,
    double corridorToleranceKm = 8.0,
    double refuelLiters = 300.0,
  }) async {
    final allStations = await getAllFuelStations();

    // 1. Build ordered waypoints: origin -> stops (ordered by sequence) -> destination
    final sortedStops = List<WaybillStop>.from(stops)
      ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));

    final waypoints = <_Waypoint>[
      _Waypoint(
        lat: route.originLat,
        lng: route.originLng,
        label: route.originName,
        stopId: null,
      ),
      ...sortedStops.map(
        (s) => _Waypoint(
          lat: s.latitude,
          lng: s.longitude,
          label: s.stopName,
          stopId: s.id,
        ),
      ),
      _Waypoint(
        lat: route.destinationLat,
        lng: route.destinationLng,
        label: route.destinationName,
        stopId: null,
      ),
    ];

    // 2. Build route segments with cumulative kilometer markers
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

    // 3. For each station, find distance to corridor and distance along route
    final matchedStations = <FuelStation>[];

    for (final station in allStations) {
      double minCorridorDist = double.infinity;
      double closestAlongRouteKm = 0.0;

      for (final segment in segments) {
        final (dist, alongDist) = _distanceToSegment(
          stationLat: station.latitude,
          stationLng: station.longitude,
          segment: segment,
        );

        if (dist < minCorridorDist) {
          minCorridorDist = dist;
          closestAlongRouteKm = alongDist;
        }
      }

      if (minCorridorDist <= corridorToleranceKm) {
        matchedStations.add(
          station.copyWith(
            distanceToCorridorKm: minCorridorDist,
            distanceAlongRouteKm: closestAlongRouteKm,
          ),
        );
      }
    }

    // 4. Sort corridor stations: lowest diesel price first, then nearest detour
    matchedStations.sort((a, b) {
      final priceComp = a.dieselPricePerLiter.compareTo(b.dieselPricePerLiter);
      if (priceComp != 0) return priceComp;
      return a.distanceToCorridorKm.compareTo(b.distanceToCorridorKm);
    });

    final recommended = matchedStations.isNotEmpty
        ? matchedStations.first
        : null;
    final totalSavings =
        recommended?.calculateEstimatedSavings(refuelLiters) ?? 0.0;
    final detourKm = recommended?.distanceToCorridorKm ?? 0.0;

    return FuelFinderRecommendation(
      routeId: route.id,
      corridorStations: List.unmodifiable(matchedStations),
      recommendedStation: recommended,
      baselineMarketPrice: recommended?.baselineMarketPrice ?? 278.0,
      defaultRefuelLiters: refuelLiters,
      totalEstimatedSavings: totalSavings,
      detourDistanceKm: detourKm,
    );
  }

  @override
  Future<WaybillStop> injectFuelStopWaypoint({
    required String routeId,
    required FuelStation station,
    required double refuelLiters,
  }) async {
    final db = await appDatabase.database;

    // Fetch existing stops for this route
    final existingStopMaps = await db.query(
      'waybill_stops',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'sequence_order ASC',
    );
    final existingStops = existingStopMaps
        .map((m) => WaybillStop.fromMap(m))
        .toList();

    // Determine target sequence order based on distance from origin
    int targetSequence = existingStops.length + 1;

    if (existingStops.isNotEmpty) {
      // Find closest insertion point: insert after the previous stop along route
      // If station has distanceAlongRouteKm, find first stop whose along-route position is ahead
      // Default to inserting in the middle or at next available sequence
      int insertIndex = 1;
      for (int i = 0; i < existingStops.length; i++) {
        final stop = existingStops[i];
        final dist = _calculateDistanceKm(
          station.latitude,
          station.longitude,
          stop.latitude,
          stop.longitude,
        );
        if (dist < 15.0) {
          // If nearby stop i, insert right after it
          insertIndex = stop.sequenceOrder + 1;
          break;
        }
      }
      targetSequence = insertIndex.clamp(1, existingStops.length + 1);
    }

    // Shift existing stops with sequence_order >= targetSequence
    await db.rawUpdate(
      'UPDATE waybill_stops SET sequence_order = sequence_order + 1 WHERE route_id = ? AND sequence_order >= ?',
      [routeId, targetSequence],
    );

    final savings = station.calculateEstimatedSavings(refuelLiters);
    final newStopId = 'WB-FUEL-${DateTime.now().millisecondsSinceEpoch}';

    final newStop = WaybillStop(
      id: newStopId,
      routeId: routeId,
      sequenceOrder: targetSequence,
      stopName: 'Refuel: ${station.name}',
      latitude: station.latitude,
      longitude: station.longitude,
      cargoDescription:
          'Corridor Diesel Bunkering (${station.formattedPrice}, Saved Rs. ${savings.toStringAsFixed(0)})',
      weightKg: 0.0,
      priority: 'SCHEDULED_FREIGHT',
      status: 'PENDING',
    );

    await db.insert(
      'waybill_stops',
      newStop.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return newStop;
  }

  (double dist, double alongDist) _distanceToSegment({
    required double stationLat,
    required double stationLng,
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

    final px = (stationLng - lng1) * cosLat;
    final py = stationLat - lat1;

    final lengthSq = dx * dx + dy * dy;

    double t = 0.0;
    if (lengthSq > 1e-12) {
      t = ((px * dx) + (py * dy)) / lengthSq;
      t = t.clamp(0.0, 1.0);
    }

    final closestLat = lat1 + t * (lat2 - lat1);
    final closestLng = lng1 + t * (lng2 - lng1);

    final dist = _calculateDistanceKm(
      stationLat,
      stationLng,
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
  final String? stopId;

  const _Waypoint({
    required this.lat,
    required this.lng,
    required this.label,
    this.stopId,
  });
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
