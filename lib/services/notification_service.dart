import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/websocket_events.dart';
import '../providers/websocket_provider.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static const String _channelId = 'taskflow_notifications';
  static const String _channelName = 'TaskFlow Notifications';
  static const String _channelDescription = 'Real-time task and collaboration notifications';

  static Future<void> initialize() async {
    if (_initialized) return;

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
    
    _initialized = true;
  }

  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate accordingly
      // This would integrate with your navigation system
    }
  }

  static Future<bool> requestPermissions() async {
    bool granted = false;
    
    // Request permissions for iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    
    // Request permissions for Android (13+)
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      granted = await androidPlugin.requestNotificationsPermission() ?? granted;
    }
    
    return granted;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.defaultPriority,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> showTaskNotification(NotificationEvent event) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await showNotification(
      id: id,
      title: event.title,
      body: event.message,
      payload: event.actionData?.toString(),
      priority: _getPriorityFromIcon(event.icon),
    );
  }

  static NotificationPriority _getPriorityFromIcon(String? icon) {
    switch (icon) {
      case 'priority':
      case 'error':
        return NotificationPriority.high;
      case 'warning':
        return NotificationPriority.defaultPriority;
      default:
        return NotificationPriority.low;
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

// Provider for notification service integration
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Auto notification handler for WebSocket events
class AutoNotificationHandler {
  final Ref ref;
  bool _isBackground = false;

  AutoNotificationHandler(this.ref) {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    // Listen to various WebSocket events and show notifications when app is in background
    ref.listen(taskUpdatesProvider, (previous, next) {
      next.whenData((event) {
        if (_isBackground) {
          _showTaskUpdateNotification(event);
        }
      });
    });

    ref.listen(taskCreatedProvider, (previous, next) {
      next.whenData((event) {
        if (_isBackground) {
          _showTaskCreatedNotification(event);
        }
      });
    });

    ref.listen(taskAssignedProvider, (previous, next) {
      next.whenData((event) {
        if (_isBackground) {
          _showTaskAssignedNotification(event);
        }
      });
    });

    ref.listen(taskCommentAddedProvider, (previous, next) {
      next.whenData((event) {
        if (_isBackground) {
          _showCommentNotification(event);
        }
      });
    });

    ref.listen(notificationsProvider, (previous, next) {
      next.whenData((event) {
        if (_isBackground) {
          NotificationService.showTaskNotification(event);
        }
      });
    });
  }

  void setBackgroundState(bool isBackground) {
    _isBackground = isBackground;
  }

  void _showTaskUpdateNotification(TaskUpdatedEvent event) {
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Task Updated',
      body: 'Task "${event.task.title}" has been updated',
      payload: 'task:${event.task.id}',
    );
  }

  void _showTaskCreatedNotification(TaskCreatedEvent event) {
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'New Task Created',
      body: 'Task "${event.task.title}" has been created',
      payload: 'task:${event.task.id}',
    );
  }

  void _showTaskAssignedNotification(TaskAssignedEvent event) {
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Task Assigned',
      body: 'You have been assigned to a new task',
      payload: 'task:${event.taskId}',
      priority: NotificationPriority.high,
    );
  }

  void _showCommentNotification(TaskCommentAddedEvent event) {
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'New Comment',
      body: 'A new comment was added to a task',
      payload: 'task:${event.taskId}',
    );
  }
}

final autoNotificationHandlerProvider = Provider<AutoNotificationHandler>((ref) {
  return AutoNotificationHandler(ref);
});

enum NotificationPriority {
  low,
  defaultPriority,
  high,
}