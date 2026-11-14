import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class MockNetworkInterceptor extends Interceptor {
  final SharedPreferences sharedPreferences;

  MockNetworkInterceptor({required this.sharedPreferences});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Read simulation flags
    final force503 =
        sharedPreferences.getBool(AppConstants.prefForceHttp503) ?? false;
    final customLatency = sharedPreferences.getInt(
      AppConstants.prefSimulatedLatency,
    );

    // Apply configurable latency: 400ms - 850ms default or custom
    final latencyMs = customLatency ?? (400 + Random().nextInt(450));
    await Future.delayed(Duration(milliseconds: latencyMs));

    if (force503) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            statusMessage: 'FleetRoute Cloud Gateway Unavailable - Simulated 503 Service Unavailable',
            data: {
              'error': 'Service Unavailable',
              'message': 'Simulated Recruiter Debug HTTP 503 triggered.',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    // Default mock success response
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 'SUCCESS',
          'path': options.path,
          'method': options.method,
          'timestamp': DateTime.now().toIso8601String(),
          'payload': options.data,
        },
      ),
    );
  }
}
