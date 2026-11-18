import 'package:fleetroute_app/core/di/injection_container.dart' as di;
import 'package:fleetroute_app/domain/entities/temperature_excursion.dart';
import 'package:fleetroute_app/domain/repositories/cold_chain_repository.dart';
import 'package:fleetroute_app/presentation/cold_chain/cold_chain_audit_view.dart';
import 'package:fleetroute_app/presentation/cold_chain/cubit/cold_chain_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestMockColdChainRepo implements ColdChainRepository {
  List<TemperatureExcursion> excursions = [
    TemperatureExcursion(
      id: 'EXC-001',
      vehicleId: 'VH-105',
      vehicleName: 'ThermoKing Reefer Express',
      routeId: 'RT-205',
      recordedTempC: -12.1,
      thresholdTempC: -15.0,
      startTime: DateTime(2026, 11, 18, 10, 0),
      endTime: null,
      durationSeconds: 420,
      severity: TemperatureExcursionSeverity.warning,
      notes: null,
      isAcknowledged: false,
    ),
    TemperatureExcursion(
      id: 'EXC-002',
      vehicleId: 'VH-102',
      vehicleName: 'Scania R500 Pharma Cold-Chain',
      routeId: 'RT-202',
      recordedTempC: -8.4,
      thresholdTempC: -15.0,
      startTime: DateTime(2026, 11, 17, 14, 0),
      endTime: DateTime(2026, 11, 17, 14, 12),
      durationSeconds: 720,
      severity: TemperatureExcursionSeverity.critical,
      notes: 'Offload seal breach; restored.',
      isAcknowledged: true,
    ),
  ];

  @override
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool onlyActive = false,
  }) async {
    return excursions;
  }

  @override
  Future<void> recordTemperatureReading({
    required String vehicleId,
    required String vehicleName,
    required String routeId,
    required double tempC,
    required DateTime timestamp,
  }) async {}

  @override
  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorNotes,
  }) async {
    final idx = excursions.indexWhere((e) => e.id == excursionId);
    if (idx >= 0) {
      excursions[idx] = excursions[idx].copyWith(
        isAcknowledged: true,
        notes: auditorNotes,
      );
    }
  }

  @override
  Future<String> exportAuditCsv({String? vehicleId}) async {
    return 'Excursion ID,Vehicle ID,Vehicle Name\nEXC-001,VH-105,"ThermoKing Reefer Express"';
  }

  @override
  Future<Map<String, dynamic>> getColdChainAuditMetrics() async {
    return {
      'total_excursions': 2,
      'active_excursions': 1,
      'breached_excursions': 2,
      'compliance_score': 50.0,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetTestMockColdChainRepo mockRepo;
  late ColdChainCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'fleetroute_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    await di.initDependencies(prefOverride: prefs);

    mockRepo = WidgetTestMockColdChainRepo();
    cubit = ColdChainCubit(coldChainRepository: mockRepo);
    await cubit.loadExcursions();
  });

  tearDown(() {
    cubit.close();
  });

  Widget createTestWidget() {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: ColdChainAuditView(cubit: cubit),
    );
  }

  group('ColdChainAuditView Widget Tests', () {
    testWidgets(
      'Test 32: Renders Cold-Chain Audit header, compliance metrics, filter chips, and excursion cards',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Cold-Chain Excursion Audit Log'), findsOneWidget);
        expect(find.text('GDP REEFER COMPLIANCE'), findsOneWidget);
        expect(find.text('50.0% COMPLIANT'), findsOneWidget);
        expect(find.text('All Excursions'), findsOneWidget);
        expect(find.text('Breached (>5m)'), findsOneWidget);
        expect(find.text('ThermoKing Reefer Express'), findsOneWidget);
        expect(find.text('Scania R500 Pharma Cold-Chain'), findsOneWidget);
        expect(find.text('Acknowledge Breach'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 33: Acknowledge Breach dialog opens and submits auditor note successfully',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap Acknowledge Breach button on unacknowledged excursion EXC-001
        await tester.tap(find.text('Acknowledge Breach'));
        await tester.pumpAndSettle();

        expect(find.text('Acknowledge Excursion EXC-001'), findsOneWidget);
        expect(find.text('Confirm Acknowledgment'), findsOneWidget);

        // Submit acknowledgment
        await tester.tap(find.text('Confirm Acknowledgment'));
        await tester.pumpAndSettle();

        expect(mockRepo.excursions.first.isAcknowledged, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 34: Export GDP Audit opens CSV preview modal sheet with copy action',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap Export GDP Audit FAB
        await tester.tap(find.text('Export GDP Audit'));
        await tester.pumpAndSettle();

        expect(find.text('Pharma GDP Excursion Audit Export'), findsOneWidget);
        expect(find.text('Copy CSV Manifest to Clipboard'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 35: Zero RenderFlex overflow errors on 800x360 landscape viewport',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 720); // 800x360 @ 2.0 dpr
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ColdChainAuditView), findsOneWidget);
        expect(find.text('Cold-Chain Excursion Audit Log'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
