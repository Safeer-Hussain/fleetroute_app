import 'package:fleetroute_app/core/di/injection_container.dart' as di;
import 'package:fleetroute_app/core/theme/app_theme.dart';
import 'package:fleetroute_app/domain/entities/fuel_finder_recommendation.dart';
import 'package:fleetroute_app/domain/entities/fuel_station.dart';
import 'package:fleetroute_app/domain/entities/route_plan.dart';
import 'package:fleetroute_app/domain/entities/waybill_stop.dart';
import 'package:fleetroute_app/domain/repositories/fuel_station_repository.dart';
import 'package:fleetroute_app/domain/repositories/route_repository.dart';
import 'package:fleetroute_app/presentation/fuel_finder/cubit/fuel_finder_cubit.dart';
import 'package:fleetroute_app/presentation/fuel_finder/fuel_finder_sheet.dart';
import 'package:fleetroute_app/presentation/route_optimizer/bloc/route_optimizer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestMockFuelStationRepository implements FuelStationRepository {
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
  ];

  WaybillStop? lastInjectedStop;

  @override
  Future<List<FuelStation>> getAllFuelStations() async => stations;

  @override
  Future<FuelFinderRecommendation> findOptimalCorridorFuelStop({
    required RoutePlan route,
    required List<WaybillStop> stops,
    double corridorToleranceKm = 8.0,
    double refuelLiters = 300.0,
  }) async {
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

class MockRouteRepoForWidgetTest implements RouteRepository {
  @override
  Future<List<RoutePlan>> getRoutes() async => [];
  @override
  Future<RoutePlan?> getRouteById(String id) async => null;
  @override
  Future<List<WaybillStop>> getStopsForRoute(String routeId) async => [];
  @override
  Future<void> saveOptimizedSequence(
    String routeId,
    List<WaybillStop> stops,
    double newDistanceKm,
    double fuelSavedLiters,
    int minutesSaved,
  ) async {}
  @override
  Future<void> createRoute(RoutePlan route, List<WaybillStop> stops) async {}
}

void main() {
  group('FuelFinderSheet Widget Tests', () {
    late WidgetTestMockFuelStationRepository mockFuelRepo;
    late FuelFinderCubit fuelFinderCubit;
    late RouteOptimizerBloc routeOptimizerBloc;

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
    ];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await di.initDependencies(prefOverride: prefs);

      mockFuelRepo = WidgetTestMockFuelStationRepository();
      fuelFinderCubit = FuelFinderCubit(fuelStationRepository: mockFuelRepo);
      routeOptimizerBloc = RouteOptimizerBloc(
        routeRepository: MockRouteRepoForWidgetTest(),
      );
    });

    tearDown(() {
      fuelFinderCubit.close();
      routeOptimizerBloc.close();
    });

    Widget createTestableWidget({Size? screenSize}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<FuelFinderCubit>.value(value: fuelFinderCubit),
          BlocProvider<RouteOptimizerBloc>.value(value: routeOptimizerBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return FuelFinderSheet(route: testRoute, stops: testStops);
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Modal sheet renders header, recommended hero card, and volume controls',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Trigger recommendation
        await fuelFinderCubit.calculateRecommendation(
          route: testRoute,
          stops: testStops,
        );

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify title & subtitle
        expect(find.text('Corridor Lowest-Price Fuel Finder'), findsOneWidget);
        expect(
          find.text('Highway Diesel Depots with Price Delta'),
          findsOneWidget,
        );

        // Verify Planned Bunkering Volume section
        expect(find.text('Planned Bunkering Volume'), findsOneWidget);
        expect(find.text('300 Liters'), findsOneWidget);

        // Verify Recommended Hero Card
        expect(find.text('LOWEST CORRIDOR PRICE'), findsOneWidget);
        expect(find.text('Taj Gasoline Highway Express Depot'), findsWidgets);
        expect(find.text('Rs. 261.20/L'), findsWidgets);

        // Verify Total Saved Rs. 5040
        expect(find.text('Rs. 5040'), findsOneWidget);

        // Verify 1-Tap inject button
        expect(
          find.text('1-Tap Inject Refueling Stop into Route'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Tapping 1-Tap Inject button executes injection and triggers repository',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await fuelFinderCubit.calculateRecommendation(
          route: testRoute,
          stops: testStops,
        );

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        final injectBtn = find.text('1-Tap Inject Refueling Stop into Route');
        expect(injectBtn, findsOneWidget);

        await tester.tap(injectBtn);
        await tester.pump();

        expect(mockFuelRepo.lastInjectedStop, isNotNull);
        expect(
          mockFuelRepo.lastInjectedStop?.stopName,
          'Refuel: Taj Gasoline Highway Express Depot',
        );
      },
    );

    testWidgets(
      'Volume ChoiceChips switch volume and recalculate total savings',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await fuelFinderCubit.calculateRecommendation(
          route: testRoute,
          stops: testStops,
        );

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Tap 150 L chip
        final chip150 = find.text('150 L');
        expect(chip150, findsOneWidget);
        await tester.tap(chip150);
        await tester.pumpAndSettle();

        expect(fuelFinderCubit.state.refuelLiters, 150.0);
        expect(find.text('150 Liters'), findsOneWidget);
      },
    );

    testWidgets(
      'Landscape 800x360 viewport safety: Zero RenderFlex overflow errors',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await fuelFinderCubit.calculateRecommendation(
          route: testRoute,
          stops: testStops,
        );

        await tester.pumpWidget(createTestableWidget());
        await tester.pumpAndSettle();

        // Verify no RenderFlex exception occurred
        expect(tester.takeException(), isNull);
        expect(find.text('Corridor Lowest-Price Fuel Finder'), findsOneWidget);
      },
    );
  });
}
