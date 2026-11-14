import 'package:fleetroute_app/domain/entities/waybill_stop.dart';
import 'package:fleetroute_app/domain/repositories/epod_repository.dart';
import 'package:fleetroute_app/presentation/epod/bloc/epod_bloc.dart';
import 'package:fleetroute_app/presentation/epod/bloc/epod_event.dart';
import 'package:flutter_test/flutter_test.dart';

class MockEpodRepository implements EpodRepository {
  List<WaybillStop> waybills = [
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
      status: 'OUT_FOR_DELIVERY',
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
      status: 'DELIVERED',
      recipientName: 'Asim Jamil',
      recipientSignatureSvg: 'M 10 50 L 90 50',
      deliveredAt: '2026-11-14 14:00:00',
    ),
    const WaybillStop(
      id: 'WB-7005',
      routeId: 'RT-201',
      sequenceOrder: 5,
      stopName: 'Raiwind Regional Distribution Center',
      latitude: 31.2480,
      longitude: 74.2150,
      cargoDescription: 'Cold-Chain Dairy Consignments',
      weightKg: 1850.0,
      priority: 'URGENT_COLD_CHAIN',
      status: 'EXCEPTION',
      exceptionReason: 'Traffic bottleneck',
    ),
  ];

  @override
  Future<List<WaybillStop>> getAllWaybills() async => waybills;

  @override
  Future<List<WaybillStop>> getWaybillsByStatus(String status) async {
    if (status == 'ALL') return waybills;
    return waybills.where((w) => w.status == status).toList();
  }

  @override
  Future<void> confirmDelivery({
    required String waybillId,
    required String recipientName,
    required String signatureSvg,
  }) async {
    final idx = waybills.indexWhere((w) => w.id == waybillId);
    if (idx != -1) {
      waybills[idx] = waybills[idx].copyWith(
        status: 'DELIVERED',
        recipientName: recipientName,
        recipientSignatureSvg: signatureSvg,
        deliveredAt: '2026-11-14 17:00:00',
      );
    }
  }

  @override
  Future<void> logException({
    required String waybillId,
    required String reason,
  }) async {
    final idx = waybills.indexWhere((w) => w.id == waybillId);
    if (idx != -1) {
      waybills[idx] = waybills[idx].copyWith(
        status: 'EXCEPTION',
        exceptionReason: reason,
      );
    }
  }
}

void main() {
  group('EpodBloc Unit Tests', () {
    late MockEpodRepository repo;
    late EpodBloc bloc;

    setUp(() {
      repo = MockEpodRepository();
      bloc = EpodBloc(epodRepository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test(
      'Test 9: LoadWaybillsEvent loads all waybills and filters correctly',
      () async {
        bloc.add(LoadWaybillsEvent());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<dynamic>((s) => s.isLoading == true),
            predicate<dynamic>(
              (s) =>
                  s.isLoading == false &&
                  s.waybills.length == 3 &&
                  s.filteredWaybills.length == 3,
            ),
          ]),
        );

        bloc.add(const FilterWaybillsEvent('DELIVERED'));
        await expectLater(
          bloc.stream,
          emits(
            predicate<dynamic>(
              (s) =>
                  s.activeFilter == 'DELIVERED' &&
                  s.filteredWaybills.length == 1 &&
                  s.filteredWaybills.first.id == 'WB-7002',
            ),
          ),
        );
      },
    );

    test('Test 10: SearchWaybillsEvent filters by query string', () async {
      bloc.add(LoadWaybillsEvent());
      await bloc.stream.firstWhere(
        (s) => !s.isLoading && s.waybills.isNotEmpty,
      );

      bloc.add(const SearchWaybillsEvent('Biologics'));
      await expectLater(
        bloc.stream,
        emits(
          predicate<dynamic>(
            (s) =>
                s.searchQuery == 'Biologics' &&
                s.filteredWaybills.length == 1 &&
                s.filteredWaybills.first.id == 'WB-7002',
          ),
        ),
      );
    });

    test('Test 11: ConfirmDeliveryEvent mutates status to DELIVERED and attaches signature', () async {
      bloc.add(LoadWaybillsEvent());
      await bloc.stream.firstWhere(
        (s) => !s.isLoading && s.waybills.isNotEmpty,
      );

      bloc.add(
        const ConfirmDeliveryEvent(
          waybillId: 'WB-7001',
          recipientName: 'Haris Mahmood',
          signatureSvg: 'M 10 20 L 50 60',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isSubmitting == true),
          predicate<dynamic>(
            (s) =>
                s.isSubmitting == false &&
                s.lastDeliveredWaybill?.id == 'WB-7001' &&
                s.lastDeliveredWaybill?.recipientName == 'Haris Mahmood' &&
                s.lastDeliveredWaybill?.status == 'DELIVERED',
          ),
        ]),
      );
    });

    test('Test 12: LogExceptionEvent updates status to EXCEPTION', () async {
      bloc.add(LoadWaybillsEvent());
      await bloc.stream.firstWhere(
        (s) => !s.isLoading && s.waybills.isNotEmpty,
      );

      bloc.add(
        const LogExceptionEvent(
          waybillId: 'WB-7001',
          reason: 'Consignee warehouse closed',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((s) => s.isSubmitting == true),
          predicate<dynamic>(
            (s) =>
                s.isSubmitting == false &&
                s.statusMessage != null &&
                s.statusMessage!.contains('Exception'),
          ),
        ]),
      );
    });
  });
}
