import 'dart:async';

import 'package:fleetroute_app/core/di/injection_container.dart' as di;
import 'package:fleetroute_app/domain/entities/temperature_excursion.dart';
import 'package:fleetroute_app/domain/entities/vehicle.dart';
import 'package:fleetroute_app/domain/repositories/cold_chain_repository.dart';
import 'package:fleetroute_app/presentation/cold_chain/cold_chain_audit_view.dart';
import 'package:fleetroute_app/presentation/cold_chain/cubit/cold_chain_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestMockColdChainRepository implements ColdChainRepository {
  List<TemperatureExcursion> excursions = [
    TemperatureExcursion(
      id: 'EXC-9001',
      vehicleId: 'VH-102',
      vehicleName: 'Scania R500 Pharma Cold-Chain',
      driverName: 'Rashid Qureshi',
      routeId: 'RT-202',
      startTime: DateTime(2026, 11, 17, 9, 15),
      endTime: DateTime(2026, 11, 17, 9, 22),
      durationSeconds: 420,
      maxRecordedTempC: -12.8,
      targetTempC: -20.0,
      thresholdTempC: -15.0,
      severity: TemperatureExcursionSeverity.critical,
      isResolved: true,
      resolutionNotes: 'Compressor thermal cycle recovery',
      acknowledgedBy: 'QA Lead Dr. Ayesha',
      complianceStatus: 'EXCURSION_VIOLATION',
    ),
    TemperatureExcursion(
      id: 'EXC-9002',
      vehicleId: 'VH-102',
      vehicleName: 'Scania R500 Pharma Cold-Chain',
      driverName: 'Rashid Qureshi',
      routeId: 'RT-202',
      startTime: DateTime(2026, 11, 18, 8, 30),
      endTime: null,
      durationSeconds: 360,
      maxRecordedTempC: -14.2,
      targetTempC: -20.0,
      thresholdTempC: -15.0,
      severity: TemperatureExcursionSeverity.critical,
      isResolved: false,
      resolutionNotes: null,
      acknowledgedBy: null,
      complianceStatus: 'EXCURSION_VIOLATION',
    ),
  ];

  final StreamController<List<TemperatureExcursion>> _controller =
      StreamController<List<TemperatureExcursion>>.broadcast();

  @override
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool breachesOnly = false,
  }) async {
    var list = excursions;
    if (vehicleId != null) {
      list = list.where((e) => e.vehicleId == vehicleId).toList();
    }
    if (breachesOnly) {
      list = list.where((e) => e.isAuditableBreach).toList();
    }
    return list;
  }

  @override
  Future<void> logExcursion(TemperatureExcursion excursion) async {
    excursions.add(excursion);
    _controller.add(excursions);
  }

  @override
  Future<void> updateExcursion(TemperatureExcursion excursion) async {
    final idx = excursions.indexWhere((e) => e.id == excursion.id);
    if (idx != -1) {
      excursions[idx] = excursion;
    }
    _controller.add(excursions);
  }

  @override
  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorName,
    required String notes,
  }) async {
    final idx = excursions.indexWhere((e) => e.id == excursionId);
    if (idx != -1) {
      excursions[idx] = excursions[idx].copyWith(
        acknowledgedBy: auditorName,
        resolutionNotes: notes,
        isResolved: true,
      );
      _controller.add(excursions);
    }
  }

  @override
  Future<String> exportAuditCsv({String? vehicleId}) async {
    final list = await getExcursions(vehicleId: vehicleId);
    return TemperatureExcursion.generateAuditCsv(list);
  }

  @override
  Stream<List<TemperatureExcursion>> watchExcursions() => _controller.stream;

  @override
  Future<TemperatureExcursion?> recordTelemetryTick({
    required Vehicle vehicle,
    required double currentTempC,
    required DateTime timestamp,
  }) async => null;

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetTestMockColdChainRepository mockRepo;
  late ColdChainCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'fleetroute_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    await di.initDependencies(prefOverride: prefs);

    mockRepo = WidgetTestMockColdChainRepository();
    cubit = ColdChainCubit(coldChainRepository: mockRepo);
    await cubit.loadExcursions();
  });

  tearDown(() {
    cubit.close();
    mockRepo.dispose();
  });

  Widget createTestWidget({required Widget child}) {
    return BlocProvider<ColdChainCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: child,
      ),
    );
  }

  group('ColdChainAuditView Widget Tests', () {
    testWidgets(
      'Test 32: Renders Cold-Chain Excursion Audit Log with metrics, threshold banner, and cards',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: ColdChainAuditView(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cold-Chain Excursion Audit Log'), findsOneWidget);
        expect(find.text('PHARMA REEFER AUDIT METRICS'), findsOneWidget);
        expect(find.text('Total Excursions'), findsOneWidget);
        expect(find.text('Breaches (>5m)'), findsOneWidget);
        expect(
          find.text(
            'Target: -20.0°C | Critical Excursion: > -15.0°C for > 300s',
          ),
          findsOneWidget,
        );
        expect(find.text('Scania R500 Pharma Cold-Chain'), findsNWidgets(2));
        expect(find.text('Export QA CSV'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 33: Tapping Sign & Acknowledge opens auditor sign-off dialog and certifies record',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: ColdChainAuditView(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        // One unresolved excursion has sign button
        final signButton = find.text('Sign & Acknowledge Excursion');
        expect(signButton, findsOneWidget);

        await tester.tap(signButton);
        await tester.pumpAndSettle();

        expect(find.text('Auditor Excursion Sign-Off'), findsOneWidget);
        expect(find.text('Auditor Full Name'), findsOneWidget);

        // Enter notes and sign
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Corrective Action & Root Cause Notes',
          ),
          'Auxiliary refrigeration unit activated.',
        );
        await tester.pump();

        await tester.tap(find.text('Sign & Archive'));
        await tester.pumpAndSettle();

        // Verified closed and archived
        expect(find.text('Sign & Acknowledge Excursion'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 34: Zero RenderFlex overflow errors on 800x360 landscape viewport',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 720); // 800x360 @ 2.0 dpr
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: ColdChainAuditView(cubit: cubit)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ColdChainAuditView), findsOneWidget);
        expect(find.text('Cold-Chain Excursion Audit Log'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
