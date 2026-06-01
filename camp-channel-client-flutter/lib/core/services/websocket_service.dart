import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'storage_service.dart';

/// Global singleton WebSocket service for real-time communication.
/// Connects to the backend's raw WebSocket endpoint at /ws/raw.
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocket? _ws;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _disposed = false;

  // Stream controllers for different event types
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _onlineStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of new chat messages: {type:"new_message", senderId, receiverId, content, ...}
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream of online status changes: {type:"online_status", userId, online}
  Stream<Map<String, dynamic>> get onlineStatusStream => _onlineStatusController.stream;

  /// Stream of read receipts: {type:"message_read", friendId, friendName}
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptController.stream;

  bool get isConnected => _ws != null && _ws!.readyState == WebSocket.open;

  /// Start connection. Called once at app startup.
  void connect() {
    _disposed = false;
    _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed) return;
    try {
      final rawToken = StorageService.getToken();
      if (rawToken == null || rawToken.isEmpty) return;
      // 去除 "Bearer " 前缀，后端 RawWebSocketHandler 直接解析纯 JWT 字符串
      final token = rawToken.startsWith('Bearer ') ? rawToken.substring(7) : rawToken;

      // 从存储的 API 地址推导 WebSocket 地址
      String host = 'localhost:8080';
      final apiUrl = StorageService.getApiBaseUrl();
      if (apiUrl != null && apiUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(apiUrl);
          host = '${uri.host}:${uri.port}';
        } catch (_) {}
      } else {
        try {
          if (Platform.isAndroid) {
            host = '10.0.2.2:8080';
          }
        } catch (_) {}
      }

      final url = 'ws://$host/ws/raw?token=$token';

      _ws = await WebSocket.connect(url);
      _ws!.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _dispatch(msg);
          } catch (_) {}
        },
        onDone: () {
          _scheduleReconnect();
        },
        onError: (_) {
          _scheduleReconnect();
        },
      );

      // Start heartbeat ping every 30 seconds
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'type': 'ping'});
      });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _dispatch(Map<String, dynamic> msg) {
    final type = msg['type']?.toString() ?? '';
    switch (type) {
      case 'new_message':
        _messageController.add(msg);
        break;
      case 'online_status':
        _onlineStatusController.add(msg);
        break;
      case 'message_read':
        _readReceiptController.add(msg);
        break;
      case 'pong':
        // Heartbeat response, ignore
        break;
      default:
        // Unknown type, still push to message stream as fallback
        _messageController.add(msg);
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_ws != null && _ws!.readyState == WebSocket.open) {
      _ws!.add(jsonEncode(data));
    }
  }

  int _reconnectAttempts = 0;

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _ws = null;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
    final delay = Duration(
      seconds: [1, 2, 4, 8, 16, 30]
          [(_reconnectAttempts < 6) ? _reconnectAttempts : 5],
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () {
      if (!_disposed) _doConnect();
    });
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Disconnect and clean up. Call on logout.
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _ws?.close();
    _ws = null;
  }
}
