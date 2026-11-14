import 'package:equatable/equatable.dart';

import '../../../domain/entities/route_plan.dart';
import '../../../domain/entities/waybill_stop.dart';

abstract class RouteOptimizerEvent extends Equatable {
  const RouteOptimizerEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoutesEvent extends RouteOptimizerEvent {}

class SelectRouteEvent extends RouteOptimizerEvent {
  final String routeId;
  const SelectRouteEvent(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class OptimizeRouteEvent extends RouteOptimizerEvent {
  final String routeId;
  const OptimizeRouteEvent(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

class ReorderStopsEvent extends RouteOptimizerEvent {
  final int oldIndex;
  final int newIndex;
  const ReorderStopsEvent({required this.oldIndex, required this.newIndex});

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class CreateRouteEvent extends RouteOptimizerEvent {
  final RoutePlan route;
  final List<WaybillStop> stops;
  const CreateRouteEvent({required this.route, required this.stops});

  @override
  List<Object?> get props => [route, stops];
}
