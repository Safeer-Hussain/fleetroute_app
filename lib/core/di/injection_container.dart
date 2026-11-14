import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../platform/native_obd_bridge.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../../domain/repositories/route_repository.dart';
import '../../domain/repositories/epod_repository.dart';
import '../../domain/repositories/obd_repository.dart';
import '../../domain/repositories/ai_copilot_repository.dart';
import '../../data/repositories/fleet_repository_impl.dart';
import '../../data/repositories/route_repository_impl.dart';
import '../../data/repositories/epod_repository_impl.dart';
import '../../data/repositories/obd_repository_impl.dart';
import '../../data/repositories/ai_copilot_repository_impl.dart';
import '../../presentation/theme/theme_cubit.dart';
import '../../presentation/connectivity/connectivity_cubit.dart';
import '../../presentation/map_command/bloc/fleet_map_bloc.dart';
import '../../presentation/route_optimizer/bloc/route_optimizer_bloc.dart';
import '../../presentation/epod/bloc/epod_bloc.dart';
import '../../presentation/obd_diagnostics/bloc/obd_diagnostics_bloc.dart';
import '../../presentation/ai_copilot/cubit/ai_dispatch_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies({SharedPreferences? prefOverride}) async {
  // Clear any existing registrations for test isolation
  if (sl.isRegistered<SharedPreferences>()) {
    await sl.reset();
  }

  // Core & External
  final sharedPreferences =
      prefOverride ?? await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  final appDatabase = AppDatabase.instance;
  sl.registerSingleton<AppDatabase>(appDatabase);

  final apiClient = ApiClient(sharedPreferences: sharedPreferences);
  sl.registerSingleton<ApiClient>(apiClient);

  final nativeBridge = NativeObdBridge();
  sl.registerSingleton<NativeObdBridge>(nativeBridge);

  final connectivity = Connectivity();
  sl.registerSingleton<Connectivity>(connectivity);

  // Repositories
  sl.registerLazySingleton<FleetRepository>(
    () => FleetRepositoryImpl(database: sl(), apiClient: sl()),
  );
  sl.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(database: sl(), apiClient: sl()),
  );
  sl.registerLazySingleton<EpodRepository>(
    () => EpodRepositoryImpl(database: sl(), apiClient: sl()),
  );
  sl.registerLazySingleton<ObdRepository>(
    () =>
        ObdRepositoryImpl(database: sl(), apiClient: sl(), nativeBridge: sl()),
  );
  sl.registerLazySingleton<AiCopilotRepository>(
    () => AiCopilotRepositoryImpl(database: sl()),
  );

  // Cubits & Blocs
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(sharedPreferences: sl()),
  );
  sl.registerFactory(
    () => ConnectivityCubit(connectivity: sl(), sharedPreferences: sl()),
  );
  sl.registerFactory(() => FleetMapBloc(fleetRepository: sl()));
  sl.registerFactory(() => RouteOptimizerBloc(routeRepository: sl()));
  sl.registerFactory(() => EpodBloc(epodRepository: sl()));
  sl.registerFactory(() => ObdDiagnosticsBloc(obdRepository: sl()));
  sl.registerFactory(() => AiDispatchCubit(aiRepository: sl()));
}
