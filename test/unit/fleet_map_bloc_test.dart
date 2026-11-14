import 'package:fleetroute_app/domain/entities/vehicle.dart';
import 'package:fleetroute_app/domain/repositories/fleet_repository.dart';
import 'package:fleetroute_app/presentation/map_command/bloc/fleet_map_bloc.dart';
import 'package:fleetroute_app/presentation/map_command/bloc/fleet_map_event.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFleetRepository implements FleetRepository {
  List<Vehicle> vehicles = [
    const Vehicle(
      id: 'VH-101',
      name: 'Volvo FH16 Globetrotter',
      plateNumber: 'LHR-8842',
      type: 'SEMI_TRUCK',
      driverName: 'Tariq Mehmood',
      driverAvatar: 'assets/images/driver_avatar.png',
      currentLat: 31.4820,
      currentLng: 74.2980,
      speedKmh: 68.5,
      headingDeg: 45.0,
      fuelLevel: 74.0,
      batterySoc: 94.0,
      cargoTempC: 21.0,
      targetTempC: 20.0,
      status: 'IN_TRANSIT',
      assignedRouteId: 'RT-201',
      routeCompletionPct: 42.0,
      hasActiveDtc: false,
      tirePressureFl: 34.2,
      tirePressureFr: 34.0,
      tirePressureRl: 35.8,
      tirePressureRr: 35.5,
    ),
    const Vehicle(
      id: 'VH-102',
      name: 'Scania R500 Pharma Cold-Chain',
      plateNumber: 'LHR-5120',
      type: 'COLD_CHAIN_VAN',
      driverName: 'Rashid Qureshi',
      driverAvatar: 'assets/images/driver_avatar.png',
      currentLat: 31.5497,
      currentLng: 74.3436,
      speedKmh: 54.0,
      headingDeg: 120.0,
      fuelLevel: 61.5,
      batterySoc: 88.0,
      cargoTempC: -18.4,
      targetTempC: -20.0,
      status: 'COLD_CHAIN_TRANSIT',
      assignedRouteId: 'RT-202',
      routeCompletionPct: 68.0,
      hasActiveDtc: true,
      tirePressureFl: 32.8,
      tirePressureFr: 33.1,
      tirePressureRl: 34.5,
      tirePressureRr: 34.2,
    ),
    const Vehicle(
      id: 'VH-105',
      name: 'ThermoKing Reefer Express',
      plateNumber: 'KHI-7721',
      type: 'COLD_CHAIN_VAN',
      driverName: 'Imran Farooq',
      driverAvatar: 'assets/images/driver_avatar.png',
      currentLat: 31.5710,
      currentLng: 74.3120,
      speedKmh: 12.0,
      headingDeg: 90.0,
      fuelLevel: 45.0,
      batterySoc: 82.0,
      cargoTempC: -12.1,
      targetTempC: -18.0,
      status: 'DELAYED',
      assignedRouteId: 'RT-205',
      routeCompletionPct: 55.0,
      hasActiveDtc: true,
      tirePressureFl: 31.0,
      tirePressureFr: 31.2,
      tirePressureRl: 33.0,
      tirePressureRr: 32.8,
    ),
  ];

  @override
  Future<List<Vehicle>> getVehicles() async => vehicles;

  @override
  Future<Vehicle?> getVehicleById(String id) async =>
      vehicles.where((v) => v.id == id).firstOrNull;

  @override
  Future<void> updateVehicleLocation(
    String id,
    double lat,
    double lng,
    double speed,
  ) async {
    final idx = vehicles.indexWhere((v) => v.id == id);
    if (idx != -1) {
      vehicles[idx] = vehicles[idx].copyWith(
        currentLat: lat,
        currentLng: lng,
        speedKmh: speed,
      );
    }
  }

  @override
  Future<void> updateVehicleTelemetry(Vehicle vehicle) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) {
      vehicles[idx] = vehicle;
    }
  }
}

void main() {
  group('FleetMapBloc Unit Tests', () {
    late MockFleetRepository repo;
    late FleetMapBloc bloc;

    setUp(() {
      repo = MockFleetRepository();
      bloc = FleetMapBloc(fleetRepository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('Test 1: LoadFleetMapEvent loads vehicles successfully', () async {
      bloc.add(LoadFleetMapEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isLoading == true),
          predicate<dynamic>(
            (s) =>
                s.isLoading == false &&
                s.vehicles.length == 3 &&
                s.filteredVehicles.length == 3,
          ),
        ]),
      );
    });

    test(
      'Test 2: FilterVehiclesEvent filters vehicles by COLD_CHAIN and DELAYED',
      () async {
        bloc.add(LoadFleetMapEvent());
        await bloc.stream.firstWhere(
          (s) => !s.isLoading && s.vehicles.isNotEmpty,
        );

        bloc.add(const FilterVehiclesEvent('COLD_CHAIN'));
        await expectLater(
          bloc.stream,
          emits(
            predicate<dynamic>(
              (s) =>
                  s.activeFilter == 'COLD_CHAIN' &&
                  s.filteredVehicles.length == 1 &&
                  s.filteredVehicles.first.id == 'VH-102',
            ),
          ),
        );

        bloc.add(const FilterVehiclesEvent('DELAYED'));
        await expectLater(
          bloc.stream,
          emits(
            predicate<dynamic>(
              (s) =>
                  s.activeFilter == 'DELAYED' &&
                  s.filteredVehicles.length == 1 &&
                  s.filteredVehicles.first.id == 'VH-105',
            ),
          ),
        );
      },
    );

    test('Test 3: SelectVehicleEvent and ClearSelectedVehicleEvent update selection', () async {
      bloc.add(LoadFleetMapEvent());
      await bloc.stream.firstWhere(
        (s) => !s.isLoading && s.vehicles.isNotEmpty,
      );

      bloc.add(const SelectVehicleEvent('VH-102'));
      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>((s) => s.selectedVehicle?.id == 'VH-102')),
      );

      bloc.add(ClearSelectedVehicleEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>((s) => s.selectedVehicle == null)),
      );
    });

    test('Test 4: InjectGeofenceBreachEvent and ClearGeofenceAlertEvent operate correctly', () async {
      bloc.add(const InjectGeofenceBreachEvent('VH-105'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<dynamic>(
            (s) =>
                s.geofenceAlert != null && s.geofenceAlert!.contains('VH-105'),
          ),
        ),
      );

      bloc.add(ClearGeofenceAlertEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<dynamic>((s) => s.geofenceAlert == null)),
      );
    });
  });
}
