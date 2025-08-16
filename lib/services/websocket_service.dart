import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/websocket_events.dart';
import '../config/environment.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final StreamController<WebSocketEvent> _eventController = StreamController.broadcast();
  final StreamController<ConnectionState> _connectionController = StreamController.broadcast();
  
  static String get _baseUrl => Environment.websocketUrl;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const int _maxReconnectAttempts = 5;
  
  ConnectionState _currentState = const ConnectionState();
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  String? _currentToken;

  // Event streams
  Stream<WebSocketEvent> get events => _eventController.stream;
  Stream<ConnectionState> get connectionState => _connectionController.stream;
  ConnectionState get currentState => _currentState;

  Future<void> connect() async {
    if (_isDisposed) return;
    if (_currentState.isConnected || _currentState.isConnecting) return;

    try {
      _updateConnectionState(ConnectionStatus.connecting);
      
      // Get authentication token
      _currentToken = await _storage.read(key: 'auth_token');
      if (_currentToken == null) {
        throw Exception('No authentication token found');
      }

      // Create WebSocket connection
      final uri = Uri.parse('$_baseUrl/ws?token=$_currentToken');
      _channel = IOWebSocketChannel.connect(uri);

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Start heartbeat
      _startHeartbeat();
      
      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
      
      if (Environment.enableDebugLogs) {
        print('✅ WebSocket connected successfully');
      }
      _updateConnectionState(ConnectionStatus.connected);
      
    } catch (e) {
      if (Environment.enableDebugLogs) {
        print('❌ WebSocket connection failed: $e');
      }
      _updateConnectionState(ConnectionStatus.error, error: e.toString());
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _isDisposed = true;
    
    // Stop timers
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    // Close subscription
    await _subscription?.cancel();
    _subscription = null;
    
    // Close channel
    await _channel?.sink.close();
    _channel = null;
    
    _updateConnectionState(ConnectionStatus.disconnected);
    if (Environment.enableDebugLogs) {
      print('🔌 WebSocket disconnected');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message as String);
      final event = WebSocketEvent.fromJson(data);
      
      // Handle special events
      if (event is ConnectionEstablishedEvent) {
        if (Environment.enableDebugLogs) {
          print('🔗 Connection established with session: ${event.sessionId}');
        }
        _updateConnectionState(ConnectionStatus.connected);
      } else if (event is UserOnlineEvent) {
        _addOnlineUser(event.userId);
      } else if (event is UserOfflineEvent) {
        _removeOnlineUser(event.userId);
      }
      
      // Broadcast event to listeners
      _eventController.add(event);
      
    } catch (e) {
      if (Environment.enableDebugLogs) {
        print('❌ Failed to parse WebSocket message: $e');
      }
    }
  }

  void _handleError(error) {
    if (Environment.enableDebugLogs) {
      print('❌ WebSocket error: $error');
    }
    _updateConnectionState(ConnectionStatus.error, error: error.toString());
    _scheduleReconnect();
  }

  void _handleDisconnection() {
    if (Environment.enableDebugLogs) {
      print('🔌 WebSocket disconnected');
    }
    _channel = null;
    _subscription = null;
    _heartbeatTimer?.cancel();
    
    if (!_isDisposed) {
      _updateConnectionState(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= _maxReconnectAttempts) {
      if (Environment.enableDebugLogs) {
        print('❌ Max reconnection attempts reached or service disposed');
      }
      _updateConnectionState(ConnectionStatus.error, error: 'Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectDelay.inSeconds * _reconnectAttempts);
    
    if (Environment.enableDebugLogs) {
      print('🔄 Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');
    }
    _updateConnectionState(ConnectionStatus.reconnecting);
    
    _reconnectTimer = Timer(delay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_channel != null && _currentState.isConnected) {
        _sendEvent(HeartbeatEvent(timestamp: DateTime.now()));
      }
    });
  }

  void _sendEvent(WebSocketEvent event) {
    if (_channel == null || !_currentState.isConnected) {
      if (Environment.enableDebugLogs) {
        print('⚠️ Cannot send event: WebSocket not connected');
      }
      return;
    }

    try {
      final message = jsonEncode(event.toJson());
      _channel!.sink.add(message);
    } catch (e) {
      if (Environment.enableDebugLogs) {
        print('❌ Failed to send WebSocket event: $e');
      }
    }
  }

  void _updateConnectionState(ConnectionStatus status, {String? error}) {
    _currentState = _currentState.copyWith(
      status: status,
      error: error,
      lastConnected: status == ConnectionStatus.connected ? DateTime.now() : null,
      reconnectAttempts: _reconnectAttempts,
    );
    
    if (!_connectionController.isClosed) {
      _connectionController.add(_currentState);
    }
  }

  void _addOnlineUser(int userId) {
    if (!_currentState.onlineUsers.contains(userId)) {
      final updatedUsers = [..._currentState.onlineUsers, userId];
      _currentState = _currentState.copyWith(onlineUsers: updatedUsers);
      _connectionController.add(_currentState);
    }
  }

  void _removeOnlineUser(int userId) {
    if (_currentState.onlineUsers.contains(userId)) {
      final updatedUsers = _currentState.onlineUsers.where((id) => id != userId).toList();
      _currentState = _currentState.copyWith(onlineUsers: updatedUsers);
      _connectionController.add(_currentState);
    }
  }

  // Public methods for sending events
  void sendTaskUpdate(int taskId, Map<String, dynamic> changes) {
    // This would typically be handled by the backend after API calls
    // but can be used for optimistic updates
  }

  void sendUserTyping(int taskId, String context) {
    if (_currentState.isConnected) {
      _sendEvent(UserTypingEvent(
        userId: 0, // Will be set by server based on token
        taskId: taskId,
        context: context,
        timestamp: DateTime.now(),
      ));
    }
  }

  void sendUserStoppedTyping(int taskId, String context) {
    if (_currentState.isConnected) {
      _sendEvent(UserStoppedTypingEvent(
        userId: 0, // Will be set by server based on token
        taskId: taskId,
        context: context,
        timestamp: DateTime.now(),
      ));
    }
  }

  // Cleanup
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }

  // Utility methods
  bool get isConnected => _currentState.isConnected;
  bool get isConnecting => _currentState.isConnecting;
  List<int> get onlineUsers => _currentState.onlineUsers;
  
  // Event filtering helpers
  Stream<T> eventsOfType<T extends WebSocketEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  Stream<TaskUpdatedEvent> get taskUpdates => eventsOfType<TaskUpdatedEvent>();
  Stream<TaskCreatedEvent> get taskCreated => eventsOfType<TaskCreatedEvent>();
  Stream<TaskDeletedEvent> get taskDeleted => eventsOfType<TaskDeletedEvent>();
  Stream<TaskStatusChangedEvent> get taskStatusChanged => eventsOfType<TaskStatusChangedEvent>();
  Stream<TaskAssignedEvent> get taskAssigned => eventsOfType<TaskAssignedEvent>();
  Stream<TaskCommentAddedEvent> get taskCommentAdded => eventsOfType<TaskCommentAddedEvent>();
  Stream<UserOnlineEvent> get userOnline => eventsOfType<UserOnlineEvent>();
  Stream<UserOfflineEvent> get userOffline => eventsOfType<UserOfflineEvent>();
  Stream<UserTypingEvent> get userTyping => eventsOfType<UserTypingEvent>();
  Stream<UserStoppedTypingEvent> get userStoppedTyping => eventsOfType<UserStoppedTypingEvent>();
  Stream<NotificationEvent> get notifications => eventsOfType<NotificationEvent>();
}