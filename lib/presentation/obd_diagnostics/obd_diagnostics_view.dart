import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/dtc_fault.dart';
import '../../domain/entities/obd_telemetry_packet.dart';
import 'bloc/obd_diagnostics_bloc.dart';
import 'bloc/obd_diagnostics_event.dart';
import 'bloc/obd_diagnostics_state.dart';

class ObdDiagnosticsView extends StatefulWidget {
  final String? initialVehicleId;

  const ObdDiagnosticsView({super.key, this.initialVehicleId});

  @override
  State<ObdDiagnosticsView> createState() => _ObdDiagnosticsViewState();
}

class _ObdDiagnosticsViewState extends State<ObdDiagnosticsView> {
  @override
  void initState() {
    super.initState();
    context.read<ObdDiagnosticsBloc>().add(InitializeObdEvent());
    if (widget.initialVehicleId != null) {
      context.read<ObdDiagnosticsBloc>().add(
        SelectObdVehicleEvent(widget.initialVehicleId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocConsumer<ObdDiagnosticsBloc, ObdDiagnosticsState>(
      listener: (context, state) {
        if (state.statusMessage != null) {
          AppFeedback.showInfo(context, state.statusMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_obd_scan_dtc',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: state.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.troubleshoot),
            label: Text(
              state.isScanning
                  ? 'Scanning CAN-bus...'
                  : 'Scan DTC Trouble Codes',
            ),
            onPressed: state.isScanning
                ? null
                : () {
                    context.read<ObdDiagnosticsBloc>().add(
                      RunDtcScanEvent(state.selectedVehicleId),
                    );
                  },
          ),
          body: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildVehicleSelector(context, state, colorScheme),
                            const SizedBox(height: 10),
                            _buildTelemetryGauges(
                              context,
                              state.latestTelemetry,
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTirePressureDiagram(
                              context,
                              state.latestTelemetry,
                              colorScheme,
                            ),
                            const SizedBox(height: 12),
                            _buildDtcScannerSection(
                              context,
                              state,
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleSelector(context, state, colorScheme),
                      const SizedBox(height: 12),
                      _buildTelemetryGauges(
                        context,
                        state.latestTelemetry,
                        colorScheme,
                      ),
                      const SizedBox(height: 14),
                      _buildTirePressureDiagram(
                        context,
                        state.latestTelemetry,
                        colorScheme,
                      ),
                      const SizedBox(height: 14),
                      _buildDtcScannerSection(context, state, colorScheme),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildVehicleSelector(
    BuildContext context,
    ObdDiagnosticsState state,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OBD-II CAN-Bus Node',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ISO 15765 CAN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: state.selectedVehicleId,
            isExpanded: true,
            dropdownColor: colorScheme.surfaceContainerHighest,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items:
                [
                  'VH-101',
                  'VH-102',
                  'VH-103',
                  'VH-104',
                  'VH-105',
                  'VH-106',
                  'VH-107',
                  'VH-108',
                  'VH-109',
                  'VH-110',
                  'VH-111',
                  'VH-112',
                ].map((id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Text(
                      'Asset $id (CAN-Bus Active)',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
            onChanged: (val) {
              if (val != null) {
                context.read<ObdDiagnosticsBloc>().add(
                  SelectObdVehicleEvent(val),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGauges(
    BuildContext context,
    ObdTelemetryPacket? packet,
    ColorScheme colorScheme,
  ) {
    final rpm = packet?.engineRpm ?? 1750;
    final speed = packet?.speedKmh ?? 68.5;
    final coolant = packet?.coolantTempC ?? 88.5;
    final fuel = packet?.fuelLevelPercent ?? 71.0;
    final cargoTemp = packet?.cargoTempC ?? -18.4;
    final soc = packet?.batterySocPercent ?? 94.0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      mainAxisExtent: 145, // Strictly avoid RenderFlex collapses
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildGaugeCard(
          title: 'Engine RPM',
          value: '$rpm',
          unit: 'RPM',
          icon: Icons.speed,
          progress: (rpm / 3000).clamp(0.0, 1.0),
          accentColor: rpm > 2400 ? colorScheme.error : colorScheme.primary,
          colorScheme: colorScheme,
        ),
        _buildGaugeCard(
          title: 'Road Speed',
          value: speed.toStringAsFixed(1),
          unit: 'km/h',
          icon: Icons.navigation,
          progress: (speed / 120).clamp(0.0, 1.0),
          accentColor: colorScheme.secondary,
          colorScheme: colorScheme,
        ),
        _buildGaugeCard(
          title: 'Coolant Temp',
          value: coolant.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.thermostat,
          progress: (coolant / 120).clamp(0.0, 1.0),
          accentColor: coolant > 98 ? colorScheme.error : colorScheme.primary,
          colorScheme: colorScheme,
        ),
        _buildGaugeCard(
          title: 'Fuel / Diesel Level',
          value: fuel.toStringAsFixed(0),
          unit: '%',
          icon: Icons.local_gas_station,
          progress: (fuel / 100).clamp(0.0, 1.0),
          accentColor: fuel < 20 ? colorScheme.error : colorScheme.tertiary,
          colorScheme: colorScheme,
        ),
        _buildGaugeCard(
          title: 'Cargo Cold-Chain',
          value: cargoTemp.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.ac_unit,
          progress: ((-cargoTemp) / 30).clamp(0.0, 1.0),
          accentColor: colorScheme.secondary,
          colorScheme: colorScheme,
        ),
        _buildGaugeCard(
          title: 'Auxiliary Battery SoC',
          value: soc.toStringAsFixed(0),
          unit: '%',
          icon: Icons.battery_charging_full,
          progress: (soc / 100).clamp(0.0, 1.0),
          accentColor: colorScheme.primary,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required double progress,
    required Color accentColor,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTirePressureDiagram(
    BuildContext context,
    ObdTelemetryPacket? packet,
    ColorScheme colorScheme,
  ) {
    final fl = packet?.tirePressureFl ?? 34.2;
    final fr = packet?.tirePressureFr ?? 34.0;
    final rl = packet?.tirePressureRl ?? 35.8;
    final rr = packet?.tirePressureRr ?? 35.5;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.tire_repair,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TPMS 4-Wheel Telemetry',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '32-36 PSI',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTireBadge('Front Left', fl, colorScheme),
              Container(
                width: 60,
                height: 70,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_shipping,
                    size: 28,
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                ),
              ),
              _buildTireBadge('Front Right', fr, colorScheme),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTireBadge('Rear Left', rl, colorScheme),
              const SizedBox(width: 60),
              _buildTireBadge('Rear Right', rr, colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTireBadge(String position, double psi, ColorScheme colorScheme) {
    final isNominal = psi >= 32.0 && psi <= 38.0;
    final color = isNominal ? colorScheme.primary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            '${psi.toStringAsFixed(1)} PSI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            position,
            style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildDtcScannerSection(
    BuildContext context,
    ObdDiagnosticsState state,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Active DTC Trouble Codes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state.activeFaults.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.cleaning_services, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    context.read<ObdDiagnosticsBloc>().add(
                      ClearDtcCodesEvent(state.selectedVehicleId),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.activeFaults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No active DTC trouble codes on CAN-bus.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.activeFaults.map(
              (f) => _buildFaultTile(context, f, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildFaultTile(
    BuildContext context,
    DtcFault f,
    ColorScheme colorScheme,
  ) {
    final isCritical = f.severity == 'CRITICAL';
    final isWarning = f.severity == 'WARNING';
    final badgeColor = isCritical
        ? colorScheme.error
        : (isWarning ? colorScheme.tertiary : colorScheme.primary);
    final isScheduled = f.status == 'SERVICE_SCHEDULED';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        f.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.system,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                f.status,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isScheduled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            f.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isScheduled && f.status != 'CLEARED')
                OutlinedButton.icon(
                  icon: const Icon(Icons.build_circle, size: 14),
                  label: const Text(
                    'Schedule Workshop Service',
                    style: TextStyle(fontSize: 10),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () {
                    context.read<ObdDiagnosticsBloc>().add(
                      ScheduleWorkshopServiceEvent(f.id),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
