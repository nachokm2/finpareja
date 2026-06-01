import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env_config.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  Completer<void>? _refreshCompleter;

  ApiClient._internal(this.dio, this.storage);

  static Future<ApiClient> create() async {
    final storage = const FlutterSecureStorage();
    final dio = Dio(BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    final client = ApiClient._internal(dio, storage);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final response = error.response;
        final reqOptions = error.requestOptions;

        if (response != null &&
            response.statusCode == 401 &&
            reqOptions.extra['retry'] != true) {
          try {
            if (client._refreshCompleter != null) {
              await client._refreshCompleter!.future;
            } else {
              client._refreshCompleter = Completer();
              final refreshToken = await storage.read(key: 'refresh_token');
              if (refreshToken == null) {
                client._refreshCompleter!.complete();
                client._refreshCompleter = null;
                return handler.next(error);
              }

              // Dio independiente para evitar recursión del interceptor
              final refreshDio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
              final refreshResp = await refreshDio.post(
                '/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final data = refreshResp.data as Map<String, dynamic>;
              final newAccess = data['access_token'] as String;
              final newRefresh = data['refresh_token'] as String;
              await storage.write(key: 'access_token', value: newAccess);
              await storage.write(key: 'refresh_token', value: newRefresh);
              client._refreshCompleter!.complete();
              client._refreshCompleter = null;
            }

            final newToken = await storage.read(key: 'access_token');
            if (newToken != null) {
              reqOptions.headers['Authorization'] = 'Bearer $newToken';
            }
            reqOptions.extra['retry'] = true;
            final clonedRequest = await dio.fetch(reqOptions);
            return handler.resolve(clonedRequest);
          } catch (e) {
            await storage.delete(key: 'access_token');
            await storage.delete(key: 'refresh_token');
            return handler.next(error);
          }
        }

        return handler.next(error);
      },
    ));

    return client;
  }
}
