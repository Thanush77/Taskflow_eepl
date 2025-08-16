import 'task.dart';

enum WebSocketEventType {
  taskUpdated,
  taskCreated,
  taskDeleted,
  taskStatusChanged,
  taskAssigned,
  taskCommentAdded,
  userOnline,
  userOffline,
  userTyping,
  userStoppedTyping,
  notification,
  connectionEstablished,
  heartbeat,
}

abstract class WebSocketEvent {
  final WebSocketEventType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const WebSocketEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final type = WebSocketEventType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => WebSocketEventType.heartbeat,
    );
    
    final timestamp = DateTime.parse(json['timestamp']);
    final data = json['data'] as Map<String, dynamic>;

    switch (type) {
      case WebSocketEventType.taskUpdated:
        return TaskUpdatedEvent.fromJson(json);
      case WebSocketEventType.taskCreated:
        return TaskCreatedEvent.fromJson(json);
      case WebSocketEventType.taskDeleted:
        return TaskDeletedEvent.fromJson(json);
      case WebSocketEventType.taskStatusChanged:
        return TaskStatusChangedEvent.fromJson(json);
      case WebSocketEventType.taskAssigned:
        return TaskAssignedEvent.fromJson(json);
      case WebSocketEventType.taskCommentAdded:
        return TaskCommentAddedEvent.fromJson(json);
      case WebSocketEventType.userOnline:
        return UserOnlineEvent.fromJson(json);
      case WebSocketEventType.userOffline:
        return UserOfflineEvent.fromJson(json);
      case WebSocketEventType.userTyping:
        return UserTypingEvent.fromJson(json);
      case WebSocketEventType.userStoppedTyping:
        return UserStoppedTypingEvent.fromJson(json);
      case WebSocketEventType.notification:
        return NotificationEvent.fromJson(json);
      case WebSocketEventType.connectionEstablished:
        return ConnectionEstablishedEvent.fromJson(json);
      case WebSocketEventType.heartbeat:
        return HeartbeatEvent.fromJson(json);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class TaskUpdatedEvent extends WebSocketEvent {
  final Task task;
  final int updatedBy;
  final Map<String, dynamic> changes;

  const TaskUpdatedEvent({
    required this.task,
    required this.updatedBy,
    required this.changes,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.taskUpdated,
          timestamp: timestamp,
          data: const {},
        );

  factory TaskUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return TaskUpdatedEvent(
      task: Task.fromJson(json['data']['task']),
      updatedBy: json['data']['updatedBy'],
      changes: json['data']['changes'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'task': task.toJson(),
        'updatedBy': updatedBy,
        'changes': changes,
      },
    };
  }
}

class TaskCreatedEvent extends WebSocketEvent {
  final Task task;
  final int createdBy;

  const TaskCreatedEvent({
    required this.task,
    required this.createdBy,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.taskCreated,
          timestamp: timestamp,
          data: const {},
        );

  factory TaskCreatedEvent.fromJson(Map<String, dynamic> json) {
    return TaskCreatedEvent(
      task: Task.fromJson(json['data']['task']),
      createdBy: json['data']['createdBy'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'task': task.toJson(),
        'createdBy': createdBy,
      },
    };
  }
}

class TaskDeletedEvent extends WebSocketEvent {
  final int taskId;
  final int deletedBy;

  const TaskDeletedEvent({
    required this.taskId,
    required this.deletedBy,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.taskDeleted,
          timestamp: timestamp,
          data: const {},
        );

  factory TaskDeletedEvent.fromJson(Map<String, dynamic> json) {
    return TaskDeletedEvent(
      taskId: json['data']['taskId'],
      deletedBy: json['data']['deletedBy'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'taskId': taskId,
        'deletedBy': deletedBy,
      },
    };
  }
}

class TaskStatusChangedEvent extends WebSocketEvent {
  final int taskId;
  final TaskStatus oldStatus;
  final TaskStatus newStatus;
  final int changedBy;

  const TaskStatusChangedEvent({
    required this.taskId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.taskStatusChanged,
          timestamp: timestamp,
          data: const {},
        );

  factory TaskStatusChangedEvent.fromJson(Map<String, dynamic> json) {
    return TaskStatusChangedEvent(
      taskId: json['data']['taskId'],
      oldStatus: TaskStatus.values.firstWhere(
        (e) => e.name == json['data']['oldStatus'],
      ),
      newStatus: TaskStatus.values.firstWhere(
        (e) => e.name == json['data']['newStatus'],
      ),
      changedBy: json['data']['changedBy'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'taskId': taskId,
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'changedBy': changedBy,
      },
    };
  }
}

class TaskAssignedEvent extends WebSocketEvent {
  final int taskId;
  final int? previousAssignee;
  final int? newAssignee;
  final int assignedBy;

  const TaskAssignedEvent({
    required this.taskId,
    this.previousAssignee,
    this.newAssignee,
    required this.assignedBy,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.taskAssigned,
          timestamp: timestamp,
          data: const {},
        );

  factory TaskAssignedEvent.fromJson(Map<String, dynamic> json) {
    return TaskAssignedEvent(
      taskId: json['data']['taskId'],
      previousAssignee: json['data']['previousAssignee'],
      newAssignee: json['data']['newAssignee'],
      assignedBy: json['data']['assignedBy'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'taskId': taskId,
        'previousAssignee': previousAssignee,
        'newAssignee': newAssignee,
        'assignedBy': assignedBy,
      },
    };
  }
}

class TaskCommentAddedEvent extends WebSocketEvent {
  final int taskId;
  final Map<String, dynamic> comment;
  final int addedBy;

  const TaskCommentAddedEvent({
    required this.taskId,
    required this.comment,
    required this.addedBy,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.taskCommentAdded,
          timestamp: timestamp,
          data: const {},
        );

  factory TaskCommentAddedEvent.fromJson(Map<String, dynamic> json) {
    return TaskCommentAddedEvent(
      taskId: json['data']['taskId'],
      comment: json['data']['comment'],
      addedBy: json['data']['addedBy'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'taskId': taskId,
        'comment': comment,
        'addedBy': addedBy,
      },
    };
  }
}

class UserOnlineEvent extends WebSocketEvent {
  final int userId;
  final String username;

  const UserOnlineEvent({
    required this.userId,
    required this.username,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.userOnline,
          timestamp: timestamp,
          data: const {},
        );

  factory UserOnlineEvent.fromJson(Map<String, dynamic> json) {
    return UserOnlineEvent(
      userId: json['data']['userId'],
      username: json['data']['username'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'userId': userId,
        'username': username,
      },
    };
  }
}

class UserOfflineEvent extends WebSocketEvent {
  final int userId;
  final String username;

  const UserOfflineEvent({
    required this.userId,
    required this.username,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.userOffline,
          timestamp: timestamp,
          data: const {},
        );

  factory UserOfflineEvent.fromJson(Map<String, dynamic> json) {
    return UserOfflineEvent(
      userId: json['data']['userId'],
      username: json['data']['username'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'userId': userId,
        'username': username,
      },
    };
  }
}

class UserTypingEvent extends WebSocketEvent {
  final int userId;
  final int taskId;
  final String context;

  const UserTypingEvent({
    required this.userId,
    required this.taskId,
    required this.context,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.userTyping,
          timestamp: timestamp,
          data: const {},
        );

  factory UserTypingEvent.fromJson(Map<String, dynamic> json) {
    return UserTypingEvent(
      userId: json['data']['userId'],
      taskId: json['data']['taskId'],
      context: json['data']['context'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'userId': userId,
        'taskId': taskId,
        'context': context,
      },
    };
  }
}

class UserStoppedTypingEvent extends WebSocketEvent {
  final int userId;
  final int taskId;
  final String context;

  const UserStoppedTypingEvent({
    required this.userId,
    required this.taskId,
    required this.context,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.userStoppedTyping,
          timestamp: timestamp,
          data: const {},
        );

  factory UserStoppedTypingEvent.fromJson(Map<String, dynamic> json) {
    return UserStoppedTypingEvent(
      userId: json['data']['userId'],
      taskId: json['data']['taskId'],
      context: json['data']['context'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'userId': userId,
        'taskId': taskId,
        'context': context,
      },
    };
  }
}

class NotificationEvent extends WebSocketEvent {
  final String title;
  final String message;
  final String? icon;
  final Map<String, dynamic>? actionData;

  const NotificationEvent({
    required this.title,
    required this.message,
    this.icon,
    this.actionData,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.notification,
          timestamp: timestamp,
          data: const {},
        );

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      title: json['data']['title'],
      message: json['data']['message'],
      icon: json['data']['icon'],
      actionData: json['data']['actionData'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'title': title,
        'message': message,
        if (icon != null) 'icon': icon,
        if (actionData != null) 'actionData': actionData,
      },
    };
  }
}

class ConnectionEstablishedEvent extends WebSocketEvent {
  final String sessionId;
  final int userId;

  const ConnectionEstablishedEvent({
    required this.sessionId,
    required this.userId,
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.connectionEstablished,
          timestamp: timestamp,
          data: const {},
        );

  factory ConnectionEstablishedEvent.fromJson(Map<String, dynamic> json) {
    return ConnectionEstablishedEvent(
      sessionId: json['data']['sessionId'],
      userId: json['data']['userId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'sessionId': sessionId,
        'userId': userId,
      },
    };
  }
}

class HeartbeatEvent extends WebSocketEvent {
  const HeartbeatEvent({
    required DateTime timestamp,
  }) : super(
          type: WebSocketEventType.heartbeat,
          timestamp: timestamp,
          data: const {},
        );

  factory HeartbeatEvent.fromJson(Map<String, dynamic> json) {
    return HeartbeatEvent(
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': {},
    };
  }
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionState {
  final ConnectionStatus status;
  final String? error;
  final DateTime? lastConnected;
  final int reconnectAttempts;
  final List<int> onlineUsers;

  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.error,
    this.lastConnected,
    this.reconnectAttempts = 0,
    this.onlineUsers = const [],
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? error,
    DateTime? lastConnected,
    int? reconnectAttempts,
    List<int>? onlineUsers,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      error: error,
      lastConnected: lastConnected ?? this.lastConnected,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      onlineUsers: onlineUsers ?? this.onlineUsers,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting || status == ConnectionStatus.reconnecting;
}