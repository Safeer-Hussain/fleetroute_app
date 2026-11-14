import 'package:equatable/equatable.dart';

import '../../../domain/entities/route_plan.dart';
import '../../../domain/entities/waybill_stop.dart';

class RouteOptimizerState extends Equatable {
  final List<RoutePlan> routes;
  final RoutePlan? selectedRoute;
  final List<WaybillStop> stops;
  final bool isLoading;
  final bool isOptimizing;
  final String? statusMessage;

  const RouteOptimizerState({
    this.routes = const [],
    this.selectedRoute,
    this.stops = const [],
    this.isLoading = false,
    this.isOptimizing = false,
    this.statusMessage,
  });

  RouteOptimizerState copyWith({
    List<RoutePlan>? routes,
    RoutePlan? selectedRoute,
    List<WaybillStop>? stops,
    bool? isLoading,
    bool? isOptimizing,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return RouteOptimizerState(
      routes: routes ?? this.routes,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      stops: stops ?? this.stops,
      isLoading: isLoading ?? this.isLoading,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
    routes,
    selectedRoute,
    stops,
    isLoading,
    isOptimizing,
    statusMessage,
  ];
}
