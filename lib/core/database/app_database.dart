import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../constants/app_constants.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      path = p.join(dbFolder.path, filePath);
    }

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        plate_number TEXT NOT NULL,
        type TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        driver_avatar TEXT NOT NULL,
        current_lat REAL NOT NULL,
        current_lng REAL NOT NULL,
        speed_kmh REAL NOT NULL,
        heading_deg REAL NOT NULL,
        fuel_level REAL NOT NULL,
        battery_soc REAL NOT NULL,
        cargo_temp_c REAL NOT NULL,
        target_temp_c REAL NOT NULL,
        status TEXT NOT NULL,
        assigned_route_id TEXT NOT NULL,
        route_completion_pct REAL NOT NULL,
        has_active_dtc INTEGER NOT NULL,
        tire_pressure_fl REAL NOT NULL,
        tire_pressure_fr REAL NOT NULL,
        tire_pressure_rl REAL NOT NULL,
        tire_pressure_rr REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        vehicle_id TEXT NOT NULL,
        origin_name TEXT NOT NULL,
        origin_lat REAL NOT NULL,
        origin_lng REAL NOT NULL,
        destination_name TEXT NOT NULL,
        destination_lat REAL NOT NULL,
        destination_lng REAL NOT NULL,
        total_distance_km REAL NOT NULL,
        optimized_distance_km REAL NOT NULL,
        fuel_saved_liters REAL NOT NULL,
        minutes_saved INTEGER NOT NULL,
        is_optimized INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE waybill_stops (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        sequence_order INTEGER NOT NULL,
        stop_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        cargo_description TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        recipient_name TEXT,
        recipient_signature_svg TEXT,
        delivered_at TEXT,
        exception_reason TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dtc_faults (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        code TEXT NOT NULL,
        title TEXT NOT NULL,
        severity TEXT NOT NULL,
        system TEXT NOT NULL,
        status TEXT NOT NULL,
        logged_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_dispatch_logs (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await seedInitialData(db);
  }

  Future<void> seedInitialData(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM vehicles'),
    );
    if (count != null && count > 0) return;

    // 12 Fleet Vehicles across Lahore Freight Network
    final initialVehicles = [
      {
        'id': 'VH-101',
        'name': 'Volvo FH16 Globetrotter',
        'plate_number': 'LHR-8842',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Tariq Mehmood',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.4820,
        'current_lng': 74.2980,
        'speed_kmh': 68.5,
        'heading_deg': 45.0,
        'fuel_level': 74.0,
        'battery_soc': 94.0,
        'cargo_temp_c': 21.0,
        'target_temp_c': 20.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-201',
        'route_completion_pct': 42.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 34.2,
        'tire_pressure_fr': 34.0,
        'tire_pressure_rl': 35.8,
        'tire_pressure_rr': 35.5,
      },
      {
        'id': 'VH-102',
        'name': 'Scania R500 Pharma Cold-Chain',
        'plate_number': 'LHR-5120',
        'type': 'COLD_CHAIN_VAN',
        'driver_name': 'Rashid Qureshi',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.5497,
        'current_lng': 74.3436,
        'speed_kmh': 54.0,
        'heading_deg': 120.0,
        'fuel_level': 61.5,
        'battery_soc': 88.0,
        'cargo_temp_c': -18.4,
        'target_temp_c': -20.0,
        'status': 'COLD_CHAIN_TRANSIT',
        'assigned_route_id': 'RT-202',
        'route_completion_pct': 68.0,
        'has_active_dtc': 1,
        'tire_pressure_fl': 32.8,
        'tire_pressure_fr': 33.1,
        'tire_pressure_rl': 34.5,
        'tire_pressure_rr': 34.2,
      },
      {
        'id': 'VH-103',
        'name': 'Mercedes Actros 2645 Heavy',
        'plate_number': 'ICT-9912',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Zahid Bilal',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.4280,
        'current_lng': 74.2250,
        'speed_kmh': 72.0,
        'heading_deg': 210.0,
        'fuel_level': 82.0,
        'battery_soc': 96.0,
        'cargo_temp_c': 24.0,
        'target_temp_c': 25.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-203',
        'route_completion_pct': 30.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 35.0,
        'tire_pressure_fr': 35.0,
        'tire_pressure_rl': 36.2,
        'tire_pressure_rr': 36.0,
      },
      {
        'id': 'VH-104',
        'name': 'BYD T9 Electric Express',
        'plate_number': 'LHR-3041',
        'type': 'ELECTRIC_COURIER',
        'driver_name': 'Kamran Akram',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.5204,
        'current_lng': 74.3587,
        'speed_kmh': 42.0,
        'heading_deg': 340.0,
        'fuel_level': 100.0,
        'battery_soc': 79.5,
        'cargo_temp_c': 22.0,
        'target_temp_c': 22.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-204',
        'route_completion_pct': 85.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 33.5,
        'tire_pressure_fr': 33.5,
        'tire_pressure_rl': 34.0,
        'tire_pressure_rr': 34.0,
      },
      {
        'id': 'VH-105',
        'name': 'ThermoKing Reefer Express',
        'plate_number': 'KHI-7721',
        'type': 'COLD_CHAIN_VAN',
        'driver_name': 'Imran Farooq',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.5710,
        'current_lng': 74.3120,
        'speed_kmh': 12.0,
        'heading_deg': 90.0,
        'fuel_level': 45.0,
        'battery_soc': 82.0,
        'cargo_temp_c': -12.1,
        'target_temp_c': -18.0,
        'status': 'DELAYED',
        'assigned_route_id': 'RT-205',
        'route_completion_pct': 55.0,
        'has_active_dtc': 1,
        'tire_pressure_fl': 31.0,
        'tire_pressure_fr': 31.2,
        'tire_pressure_rl': 33.0,
        'tire_pressure_rr': 32.8,
      },
      {
        'id': 'VH-106',
        'name': 'Isuzu Forward FTR 850',
        'plate_number': 'LHR-1988',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Nawaz Shah',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.4700,
        'current_lng': 74.2720,
        'speed_kmh': 0.0,
        'heading_deg': 0.0,
        'fuel_level': 95.0,
        'battery_soc': 98.0,
        'cargo_temp_c': 20.0,
        'target_temp_c': 20.0,
        'status': 'IDLE_DEPOT',
        'assigned_route_id': 'RT-206',
        'route_completion_pct': 0.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 34.0,
        'tire_pressure_fr': 34.0,
        'tire_pressure_rl': 35.0,
        'tire_pressure_rr': 35.0,
      },
      {
        'id': 'VH-107',
        'name': 'Hino 500 Series Heavy Hauler',
        'plate_number': 'FSD-4389',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Saeed Anwar',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.3910,
        'current_lng': 74.1950,
        'speed_kmh': 62.0,
        'heading_deg': 180.0,
        'fuel_level': 53.0,
        'battery_soc': 91.0,
        'cargo_temp_c': 22.5,
        'target_temp_c': 20.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-207',
        'route_completion_pct': 25.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 34.5,
        'tire_pressure_fr': 34.5,
        'tire_pressure_rl': 35.2,
        'tire_pressure_rr': 35.0,
      },
      {
        'id': 'VH-108',
        'name': 'MAN TGX 18.500 EfficientLine',
        'plate_number': 'LHR-6119',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Waqas Bhatti',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.6150,
        'current_lng': 74.2850,
        'speed_kmh': 75.0,
        'heading_deg': 315.0,
        'fuel_level': 68.0,
        'battery_soc': 95.0,
        'cargo_temp_c': 19.5,
        'target_temp_c': 20.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-208',
        'route_completion_pct': 70.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 34.0,
        'tire_pressure_fr': 34.1,
        'tire_pressure_rl': 35.5,
        'tire_pressure_rr': 35.5,
      },
      {
        'id': 'VH-109',
        'name': 'Foton eAumark Electric City',
        'plate_number': 'LHR-7290',
        'type': 'ELECTRIC_COURIER',
        'driver_name': 'Bilal Siddiqui',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.4680,
        'current_lng': 74.3850,
        'speed_kmh': 38.0,
        'heading_deg': 90.0,
        'fuel_level': 100.0,
        'battery_soc': 64.0,
        'cargo_temp_c': 21.0,
        'target_temp_c': 21.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-209',
        'route_completion_pct': 90.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 33.2,
        'tire_pressure_fr': 33.0,
        'tire_pressure_rl': 34.0,
        'tire_pressure_rr': 34.1,
      },
      {
        'id': 'VH-110',
        'name': 'Carrier Transicold Transit Van',
        'plate_number': 'RWP-2108',
        'type': 'COLD_CHAIN_VAN',
        'driver_name': 'Asif Javed',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.5050,
        'current_lng': 74.3210,
        'speed_kmh': 49.0,
        'heading_deg': 270.0,
        'fuel_level': 58.0,
        'battery_soc': 89.0,
        'cargo_temp_c': -21.0,
        'target_temp_c': -20.0,
        'status': 'COLD_CHAIN_TRANSIT',
        'assigned_route_id': 'RT-210',
        'route_completion_pct': 50.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 33.8,
        'tire_pressure_fr': 33.9,
        'tire_pressure_rl': 34.7,
        'tire_pressure_rr': 34.5,
      },
      {
        'id': 'VH-111',
        'name': 'JAC N-Series Heavy Cargo',
        'plate_number': 'LHR-9011',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Hamza Sheikh',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.4720,
        'current_lng': 74.2750,
        'speed_kmh': 0.0,
        'heading_deg': 0.0,
        'fuel_level': 88.0,
        'battery_soc': 96.0,
        'cargo_temp_c': 20.0,
        'target_temp_c': 20.0,
        'status': 'IDLE_DEPOT',
        'assigned_route_id': 'RT-211',
        'route_completion_pct': 0.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 34.0,
        'tire_pressure_fr': 34.0,
        'tire_pressure_rl': 35.0,
        'tire_pressure_rr': 35.0,
      },
      {
        'id': 'VH-112',
        'name': 'DAF XF 480 Super Space',
        'plate_number': 'LHR-4433',
        'type': 'SEMI_TRUCK',
        'driver_name': 'Zulqarnain Haider',
        'driver_avatar': 'assets/images/driver_avatar.png',
        'current_lat': 31.5920,
        'current_lng': 74.4210,
        'speed_kmh': 64.0,
        'heading_deg': 40.0,
        'fuel_level': 77.0,
        'battery_soc': 93.0,
        'cargo_temp_c': 23.0,
        'target_temp_c': 20.0,
        'status': 'IN_TRANSIT',
        'assigned_route_id': 'RT-212',
        'route_completion_pct': 60.0,
        'has_active_dtc': 0,
        'tire_pressure_fl': 34.2,
        'tire_pressure_fr': 34.2,
        'tire_pressure_rl': 35.6,
        'tire_pressure_rr': 35.4,
      },
    ];

    for (final v in initialVehicles) {
      await db.insert('vehicles', v);
    }

    // Initial Primary Route (RT-201)
    await db.insert('routes', {
      'id': 'RT-201',
      'name': 'Lahore Freight Trunk Corridor Alpha',
      'vehicle_id': 'VH-101',
      'origin_name': 'Thokar Logistics Depot',
      'origin_lat': 31.4700,
      'origin_lng': 74.2720,
      'destination_name': 'Sundar Freight Terminal',
      'destination_lat': 31.2820,
      'destination_lng': 74.1750,
      'total_distance_km': 48.6,
      'optimized_distance_km': 39.2,
      'fuel_saved_liters': 3.8,
      'minutes_saved': 24,
      'is_optimized': 1,
      'status': 'ACTIVE',
    });

    // Initial Waybill Stops for RT-201
    final initialStops = [
      {
        'id': 'WB-7001',
        'route_id': 'RT-201',
        'sequence_order': 1,
        'stop_name': 'Multan Road Logistics Depot',
        'latitude': 31.4700,
        'longitude': 74.2720,
        'cargo_description': 'High-Density Pallet Freight',
        'weight_kg': 4200.0,
        'priority': 'SCHEDULED_FREIGHT',
        'status': 'DELIVERED',
        'recipient_name': 'Asim Jamil (Depot Supv)',
        'recipient_signature_svg': 'M 10 50 Q 50 10 90 50 T 170 50',
        'delivered_at': '2026-11-14 14:30:00',
        'exception_reason': null,
      },
      {
        'id': 'WB-7002',
        'route_id': 'RT-201',
        'sequence_order': 2,
        'stop_name': 'Gulberg Commercial Distribution Hub',
        'latitude': 31.5150,
        'longitude': 74.3450,
        'cargo_description': 'Insulated Biologics & Vaccines',
        'weight_kg': 650.0,
        'priority': 'URGENT_COLD_CHAIN',
        'status': 'OUT_FOR_DELIVERY',
        'recipient_name': null,
        'recipient_signature_svg': null,
        'delivered_at': null,
        'exception_reason': null,
      },
      {
        'id': 'WB-7003',
        'route_id': 'RT-201',
        'sequence_order': 3,
        'stop_name': 'Kot Lakhpat Industrial Park',
        'latitude': 31.4420,
        'longitude': 74.3310,
        'cargo_description': 'Precision Electronic Components',
        'weight_kg': 1200.0,
        'priority': 'STANDARD_PARCEL',
        'status': 'PENDING',
        'recipient_name': null,
        'recipient_signature_svg': null,
        'delivered_at': null,
        'exception_reason': null,
      },
      {
        'id': 'WB-7004',
        'route_id': 'RT-201',
        'sequence_order': 4,
        'stop_name': 'Sundar Industrial Estate Terminal',
        'latitude': 31.2820,
        'longitude': 74.1750,
        'cargo_description': 'Industrial Machinery Spares',
        'weight_kg': 3100.0,
        'priority': 'SCHEDULED_FREIGHT',
        'status': 'PENDING',
        'recipient_name': null,
        'recipient_signature_svg': null,
        'delivered_at': null,
        'exception_reason': null,
      },
      {
        'id': 'WB-7005',
        'route_id': 'RT-201',
        'sequence_order': 5,
        'stop_name': 'Raiwind Regional Distribution Center',
        'latitude': 31.2480,
        'longitude': 74.2150,
        'cargo_description': 'Cold-Chain Dairy Consignments',
        'weight_kg': 1850.0,
        'priority': 'URGENT_COLD_CHAIN',
        'status': 'EXCEPTION',
        'recipient_name': null,
        'recipient_signature_svg': null,
        'delivered_at': null,
        'exception_reason': 'Geofence Traffic Bottleneck on Canal Expressway',
      },
    ];

    for (final s in initialStops) {
      await db.insert('waybill_stops', s);
    }

    // Initial DTC Faults
    final initialDtc = [
      {
        'id': 'DTC-01',
        'vehicle_id': 'VH-102',
        'code': 'P0128',
        'title': 'Coolant Thermostat Below Regulating Temp',
        'severity': 'WARNING',
        'system': 'Powertrain Engine Cooling',
        'status': 'ACTIVE',
        'logged_at': '2026-11-14 11:20:15',
      },
      {
        'id': 'DTC-02',
        'vehicle_id': 'VH-102',
        'code': 'C0034',
        'title': 'Right Front Wheel Speed Sensor Range Performance',
        'severity': 'WARNING',
        'system': 'Chassis Anti-Lock Braking',
        'status': 'ACTIVE',
        'logged_at': '2026-11-14 11:22:40',
      },
      {
        'id': 'DTC-03',
        'vehicle_id': 'VH-105',
        'code': 'P0534',
        'title': 'Air Conditioner Refrigerant Charge Loss / Reefer Excursion',
        'severity': 'CRITICAL',
        'system': 'Auxiliary Cold-Chain Reefer',
        'status': 'ACTIVE',
        'logged_at': '2026-11-14 12:45:10',
      },
      {
        'id': 'DTC-04',
        'vehicle_id': 'VH-101',
        'code': 'P0420',
        'title': 'Catalyst System Efficiency Below Threshold',
        'severity': 'INFO',
        'system': 'Exhaust Emission Control',
        'status': 'CLEARED',
        'logged_at': '2026-11-13 18:00:00',
      },
    ];

    for (final d in initialDtc) {
      await db.insert('dtc_faults', d);
    }

    // Initial AI Assistant conversation logs
    await db.insert('ai_dispatch_logs', {
      'id': 'MSG-001',
      'role': 'assistant',
      'content': 'FleetRoute On-Device AI Dispatch Copilot initialized. All 12 fleet telematics streams, cold-chain monitors, and OBD-II CAN-bus interfaces are online. How can I assist dispatch operations today?',
      'timestamp': '2026-11-14 14:00:00',
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
