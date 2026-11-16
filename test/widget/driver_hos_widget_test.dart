import 'dart:async';
import 'dart:math' as math;

import 'package:fleetroute_app/core/di/injection_container.dart' as di;
import 'package:fleetroute_app/domain/entities/driver_hos_log.dart';
import 'package:fleetroute_app/domain/entities/rest_stop.dart';
import 'package:fleetroute_app/domain/repositories/hos_repository.dart';
import 'package:fleetroute_app/main.dart';
import 'package:fleetroute_app/presentation/hos/cubit/driver_hos_cubit.dart';
import 'package:fleetroute_app/presentation/hos/driver_hos_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestMockHosRepository implements HosRepository {
  DriverHosLog log = DriverHosLog(
    driverId: 'DRV-101',
    driverName: 'Tariq Mehmood',
    vehicleId: 'VH-101',
    currentStatus: HosDutyStatus.driving,
    drivingSecondsToday: 24300,
    onDutySecondsToday: 27000,
    secondsUntilBreakRequired: 4500,
    breakDurationSeconds: 0,
    lastStatusChange: DateTime(2026, 11, 16, 6, 0),
  );

  List<RestStop> restStops = [
    const RestStop(
      id: 'RS-001',
      name: 'M-2 Sukheke Service Area & Freight Rest Plaza',
      highway: 'M-2 Motorway Km 87',
      latitude: 31.8670,
      longitude: 73.5120,
      distanceKm: 42.5,
      amenities: ['Diesel High-Flow', 'Secure Truck Parking'],
      availableTruckBays: 34,
    ),
    const RestStop(
      id: 'RS-002',
      name: 'M-2 Sial Rest Area & Heavy Vehicle Terminal',
      highway: 'M-2 Motorway Km 132',
      latitude: 32.1480,
      longitude: 73.1250,
      distanceKm: 85.0,
      amenities: ['Mosque', 'Truck Tire Repair'],
      availableTruckBays: 28,
    ),
  ];

  final StreamController<DriverHosLog> _controller =
      StreamController<DriverHosLog>.broadcast();

  @override
  Future<DriverHosLog> getDriverHosLog(String driverId) async => log;

  @override
  Future<void> updateDutyStatus(
    String driverId,
    HosDutyStatus newStatus,
  ) async {
    log = log.copyWith(
      currentStatus: newStatus,
      lastStatusChange: DateTime.now(),
    );
    _controller.add(log);
  }

  @override
  Future<void> logDrivingSecondsTick(String driverId, int deltaSeconds) async {
    log = log.copyWith(
      drivingSecondsToday: log.drivingSecondsToday + deltaSeconds,
      secondsUntilBreakRequired: math.max(
        0,
        log.secondsUntilBreakRequired - deltaSeconds,
      ),
    );
    _controller.add(log);
  }

  @override
  Future<void> resetBreakTimer(String driverId) async {
    log = log.copyWith(
      secondsUntilBreakRequired: DriverHosLog.maxConsecutiveSecondsBeforeBreak,
      breakDurationSeconds: 0,
      currentStatus: HosDutyStatus.offDuty,
      lastStatusChange: DateTime.now(),
    );
    _controller.add(log);
  }

  @override
  Future<List<RestStop>> getNearestRestStops({
    required double currentLat,
    required double currentLng,
  }) async => restStops;

  @override
  Stream<DriverHosLog> watchDriverHosLog(String driverId) => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetTestMockHosRepository mockRepo;
  late DriverHosCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'fleetroute_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    await di.initDependencies(prefOverride: prefs);

    mockRepo = WidgetTestMockHosRepository();
    cubit = DriverHosCubit(hosRepository: mockRepo);
    await cubit.loadHos();

    FlutterError.onError = (details) {
      debugPrint('FLUTTER_ERROR_NODE: ${details.summary}');
      debugPrint('CONTEXT: ${details.context}');
    };
  });

  tearDown(() {
    cubit.close();
    mockRepo.dispose();
  });

  group('DriverHosView Widget Tests', () {
    testWidgets(
      'Test 26: Renders HOS countdown dials, driver info card, and rest stop cards cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          FleetRouteApp(home: DriverHosView(cubit: cubit)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(DriverHosView), findsOneWidget);
        expect(find.text('Driver HOS Fatigue & Rest Timer'), findsOneWidget);
        expect(find.text('Driving Left'), findsOneWidget);
        expect(find.text('Break Due In'), findsOneWidget);
        expect(find.text('DRIVING'), findsOneWidget);
        expect(find.text('ON DUTY'), findsOneWidget);
        expect(find.text('SLEEPER BERTH'), findsOneWidget);
        expect(find.text('OFF DUTY'), findsOneWidget);
        expect(find.text('Tariq Mehmood'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 27: Zero RenderFlex overflow errors on 800x360 landscape viewport',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          FleetRouteApp(home: DriverHosView(cubit: cubit)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(DriverHosView), findsOneWidget);
        // Verify master-detail two panes exist
        expect(find.text('Nearest Freight Rest Plazas'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Test 28: Tapping duty status button switches status cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(FleetRouteApp(home: DriverHosView(cubit: cubit)));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap SLEEPER BERTH
      final sleeperBtn = find.text('SLEEPER BERTH');
      expect(sleeperBtn, findsOneWidget);
      await tester.tap(sleeperBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      // Tap Log 30m Break button
      final breakBtn = find.text('Log 30m Break');
      expect(breakBtn, findsOneWidget);
      await tester.tap(breakBtn);
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
