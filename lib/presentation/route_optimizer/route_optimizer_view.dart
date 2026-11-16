import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/entities/waybill_stop.dart';
import 'bloc/route_optimizer_bloc.dart';
import 'bloc/route_optimizer_event.dart';
import 'bloc/route_optimizer_state.dart';

class RouteOptimizerView extends StatefulWidget {
  final String? initialVehicleId;

  const RouteOptimizerView({super.key, this.initialVehicleId});

  @override
  State<RouteOptimizerView> createState() => _RouteOptimizerViewState();
}

class _RouteOptimizerViewState extends State<RouteOptimizerView> {
  @override
  void initState() {
    super.initState();
    context.read<RouteOptimizerBloc>().add(LoadRoutesEvent());
  }

  void _openCreateRouteModal(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _CreateRouteModal(
          onSubmit: (newRoute, newStops) {
            context.read<RouteOptimizerBloc>().add(
              CreateRouteEvent(route: newRoute, stops: newStops),
            );
            AppFeedback.showSuccess(
              context,
              'Dispatch Route "${newRoute.name}" created and synced.',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocConsumer<RouteOptimizerBloc, RouteOptimizerState>(
      listener: (context, state) {
        if (state.statusMessage != null) {
          AppFeedback.showSuccess(context, state.statusMessage!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.routes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final selected = state.selectedRoute;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_dispatch_new_route',
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.add_road),
            label: const Text('Create Dispatch Route'),
            onPressed: () => _openCreateRouteModal(context, colorScheme),
          ),
          body: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRouteSelector(context, state, colorScheme),
                            const SizedBox(height: 12),
                            if (selected != null)
                              _buildRouteMetricsCard(
                                context,
                                selected,
                                state,
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
                      flex: 6,
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: _buildStopsSequencer(
                          context,
                          state,
                          colorScheme,
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
                      _buildRouteSelector(context, state, colorScheme),
                      const SizedBox(height: 12),
                      if (selected != null) ...[
                        _buildRouteMetricsCard(
                          context,
                          selected,
                          state,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildStopsSequencer(context, state, colorScheme),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildRouteSelector(
    BuildContext context,
    RouteOptimizerState state,
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
            children: [
              Icon(Icons.route, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Active Dispatch Manifest',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: state.selectedRoute?.id,
            dropdownColor: colorScheme.surfaceContainerHighest,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: state.routes.map((r) {
              return DropdownMenuItem(
                value: r.id,
                child: Text(
                  '${r.name} (${r.id})',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                context.read<RouteOptimizerBloc>().add(SelectRouteEvent(val));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMetricsCard(
    BuildContext context,
    RoutePlan route,
    RouteOptimizerState state,
    ColorScheme colorScheme,
  ) {
    final fuelSavingsPct = route.totalDistanceKm > 0
        ? ((route.totalDistanceKm - route.optimizedDistanceKm) /
                  route.totalDistanceKm *
                  100)
              .clamp(0.0, 100.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Haversine Optimization Metrics',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: route.isOptimized
                      ? colorScheme.primary.withOpacity(0.18)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  route.isOptimized ? 'OPTIMIZED' : 'STANDARD',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: route.isOptimized
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Distance Saved',
                  '${(route.totalDistanceKm - route.optimizedDistanceKm).toStringAsFixed(1)} km',
                  Icons.straighten,
                  colorScheme.primary,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Fuel / Energy Saved',
                  '${fuelSavingsPct.toStringAsFixed(1)}% (${route.fuelSavedLiters} L)',
                  Icons.local_gas_station,
                  colorScheme.secondary,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Minutes Saved',
                  '${route.minutesSaved} min',
                  Icons.timer,
                  colorScheme.tertiary,
                  colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: state.isOptimizing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(
                state.isOptimizing
                    ? 'Running Spatial Haversine Solver...'
                    : 'Run AI Route Optimization Engine',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: state.isOptimizing
                  ? null
                  : () {
                      context.read<RouteOptimizerBloc>().add(
                        OptimizeRouteEvent(route.id),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStopsSequencer(
    BuildContext context,
    RouteOptimizerState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Waybill Stop Sequencer (${state.stops.length} stops)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Drag to reorder',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.stops.length,
          onReorder: (oldIndex, newIndex) {
            context.read<RouteOptimizerBloc>().add(
              ReorderStopsEvent(oldIndex: oldIndex, newIndex: newIndex),
            );
          },
          itemBuilder: (context, index) {
            final stop = state.stops[index];
            return Container(
              key: ValueKey(stop.id),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 13,
                  backgroundColor: colorScheme.primary.withOpacity(0.18),
                  child: Text(
                    '${stop.sequenceOrder}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  stop.stopName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${stop.cargoDescription} • ${stop.weightKg} kg',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPriorityBadge(stop.priority, colorScheme),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority, ColorScheme colorScheme) {
    Color bg = colorScheme.surfaceContainerHighest;
    Color fg = colorScheme.onSurface;

    if (priority == 'URGENT_COLD_CHAIN') {
      bg = colorScheme.secondary.withOpacity(0.18);
      fg = colorScheme.secondary;
    } else if (priority == 'SCHEDULED_FREIGHT') {
      bg = colorScheme.primary.withOpacity(0.18);
      fg = colorScheme.primary;
    } else {
      bg = colorScheme.surfaceContainerHighest;
      fg = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.replaceAll('_', ' '),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _CreateRouteModal extends StatefulWidget {
  final void Function(RoutePlan route, List<WaybillStop> stops) onSubmit;

  const _CreateRouteModal({required this.onSubmit});

  @override
  State<_CreateRouteModal> createState() => _CreateRouteModalState();
}

class _CreateRouteModalState extends State<_CreateRouteModal> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameCtrl = TextEditingController(
    text: 'Canal Expressway Freight Loop Beta',
  );
  final _originCtrl = TextEditingController(
    text: 'Thokar Regional Logistics Depot',
  );
  final _destCtrl = TextEditingController(
    text: 'Raiwind Regional Distribution Center',
  );
  final _stopNameCtrl = TextEditingController(text: 'Chung Commercial Depot');
  final _weightCtrl = TextEditingController(text: '2400');
  String _selectedVehicleId = 'VH-101';
  String _priority = 'SCHEDULED_FREIGHT';

  @override
  void dispose() {
    _routeNameCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _stopNameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final routeId = 'RT-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final weight = double.tryParse(_weightCtrl.text) ?? 1000.0;

    final route = RoutePlan(
      id: routeId,
      name: _routeNameCtrl.text.trim(),
      vehicleId: _selectedVehicleId,
      originName: _originCtrl.text.trim(),
      originLat: 31.4700,
      originLng: 74.2720,
      destinationName: _destCtrl.text.trim(),
      destinationLat: 31.2480,
      destinationLng: 74.2150,
      totalDistanceKm: 34.5,
      optimizedDistanceKm: 34.5,
      fuelSavedLiters: 0.0,
      minutesSaved: 0,
      isOptimized: false,
      status: 'ACTIVE',
    );

    final stop = WaybillStop(
      id: 'WB-${DateTime.now().millisecondsSinceEpoch % 10000}',
      routeId: routeId,
      sequenceOrder: 1,
      stopName: _stopNameCtrl.text.trim(),
      latitude: 31.4120,
      longitude: 74.2450,
      cargoDescription: 'Standard Palletized Goods',
      weightKg: weight,
      priority: _priority,
      status: 'PENDING',
    );

    widget.onSubmit(route, [stop]);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Dispatch Route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _routeNameCtrl,
                  decoration: const InputDecoration(labelText: 'Route Name'),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Route name cannot be blank'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _originCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Origin Depot',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _destCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Destination Hub',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _stopNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Primary Waybill Stop',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Stop name cannot be blank'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedVehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Vehicle',
                        ),
                        dropdownColor: colorScheme.surfaceContainerHighest,
                        items: ['VH-101', 'VH-102', 'VH-103', 'VH-104'].map((
                          id,
                        ) {
                          return DropdownMenuItem(value: id, child: Text(id));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedVehicleId = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cargo Weight (kg)',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(val) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority Level',
                  ),
                  dropdownColor: colorScheme.surfaceContainerHighest,
                  items: const [
                    DropdownMenuItem(
                      value: 'URGENT_COLD_CHAIN',
                      child: Text('Urgent Cold-Chain'),
                    ),
                    DropdownMenuItem(
                      value: 'SCHEDULED_FREIGHT',
                      child: Text('Scheduled Freight'),
                    ),
                    DropdownMenuItem(
                      value: 'STANDARD_PARCEL',
                      child: Text('Standard Parcel'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _priority = val);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save & Dispatch Route'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
