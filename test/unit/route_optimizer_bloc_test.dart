import 'package:fleetroute_app/domain/entities/route_plan.dart';
import 'package:fleetroute_app/domain/entities/waybill_stop.dart';
import 'package:fleetroute_app/domain/repositories/route_repository.dart';
import 'package:fleetroute_app/presentation/route_optimizer/bloc/route_optimizer_bloc.dart';
import 'package:fleetroute_app/presentation/route_optimizer/bloc/route_optimizer_event.dart';
import 'package:flutter_test/flutter_test.dart';

class MockRouteRepository implements RouteRepository {
  List<RoutePlan> routes = [
    const RoutePlan(
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
      optimizedDistanceKm: 48.6,
      fuelSavedLiters: 0.0,
      minutesSaved: 0,
      isOptimized: false,
      status: 'ACTIVE',
    ),
  ];

  List<WaybillStop> stops = [
    const WaybillStop(
      id: 'WB-7001',
      routeId: 'RT-201',
      sequenceOrder: 1,
      stopName: 'Multan Road Logistics Depot',
      latitude: 31.4700,
      longitude: 74.2720,
      cargoDescription: 'High-Density Pallet Freight',
      weightKg: 4200.0,
      priority: 'SCHEDULED_FREIGHT',
      status: 'PENDING',
    ),
    const WaybillStop(
      id: 'WB-7002',
      routeId: 'RT-201',
      sequenceOrder: 2,
      stopName: 'Gulberg Commercial Distribution Hub',
      latitude: 31.5150,
      longitude: 74.3450,
      cargoDescription: 'Insulated Biologics & Vaccines',
      weightKg: 650.0,
      priority: 'URGENT_COLD_CHAIN',
      status: 'PENDING',
    ),
    const WaybillStop(
      id: 'WB-7003',
      routeId: 'RT-201',
      sequenceOrder: 3,
      stopName: 'Kot Lakhpat Industrial Park',
      latitude: 31.4420,
      longitude: 74.3310,
      cargoDescription: 'Precision Electronic Components',
      weightKg: 1200.0,
      priority: 'STANDARD_PARCEL',
      status: 'PENDING',
    ),
  ];

  @override
  Future<List<RoutePlan>> getRoutes() async => routes;

  @override
  Future<RoutePlan?> getRouteById(String id) async =>
      routes.where((r) => r.id == id).firstOrNull;

  @override
  Future<List<WaybillStop>> getStopsForRoute(String routeId) async =>
      stops.where((s) => s.routeId == routeId).toList();

  @override
  Future<void> saveOptimizedSequence(
    String routeId,
    List<WaybillStop> newStops,
    double newDistanceKm,
    double fuelSavedLiters,
    int minutesSaved,
  ) async {
    stops = List.from(newStops);
    final idx = routes.indexWhere((r) => r.id == routeId);
    if (idx != -1) {
      routes[idx] = routes[idx].copyWith(
        optimizedDistanceKm: newDistanceKm,
        fuelSavedLiters: fuelSavedLiters,
        minutesSaved: minutesSaved,
        isOptimized: true,
      );
    }
  }

  @override
  Future<void> createRoute(RoutePlan route, List<WaybillStop> newStops) async {
    routes.add(route);
    stops.addAll(newStops);
  }
}

void main() {
  group('RouteOptimizerBloc Unit Tests', () {
    late MockRouteRepository repo;
    late RouteOptimizerBloc bloc;

    setUp(() {
      repo = MockRouteRepository();
      bloc = RouteOptimizerBloc(routeRepository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('Test 5: LoadRoutesEvent loads routes and assigned stops', () async {
      bloc.add(LoadRoutesEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isLoading == true),
          predicate<dynamic>(
            (s) =>
                s.isLoading == false &&
                s.routes.isNotEmpty &&
                s.stops.length == 3 &&
                s.selectedRoute?.id == 'RT-201',
          ),
        ]),
      );
    });

    test('Test 6: OptimizeRouteEvent re-sequences stops prioritizing Urgent Cold-Chain', () async {
      bloc.add(LoadRoutesEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading && s.stops.isNotEmpty);

      bloc.add(const OptimizeRouteEvent('RT-201'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isOptimizing == true),
          predicate<dynamic>(
            (s) =>
                s.isOptimizing == false &&
                s.selectedRoute?.isOptimized == true &&
                s.selectedRoute!.optimizedDistanceKm <
                    s.selectedRoute!.totalDistanceKm &&
                s.stops.first.priority == 'URGENT_COLD_CHAIN',
          ),
        ]),
      );
    });

    test('Test 7: ReorderStopsEvent updates sequenceOrder manually', () async {
      bloc.add(LoadRoutesEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading && s.stops.isNotEmpty);

      bloc.add(const ReorderStopsEvent(oldIndex: 0, newIndex: 2));
      await expectLater(
        bloc.stream,
        emits(
          predicate<dynamic>(
            (s) =>
                s.stops.length == 3 &&
                s.stops[0].sequenceOrder == 1 &&
                s.stops[1].sequenceOrder == 2 &&
                s.stops[2].sequenceOrder == 3,
          ),
        ),
      );
    });

    test(
      'Test 8: CreateRouteEvent creates new route and updates list',
      () async {
        const newRoute = RoutePlan(
          id: 'RT-999',
          name: 'Test Freight Expressway',
          vehicleId: 'VH-104',
          originName: 'Depot Alpha',
          originLat: 31.47,
          originLng: 74.27,
          destinationName: 'Hub Omega',
          destinationLat: 31.28,
          destinationLng: 74.17,
          totalDistanceKm: 25.0,
          optimizedDistanceKm: 25.0,
          fuelSavedLiters: 0.0,
          minutesSaved: 0,
          isOptimized: false,
          status: 'ACTIVE',
        );

        const newStop = WaybillStop(
          id: 'WB-9901',
          routeId: 'RT-999',
          sequenceOrder: 1,
          stopName: 'Express Stop 1',
          latitude: 31.40,
          longitude: 74.25,
          cargoDescription: 'Express Parcels',
          weightKg: 500.0,
          priority: 'STANDARD_PARCEL',
          status: 'PENDING',
        );

        bloc.add(const CreateRouteEvent(route: newRoute, stops: [newStop]));
        await expectLater(
          bloc.stream,
          emits(
            predicate<dynamic>(
              (s) =>
                  s.routes.any((r) => r.id == 'RT-999') &&
                  s.selectedRoute?.id == 'RT-999' &&
                  s.stops.any((st) => st.id == 'WB-9901'),
            ),
          ),
        );
      },
    );
  });
}
