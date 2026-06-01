import 'package:dio/dio.dart';
import '../services/storage_service.dart';

/// 身份认证与登录失效拦截器
class AuthInterceptor extends Interceptor {
  // 定义强制下线的回调接口（例如，弹窗提示并跳转登录页）
  static void Function(String message)? onForceLogout;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = token;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final code = responseData['code'];
      // 1009 为后端 ErrorCode.DEVICE_FORCE_LOGOUT 定义的错误码：账号已在其他设备登录被踢出
      if (code == 1009) {
        _handleForceLogout("您的账号已在其他设备登录，您已被强制下线。");
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      final status = err.response!.statusCode;
      final responseData = err.response!.data;

      // 如果是 401 未登录/失效
      if (status == 401) {
        String msg = "登录状态已过期，请重新登录";
        if (responseData is Map<String, dynamic>) {
          final code = responseData['code'];
          final message = responseData['message'];
          if (code == 1009) {
            msg = "您的账号在别处登录，已自动退出";
          } else if (message != null) {
            msg = message;
          }
        }
        _handleForceLogout(msg);
      }
    }
    handler.next(err);
  }

  /// 统一处理强制下线逻辑
  void _handleForceLogout(String reason) {
    // 1. 清除本地缓存的无效凭证
    StorageService.clearAuth();

    // 2. 触发 UI 层的强制下线回调
    if (onForceLogout != null) {
      onForceLogout!(reason);
    }
  }
}
