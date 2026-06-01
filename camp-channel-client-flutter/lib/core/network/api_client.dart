import 'dart:io';
import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import '../services/storage_service.dart';

/// 统一网络请求客户端 (单例)
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._internal({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _getEffectiveBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  factory ApiClient({String? baseUrl}) {
    _instance ??= ApiClient._internal(baseUrl: baseUrl);
    return _instance!;
  }

  /// Reset singleton (e.g. after changing base URL)
  static void reset({String? baseUrl}) {
    _instance = ApiClient._internal(baseUrl: baseUrl);
  }

  /// 优先使用 SharedPreferences 中存储的地址，否则按平台返回默认值
  static String _getEffectiveBaseUrl() {
    final stored = StorageService.getApiBaseUrl();
    if (stored != null && stored.isNotEmpty) return stored;
    return _getDefaultBaseUrl();
  }

  static String _getDefaultBaseUrl() {
    try {
      if (Platform.isAndroid) {
        return 'http://10.50.30.104:8080/api';
      }
    } catch (_) {}
    return 'http://localhost:8080/api';
  }

  Dio get dio => _dio;

  /// 将相对路径的头像/图片转为完整 URL
  static String processImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = StorageService.getApiBaseUrl() ?? _getDefaultBaseUrl();
    // base 是 http://host:port/api，图片路径是 /uploads/...
    // 因为 Spring Boot 配置了 context-path: /api，静态资源也需要 /api 前缀
    return '$base$url';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Upload a file using multipart/form-data
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path),
      if (data != null) ...data,
    });
    return await _dio.post<T>(path, data: formData);
  }
}
