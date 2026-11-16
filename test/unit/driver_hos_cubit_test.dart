import 'dart:async';

import 'package:fleetroute_app/domain/entities/driver_hos_log.dart';
import 'package:fleetroute_app/domain/entities/rest_stop.dart';
import 'package:fleetroute_app/domain/repositories/hos_repository.dart';
import 'package:fleetroute_app/presentation/hos/cubit/driver_hos_cubit.dart';
import 'package:fleetroute_app/presentation/hos/cubit/driver_hos_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHosRepository implements HosRepository {
  DriverHosLog log = DriverHosLog(
    driverId: 'DRV-101',
    driverName: 'Tariq Mehmood',
    vehicleId: 'VH-101',
    currentStatus: HosDutyStatus.driving,
    drivingSecondsToday: 24300, // 6h 45m
    onDutySecondsToday: 27000, // 7h 30m
    secondsUntilBreakRequired: 4500, // 1h 15m left
    breakDurationSeconds: 0,
    lastStatusChange: DateTime(2026, 11, 16, 6, 0),
  );

  List<RestStop> restStops = [
    const RestStop(
      id: 'RS-001',
      name: 'M-2 Sukheke Service Area',
      highway: 'M-2 Motorway Km 87',
      latitude: 31.8670,
      longitude: 73.5120,
      distanceKm: 42.5,
      amenities: ['Diesel High-Flow', 'Secure Truck Parking'],
      availableTruckBays: 34,
    ),
    const RestStop(
      id: 'RS-002',
      name: 'M-2 Sial Rest Area',
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
  Future<DriverHosLog> getDriverHosLog(String driverId) async {
    return log;
  }

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
    int newDriving = log.drivingSecondsToday;
    int newOnDuty = log.onDutySecondsToday;
    int newBreak = log.secondsUntilBreakRequired;
    int newRest = log.breakDurationSeconds;

    if (log.currentStatus == HosDutyStatus.driving) {
      newDriving += deltaSeconds;
      newOnDuty += deltaSeconds;
      newBreak = (newBreak - deltaSeconds).clamp(0, 999999);
    } else if (log.currentStatus == HosDutyStatus.onDuty) {
      newOnDuty += deltaSeconds;
    } else {
      newRest += deltaSeconds;
      if (newRest >= DriverHosLog.mandatoryBreakSeconds) {
        newBreak = DriverHosLog.maxConsecutiveSecondsBeforeBreak;
      }
    }

    log = log.copyWith(
      drivingSecondsToday: newDriving,
      onDutySecondsToday: newOnDuty,
      secondsUntilBreakRequired: newBreak,
      breakDurationSeconds: newRest,
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
  }) async {
    return restStops;
  }

  @override
  Stream<DriverHosLog> watchDriverHosLog(String driverId) {
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('DriverHosCubit Unit Tests', () {
    late MockHosRepository mockRepo;
    late DriverHosCubit cubit;

    setUp(() {
      mockRepo = MockHosRepository();
      cubit = DriverHosCubit(hosRepository: mockRepo);
    });

    tearDown(() {
      cubit.close();
      mockRepo.dispose();
    });

    test('Test 19: loadHos loads driver log and nearest rest stops', () async {
      await cubit.loadHos(driverId: 'DRV-101');

      expect(cubit.state.status, DriverHosViewStatus.loaded);
      expect(cubit.state.hosLog?.driverId, 'DRV-101');
      expect(cubit.state.hosLog?.driverName, 'Tariq Mehmood');
      expect(cubit.state.nearestRestStops.length, 2);
      expect(cubit.state.selectedRestStop?.id, 'RS-001');
    });

    test('Test 20: changeDutyStatus mutates status and emits notice', () async {
      await cubit.loadHos(driverId: 'DRV-101');
      await cubit.changeDutyStatus(HosDutyStatus.sleeperBerth);

      expect(cubit.state.hosLog?.currentStatus, HosDutyStatus.sleeperBerth);
      expect(cubit.state.userNotice, contains('SLEEPER BERTH'));
    });

    test('Test 21: tickSimulation increments driving seconds and decrements break countdown', () async {
      await cubit.loadHos(driverId: 'DRV-101');
      final initialDriving = cubit.state.hosLog!.drivingSecondsToday;
      final initialBreak = cubit.state.hosLog!.secondsUntilBreakRequired;

      await cubit.tickSimulation(deltaSeconds: 600); // 10 minutes

      expect(
        cubit.state.hosLog!.drivingSecondsToday,
        equals(initialDriving + 600),
      );
      expect(
        cubit.state.hosLog!.secondsUntilBreakRequired,
        equals(initialBreak - 600),
      );
    });

    test(
      'Test 22: Approaching break threshold triggers warning state',
      () async {
        mockRepo.log = mockRepo.log.copyWith(
          secondsUntilBreakRequired:
              1800, // 30 mins left before mandatory break
        );

        await cubit.loadHos(driverId: 'DRV-101');

        expect(cubit.state.warningState, HosWarningState.warning);
      },
    );

    test(
      'Test 23: Exceeding 11h driving triggers HOS violation state',
      () async {
        mockRepo.log = mockRepo.log.copyWith(
          drivingSecondsToday: 11 * 3600 + 60, // 11h 01m
        );

        await cubit.loadHos(driverId: 'DRV-101');

        expect(cubit.state.warningState, HosWarningState.violation);
      },
    );

    test(
      'Test 24: takeMandatoryBreak resets consecutive break timer to 8h',
      () async {
        mockRepo.log = mockRepo.log.copyWith(
          secondsUntilBreakRequired: 0,
          currentStatus: HosDutyStatus.driving,
        );

        await cubit.loadHos(driverId: 'DRV-101');
        await cubit.takeMandatoryBreak();

        expect(
          cubit.state.hosLog!.secondsUntilBreakRequired,
          DriverHosLog.maxConsecutiveSecondsBeforeBreak,
        );
        expect(cubit.state.hosLog!.currentStatus, HosDutyStatus.offDuty);
        expect(
          cubit.state.userNotice,
          contains('Mandatory 30-minute rest logged'),
        );
      },
    );

    test('Test 25: selectRestStop updates selectedRestStop in state', () async {
      await cubit.loadHos(driverId: 'DRV-101');
      final secondStop = mockRepo.restStops[1];

      cubit.selectRestStop(secondStop);

      expect(cubit.state.selectedRestStop?.id, 'RS-002');
    });
  });
}
