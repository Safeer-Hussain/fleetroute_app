import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_feedback.dart';
import '../../domain/entities/vehicle.dart';
import 'bloc/fleet_map_bloc.dart';
import 'bloc/fleet_map_event.dart';
import 'bloc/fleet_map_state.dart';

class FleetMapCommandView extends StatefulWidget {
  final void Function(int tabIndex, {String? targetVehicleId})? onNavigateTab;

  const FleetMapCommandView({super.key, this.onNavigateTab});

  @override
  State<FleetMapCommandView> createState() => _FleetMapCommandViewState();
}

class _FleetMapCommandViewState extends State<FleetMapCommandView> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    context.read<FleetMapBloc>().add(LoadFleetMapEvent());
  }

  void _recenterMap() {
    _mapController.move(
      const LatLng(AppConstants.defaultLat, AppConstants.defaultLng),
      AppConstants.defaultZoom,
    );
  }

  void _focusVehicle(Vehicle v) {
    _mapController.move(LatLng(v.currentLat, v.currentLng), 13.5);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocConsumer<FleetMapBloc, FleetMapState>(
      listener: (context, state) {
        if (state.geofenceAlert != null) {
          AppFeedback.showWarning(context, state.geofenceAlert!);
          context.read<FleetMapBloc>().add(ClearGeofenceAlertEvent());
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.vehicles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (isLandscape) {
          return Row(
            children: [
              Expanded(
                flex: 6,
                child: _buildMapCanvas(context, state, colorScheme, true),
              ),
              VerticalDivider(width: 1, color: colorScheme.outlineVariant),
              Expanded(
                flex: 4,
                child: _buildLandscapeDetailPane(context, state, colorScheme),
              ),
            ],
          );
        }

        return Stack(
          children: [
            _buildMapCanvas(context, state, colorScheme, false),
            // Filter chip row at top
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildFilterChips(context, state, colorScheme),
            ),
            // Selected vehicle card at bottom
            if (state.selectedVehicle != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: _buildVehicleTelemetryCard(
                  context,
                  state.selectedVehicle!,
                  colorScheme,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMapCanvas(
    BuildContext context,
    FleetMapState state,
    ColorScheme colorScheme,
    bool isLandscape,
  ) {
    final depotCoord = const LatLng(
      AppConstants.depotLat,
      AppConstants.depotLng,
    );

    // Build markers for vehicles
    final markers = state.filteredVehicles.map((v) {
      final isSelected = state.selectedVehicle?.id == v.id;
      final markerColor = _getVehicleColor(v.status, colorScheme);

      return Marker(
        point: LatLng(v.currentLat, v.currentLng),
        width: isSelected ? 48 : 38,
        height: isSelected ? 48 : 38,
        child: GestureDetector(
          onTap: () {
            context.read<FleetMapBloc>().add(SelectVehicleEvent(v.id));
            _focusVehicle(v);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colorScheme.onSurface : colorScheme.surface,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(0.4),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 3 : 1,
                ),
              ],
            ),
            child: Icon(
              _getVehicleIcon(v.type),
              size: isSelected ? 22 : 18,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }).toList();

    // Primary Logistics Depot Marker
    final depotMarker = Marker(
      point: depotCoord,
      width: 44,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.primary, width: 2),
        ),
        child: Icon(
          Icons.warehouse_outlined,
          color: colorScheme.primary,
          size: 22,
        ),
      ),
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(
              AppConstants.defaultLat,
              AppConstants.defaultLng,
            ),
            initialZoom: AppConstants.defaultZoom,
            minZoom: 9.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.safeer.fleetroute',
            ),
            // Geofence Circle around Logistics Depot
            CircleLayer(
              circles: [
                CircleMarker(
                  point: depotCoord,
                  radius: AppConstants.geofenceRadiusKm * 1000,
                  useRadiusInMeter: true,
                  color: colorScheme.primary.withOpacity(0.08),
                  borderColor: colorScheme.primary.withOpacity(0.6),
                  borderStrokeWidth: 1.8,
                ),
              ],
            ),
            MarkerLayer(markers: [...markers, depotMarker]),
          ],
        ),

        // Map Control Floating Action Buttons with UNIQUE HERO TAGS
        Positioned(
          right: 14,
          top: isLandscape ? 12 : 64,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_fleet_map_recenter',
                backgroundColor: colorScheme.surfaceContainer,
                foregroundColor: colorScheme.onSurface,
                onPressed: _recenterMap,
                child: const Icon(Icons.my_location, size: 18),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'fab_fleet_map_simulate',
                backgroundColor: state.isSimulating
                    ? colorScheme.primary
                    : colorScheme.surfaceContainer,
                foregroundColor: state.isSimulating
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                onPressed: () {
                  context.read<FleetMapBloc>().add(
                    ToggleFleetSimulationEvent(),
                  );
                },
                child: Icon(
                  state.isSimulating ? Icons.pause : Icons.play_arrow,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    FleetMapState state,
    ColorScheme colorScheme,
  ) {
    final filters = [
      {'key': 'ALL', 'label': 'All (${state.vehicles.length})'},
      {
        'key': 'IN_TRANSIT',
        'label':
            'Transit (${state.vehicles.where((v) => v.status == 'IN_TRANSIT').length})',
      },
      {
        'key': 'COLD_CHAIN',
        'label':
            'Cold-Chain (${state.vehicles.where((v) => v.status == 'COLD_CHAIN_TRANSIT').length})',
      },
      {
        'key': 'DELAYED',
        'label':
            'Delayed (${state.vehicles.where((v) => v.status == 'DELAYED').length})',
      },
      {
        'key': 'IDLE_DEPOT',
        'label':
            'Depot (${state.vehicles.where((v) => v.status == 'IDLE_DEPOT').length})',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = state.activeFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                f['label']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainer.withOpacity(0.92),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              onSelected: (_) {
                context.read<FleetMapBloc>().add(
                  FilterVehiclesEvent(f['key']!),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehicleTelemetryCard(
    BuildContext context,
    Vehicle v,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.surface.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  _getVehicleIcon(v.type),
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${v.id} • ${v.plateNumber} • Driver: ${v.driverName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(v.status, colorScheme),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  context.read<FleetMapBloc>().add(ClearSelectedVehicleEvent());
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                'Speed',
                '${v.speedKmh.toStringAsFixed(1)} km/h',
                colorScheme,
              ),
              _buildMiniMetric(
                'Cargo Temp',
                '${v.cargoTempC.toStringAsFixed(1)} °C',
                colorScheme,
                isWarning: v.type == 'COLD_CHAIN_VAN' && v.cargoTempC > -15.0,
              ),
              _buildMiniMetric(
                v.type == 'ELECTRIC_COURIER' ? 'Battery SoC' : 'Fuel',
                '${(v.type == 'ELECTRIC_COURIER' ? v.batterySoc : v.fuelLevel).toStringAsFixed(0)}%',
                colorScheme,
              ),
              _buildMiniMetric(
                'Route Done',
                '${v.routeCompletionPct.toStringAsFixed(0)}%',
                colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.alt_route, size: 16),
                  label: const Text(
                    'Optimize Route',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    widget.onNavigateTab?.call(1, targetVehicleId: v.id);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.speed, size: 16),
                  label: const Text(
                    'Inspect OBD-II',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    widget.onNavigateTab?.call(3, targetVehicleId: v.id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeDetailPane(
    BuildContext context,
    FleetMapState state,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      controller: ScrollController(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fleet Telematics Radar',
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
          const SizedBox(height: 8),
          _buildFilterChips(context, state, colorScheme),
          const SizedBox(height: 8),
          if (state.selectedVehicle != null) ...[
            _buildVehicleTelemetryCard(
              context,
              state.selectedVehicle!,
              colorScheme,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Active Corridor Assets (${state.filteredVehicles.length})',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ...state.filteredVehicles.map((v) {
            final isSelected = state.selectedVehicle?.id == v.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _getVehicleColor(v.status, colorScheme),
                  child: Icon(
                    _getVehicleIcon(v.type),
                    size: 14,
                    color: colorScheme.onPrimary,
                  ),
                ),
                title: Text(
                  '${v.id} • ${v.name}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${v.speedKmh.toStringAsFixed(0)} km/h • ${v.driverName}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: _buildStatusBadge(v.status, colorScheme),
                onTap: () {
                  context.read<FleetMapBloc>().add(SelectVehicleEvent(v.id));
                  _focusVehicle(v);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool isWarning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isWarning ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color bg = colorScheme.surfaceContainerHighest;
    Color fg = colorScheme.onSurface;

    if (status == 'IN_TRANSIT') {
      bg = colorScheme.primary.withOpacity(0.18);
      fg = colorScheme.primary;
    } else if (status == 'COLD_CHAIN_TRANSIT') {
      bg = colorScheme.secondary.withOpacity(0.18);
      fg = colorScheme.secondary;
    } else if (status == 'DELAYED') {
      bg = colorScheme.error.withOpacity(0.18);
      fg = colorScheme.error;
    } else if (status == 'IDLE_DEPOT') {
      bg = colorScheme.surfaceContainerHighest;
      fg = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Color _getVehicleColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'IN_TRANSIT':
        return colorScheme.primary;
      case 'COLD_CHAIN_TRANSIT':
        return colorScheme.secondary;
      case 'DELAYED':
        return colorScheme.error;
      case 'IDLE_DEPOT':
      default:
        return colorScheme.outline;
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'COLD_CHAIN_VAN':
        return Icons.ac_unit;
      case 'ELECTRIC_COURIER':
        return Icons.electric_bolt;
      case 'SEMI_TRUCK':
      default:
        return Icons.local_shipping;
    }
  }
}
