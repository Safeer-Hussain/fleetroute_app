import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_network_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient({required SharedPreferences sharedPreferences}) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.fleetroute.enterprise/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Client-Platform': 'Flutter-Enterprise',
        },
      ),
    );

    dio.interceptors.add(
      MockNetworkInterceptor(sharedPreferences: sharedPreferences),
    );
  }
}
