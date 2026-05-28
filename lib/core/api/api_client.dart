import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://backend-ten-jade-90.vercel.app',
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Attach Supabase JWT on every request if available
        if (SupabaseConfig.isConfigured) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
        final data = error.response?.data;
        String message;
        if (data is Map) {
          message = data['error']?.toString() ?? data['message']?.toString() ?? 'Server error $status';
        } else if (data is String && data.isNotEmpty && !data.startsWith('<')) {
          message = data;
        } else {
          message = error.message ?? 'Request failed ($status)';
        }
        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(status: status, message: message),
          ),
        );
      },
    ));
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {dynamic data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}

class ApiException implements Exception {
  const ApiException({this.status, required this.message});
  final int? status;
  final String message;

  bool get isUnauthorized => status == 401;
  bool get isNotFound => status == 404;

  @override
  String toString() => message;
}

/// Extracts a human-readable message from any exception, unwrapping
/// DioException → ApiException when present.
String friendlyError(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    final inner = e.error;
    if (inner is ApiException) return inner.message;
    return e.message ?? 'Request failed';
  }
  return e.toString();
}
