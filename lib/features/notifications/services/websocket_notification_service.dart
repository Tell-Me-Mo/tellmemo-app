import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/auth_service.dart';
import '../data/models/notification_model.dart';

final webSocketNotificationServiceProvider = Provider<WebSocketNotificationService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return WebSocketNotificationService(authService);
});

class WebSocketNotificationService {
  final AuthService _authService;
  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 30);

  WebSocketNotificationService(this._authService);

  Stream<WebSocketMessage> get messages => _messageController?.stream ?? const Stream.empty();
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Get the base URL from environment or configuration
      final wsUrl = _getWebSocketUrl(token);

      // Create WebSocket channel (platform-appropriate implementation)
      // Note: Token is passed in URL query parameter for both platforms
      // as WebSocketChannel.connect doesn't support custom headers
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _messageController = StreamController<WebSocketMessage>.broadcast();

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      // Start ping timer to keep connection alive
      _startPingTimer();

      debugPrint('WebSocket connected to notification service');
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _handleError(e);
    }
  }

  String _getWebSocketUrl(String token) {
    // Get base URL from environment
    const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'localhost:8000');
    final protocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final cleanUrl = baseUrl.replaceAll(RegExp(r'^https?://'), '');

    // For web, we need to include token as query parameter
    if (kIsWeb) {
      return '$protocol://$cleanUrl/ws/notifications?token=$token';
    }

    return '$protocol://$cleanUrl/ws/notifications?token=$token';
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final wsMessage = WebSocketMessage.fromJson(data);
      _messageController?.add(wsMessage);

      // Reset ping timer on any message
      _resetPingTimer();
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDone() {
    debugPrint('WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      debugPrint('Attempting to reconnect WebSocket (attempt $_reconnectAttempts)');
      connect();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }

  void _resetPingTimer() {
    _startPingTimer();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    sendMessage({
      'type': 'mark_read',
      'notification_id': notificationId,
    });
  }

  Future<void> markAllAsRead() async {
    sendMessage({
      'type': 'mark_all_read',
    });
  }

  Future<void> requestUnreadCount() async {
    sendMessage({
      'type': 'get_unread_count',
    });
  }

  Future<void> disconnect() async {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _channel?.sink.close();
    await _messageController?.close();
    _channel = null;
    _messageController = null;
  }

  void dispose() {
    disconnect();
  }
}

// WebSocket message types
class WebSocketMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String? timestamp;

  WebSocketMessage({
    required this.type,
    this.data,
    this.timestamp,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'],
      timestamp: json['timestamp'],
    );
  }

  bool get isNotification => type == 'notification';
  bool get isHeartbeat => type == 'heartbeat';
  bool get isPong => type == 'pong';
  bool get isUnreadCount => type == 'unread_count';
  bool get isNotificationRead => type == 'notification_read';
  bool get isNotificationArchived => type == 'notification_archived';
  bool get isError => type == 'error';

  NotificationModel? get notification {
    if (!isNotification || data == null) return null;
    try {
      return NotificationModel.fromJson(data!);
    } catch (e) {
      debugPrint('Error parsing notification from WebSocket: $e');
      return null;
    }
  }

  int? get unreadCount {
    if (!isUnreadCount || data == null) return null;
    return data!['count'];
  }

  String? get notificationId {
    if (!isNotificationRead && !isNotificationArchived) return null;
    return data?['notification_id'];
  }

  String? get errorMessage {
    if (!isError) return null;
    return data?['message'];
  }
}