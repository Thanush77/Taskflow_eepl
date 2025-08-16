import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/websocket_events.dart';
import '../services/websocket_service.dart';
import 'task_provider.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  
  // Dispose service when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

final webSocketConnectionProvider = StreamProvider<ConnectionState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionState;
});

final webSocketEventsProvider = StreamProvider<WebSocketEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events;
});

// Specific event type providers for easier consumption
final taskUpdatesProvider = StreamProvider<TaskUpdatedEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.taskUpdates;
});

final taskCreatedProvider = StreamProvider<TaskCreatedEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.taskCreated;
});

final taskDeletedProvider = StreamProvider<TaskDeletedEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.taskDeleted;
});

final taskStatusChangedProvider = StreamProvider<TaskStatusChangedEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.taskStatusChanged;
});

final taskAssignedProvider = StreamProvider<TaskAssignedEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.taskAssigned;
});

final taskCommentAddedProvider = StreamProvider<TaskCommentAddedEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.taskCommentAdded;
});

final userOnlineProvider = StreamProvider<UserOnlineEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.userOnline;
});

final userOfflineProvider = StreamProvider<UserOfflineEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.userOffline;
});

final userTypingProvider = StreamProvider<UserTypingEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.userTyping;
});

final userStoppedTypingProvider = StreamProvider<UserStoppedTypingEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.userStoppedTyping;
});

final notificationsProvider = StreamProvider<NotificationEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.notifications;
});

// Current connection state provider (synchronous)
final currentConnectionStateProvider = Provider<ConnectionState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.currentState;
});

// Online users provider
final onlineUsersProvider = Provider<List<int>>((ref) {
  final connectionState = ref.watch(currentConnectionStateProvider);
  return connectionState.onlineUsers;
});

// Connection status helpers
final isConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(currentConnectionStateProvider);
  return connectionState.isConnected;
});

final isConnectingProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(currentConnectionStateProvider);
  return connectionState.isConnecting;
});

// Typing indicators for specific tasks
final typingIndicatorsProvider = StateNotifierProvider<TypingIndicatorsNotifier, Map<int, List<int>>>((ref) {
  return TypingIndicatorsNotifier(ref);
});

class TypingIndicatorsNotifier extends StateNotifier<Map<int, List<int>>> {
  final Ref ref;
  
  TypingIndicatorsNotifier(this.ref) : super({}) {
    // Listen to typing events and update state
    ref.listen(userTypingProvider, (previous, next) {
      next.whenData((event) {
        _addTypingUser(event.taskId, event.userId);
        // Auto-remove after 3 seconds if no stop typing event
        Future.delayed(const Duration(seconds: 3), () {
          _removeTypingUser(event.taskId, event.userId);
        });
      });
    });
    
    ref.listen(userStoppedTypingProvider, (previous, next) {
      next.whenData((event) {
        _removeTypingUser(event.taskId, event.userId);
      });
    });
  }
  
  void _addTypingUser(int taskId, int userId) {
    final currentState = {...state};
    final currentUsers = currentState[taskId] ?? [];
    
    if (!currentUsers.contains(userId)) {
      currentState[taskId] = [...currentUsers, userId];
      state = currentState;
    }
  }
  
  void _removeTypingUser(int taskId, int userId) {
    final currentState = {...state};
    final currentUsers = currentState[taskId] ?? [];
    
    if (currentUsers.contains(userId)) {
      final updatedUsers = currentUsers.where((id) => id != userId).toList();
      if (updatedUsers.isEmpty) {
        currentState.remove(taskId);
      } else {
        currentState[taskId] = updatedUsers;
      }
      state = currentState;
    }
  }
  
  List<int> getTypingUsersForTask(int taskId) {
    return state[taskId] ?? [];
  }
}

// WebSocket actions
class WebSocketActions {
  final Ref ref;
  
  WebSocketActions(this.ref);
  
  Future<void> connect() async {
    final service = ref.read(webSocketServiceProvider);
    await service.connect();
  }
  
  Future<void> disconnect() async {
    final service = ref.read(webSocketServiceProvider);
    await service.disconnect();
  }
  
  void sendUserTyping(int taskId, String context) {
    final service = ref.read(webSocketServiceProvider);
    service.sendUserTyping(taskId, context);
  }
  
  void sendUserStoppedTyping(int taskId, String context) {
    final service = ref.read(webSocketServiceProvider);
    service.sendUserStoppedTyping(taskId, context);
  }
}

final webSocketActionsProvider = Provider<WebSocketActions>((ref) {
  return WebSocketActions(ref);
});

// Real-time task synchronization
class RealTimeTaskSync extends StateNotifier<bool> {
  final Ref ref;
  
  RealTimeTaskSync(this.ref) : super(false) {
    _setupTaskEventListeners();
  }
  
  void _setupTaskEventListeners() {
    // Listen to task updates and sync with task provider
    ref.listen(taskUpdatesProvider, (previous, next) {
      next.whenData((event) async {
        // Update task in the task provider
        final taskNotifier = ref.read(taskProvider.notifier);
        await taskNotifier.updateTaskFromEvent(event);
      });
    });
    
    ref.listen(taskCreatedProvider, (previous, next) {
      next.whenData((event) async {
        final taskNotifier = ref.read(taskProvider.notifier);
        await taskNotifier.addTaskFromEvent(event);
      });
    });
    
    ref.listen(taskDeletedProvider, (previous, next) {
      next.whenData((event) async {
        final taskNotifier = ref.read(taskProvider.notifier);
        await taskNotifier.removeTaskFromEvent(event);
      });
    });
    
    ref.listen(taskStatusChangedProvider, (previous, next) {
      next.whenData((event) async {
        final taskNotifier = ref.read(taskProvider.notifier);
        await taskNotifier.updateTaskStatusFromEvent(event);
      });
    });
    
    ref.listen(taskAssignedProvider, (previous, next) {
      next.whenData((event) async {
        final taskNotifier = ref.read(taskProvider.notifier);
        await taskNotifier.updateTaskAssignmentFromEvent(event);
      });
    });
  }
}


final realTimeTaskSyncProvider = StateNotifierProvider<RealTimeTaskSync, bool>((ref) {
  return RealTimeTaskSync(ref);
});