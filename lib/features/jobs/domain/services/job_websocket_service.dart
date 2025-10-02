import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../../../../core/config/api_config.dart';

class JobWebSocketService {
  WebSocketChannel? _channel;
  String? _clientId;
  bool _isConnected = false;
  
  // Stream controllers for job updates
  final _jobUpdateController = StreamController<JobModel>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  
  // Reconnection settings
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  
  // Ping/pong for keepalive
  Timer? _pingTimer;
  static const Duration _pingInterval = Duration(seconds: 30);
  
  // Tracked jobs and projects
  final Set<String> _subscribedJobs = {};
  String? _subscribedProject;
  
  // Streams
  Stream<JobModel> get jobUpdates => _jobUpdateController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;
  bool get isConnected => _isConnected;
  
  // Generate WebSocket URL
  String get _wsUrl {
    final baseUrl = ApiConfig.baseUrl;
    final wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceAll(RegExp(r'^https?://'), '');
    return '$wsProtocol://$host/ws/jobs${_clientId != null ? '?client_id=$_clientId' : ''}';
  }
  
  /// Connect to WebSocket server
  Future<void> connect({String? clientId}) async {
    if (_isConnected) return;
    
    _clientId = clientId;
    
    try {
      debugPrint('[JobWebSocket] Connecting to $_wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      
      // Start ping timer for keepalive
      _startPingTimer();
      
      // Re-subscribe to previous subscriptions
      await _resubscribe();
      
      debugPrint('[JobWebSocket] Connected successfully');
    } catch (e) {
      debugPrint('[JobWebSocket] Connection failed: $e');
      _handleError(e);
    }
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    debugPrint('[JobWebSocket] Disconnecting...');
    
    _cancelReconnectTimer();
    _cancelPingTimer();
    
    _channel?.sink.close();
    _channel = null;
    
    _isConnected = false;
    _connectionStateController.add(false);
  }
  
  /// Subscribe to job updates
  Future<void> subscribeToJob(String jobId) async {
    if (!_isConnected) {
      await connect();
    }
    
    _subscribedJobs.add(jobId);
    
    _sendMessage({
      'action': 'subscribe',
      'job_id': jobId,
    });
    
    debugPrint('[JobWebSocket] Subscribed to job $jobId');
  }
  
  /// Unsubscribe from job updates
  void unsubscribeFromJob(String jobId) {
    _subscribedJobs.remove(jobId);
    
    if (_isConnected) {
      _sendMessage({
        'action': 'unsubscribe',
        'job_id': jobId,
      });
    }
    
    debugPrint('[JobWebSocket] Unsubscribed from job $jobId');
  }
  
  /// Subscribe to all jobs in a project
  Future<void> subscribeToProject(String projectId) async {
    if (!_isConnected) {
      await connect();
    }
    
    _subscribedProject = projectId;
    
    _sendMessage({
      'action': 'subscribe_project',
      'project_id': projectId,
    });
    
    debugPrint('[JobWebSocket] Subscribed to project $projectId');
  }
  
  /// Get status of a specific job
  void getJobStatus(String jobId) {
    if (!_isConnected) return;
    
    _sendMessage({
      'action': 'get_status',
      'job_id': jobId,
    });
  }
  
  /// Cancel a job
  void cancelJob(String jobId) {
    if (!_isConnected) return;
    
    _sendMessage({
      'action': 'cancel',
      'job_id': jobId,
    });
  }
  
  /// Send message to server
  void _sendMessage(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) return;
    
    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
    } catch (e) {
      debugPrint('[JobWebSocket] Error sending message: $e');
    }
  }
  
  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;
      
      switch (type) {
        case 'connection':
          debugPrint('[JobWebSocket] Connection confirmed: ${data['client_id']}');
          break;
          
        case 'job_update':
          final jobData = data['job'] as Map<String, dynamic>;
          final job = JobModel.fromJson(jobData);
          _jobUpdateController.add(job);
          debugPrint('[JobWebSocket] Job update: ${job.jobId} - ${job.status.value} (${job.progress}%)');
          break;
          
        case 'new_job':
          // Handle new job notification (e.g., from Fireflies webhook)
          final jobData = data['job'] as Map<String, dynamic>;
          final job = JobModel.fromJson(jobData);
          _jobUpdateController.add(job);
          debugPrint('[JobWebSocket] New job started: ${job.jobId} - ${job.jobType.value} from integration');
          
          // Auto-subscribe to this job for updates
          subscribeToJob(job.jobId);
          break;
          
        case 'job_cancelled':
          debugPrint('[JobWebSocket] Job cancelled: ${data['job_id']}');
          break;
          
        case 'error':
          debugPrint('[JobWebSocket] Server error: ${data['error']}');
          break;
          
        case 'pong':
          // Keepalive response
          break;
          
        default:
          debugPrint('[JobWebSocket] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[JobWebSocket] Error handling message: $e');
    }
  }
  
  /// Handle connection errors
  void _handleError(dynamic error) {
    debugPrint('[JobWebSocket] WebSocket error: $error');
    _handleDisconnect();
  }
  
  /// Handle disconnection
  void _handleDisconnect() {
    debugPrint('[JobWebSocket] Disconnected');

    _isConnected = false;

    // Only add to stream if it's not closed
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(false);
    }

    _cancelPingTimer();
    _scheduleReconnect();
  }
  
  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    // Don't schedule reconnect if controllers are closed (disposed)
    if (_connectionStateController.isClosed || _jobUpdateController.isClosed) {
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[JobWebSocket] Max reconnection attempts reached');
      return;
    }

    _cancelReconnectTimer();

    _reconnectAttempts++;
    debugPrint('[JobWebSocket] Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts');

    _reconnectTimer = Timer(_reconnectDelay, () async {
      // Check again if not disposed before reconnecting
      if (!_isConnected && !_connectionStateController.isClosed) {
        await connect(clientId: _clientId);
      }
    });
  }
  
  /// Cancel reconnection timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Start ping timer for keepalive
  void _startPingTimer() {
    _cancelPingTimer();
    
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_isConnected) {
        _sendMessage({'action': 'ping'});
      }
    });
  }
  
  /// Cancel ping timer
  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
  
  /// Re-subscribe to previous subscriptions after reconnect
  Future<void> _resubscribe() async {
    // Re-subscribe to jobs
    for (final jobId in _subscribedJobs) {
      _sendMessage({
        'action': 'subscribe',
        'job_id': jobId,
      });
    }
    
    // Re-subscribe to project
    if (_subscribedProject != null) {
      _sendMessage({
        'action': 'subscribe_project',
        'project_id': _subscribedProject,
      });
    }
  }
  
  /// Clean up resources
  void dispose() {
    // Cancel any timers first to prevent them from firing after disposal
    _cancelPingTimer();
    _cancelReconnectTimer();

    // Then disconnect
    disconnect();

    // Finally close the stream controllers
    _jobUpdateController.close();
    _connectionStateController.close();
  }
}