import 'package:fleetroute_app/domain/entities/temperature_excursion.dart';
import 'package:fleetroute_app/domain/repositories/cold_chain_repository.dart';
import 'package:fleetroute_app/presentation/cold_chain/cubit/cold_chain_cubit.dart';
import 'package:fleetroute_app/presentation/cold_chain/cubit/cold_chain_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockColdChainRepository implements ColdChainRepository {
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
      durationSeconds: 420, // 7 min (Breached > 5m)
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
      durationSeconds: 720, // 12 min (Resolved)
      severity: TemperatureExcursionSeverity.critical,
      notes: 'Door seal restored',
      isAcknowledged: true,
    ),
    TemperatureExcursion(
      id: 'EXC-003',
      vehicleId: 'VH-110',
      vehicleName: 'Carrier Transicold Transit Van',
      routeId: 'RT-210',
      recordedTempC: -14.2,
      thresholdTempC: -15.0,
      startTime: DateTime(2026, 11, 16, 9, 0),
      endTime: DateTime(2026, 11, 16, 9, 4),
      durationSeconds: 240, // 4 min (Under 5m)
      severity: TemperatureExcursionSeverity.warning,
      notes: null,
      isAcknowledged: true,
    ),
  ];

  bool shouldThrow = false;

  @override
  Future<List<TemperatureExcursion>> getExcursions({
    String? vehicleId,
    bool onlyActive = false,
  }) async {
    if (shouldThrow) throw Exception('Database read error');
    var list = excursions;
    if (vehicleId != null) {
      list = list.where((e) => e.vehicleId == vehicleId).toList();
    }
    if (onlyActive) {
      list = list.where((e) => e.isActive).toList();
    }
    return list;
  }

  @override
  Future<void> recordTemperatureReading({
    required String vehicleId,
    required String vehicleName,
    required String routeId,
    required double tempC,
    required DateTime timestamp,
  }) async {
    if (shouldThrow) throw Exception('Telemetry ingest failure');

    final index = excursions.indexWhere(
      (e) => e.vehicleId == vehicleId && e.isActive,
    );

    if (tempC > -15.0) {
      if (index >= 0) {
        final existing = excursions[index];
        final elapsed = timestamp.difference(existing.startTime).inSeconds;
        excursions[index] = existing.copyWith(
          recordedTempC: tempC > existing.recordedTempC
              ? tempC
              : existing.recordedTempC,
          durationSeconds: elapsed > existing.durationSeconds
              ? elapsed
              : existing.durationSeconds,
          severity: TemperatureExcursionSeverity.fromTemperature(
            tempC > existing.recordedTempC ? tempC : existing.recordedTempC,
          ),
        );
      } else {
        excursions.insert(
          0,
          TemperatureExcursion(
            id: 'EXC-${DateTime.now().millisecondsSinceEpoch}',
            vehicleId: vehicleId,
            vehicleName: vehicleName,
            routeId: routeId,
            recordedTempC: tempC,
            thresholdTempC: -15.0,
            startTime: timestamp,
            endTime: null,
            durationSeconds: 0,
            severity: TemperatureExcursionSeverity.fromTemperature(tempC),
            isAcknowledged: false,
          ),
        );
      }
    } else {
      if (index >= 0) {
        final existing = excursions[index];
        final elapsed = timestamp.difference(existing.startTime).inSeconds;
        excursions[index] = existing.copyWith(
          endTime: timestamp,
          durationSeconds: elapsed > existing.durationSeconds
              ? elapsed
              : existing.durationSeconds,
        );
      }
    }
  }

  @override
  Future<void> acknowledgeExcursion({
    required String excursionId,
    required String auditorNotes,
  }) async {
    final index = excursions.indexWhere((e) => e.id == excursionId);
    if (index >= 0) {
      excursions[index] = excursions[index].copyWith(
        isAcknowledged: true,
        notes: auditorNotes,
      );
    }
  }

  @override
  Future<String> exportAuditCsv({String? vehicleId}) async {
    final list = await getExcursions(vehicleId: vehicleId);
    final buffer = StringBuffer();
    buffer.writeln(
      'Excursion ID,Vehicle ID,Vehicle Name,Route ID,Peak Temp (°C),Threshold (°C),Start Time,End Time,Duration (s),Duration (min),Severity,Status,Acknowledged,Auditor Notes',
    );
    for (final e in list) {
      buffer.writeln(e.toCsvRow());
    }
    return buffer.toString();
  }

  @override
  Future<Map<String, dynamic>> getColdChainAuditMetrics() async {
    final active = excursions.where((e) => e.isActive).length;
    final breached = excursions.where((e) => e.isThresholdBreached).length;
    final compliance =
        (((excursions.length - breached) / excursions.length) * 100);
    return {
      'total_excursions': excursions.length,
      'active_excursions': active,
      'breached_excursions': breached,
      'compliance_score': compliance,
    };
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
  });

  group('ColdChainCubit & TemperatureExcursion Unit Tests', () {
    test('loadExcursions loads excursions and audit metrics cleanly', () async {
      await cubit.loadExcursions();

      expect(cubit.state.status, ColdChainStatus.loaded);
      expect(cubit.state.excursions.length, 3);
      expect(cubit.state.metrics['total_excursions'], 3);
      expect(cubit.state.metrics['active_excursions'], 1);
      expect(cubit.state.metrics['breached_excursions'], 2);
    });

    test('Filtered excursions separates active breaches vs resolved', () async {
      await cubit.loadExcursions();

      cubit.setFilter(ColdChainFilter.all);
      expect(cubit.state.filteredExcursions.length, 3);

      cubit.setFilter(ColdChainFilter.activeBreaches);
      expect(cubit.state.filteredExcursions.length, 2);

      cubit.setFilter(ColdChainFilter.resolved);
      expect(cubit.state.filteredExcursions.length, 2);
    });

    test(
      'Temperature breach detection: duration >= 300s is marked as breached',
      () {
        final subThreshold = TemperatureExcursion(
          id: 'EXC-T1',
          vehicleId: 'VH-101',
          vehicleName: 'Test Reefer',
          routeId: 'RT-101',
          recordedTempC: -14.0,
          thresholdTempC: -15.0,
          startTime: DateTime.now(),
          durationSeconds: 299,
          severity: TemperatureExcursionSeverity.warning,
        );
        expect(subThreshold.isThresholdBreached, isFalse);

        final breached = subThreshold.copyWith(durationSeconds: 300);
        expect(breached.isThresholdBreached, isTrue);
        expect(breached.formattedDuration, '5m 0s');
      },
    );

    test(
      'Severity escalation: temp > -10.0°C escalates to critical severity',
      () {
        expect(
          TemperatureExcursionSeverity.fromTemperature(-18.0),
          TemperatureExcursionSeverity.nominal,
        );
        expect(
          TemperatureExcursionSeverity.fromTemperature(-13.5),
          TemperatureExcursionSeverity.warning,
        );
        expect(
          TemperatureExcursionSeverity.fromTemperature(-7.2),
          TemperatureExcursionSeverity.critical,
        );
      },
    );

    test('recordReading creates new active excursion when temp > -15.0°C and closes it when temp <= -15.0°C', () async {
      final start = DateTime(2026, 11, 18, 12, 0);
      await cubit.recordReading(
        vehicleId: 'VH-999',
        vehicleName: 'New Cold Van',
        routeId: 'RT-999',
        tempC: -11.5,
        timestamp: start,
      );

      expect(
        cubit.state.excursions.any(
          (e) => e.vehicleId == 'VH-999' && e.isActive,
        ),
        isTrue,
      );

      // Temperature normalizes 10 minutes later
      final end = start.add(const Duration(minutes: 10));
      await cubit.recordReading(
        vehicleId: 'VH-999',
        vehicleName: 'New Cold Van',
        routeId: 'RT-999',
        tempC: -18.5,
        timestamp: end,
      );

      final closed = cubit.state.excursions.firstWhere(
        (e) => e.vehicleId == 'VH-999',
      );
      expect(closed.isActive, isFalse);
      expect(closed.durationSeconds, 600);
      expect(closed.isThresholdBreached, isTrue);
    });

    test('acknowledgeExcursion updates notes and status in state', () async {
      await cubit.loadExcursions();
      await cubit.acknowledgeExcursion(
        excursionId: 'EXC-001',
        auditorNotes: 'Thermostat recalibrated and freon pressure checked.',
      );

      final updated = cubit.state.excursions.firstWhere(
        (e) => e.id == 'EXC-001',
      );
      expect(updated.isAcknowledged, isTrue);
      expect(updated.notes, contains('Thermostat recalibrated'));
      expect(cubit.state.successMessage, contains('acknowledged'));
    });

    test(
      'exportAuditCsv produces RFC 4180 compliant CSV header and data rows',
      () async {
        final csv = await cubit.exportAuditCsv();

        expect(
          csv,
          contains(
            'Excursion ID,Vehicle ID,Vehicle Name,Route ID,Peak Temp (°C)',
          ),
        );
        expect(csv, contains('EXC-001,VH-105,"ThermoKing Reefer Express"'));
        expect(csv, contains('EXC-002,VH-102,"Scania R500 Pharma Cold-Chain"'));
        expect(cubit.state.exportedCsv, isNotNull);
      },
    );

    test('Defensively handles repository exceptions on load', () async {
      mockRepo.shouldThrow = true;
      await cubit.loadExcursions();

      expect(cubit.state.status, ColdChainStatus.error);
      expect(
        cubit.state.errorMessage,
        contains('Failed to load cold-chain excursions'),
      );
    });
  });
}
