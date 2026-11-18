import 'dart:async';

import 'package:fleetroute_app/domain/entities/temperature_excursion.dart';
import 'package:fleetroute_app/domain/entities/vehicle.dart';
import 'package:fleetroute_app/domain/repositories/cold_chain_repository.dart';
import 'package:fleetroute_app/presentation/cold_chain/cubit/cold_chain_cubit.dart';
import 'package:fleetroute_app/presentation/cold_chain/cubit/cold_chain_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockColdChainRepository implements ColdChainRepository {
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
    TemperatureExcursion(
      id: 'EXC-9003',
      vehicleId: 'VH-110',
      vehicleName: 'Carrier Transicold Transit Van',
      driverName: 'Asif Javed',
      routeId: 'RT-210',
      startTime: DateTime(2026, 11, 18, 10, 5),
      endTime: DateTime(2026, 11, 18, 10, 8),
      durationSeconds: 180,
      maxRecordedTempC: -16.5,
      targetTempC: -20.0,
      thresholdTempC: -15.0,
      severity: TemperatureExcursionSeverity.warning,
      isResolved: true,
      resolutionNotes: 'Door open transient during parcel drop',
      acknowledgedBy: 'Station Supervisor Farooq',
      complianceStatus: 'COMPLIANT_TRANSIENT',
    ),
  ];

  final StreamController<List<TemperatureExcursion>> _controller =
      StreamController<List<TemperatureExcursion>>.broadcast();

  bool shouldThrow = false;
  TemperatureExcursion? activeLiveExcursion;

  @override
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool breachesOnly = false,
  }) async {
    if (shouldThrow) throw Exception('Database error');
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
    } else {
      excursions.add(excursion);
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
  }) async {
    if (currentTempC > TemperatureExcursion.criticalThresholdCelsius) {
      if (activeLiveExcursion == null) {
        activeLiveExcursion = TemperatureExcursion(
          id: 'EXC-LIVE',
          vehicleId: vehicle.id,
          vehicleName: vehicle.name,
          driverName: vehicle.driverName,
          routeId: vehicle.assignedRouteId,
          startTime: timestamp,
          durationSeconds: 0,
          maxRecordedTempC: currentTempC,
          severity: TemperatureExcursionSeverity.critical,
          complianceStatus: 'COMPLIANT_TRANSIENT',
        );
        excursions.add(activeLiveExcursion!);
        _controller.add(excursions);
        return activeLiveExcursion;
      } else {
        final duration = timestamp
            .difference(activeLiveExcursion!.startTime)
            .inSeconds;
        final maxTemp = currentTempC > activeLiveExcursion!.maxRecordedTempC
            ? currentTempC
            : activeLiveExcursion!.maxRecordedTempC;
        final isBreach =
            duration >= TemperatureExcursion.breachDurationSecondsThreshold;

        activeLiveExcursion = activeLiveExcursion!.copyWith(
          durationSeconds: duration,
          maxRecordedTempC: maxTemp,
          complianceStatus: isBreach
              ? 'EXCURSION_VIOLATION'
              : 'COMPLIANT_TRANSIENT',
        );
        final idx = excursions.indexWhere(
          (e) => e.id == activeLiveExcursion!.id,
        );
        if (idx != -1) excursions[idx] = activeLiveExcursion!;
        _controller.add(excursions);
        return activeLiveExcursion;
      }
    } else {
      if (activeLiveExcursion != null) {
        final duration = timestamp
            .difference(activeLiveExcursion!.startTime)
            .inSeconds;
        final isBreach =
            duration >= TemperatureExcursion.breachDurationSecondsThreshold;

        final resolved = activeLiveExcursion!.copyWith(
          endTime: timestamp,
          durationSeconds: duration,
          isResolved: true,
          complianceStatus: isBreach
              ? 'EXCURSION_VIOLATION'
              : 'COMPLIANT_TRANSIENT',
        );
        final idx = excursions.indexWhere(
          (e) => e.id == activeLiveExcursion!.id,
        );
        if (idx != -1) excursions[idx] = resolved;
        activeLiveExcursion = null;
        _controller.add(excursions);
        return resolved;
      }
      return null;
    }
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  late MockColdChainRepository mockRepo;
  late ColdChainCubit cubit;

  setUp(() {
    mockRepo = MockColdChainRepository();
    cubit = ColdChainCubit(coldChainRepository: mockRepo);
  });

  tearDown(() {
    cubit.close();
    mockRepo.dispose();
  });

  group('ColdChainCubit & TemperatureExcursion Unit Tests', () {
    test(
      'loadExcursions loads all seeded audit records and computes metrics',
      () async {
        await cubit.loadExcursions();

        expect(cubit.state.allExcursions.length, 3);
        expect(cubit.state.totalExcursions, 3);
        expect(cubit.state.criticalBreachCount, 2); // EXC-9001 and EXC-9002
        expect(cubit.state.compliantTransientCount, 1); // EXC-9003
        expect(cubit.state.unresolvedCount, 1); // EXC-9002
      },
    );

    test('Filter switching isolates breachesOnly and unresolvedOnly', () async {
      await cubit.loadExcursions();

      cubit.setFilter(ColdChainFilter.breachesOnly);
      expect(cubit.state.filteredExcursions.length, 2);
      expect(
        cubit.state.filteredExcursions.every((e) => e.isAuditableBreach),
        isTrue,
      );

      cubit.setFilter(ColdChainFilter.unresolvedOnly);
      expect(cubit.state.filteredExcursions.length, 1);
      expect(cubit.state.filteredExcursions.first.id, 'EXC-9002');

      cubit.setFilter(ColdChainFilter.all);
      expect(cubit.state.filteredExcursions.length, 3);
    });

    test(
      'acknowledgeExcursion updates auditor name, notes, and resolves record',
      () async {
        await cubit.loadExcursions();

        await cubit.acknowledgeExcursion(
          excursionId: 'EXC-9002',
          auditorName: 'Lead Inspector Tariq',
          notes: 'Backup cooling unit deployed; pharmaceuticals quarantined.',
        );

        expect(cubit.state.unresolvedCount, 0);
        final updated = cubit.state.allExcursions.firstWhere(
          (e) => e.id == 'EXC-9002',
        );
        expect(updated.isResolved, isTrue);
        expect(updated.acknowledgedBy, 'Lead Inspector Tariq');
        expect(
          updated.resolutionNotes,
          contains('Backup cooling unit deployed'),
        );
      },
    );

    test('exportAuditCsv produces valid GDP-compliant CSV structure', () async {
      final csv = await cubit.exportAuditCsv();

      expect(csv, contains('excursion_id,vehicle_id,vehicle_name'));
      expect(csv, contains('EXC-9001,VH-102,Scania R500 Pharma Cold-Chain'));
      expect(csv, contains('EXCURSION_VIOLATION'));
      expect(csv, contains('COMPLIANT_TRANSIENT'));
      expect(cubit.state.exportedCsv, isNotNull);
    });

    test('Duration threshold boundary tests: <5 min compliant vs >=5 min violation', () {
      final transient = TemperatureExcursion(
        id: 'TEST-1',
        vehicleId: 'VH-102',
        vehicleName: 'Reefer Van',
        driverName: 'Driver',
        routeId: 'RT-1',
        startTime: DateTime.now().subtract(const Duration(seconds: 290)),
        durationSeconds: 290, // 4m 50s (< 300s)
        maxRecordedTempC: -13.0, // Above -15.0°C
        severity: TemperatureExcursionSeverity.critical,
        complianceStatus: 'COMPLIANT_TRANSIENT',
      );
      expect(transient.isAuditableBreach, isFalse);

      final breach = TemperatureExcursion(
        id: 'TEST-2',
        vehicleId: 'VH-102',
        vehicleName: 'Reefer Van',
        driverName: 'Driver',
        routeId: 'RT-1',
        startTime: DateTime.now().subtract(const Duration(seconds: 305)),
        durationSeconds: 305, // 5m 5s (>= 300s)
        maxRecordedTempC: -14.5, // Above -15.0°C
        severity: TemperatureExcursionSeverity.critical,
        complianceStatus: 'EXCURSION_VIOLATION',
      );
      expect(breach.isAuditableBreach, isTrue);
    });
  });
}
