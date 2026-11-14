import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityState extends Equatable {
  final bool isOffline;
  final bool isSimulatedOffline;

  const ConnectivityState({
    required this.isOffline,
    this.isSimulatedOffline = false,
  });

  ConnectivityState copyWith({bool? isOffline, bool? isSimulatedOffline}) {
    return ConnectivityState(
      isOffline: isOffline ?? this.isOffline,
      isSimulatedOffline: isSimulatedOffline ?? this.isSimulatedOffline,
    );
  }

  @override
  List<Object?> get props => [isOffline, isSimulatedOffline];
}

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity connectivity;
  final SharedPreferences sharedPreferences;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityCubit({
    required this.connectivity,
    required this.sharedPreferences,
  }) : super(const ConnectivityState(isOffline: false)) {
    _init();
  }

  void _init() {
    _subscription = connectivity.onConnectivityChanged.listen((results) {
      final isDisconnected = results.contains(ConnectivityResult.none);
      if (!state.isSimulatedOffline) {
        emit(state.copyWith(isOffline: isDisconnected));
      }
    });
  }

  void toggleSimulatedOffline() {
    final nextSim = !state.isSimulatedOffline;
    sharedPreferences.setBool('simulated_offline', nextSim);
    emit(state.copyWith(isSimulatedOffline: nextSim, isOffline: nextSim));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
