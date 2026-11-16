import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection_container.dart';
import '../../core/utils/app_feedback.dart';
import '../connectivity/connectivity_cubit.dart';
import '../map_command/bloc/fleet_map_bloc.dart';
import '../map_command/bloc/fleet_map_event.dart';
import '../obd_diagnostics/bloc/obd_diagnostics_bloc.dart';
import '../obd_diagnostics/bloc/obd_diagnostics_event.dart';
import '../theme/theme_cubit.dart';
import '../hos/driver_hos_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _openRecruiterDebugDrawer(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return const _RecruiterDebugDrawer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeCubit = context.watch<ThemeCubit>();
    final isDark = themeCubit.state == ThemeMode.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Fleet Command Settings',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INTERFACE & APPEARANCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SwitchListTile(
                title: Text(
                  'Obsidian Logistics Dark Mode',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  isDark
                      ? 'Deep Obsidian #0B132B with Emerald & Cyan Accents'
                      : 'Crisp Daylight Logistics High-Contrast Theme',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: isDark,
                activeColor: colorScheme.primary,
                onChanged: (_) {
                  themeCubit.toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DRIVER COMPLIANCE & SAFETY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(Icons.timer_outlined, color: colorScheme.primary),
                title: Text(
                  'Driver Hours of Service (HOS) & Rest Plazas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'FMCSA 49 CFR § 395 Fatigue Tracking, 30-min break alerts, and nearest freight rest stops',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DriverHosView()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'OFFLINE SYNCHRONIZATION & STORAGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Local Spatial Database',
                    'SQLite (fleetroute_enterprise.db)',
                    colorScheme,
                  ),
                  const Divider(height: 14),
                  _buildStatRow(
                    'Active Corridors',
                    'Lahore Ring Road & M2 Freight Corridor',
                    colorScheme,
                  ),
                  const Divider(height: 14),
                  _buildStatRow(
                    'CAN-bus Telemetry Protocol',
                    'ISO 15765-4 CAN / J1939 Heavy Duty',
                    colorScheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onLongPress: () {
                      _openRecruiterDebugDrawer(context, colorScheme);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FleetRoute ${AppConstants.appVersion} (Long-press for Debug Drawer)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Architect: Safeer Hussain • Enterprise Logistics Platform',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RecruiterDebugDrawer extends StatefulWidget {
  const _RecruiterDebugDrawer();

  @override
  State<_RecruiterDebugDrawer> createState() => _RecruiterDebugDrawerState();
}

class _RecruiterDebugDrawerState extends State<_RecruiterDebugDrawer> {
  late SharedPreferences _prefs;
  bool _force503 = false;
  int _simLatency = 600;

  @override
  void initState() {
    super.initState();
    _prefs = sl<SharedPreferences>();
    _force503 = _prefs.getBool(AppConstants.prefForceHttp503) ?? false;
    _simLatency = _prefs.getInt(AppConstants.prefSimulatedLatency) ?? 600;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connCubit = context.watch<ConnectivityCubit>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recruiter & QA Diagnostic Drawer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text(
                  'Simulate Offline Field Mode',
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: const Text(
                  'Forces offline SQLite buffering banner',
                  style: TextStyle(fontSize: 10),
                ),
                value: connCubit.state.isSimulatedOffline,
                onChanged: (_) {
                  connCubit.toggleSimulatedOffline();
                },
              ),
              SwitchListTile(
                title: const Text(
                  'Force Cloud Gateway HTTP 503',
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: const Text(
                  'Simulates 503 error retry views on mock interceptor',
                  style: TextStyle(fontSize: 10),
                ),
                value: _force503,
                onChanged: (val) {
                  setState(() => _force503 = val);
                  _prefs.setBool(AppConstants.prefForceHttp503, val);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Simulated API Latency: $_simLatency ms',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Slider(
                value: _simLatency.toDouble(),
                min: 0,
                max: 2000,
                divisions: 8,
                label: '$_simLatency ms',
                activeColor: colorScheme.primary,
                onChanged: (val) {
                  setState(() => _simLatency = val.toInt());
                  _prefs.setInt(AppConstants.prefSimulatedLatency, val.toInt());
                },
              ),
              const Divider(height: 16),
              Text(
                'FIELD SIMULATION INJECTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.warning, size: 14),
                      label: const Text(
                        'Inject Geofence Breach',
                        style: TextStyle(fontSize: 10),
                      ),
                      onPressed: () {
                        context.read<FleetMapBloc>().add(
                          const InjectGeofenceBreachEvent('VH-105'),
                        );
                        Navigator.of(context).pop();
                        AppFeedback.showWarning(
                          context,
                          'Simulated Geofence Breach injected for VH-105.',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.minor_crash, size: 14),
                      label: const Text(
                        'Inject DTC Engine Code',
                        style: TextStyle(fontSize: 10),
                      ),
                      onPressed: () {
                        context.read<ObdDiagnosticsBloc>().add(
                          const RunDtcScanEvent('VH-102'),
                        );
                        Navigator.of(context).pop();
                        AppFeedback.showWarning(
                          context,
                          'DTC Trouble Code injected onto CAN-bus.',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
