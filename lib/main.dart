import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'presentation/ai_copilot/cubit/ai_dispatch_cubit.dart';
import 'presentation/connectivity/connectivity_cubit.dart';
import 'presentation/epod/bloc/epod_bloc.dart';
import 'presentation/hos/cubit/driver_hos_cubit.dart';
import 'presentation/map_command/bloc/fleet_map_bloc.dart';
import 'presentation/obd_diagnostics/bloc/obd_diagnostics_bloc.dart';
import 'presentation/route_optimizer/bloc/route_optimizer_bloc.dart';
import 'presentation/splash/splash_view.dart';
import 'presentation/theme/theme_cubit.dart';
import 'presentation/toll/cubit/toll_estimator_cubit.dart';
import 'presentation/cold_chain/cubit/cold_chain_cubit.dart';
import 'presentation/fuel_finder/cubit/fuel_finder_cubit.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint(
          'FleetRoute Uncaught FlutterError: ${details.exceptionAsString()}',
        );
      };

      // Minimal defensive pre-runApp initialization
      try {
        await di.initDependencies();
      } catch (e) {
        debugPrint('Defensive DI initialization warning: $e');
      }

      runApp(const FleetRouteApp());
    },
    (error, stack) {
      debugPrint(
        'FleetRoute runZonedGuarded caught unhandled error: $error\n$stack',
      );
    },
  );
}

class FleetRouteApp extends StatelessWidget {
  final Widget? home;
  const FleetRouteApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => di.sl<ThemeCubit>()),
        BlocProvider<ConnectivityCubit>(
          create: (_) => di.sl<ConnectivityCubit>(),
        ),
        BlocProvider<FleetMapBloc>(create: (_) => di.sl<FleetMapBloc>()),
        BlocProvider<RouteOptimizerBloc>(
          create: (_) => di.sl<RouteOptimizerBloc>(),
        ),
        BlocProvider<EpodBloc>(create: (_) => di.sl<EpodBloc>()),
        BlocProvider<ObdDiagnosticsBloc>(
          create: (_) => di.sl<ObdDiagnosticsBloc>(),
        ),
        BlocProvider<AiDispatchCubit>(create: (_) => di.sl<AiDispatchCubit>()),
        BlocProvider<DriverHosCubit>(create: (_) => di.sl<DriverHosCubit>()),
        BlocProvider<TollEstimatorCubit>(
          create: (_) => di.sl<TollEstimatorCubit>(),
        ),
        BlocProvider<ColdChainCubit>(create: (_) => di.sl<ColdChainCubit>()),
        BlocProvider<FuelFinderCubit>(create: (_) => di.sl<FuelFinderCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: home ?? const SplashView(),
          );
        },
      ),
    );
  }
}
