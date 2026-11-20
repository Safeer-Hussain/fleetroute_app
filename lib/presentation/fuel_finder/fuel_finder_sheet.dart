import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/app_feedback.dart';
import '../../domain/entities/fuel_station.dart';
import '../../domain/entities/route_plan.dart';
import '../../domain/entities/waybill_stop.dart';
import '../route_optimizer/bloc/route_optimizer_bloc.dart';
import '../route_optimizer/bloc/route_optimizer_event.dart';
import 'cubit/fuel_finder_cubit.dart';
import 'cubit/fuel_finder_state.dart';

class FuelFinderSheet extends StatelessWidget {
  final RoutePlan route;
  final List<WaybillStop> stops;

  const FuelFinderSheet({super.key, required this.route, required this.stops});

  static Future<void> show({
    required BuildContext context,
    required RoutePlan route,
    required List<WaybillStop> stops,
  }) {
    final fuelFinderCubit = context.read<FuelFinderCubit>();
    fuelFinderCubit.calculateRecommendation(route: route, stops: stops);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider.value(
        value: fuelFinderCubit,
        child: FuelFinderSheet(route: route, stops: stops),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BlocConsumer<FuelFinderCubit, FuelFinderState>(
          listener: (context, state) {
            if (state.status == FuelFinderStatus.injected &&
                state.statusMessage != null) {
              AppFeedback.showSuccess(context, state.statusMessage!);
              context.read<RouteOptimizerBloc>().add(LoadRoutesEvent());
              Navigator.of(context).pop();
            } else if (state.status == FuelFinderStatus.error &&
                state.errorMessage != null) {
              AppFeedback.showError(context, state.errorMessage!);
            }
          },
          builder: (context, state) {
            final recommendation = state.recommendation;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDragHandle(colorScheme),
                _buildHeader(context, colorScheme),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildVolumeControls(context, state, colorScheme),
                        const SizedBox(height: 12),
                        _buildToleranceSelector(context, state, colorScheme),
                        const SizedBox(height: 14),
                        if (state.status == FuelFinderStatus.loading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        else if (recommendation != null) ...[
                          if (recommendation.recommendedStation != null)
                            _buildRecommendedHeroCard(
                              context,
                              state,
                              recommendation.recommendedStation!,
                              colorScheme,
                            )
                          else
                            _buildNoStationsCard(colorScheme),
                          const SizedBox(height: 16),
                          _buildCorridorStationsHeader(
                            recommendation.corridorStations.length,
                            colorScheme,
                          ),
                          const SizedBox(height: 8),
                          ...recommendation.corridorStations.map(
                            (station) => _buildStationCard(
                              context,
                              state,
                              station,
                              station.id ==
                                  recommendation.recommendedStation?.id,
                              colorScheme,
                            ),
                          ),
                        ] else
                          _buildNoStationsCard(colorScheme),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_gas_station,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Corridor Lowest-Price Fuel Finder',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Highway Diesel Depots with Price Delta',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControls(
    BuildContext context,
    FuelFinderState state,
    ColorScheme colorScheme,
  ) {
    final volumes = [150.0, 250.0, 300.0, 450.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
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
                  'Planned Bunkering Volume',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${state.refuelLiters.toStringAsFixed(0)} Liters',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: volumes.map((v) {
              final isSelected = (state.refuelLiters == v);
              return ChoiceChip(
                label: Text('${v.toStringAsFixed(0)} L'),
                selected: isSelected,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                onSelected: (selected) {
                  if (selected) {
                    context.read<FuelFinderCubit>().updateRefuelLiters(
                      liters: v,
                      route: route,
                      stops: stops,
                    );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToleranceSelector(
    BuildContext context,
    FuelFinderState state,
    ColorScheme colorScheme,
  ) {
    final tolerances = [5.0, 8.0, 15.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corridor Detour Tolerance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Max distance off primary highway route',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${state.corridorToleranceKm.toStringAsFixed(0)} km',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tolerances.map((t) {
              final isSelected = (state.corridorToleranceKm == t);
              return ChoiceChip(
                label: Text('${t.toStringAsFixed(0)} km'),
                selected: isSelected,
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onSecondary
                      : colorScheme.onSurface,
                ),
                selectedColor: colorScheme.secondary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                onSelected: (selected) {
                  if (selected) {
                    context.read<FuelFinderCubit>().updateCorridorTolerance(
                      toleranceKm: t,
                      route: route,
                      stops: stops,
                    );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedHeroCard(
    BuildContext context,
    FuelFinderState state,
    FuelStation station,
    ColorScheme colorScheme,
  ) {
    final savings = station.calculateEstimatedSavings(state.refuelLiters);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 13, color: colorScheme.onPrimary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'LOWEST CORRIDOR PRICE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  '${station.distanceToCorridorKm.toStringAsFixed(1)} km detour',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            station.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            '${station.brand} · ${station.highway}',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniTile(
                  label: 'Station Diesel Price',
                  value:
                      'Rs. ${station.dieselPricePerLiter.toStringAsFixed(2)}/L',
                  colorScheme: colorScheme,
                  isHighlighted: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricMiniTile(
                  label: 'Savings Delta',
                  value:
                      'Rs. ${station.priceSavingsPerLiter.toStringAsFixed(2)}/L',
                  colorScheme: colorScheme,
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricMiniTile(
                  label: 'Total Saved',
                  value: 'Rs. ${savings.toStringAsFixed(0)}',
                  colorScheme: colorScheme,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: state.status == FuelFinderStatus.injecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_location_alt, size: 18),
              label: Text(
                state.status == FuelFinderStatus.injecting
                    ? 'Injecting Fuel Waypoint...'
                    : '1-Tap Inject Refueling Stop into Route',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: state.status == FuelFinderStatus.injecting
                  ? null
                  : () {
                      context.read<FuelFinderCubit>().injectFuelStopWaypoint(
                        routeId: route.id,
                        station: station,
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniTile({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isHighlighted
                  ? colorScheme.primary
                  : colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorStationsHeader(int count, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Corridor Stations Mapped ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Ranked by Diesel Price',
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStationCard(
    BuildContext context,
    FuelFinderState state,
    FuelStation station,
    bool isRecommended,
    ColorScheme colorScheme,
  ) {
    final savings = station.calculateEstimatedSavings(state.refuelLiters);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecommended
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${station.distanceToCorridorKm.toStringAsFixed(1)} km off corridor',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${station.brand} · ${station.highway}',
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Rs. ${station.dieselPricePerLiter.toStringAsFixed(2)}/L',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Save Rs. ${savings.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRecommended)
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label: const Text('Inject'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onPressed: state.status == FuelFinderStatus.injecting
                      ? null
                      : () {
                          context
                              .read<FuelFinderCubit>()
                              .injectFuelStopWaypoint(
                                routeId: route.id,
                                station: station,
                              );
                        },
                ),
            ],
          ),
          if (station.amenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: station.amenities.take(3).map((a) {
                final label = a.replaceAll('_', ' ');
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoStationsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'No Verified Stations Within Corridor Detour',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Increase corridor tolerance distance to expand search',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
