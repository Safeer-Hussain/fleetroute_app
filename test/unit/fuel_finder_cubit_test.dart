import 'package:flutter_test/flutter_test.dart';
import 'package:fleetroute_app/domain/entities/fuel_finder_recommendation.dart';
import 'package:fleetroute_app/domain/entities/fuel_station.dart';
import 'package:fleetroute_app/domain/entities/route_plan.dart';
import 'package:fleetroute_app/domain/entities/waybill_stop.dart';
import 'package:fleetroute_app/domain/repositories/fuel_station_repository.dart';
import 'package:fleetroute_app/presentation/fuel_finder/cubit/fuel_finder_cubit.dart';
import 'package:fleetroute_app/presentation/fuel_finder/cubit/fuel_finder_state.dart';

class MockFuelStationRepository implements FuelStationRepository {
  List<FuelStation> stations = [
    const FuelStation(
      id: 'FS-001',
      name: 'Taj Gasoline Highway Express Depot',
      highway: 'Multan Road Km 28',
      latitude: 31.3650,
      longitude: 74.2180,
      brand: 'Taj Gasoline',
      dieselPricePerLiter: 261.20,
      baselineMarketPrice: 278.00,
      amenities: ['HIGH_SPEED_PUMPS', 'TRUCK_PARKING', 'DRIVER_LOUNGE'],
      hasDedicatedTruckBays: true,
      distanceToCorridorKm: 1.2,
      distanceAlongRouteKm: 18.5,
    ),
    const FuelStation(
      id: 'FS-002',
      name: 'PSO Platinum Commercial Fleet Stop',
      highway: 'M-2 Motorway Km 22',
      latitude: 31.5450,
      longitude: 74.2250,
      brand: 'PSO',
      dieselPricePerLiter: 264.50,
      baselineMarketPrice: 278.00,
      amenities: ['HIGH_SPEED_PUMPS', 'TRUCK_PARKING'],
      hasDedicatedTruckBays: true,
      distanceToCorridorKm: 4.8,
      distanceAlongRouteKm: 28.0,
    ),
    const FuelStation(
      id: 'FS-003',
      name: 'Far Detour Fuel Station',
      highway: 'Remote Bypass Km 80',
      latitude: 31.9000,
      longitude: 74.9000,
      brand: 'Local Oil',
      dieselPricePerLiter: 255.00,
      baselineMarketPrice: 278.00,
      amenities: ['TRUCK_PARKING'],
      hasDedicatedTruckBays: false,
      distanceToCorridorKm: 25.0,
      distanceAlongRouteKm: 85.0,
    ),
  ];

  bool shouldThrow = false;
  WaybillStop? lastInjectedStop;

  @override
  Future<List<FuelStation>> getAllFuelStations() async {
    if (shouldThrow) throw Exception('Database failure');
    return stations;
  }

  @override
  Future<FuelFinderRecommendation> findOptimalCorridorFuelStop({
    required RoutePlan route,
    required List<WaybillStop> stops,
    double corridorToleranceKm = 8.0,
    double refuelLiters = 300.0,
  }) async {
    if (shouldThrow) throw Exception('Corridor search failure');

    final matched = stations
        .where((s) => s.distanceToCorridorKm <= corridorToleranceKm)
        .toList();
    matched.sort(
      (a, b) => a.dieselPricePerLiter.compareTo(b.dieselPricePerLiter),
    );

    final best = matched.isNotEmpty ? matched.first : null;
    final totalSavings = best?.calculateEstimatedSavings(refuelLiters) ?? 0.0;

    return FuelFinderRecommendation(
      routeId: route.id,
      corridorStations: matched,
      recommendedStation: best,
      baselineMarketPrice: 278.00,
      defaultRefuelLiters: refuelLiters,
      totalEstimatedSavings: totalSavings,
      detourDistanceKm: best?.distanceToCorridorKm ?? 0.0,
    );
  }

  @override
  Future<WaybillStop> injectFuelStopWaypoint({
    required String routeId,
    required FuelStation station,
    required double refuelLiters,
  }) async {
    if (shouldThrow) throw Exception('Waypoint injection failure');

    final savings = station.calculateEstimatedSavings(refuelLiters);
    final stop = WaybillStop(
      id: 'WB-FUEL-TEST',
      routeId: routeId,
      sequenceOrder: 2,
      stopName: 'Refuel: ${station.name}',
      latitude: station.latitude,
      longitude: station.longitude,
      cargoDescription:
          'Corridor Diesel Bunkering (${station.formattedPrice}, Saved Rs. ${savings.toStringAsFixed(0)})',
      weightKg: 0.0,
      priority: 'SCHEDULED_FREIGHT',
      status: 'PENDING',
    );

    lastInjectedStop = stop;
    return stop;
  }
}

void main() {
  group('FuelFinderCubit & FuelStation Lowest-Price Route Finder Unit Tests', () {
    late MockFuelStationRepository mockRepo;
    late FuelFinderCubit cubit;

    final testRoute = const RoutePlan(
      id: 'RT-201',
      name: 'Lahore Freight Trunk Corridor Alpha',
      vehicleId: 'VH-101',
      originName: 'Thokar Logistics Depot',
      originLat: 31.4700,
      originLng: 74.2720,
      destinationName: 'Sundar Freight Terminal',
      destinationLat: 31.2820,
      destinationLng: 74.1750,
      totalDistanceKm: 48.6,
      optimizedDistanceKm: 39.2,
      fuelSavedLiters: 3.8,
      minutesSaved: 24,
      isOptimized: true,
      status: 'ACTIVE',
    );

    final testStops = [
      const WaybillStop(
        id: 'WB-7001',
        routeId: 'RT-201',
        sequenceOrder: 1,
        stopName: 'Multan Road Logistics Depot',
        latitude: 31.4700,
        longitude: 74.2720,
        cargoDescription: 'Pallet Freight',
        weightKg: 4200.0,
        priority: 'SCHEDULED_FREIGHT',
        status: 'DELIVERED',
      ),
      const WaybillStop(
        id: 'WB-7002',
        routeId: 'RT-201',
        sequenceOrder: 2,
        stopName: 'Sundar Industrial Estate',
        latitude: 31.2820,
        longitude: 74.1750,
        cargoDescription: 'Heavy Machinery',
        weightKg: 3100.0,
        priority: 'SCHEDULED_FREIGHT',
        status: 'PENDING',
      ),
    ];

    setUp(() {
      mockRepo = MockFuelStationRepository();
      cubit = FuelFinderCubit(fuelStationRepository: mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is clean with default parameters', () {
      expect(cubit.state.status, FuelFinderStatus.initial);
      expect(cubit.state.refuelLiters, 300.0);
      expect(cubit.state.corridorToleranceKm, 8.0);
      expect(cubit.state.recommendation, isNull);
    });

    test('calculateRecommendation filters by corridor tolerance and picks lowest price', () async {
      await cubit.calculateRecommendation(route: testRoute, stops: testStops);

      expect(cubit.state.status, FuelFinderStatus.loaded);
      final rec = cubit.state.recommendation;
      expect(rec, isNotNull);
      // FS-003 is 25 km away, so tolerance 8 km filters it out
      expect(rec!.corridorStations.length, 2);
      expect(rec.recommendedStation?.id, 'FS-001');
      expect(
        rec.recommendedStation?.name,
        'Taj Gasoline Highway Express Depot',
      );
      expect(rec.recommendedStation?.dieselPricePerLiter, 261.20);
    });

    test('Price delta calculation matches regional baseline', () {
      final station = mockRepo.stations.first;
      expect(station.baselineMarketPrice, 278.00);
      expect(station.dieselPricePerLiter, 261.20);

      // Delta: 278.00 - 261.20 = 16.80
      final expectedDelta = 278.00 - 261.20;
      expect(station.priceSavingsPerLiter, closeTo(expectedDelta, 0.001));
      expect(station.formattedPrice, 'Rs. 261.20/L');
      expect(station.formattedSavings, 'Rs. 16.80/L savings');
    });

    test(
      'Bunkering volume calculation accurately scales total cost savings',
      () async {
        await cubit.calculateRecommendation(
          route: testRoute,
          stops: testStops,
          customLiters: 300.0,
        );

        final rec = cubit.state.recommendation!;
        // 16.80 * 300.0 = Rs. 5,040 savings
        expect(rec.totalEstimatedSavings, closeTo(5040.0, 0.1));

        // Update volume to 500 Liters
        cubit.updateRefuelLiters(
          liters: 500.0,
          route: testRoute,
          stops: testStops,
        );
        // Wait for async update
        await Future.delayed(const Duration(milliseconds: 50));

        final updatedRec = cubit.state.recommendation!;
        // 16.80 * 500.0 = Rs. 8,400 savings
        expect(updatedRec.totalEstimatedSavings, closeTo(8400.0, 0.1));
      },
    );

    test(
      'updateCorridorTolerance dynamically restricts corridor matching',
      () async {
        // 2.0 km tolerance will only match FS-001 (detour 1.2 km), excluding FS-002 (4.8 km)
        cubit.updateCorridorTolerance(
          toleranceKm: 2.0,
          route: testRoute,
          stops: testStops,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        final rec = cubit.state.recommendation!;
        expect(rec.corridorStations.length, 1);
        expect(rec.corridorStations.first.id, 'FS-001');
      },
    );

    test(
      '1-tap injectFuelStopWaypoint injects waypoint and emits injected state',
      () async {
        bool callbackFired = false;
        final station = mockRepo.stations.first;

        await cubit.injectFuelStopWaypoint(
          routeId: testRoute.id,
          station: station,
          onInjected: () => callbackFired = true,
        );

        expect(cubit.state.status, FuelFinderStatus.injected);
        expect(cubit.state.injectedStop, isNotNull);
        expect(
          cubit.state.injectedStop?.stopName,
          'Refuel: Taj Gasoline Highway Express Depot',
        );
        expect(mockRepo.lastInjectedStop, isNotNull);
        expect(callbackFired, isTrue);
      },
    );

    test('Handles repository exception gracefully with error status', () async {
      mockRepo.shouldThrow = true;

      await cubit.calculateRecommendation(route: testRoute, stops: testStops);

      expect(cubit.state.status, FuelFinderStatus.error);
      expect(
        cubit.state.errorMessage,
        contains('Corridor fuel optimization error'),
      );
    });

    test('clearStatusMessage resets message to null', () {
      cubit.emit(cubit.state.copyWith(statusMessage: 'Waypoint Injected'));
      expect(cubit.state.statusMessage, 'Waypoint Injected');

      cubit.clearStatusMessage();
      expect(cubit.state.statusMessage, isNull);
    });
  });
}
