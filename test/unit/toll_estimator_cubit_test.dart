import 'package:fleetroute_app/domain/entities/route_plan.dart';
import 'package:fleetroute_app/domain/entities/toll_barrier.dart';
import 'package:fleetroute_app/domain/entities/toll_estimate.dart';
import 'package:fleetroute_app/domain/entities/waybill_stop.dart';
import 'package:fleetroute_app/domain/repositories/toll_repository.dart';
import 'package:fleetroute_app/presentation/toll/cubit/toll_estimator_cubit.dart';
import 'package:fleetroute_app/presentation/toll/cubit/toll_estimator_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTollRepository implements TollRepository {
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

  RouteTollEstimate? savedEstimate;
  bool shouldThrow = false;

  @override
  Future<List<TollBarrier>> getAllTollBarriers() async {
    if (shouldThrow) throw Exception('Database connection failure');
    return barriers;
  }

  @override
  Future<RouteTollEstimate> estimateRouteToll({
    required RoutePlan route,
    required List<WaybillStop> stops,
    required VehicleAxleTier axleTier,
    bool useElectronicTag = true,
  }) async {
    if (shouldThrow) throw Exception('Spatial calculation error');

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
          distanceFromOriginKm: (i + 1) * 25.0,
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

    savedEstimate = estimate;
    return estimate;
  }

  @override
  Future<void> saveRouteTollEstimate(RouteTollEstimate estimate) async {
    savedEstimate = estimate;
  }

  @override
  Future<RouteTollEstimate?> getSavedRouteTollEstimate(String routeId) async {
    return savedEstimate;
  }
}

void main() {
  late MockTollRepository mockRepository;
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

  setUp(() {
    mockRepository = MockTollRepository();
    cubit = TollEstimatorCubit(tollRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('TollEstimatorCubit', () {
    test(
      'initial state has default 4-axle tier and electronic tag enabled',
      () {
        expect(cubit.state.status, TollEstimatorStatus.initial);
        expect(cubit.state.selectedAxleTier, VehicleAxleTier.fourAxlePlus);
        expect(cubit.state.useElectronicTag, isTrue);
        expect(cubit.state.estimate, isNull);
      },
    );

    test('calculateEstimate calculates 4-axle semi fees correctly with M-Tag discount and customs', () async {
      await cubit.calculateEstimate(
        route: testRoute,
        stops: testStops,
        axleTier: VehicleAxleTier.fourAxlePlus,
        useElectronicTag: true,
      );

      expect(cubit.state.status, TollEstimatorStatus.loaded);
      final est = cubit.state.estimate!;
      expect(est.routeId, 'RT-201');
      expect(est.axleTier, VehicleAxleTier.fourAxlePlus);
      expect(est.crossings.length, 2);

      // TB-001 (Highway): Base = 950, Disc = 47.5, Net = 902.5
      // TB-006 (Customs): Base = 1200, Disc = 60, Customs = 1500, Net = 2640
      expect(est.totalTollFees, 2150.0);
      expect(est.totalCustomsFees, 1500.0);
      expect(est.totalElectronicDiscounts, 107.5);
      expect(est.netTotalFee, 3542.5);
      expect(est.highwayTollCount, 1);
      expect(est.borderCustomsCount, 1);
    });

    test(
      'setAxleTier switches to 2-axle tier and recalculates lower base fees',
      () async {
        await cubit.calculateEstimate(
          route: testRoute,
          stops: testStops,
          axleTier: VehicleAxleTier.fourAxlePlus,
        );

        await cubit.setAxleTier(VehicleAxleTier.twoAxle);

        expect(cubit.state.selectedAxleTier, VehicleAxleTier.twoAxle);
        final est = cubit.state.estimate!;
        // TB-001 (2-axle): 240, TB-006 (2-axle): 300
        expect(est.totalTollFees, 540.0);
        expect(est.totalCustomsFees, 1500.0);
        expect(est.totalElectronicDiscounts, 27.0);
        expect(est.netTotalFee, 2013.0);
      },
    );

    test(
      'toggleElectronicTag disables M-Tag discount and charges full base toll',
      () async {
        await cubit.calculateEstimate(
          route: testRoute,
          stops: testStops,
          axleTier: VehicleAxleTier.fourAxlePlus,
          useElectronicTag: true,
        );

        await cubit.toggleElectronicTag(false);

        expect(cubit.state.useElectronicTag, isFalse);
        final est = cubit.state.estimate!;
        expect(est.totalElectronicDiscounts, 0.0);
        expect(est.netTotalFee, 3650.0);
      },
    );

    test(
      'calculateEstimate handles repository exception defensively',
      () async {
        mockRepository.shouldThrow = true;

        await cubit.calculateEstimate(route: testRoute, stops: testStops);

        expect(cubit.state.status, TollEstimatorStatus.error);
        expect(
          cubit.state.errorMessage,
          contains('Failed to estimate route tolls'),
        );
      },
    );
  });

  group('TollBarrier & RouteTollEstimate Domain Entities', () {
    test('VehicleAxleTier mapping from vehicle types', () {
      expect(
        VehicleAxleTier.fromVehicleType('ELECTRIC_COURIER'),
        VehicleAxleTier.twoAxle,
      );
      expect(
        VehicleAxleTier.fromVehicleType('COLD_CHAIN_VAN'),
        VehicleAxleTier.threeAxle,
      );
      expect(
        VehicleAxleTier.fromVehicleType('SEMI_TRUCK'),
        VehicleAxleTier.fourAxlePlus,
      );
    });

    test('TollBarrier serialization and fee lookup', () {
      const barrier = TollBarrier(
        id: 'TB-TEST',
        name: 'Test Toll Plaza',
        highway: 'M-2 Km 50',
        latitude: 31.5,
        longitude: 74.2,
        barrierType: TollBarrierType.highwayToll,
        feeTwoAxle: 100.0,
        feeThreeAxle: 200.0,
        feeFourAxlePlus: 400.0,
        customsClearanceFee: 0.0,
        acceptsElectronicToll: true,
      );

      expect(barrier.getFeeForAxle(VehicleAxleTier.twoAxle), 100.0);
      expect(barrier.getFeeForAxle(VehicleAxleTier.threeAxle), 200.0);
      expect(barrier.getFeeForAxle(VehicleAxleTier.fourAxlePlus), 400.0);

      final map = barrier.toMap();
      final revived = TollBarrier.fromMap(map);
      expect(revived, equals(barrier));
    });

    test('RouteTollEstimate serialization preserves crossings json', () {
      const crossing = TollBarrierCrossing(
        barrier: TollBarrier(
          id: 'TB-001',
          name: 'Ravi Toll Plaza',
          highway: 'M-2',
          latitude: 31.6,
          longitude: 74.2,
          barrierType: TollBarrierType.highwayToll,
          feeTwoAxle: 240.0,
          feeThreeAxle: 480.0,
          feeFourAxlePlus: 950.0,
          customsClearanceFee: 0.0,
          acceptsElectronicToll: true,
        ),
        axleTier: VehicleAxleTier.fourAxlePlus,
        baseTollFee: 950.0,
        customsFee: 0.0,
        electronicDiscount: 47.5,
        netFee: 902.5,
        distanceFromOriginKm: 12.4,
      );

      const estimate = RouteTollEstimate(
        routeId: 'RT-201',
        axleTier: VehicleAxleTier.fourAxlePlus,
        crossings: [crossing],
        totalTollFees: 950.0,
        totalCustomsFees: 0.0,
        totalElectronicDiscounts: 47.5,
        netTotalFee: 902.5,
      );

      final map = estimate.toMap();
      final revived = RouteTollEstimate.fromMap(map);

      expect(revived.routeId, 'RT-201');
      expect(revived.crossings.length, 1);
      expect(revived.crossings.first.barrier.name, 'Ravi Toll Plaza');
      expect(revived.netTotalFee, 902.5);
    });
  });
}
