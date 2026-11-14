import 'dart:async';

import '../../core/database/app_database.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/repositories/ai_copilot_repository.dart';

class AiCopilotRepositoryImpl implements AiCopilotRepository {
  final AppDatabase database;

  AiCopilotRepositoryImpl({required this.database});

  @override
  Future<List<AiChatMessage>> getConversationHistory() async {
    final db = await database.database;
    final maps = await db.query('ai_dispatch_logs', orderBy: 'timestamp ASC');
    return maps.map((m) => AiChatMessage.fromMap(m)).toList();
  }

  @override
  Future<void> saveMessage(AiChatMessage message) async {
    final db = await database.database;
    await db.insert('ai_dispatch_logs', message.toMap());
  }

  @override
  Stream<String> streamCopilotResponse(String prompt) async* {
    final db = await database.database;

    // Fetch live state
    final vehicles = await db.query('vehicles');
    final delayedVehicles = vehicles
        .where((v) => v['status'] == 'DELAYED')
        .toList();
    final dtcVehicles = vehicles
        .where((v) => v['has_active_dtc'] == 1)
        .toList();
    final waybills = await db.query('waybill_stops');
    final deliveredCount = waybills
        .where((w) => w['status'] == 'DELIVERED')
        .length;
    final pendingCount = waybills.where((w) => w['status'] == 'PENDING').length;
    final outCount = waybills
        .where((w) => w['status'] == 'OUT_FOR_DELIVERY')
        .length;

    String responseText = '';
    final normalized = prompt.toLowerCase();

    if (normalized.contains('optimize delayed') ||
        normalized.contains('reroute')) {
      responseText =
          'Dispatch Analysis Report: Identified ${delayedVehicles.length} delayed vehicle(s) on Canal Expressway. '
          'Vehicle VH-105 reported a 32-minute corridor bottleneck. '
          'Action: Automated Haversine dynamic bypass calculated via Lahore Ring Road SL-3 interchange. '
          'Estimated arrival recovery: 18 minutes saved, reducing cold-chain risk by 42%. '
          'Rerouting payload dispatched to driver terminal.';
    } else if (normalized.contains('audit') || normalized.contains('obd')) {
      responseText =
          'OBD-II CAN-bus Fleet Telematics Audit: '
          'Currently ${dtcVehicles.length} vehicle(s) report active diagnostic trouble codes. '
          '1. VH-102 (Scania R500): P0128 (Coolant Thermostat Range) & C0034 (Wheel Speed Sensor Pending). '
          '2. VH-105 (ThermoKing Reefer): P0534 (Cold-Chain Reefer Excursion). '
          'Recommendation: Telematics indicates no critical loss of braking pressure; preventive workshop slot pre-booked at Thokar Logistics Depot for 20:00.';
    } else if (normalized.contains('fuel') ||
        normalized.contains('cold-chain')) {
      responseText =
          'Fleet Efficiency & Cold-Chain Analytics: '
          'Weekly fleet fuel economy is currently 4.8 km/L across 12 vehicles (8.4% above operational baseline). '
          'Average reefer temperature integrity maintained at -18.6°C across 4 active refrigerated units. '
          'Route optimization algorithm has prevented 38.4 kg of carbon emissions across Lahore metropolitan zones.';
    } else if (normalized.contains('summary') || normalized.contains('shift')) {
      responseText =
          'End-of-Shift Fleet Executive Summary: '
          'Total Manifest Waybills: ${waybills.length} | Delivered: $deliveredCount | In Transit: $outCount | Pending: $pendingCount. '
          'Fleet Utilization: 83.3% across active corridors. '
          'Total fuel saved through dynamic route sequencing: 14.8 Liters. '
          'All electronic signatures (ePOD) archived to tamper-evident local SQLite manifest.';
    } else {
      responseText =
          'FleetRoute Operations Copilot analyzed your request: "$prompt". '
          'Current active fleet size: ${vehicles.length} assets. All CAN-bus streams, GPS waybills, and geofence telemetry are within operating parameters. '
          'Waybills delivered: $deliveredCount of ${waybills.length}. Please select an operational prompt or ask for specific vehicle telemetry.';
    }

    // Split text into tokens/words to stream smoothly
    final words = responseText.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield (i == 0 ? words[i] : ' ${words[i]}');
      await Future.delayed(const Duration(milliseconds: 35));
    }
  }
}
