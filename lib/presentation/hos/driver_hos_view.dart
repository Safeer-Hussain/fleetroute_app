import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection_container.dart' as di;
import '../../core/utils/app_feedback.dart';
import '../../domain/entities/driver_hos_log.dart';
import '../../domain/entities/rest_stop.dart';
import 'cubit/driver_hos_cubit.dart';
import 'cubit/driver_hos_state.dart';

class DriverHosView extends StatelessWidget {
  final String driverId;
  final String driverName;
  final String vehicleId;
  final double currentLat;
  final double currentLng;
  final DriverHosCubit? cubit;

  const DriverHosView({
    super.key,
    this.driverId = 'DRV-101',
    this.driverName = 'Tariq Mehmood',
    this.vehicleId = 'VH-101',
    this.currentLat = 31.5204,
    this.currentLng = 74.3587,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      cubit!.loadHos(driverId: driverId, lat: currentLat, lng: currentLng);
      return BlocProvider<DriverHosCubit>.value(
        value: cubit!,
        child: const _DriverHosContent(),
      );
    }

    return BlocProvider<DriverHosCubit>(
      create: (_) =>
          di.sl<DriverHosCubit>()
            ..loadHos(driverId: driverId, lat: currentLat, lng: currentLng),
      child: const _DriverHosContent(),
    );
  }
}

class _DriverHosContent extends StatelessWidget {
  const _DriverHosContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocConsumer<DriverHosCubit, DriverHosState>(
      listener: (context, state) {
        if (state.userNotice != null) {
          if (state.warningState == HosWarningState.violation) {
            AppFeedback.showError(context, state.userNotice!);
          } else if (state.warningState == HosWarningState.warning) {
            AppFeedback.showWarning(context, state.userNotice!);
          } else {
            AppFeedback.showSuccess(context, state.userNotice!);
          }
          context.read<DriverHosCubit>().clearNotice();
        } else if (state.errorMessage != null) {
          AppFeedback.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final hosLog = state.hosLog;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            toolbarHeight: isLandscape ? 36 : 48,
            backgroundColor: colorScheme.surfaceContainer,
            elevation: 0,
            title: Text(
              isLandscape
                  ? 'HOS & Rest Timer'
                  : 'Driver HOS Fatigue & Rest Timer',
              style: TextStyle(
                fontSize: isLandscape ? 12 : 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (hosLog != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Center(
                    child: _ComplianceStatusBadge(
                      warningState: hosLog.warningState,
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_hos_simulate_drive',
            backgroundColor: state.isSimulatingDrive
                ? colorScheme.error
                : colorScheme.primary,
            foregroundColor: state.isSimulatingDrive
                ? colorScheme.onError
                : colorScheme.onPrimary,
            icon: Icon(
              state.isSimulatingDrive ? Icons.pause : Icons.play_arrow,
              size: 18,
            ),
            label: Text(
              state.isSimulatingDrive
                  ? 'Pause Drive Sim'
                  : 'Simulate Drive (+60s/s)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              context.read<DriverHosCubit>().toggleDriveSimulation();
            },
          ),
          body: state.status == DriverHosViewStatus.loading
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colorScheme.primary,
                  ),
                )
              : hosLog == null
              ? Center(
                  child: Text(
                    'No HOS telematics records found.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                )
              : isLandscape
              ? _LandscapeLayout(hosLog: hosLog, state: state)
              : _PortraitLayout(hosLog: hosLog, state: state),
        );
      },
    );
  }
}

class _ComplianceStatusBadge extends StatelessWidget {
  final HosWarningState warningState;

  const _ComplianceStatusBadge({required this.warningState});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color badgeBg;
    Color badgeFg;
    IconData icon;

    switch (warningState) {
      case HosWarningState.normal:
        badgeBg = colorScheme.secondaryContainer;
        badgeFg = colorScheme.onSecondaryContainer;
        icon = Icons.verified_user_outlined;
        break;
      case HosWarningState.warning:
        badgeBg = colorScheme.errorContainer.withValues(alpha: 0.6);
        badgeFg = colorScheme.onErrorContainer;
        icon = Icons.warning_amber_outlined;
        break;
      case HosWarningState.violation:
        badgeBg = colorScheme.error;
        badgeFg = colorScheme.onError;
        icon = Icons.gpp_bad_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeFg),
          const SizedBox(width: 4),
          Text(
            warningState.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeFg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final DriverHosLog hosLog;
  final DriverHosState state;

  const _PortraitLayout({required this.hosLog, required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DriverHeaderCard(hosLog: hosLog),
          const SizedBox(height: 12),
          _DutyStatusSelector(currentStatus: hosLog.currentStatus),
          const SizedBox(height: 14),
          _HosGaugesSection(hosLog: hosLog),
          const SizedBox(height: 14),
          _MandatoryBreakCard(hosLog: hosLog),
          const SizedBox(height: 14),
          _NearestRestStopsSection(
            stops: state.nearestRestStops,
            selectedStop: state.selectedRestStop,
          ),
          const SizedBox(height: 72), // FAB clear space
        ],
      ),
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  final DriverHosLog hosLog;
  final DriverHosState state;

  const _LandscapeLayout({required this.hosLog, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Master Pane: Clocks, Status, & Driver Info
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DriverHeaderCard(hosLog: hosLog),
                const SizedBox(height: 8),
                _DutyStatusSelector(currentStatus: hosLog.currentStatus),
                const SizedBox(height: 8),
                _HosGaugesSection(hosLog: hosLog),
                const SizedBox(height: 8),
                _MandatoryBreakCard(hosLog: hosLog),
              ],
            ),
          ),
        ),
        // Right Detail Pane: Nearest Freight Rest Stops
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NearestRestStopsSection(
                  stops: state.nearestRestStops,
                  selectedStop: state.selectedRestStop,
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverHeaderCard extends StatelessWidget {
  final DriverHosLog hosLog;

  const _DriverHeaderCard({required this.hosLog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: const AssetImage(
              'assets/images/driver_avatar.png',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hosLog.driverName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Unit: ${hosLog.vehicleId} • ${hosLog.driverId}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '49 CFR §395',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DutyStatusSelector extends StatelessWidget {
  final HosDutyStatus currentStatus;

  const _DutyStatusSelector({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final statuses = [
      HosDutyStatus.driving,
      HosDutyStatus.onDuty,
      HosDutyStatus.sleeperBerth,
      HosDutyStatus.offDuty,
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: statuses.map((s) {
          final isSelected = s == currentStatus;
          return Expanded(
            child: InkWell(
              onTap: () {
                context.read<DriverHosCubit>().changeDutyStatus(s);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  s.displayName,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HosGaugesSection extends StatelessWidget {
  final DriverHosLog hosLog;

  const _HosGaugesSection({required this.hosLog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color driveColor;
    if (hosLog.drivingSecondsToday >= DriverHosLog.maxDrivingSeconds) {
      driveColor = colorScheme.error;
    } else if (hosLog.drivingSecondsToday >= (10 * 3600)) {
      driveColor = colorScheme.error.withValues(alpha: 0.8);
    } else {
      driveColor = colorScheme.primary;
    }

    Color breakColor;
    if (hosLog.secondsUntilBreakRequired <= 0) {
      breakColor = colorScheme.error;
    } else if (hosLog.secondsUntilBreakRequired <= 3600) {
      breakColor = colorScheme.tertiary;
    } else {
      breakColor = colorScheme.secondary;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HosGaugeCard(
                title: 'Driving Left',
                subtitle: '11h Shift Limit',
                timeDisplay: hosLog.drivingRemainingFormatted,
                progress: 1.0 - hosLog.drivingProgressPct,
                progressColor: driveColor,
                consumedDisplay: '${hosLog.drivingConsumedFormatted} Driven',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HosGaugeCard(
                title: 'Break Due In',
                subtitle: '8h Rest Trigger',
                timeDisplay: hosLog.breakCountdownFormatted,
                progress:
                    (hosLog.secondsUntilBreakRequired /
                            DriverHosLog.maxConsecutiveSecondsBeforeBreak)
                        .clamp(0.0, 1.0),
                progressColor: breakColor,
                consumedDisplay: '30m Rest Required',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '14h Shift Window Consumed: ${hosLog.onDutyConsumedFormatted}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${hosLog.formatSeconds(hosLog.onDutySecondsRemaining)} left',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HosGaugeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeDisplay;
  final double progress;
  final Color progressColor;
  final String consumedDisplay;

  const _HosGaugeCard({
    required this.title,
    required this.subtitle,
    required this.timeDisplay,
    required this.progress,
    required this.progressColor,
    required this.consumedDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            timeDisplay,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: progressColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            consumedDisplay,
            style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MandatoryBreakCard extends StatelessWidget {
  final DriverHosLog hosLog;

  const _MandatoryBreakCard({required this.hosLog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isBreakDue = hosLog.secondsUntilBreakRequired <= 3600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBreakDue
            ? colorScheme.errorContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBreakDue ? colorScheme.error : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 22,
            color: isBreakDue ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FMCSA 30-Min Rest',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hosLog.secondsUntilBreakRequired <= 0
                      ? 'Violation: 30m break past due.'
                      : 'Must log >=30 min rest before 8h drive.',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBreakDue
                  ? colorScheme.error
                  : colorScheme.secondaryContainer,
              foregroundColor: isBreakDue
                  ? colorScheme.onError
                  : colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () {
              context.read<DriverHosCubit>().takeMandatoryBreak();
            },
            child: const Text(
              'Log 30m Break',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearestRestStopsSection extends StatelessWidget {
  final List<RestStop> stops;
  final RestStop? selectedStop;

  const _NearestRestStopsSection({
    required this.stops,
    required this.selectedStop,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Nearest Freight Rest Plazas',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${stops.length} Hubs',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (stops.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Searching corridor rest stops...',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...stops.map((stop) {
            final isSelected = selectedStop?.id == stop.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${stop.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.route_outlined,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.highway,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${stop.availableTruckBays} Bays Free',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: stop.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(
                            fontSize: 9,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          side: BorderSide(color: colorScheme.primary),
                        ),
                        onPressed: () {
                          context.read<DriverHosCubit>().selectRestStop(stop);
                          AppFeedback.showSuccess(
                            context,
                            'Rest Stop ${stop.name} set as next route waypoint.',
                          );
                        },
                        icon: Icon(
                          Icons.navigation_outlined,
                          size: 12,
                          color: colorScheme.primary,
                        ),
                        label: Text(
                          'Set Waypoint',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
