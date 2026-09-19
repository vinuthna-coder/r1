import 'dart:convert';

import 'package:dio/dio.dart';
import '../../app/env.dart';
import '../errors/error_handler.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  ApiClient(this._storage, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
                baseUrl: AppEnvironment.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                // Spring often returns bare strings (JWT / status messages)
                // via StringHttpMessageConverter — not JSON-encoded.
                responseType: ResponseType.plain,
                headers: const {'Accept': '*/*'})) {
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _storage.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }
  final SecureStorageService _storage;
  final Dio _dio;
  Future<T> get<T>(String path,
          {Map<String, dynamic>? query, required T Function(dynamic) decode}) =>
      _run(() => _dio.get(path, queryParameters: query), decode);
  Future<T> post<T>(String path,
          {dynamic data,
          Map<String, dynamic>? query,
          required T Function(dynamic) decode}) =>
      _run(() => _dio.post(path, data: data, queryParameters: query), decode);
  Future<T> put<T>(String path,
          {dynamic data,
          Map<String, dynamic>? query,
          required T Function(dynamic) decode}) =>
      _run(() => _dio.put(path, data: data, queryParameters: query), decode);
  Future<T> delete<T>(String path,
          {Map<String, dynamic>? query, required T Function(dynamic) decode}) =>
      _run(() => _dio.delete(path, queryParameters: query), decode);

  Future<T> _run<T>(Future<Response<dynamic>> Function() request,
      T Function(dynamic) decode) async {
    try {
      return decode(_decodeBody((await request()).data));
    } catch (error) {
      throw toApiException(error);
    }
  }

  dynamic _decodeBody(dynamic raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      return raw;
    }
    final text = raw.trim();
    if (text.isEmpty) {
      return '';
    }
    if (text.startsWith('{') ||
        text.startsWith('[') ||
        (text.startsWith('"') && text.endsWith('"'))) {
      return jsonDecode(text);
    }
    return text;
  }
}
