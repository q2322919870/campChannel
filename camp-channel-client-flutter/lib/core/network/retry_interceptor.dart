import 'package:dio/dio.dart';
import 'dart:async';

/// 网络请求重试拦截器，应对网络波动场景
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries;
  final Duration _retryDelay;

  RetryInterceptor(this._dio, {int maxRetries = 3, Duration? retryDelay})
      : _maxRetries = maxRetries,
        _retryDelay = retryDelay ?? const Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // 已达最大重试次数或非可重试错误，直接失败
    final retryCount = requestOptions.extra['retryCount'] as int? ?? 0;
    if (retryCount >= _maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    requestOptions.extra['retryCount'] = retryCount + 1;
    final delay = _retryDelay * (retryCount + 1);

    try {
      await Future.delayed(delay);
      final response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (e) {
      handler.next(err);
    }
  }

  /// 判断错误是否可重试（网络错误、超时、5xx 服务器错误）
  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status >= 500 && status < 600;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }
}
