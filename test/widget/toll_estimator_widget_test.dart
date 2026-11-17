import 'package:fleetroute_app/core/di/injection_container.dart' as di;
import 'package:fleetroute_app/domain/entities/route_plan.dart';
import 'package:fleetroute_app/domain/entities/toll_barrier.dart';
import 'package:fleetroute_app/domain/entities/toll_estimate.dart';
import 'package:fleetroute_app/domain/entities/waybill_stop.dart';
import 'package:fleetroute_app/domain/repositories/toll_repository.dart';
import 'package:fleetroute_app/presentation/toll/cubit/toll_estimator_cubit.dart';
import 'package:fleetroute_app/presentation/toll/toll_breakdown_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestMockTollRepository implements TollRepository {
  List<TollBarrier> barriers = [
    const TollBarrier(
      id: 'TB-001',
      name: 'M-2 Ravi Main Toll Plaza',
      highway: 'M-2 Motorway Km 0',
      latitude: 31.6020,
      longitude: 74.2750,
      barrierType: TollBarrierType.highwayToll,
      feeTwoAxle: 240.0,
      feeThreeAxle: 480.0,
      feeFourAxlePlus: 950.0,
      customsClearanceFee: 0.0,
      acceptsElectronicToll: true,
    ),
    const TollBarrier(
      id: 'TB-006',
      name: 'Punjab-KP Provincial Border Customs Post',
      highway: 'N-5 Attock Khairabad Bridge',
      latitude: 33.8990,
      longitude: 72.2410,
      barrierType: TollBarrierType.borderCustoms,
      feeTwoAxle: 300.0,
      feeThreeAxle: 600.0,
      feeFourAxlePlus: 1200.0,
      customsClearanceFee: 1500.0,
      acceptsElectronicToll: true,
    ),
  ];

  @override
  Future<List<TollBarrier>> getAllTollBarriers() async => barriers;

  @override
  Future<RouteTollEstimate> estimateRouteToll({
    required RoutePlan route,
    required List<WaybillStop> stops,
    required VehicleAxleTier axleTier,
    bool useElectronicTag = true,
  }) async {
    final crossings = <TollBarrierCrossing>[];
    for (int i = 0; i < barriers.length; i++) {
      final b = barriers[i];
      final baseFee = b.getFeeForAxle(axleTier);
      final customs = b.barrierType == TollBarrierType.borderCustoms
          ? b.customsClearanceFee
          : 0.0;
      final discount = (useElectronicTag && b.acceptsElectronicToll)
          ? (baseFee * 0.05)
          : 0.0;
      final net = (baseFee - discount) + customs;

      crossings.add(
        TollBarrierCrossing(
          barrier: b,
          axleTier: axleTier,
          baseTollFee: baseFee,
          customsFee: customs,
          electronicDiscount: discount,
          netFee: net,
          distanceFromOriginKm: (i + 1) * 28.5,
        ),
      );
    }

    double totalToll = 0;
    double totalCustoms = 0;
    double totalDiscounts = 0;
    double netTotal = 0;

    for (final c in crossings) {
      totalToll += c.baseTollFee;
      totalCustoms += c.customsFee;
      totalDiscounts += c.electronicDiscount;
      netTotal += c.netFee;
    }

    return RouteTollEstimate(
      routeId: route.id,
      axleTier: axleTier,
      crossings: crossings,
      totalTollFees: totalToll,
      totalCustomsFees: totalCustoms,
      totalElectronicDiscounts: totalDiscounts,
      netTotalFee: netTotal,
      electronicTagUsed: useElectronicTag,
    );
  }

  @override
  Future<void> saveRouteTollEstimate(RouteTollEstimate estimate) async {}

  @override
  Future<RouteTollEstimate?> getSavedRouteTollEstimate(String routeId) async =>
      null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetTestMockTollRepository mockRepo;
  late TollEstimatorCubit cubit;

  const testRoute = RoutePlan(
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

  const testStops = <WaybillStop>[
    WaybillStop(
      id: 'WB-7001',
      routeId: 'RT-201',
      sequenceOrder: 1,
      stopName: 'Multan Road Logistics Depot',
      latitude: 31.4700,
      longitude: 74.2720,
      cargoDescription: 'High-Density Pallet Freight',
      weightKg: 4200.0,
      priority: 'SCHEDULED_FREIGHT',
      status: 'DELIVERED',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({'fleetroute_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    await di.initDependencies(prefOverride: prefs);

    mockRepo = WidgetTestMockTollRepository();
    cubit = TollEstimatorCubit(tollRepository: mockRepo);
    await cubit.calculateEstimate(
      route: testRoute,
      stops: testStops,
      axleTier: VehicleAxleTier.fourAxlePlus,
      useElectronicTag: true,
    );
  });

  tearDown(() {
    cubit.close();
  });

  Widget createTestWidget({required Widget child}) {
    return BlocProvider<TollEstimatorCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  group('TollBreakdownSheet Widget Tests', () {
    testWidgets(
      'Test 29: Renders Toll Breakdown Sheet with axle tiers, M-Tag toggle, summary, and barriers',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const TollBreakdownSheet()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Corridor Toll & Customs Manifest'), findsOneWidget);
        expect(
          find.text('Automated Axle & Border Tariff Audit'),
          findsOneWidget,
        );
        expect(find.text('2-AXLE'), findsOneWidget);
        expect(find.text('3-AXLE'), findsOneWidget);
        expect(find.text('4-AXLE+'), findsOneWidget);
        expect(find.text('Electronic M-Tag / FastTag'), findsOneWidget);
        expect(find.text('TOTAL CORRIDOR TARIFF'), findsOneWidget);
        expect(find.text('Rs. 3543'), findsOneWidget);
        expect(find.text('2 BARRIERS'), findsOneWidget);
        expect(find.text('M-2 Ravi Main Toll Plaza'), findsOneWidget);
        expect(
          find.text('Punjab-KP Provincial Border Customs Post'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Test 30: Switching axle tier updates total fee dynamically', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(child: const TollBreakdownSheet()),
      );
      await tester.pumpAndSettle();

      // Initially 4-axle
      expect(find.text('Rs. 3543'), findsOneWidget);

      // Tap 2-AXLE
      await tester.tap(find.text('2-AXLE'));
      await tester.pumpAndSettle();

      expect(cubit.state.selectedAxleTier, VehicleAxleTier.twoAxle);
      expect(find.text('Rs. 2013'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Test 31: Zero RenderFlex overflow errors on 800x360 landscape viewport',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 720); // 800x360 @ 2.0 dpr
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const TollBreakdownSheet()),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TollBreakdownSheet), findsOneWidget);
        expect(find.text('Corridor Toll & Customs Manifest'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
