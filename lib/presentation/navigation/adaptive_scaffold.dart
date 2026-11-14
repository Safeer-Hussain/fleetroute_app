import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../ai_copilot/ai_dispatch_copilot_view.dart';
import '../connectivity/connectivity_cubit.dart';
import '../epod/epod_hub_view.dart';
import '../map_command/fleet_map_command_view.dart';
import '../obd_diagnostics/obd_diagnostics_view.dart';
import '../route_optimizer/route_optimizer_view.dart';
import '../settings/settings_view.dart';

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({super.key});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;
  String? _targetVehicleId;

  void _onNavigateTab(int index, {String? targetVehicleId}) {
    setState(() {
      _currentIndex = index;
      _targetVehicleId = targetVehicleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isOffline = context.watch<ConnectivityCubit>().state.isOffline;

    final pages = [
      FleetMapCommandView(onNavigateTab: _onNavigateTab),
      RouteOptimizerView(initialVehicleId: _targetVehicleId),
      const EpodHubView(),
      ObdDiagnosticsView(initialVehicleId: _targetVehicleId),
      const AiDispatchCopilotView(),
    ];

    final titles = [
      'Fleet Telematics Radar',
      'Multi-Stop Route Optimizer',
      'Electronic Proof of Delivery (ePOD)',
      'OBD-II CAN-Bus Diagnostics',
      'On-Device AI Dispatch Copilot',
    ];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: isLandscape ? 36 : 48,
          backgroundColor: colorScheme.surfaceContainer,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.all(isLandscape ? 6.0 : 8.0),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
          title: Text(
            isLandscape ? AppConstants.appName : titles[_currentIndex],
            style: TextStyle(
              fontSize: isLandscape ? 13 : 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: isLandscape ? 18 : 20),
              tooltip: 'Settings & Recruiter Drawer',
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Animated Offline Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isOffline ? 28 : 0,
              color: colorScheme.error,
              child: isOffline
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 14,
                            color: colorScheme.onError,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Offline Field Mode - Buffering Telematics & ePOD to Local SQLite',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onError,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: isLandscape
                  ? Row(
                      children: [
                        // Landscape 360dp-safe compact NavigationRail
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height -
                                  (isLandscape ? 64 : 76),
                            ),
                            child: IntrinsicHeight(
                              child: NavigationRail(
                                minWidth: 56,
                                labelType: NavigationRailLabelType.none,
                                backgroundColor: colorScheme.surfaceContainer,
                                selectedIndex: _currentIndex,
                                onDestinationSelected: (index) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                                destinations: const [
                                  NavigationRailDestination(
                                    icon: Icon(Icons.map_outlined),
                                    selectedIcon: Icon(Icons.map),
                                    label: Text('Map'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.alt_route_outlined),
                                    selectedIcon: Icon(Icons.alt_route),
                                    label: Text('Route'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(
                                      Icons.assignment_turned_in_outlined,
                                    ),
                                    selectedIcon: Icon(
                                      Icons.assignment_turned_in,
                                    ),
                                    label: Text('ePOD'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.speed_outlined),
                                    selectedIcon: Icon(Icons.speed),
                                    label: Text('OBD-II'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.psychology_outlined),
                                    selectedIcon: Icon(Icons.psychology),
                                    label: Text('Copilot'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        VerticalDivider(
                          width: 1,
                          color: colorScheme.outlineVariant,
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: pages,
                          ),
                        ),
                      ],
                    )
                  : IndexedStack(index: _currentIndex, children: pages),
            ),
          ],
        ),
        bottomNavigationBar: isLandscape
            ? null
            : NavigationBar(
                height: 60,
                backgroundColor: colorScheme.surfaceContainer,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined, size: 20),
                    selectedIcon: Icon(Icons.map, size: 20),
                    label: 'Map',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.alt_route_outlined, size: 20),
                    selectedIcon: Icon(Icons.alt_route, size: 20),
                    label: 'Routes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_turned_in_outlined, size: 20),
                    selectedIcon: Icon(Icons.assignment_turned_in, size: 20),
                    label: 'ePOD',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.speed_outlined, size: 20),
                    selectedIcon: Icon(Icons.speed, size: 20),
                    label: 'OBD-II',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.psychology_outlined, size: 20),
                    selectedIcon: Icon(Icons.psychology, size: 20),
                    label: 'AI Copilot',
                  ),
                ],
              ),
      ),
    );
  }
}
