/// 统一 API 响应包装类
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final int timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  /// 从 Map 反序列化
  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic json)? fromJsonT) {
    return ApiResponse<T>(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
      timestamp: json['timestamp'] as int,
    );
  }

  /// 辅助判断操作是否成功
  bool get isSuccess => code == 200;
}
