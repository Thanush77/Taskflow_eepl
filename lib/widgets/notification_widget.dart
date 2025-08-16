import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/websocket_events.dart';
import '../providers/websocket_provider.dart';

class NotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationOverlay({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends ConsumerState<NotificationOverlay> {
  final List<NotificationItem> _notifications = [];
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();

  @override
  void initState() {
    super.initState();
  }

  void _showNotification(NotificationEvent event) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.title,
      message: event.message,
      icon: event.icon,
      timestamp: event.timestamp,
      actionData: event.actionData,
    );

    setState(() {
      _notifications.insert(0, notification);
      // Keep only the last 5 notifications
      if (_notifications.length > 5) {
        _notifications.removeLast();
      }
    });

    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _removeNotification(notification.id);
    });
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsProvider, (previous, next) {
      next.whenData((notification) {
        _showNotification(notification);
      });
    });

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Overlay(
        key: _overlayKey,
        initialEntries: [
          OverlayEntry(
            builder: (context) => Scaffold(
              body: Stack(
                children: [
                  widget.child,
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _notifications
                          .map((notification) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildNotificationCard(notification),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.white,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                if (notification.icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(notification.icon!),
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeNotification(notification.id),
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.gray500,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Message
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Footer
            Row(
              children: [
                Text(
                  _formatTime(notification.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                  ),
                ),
                const Spacer(),
                if (notification.actionData != null)
                  TextButton(
                    onPressed: () => _handleAction(notification.actionData!),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'task':
        return Icons.task_alt;
      case 'assignment':
        return Icons.assignment_ind;
      case 'comment':
        return Icons.comment;
      case 'priority':
        return Icons.priority_high;
      case 'status':
        return Icons.update;
      case 'user':
        return Icons.person;
      case 'team':
        return Icons.group;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _handleAction(Map<String, dynamic> actionData) {
    // Handle notification actions like navigation
    final type = actionData['type'] as String?;
    final id = actionData['id'] as int?;
    
    if (type == 'task' && id != null) {
      // Navigate to task detail
      Navigator.of(context).pushNamed('/task-detail', arguments: id);
    } else if (type == 'user' && id != null) {
      // Navigate to user profile
      Navigator.of(context).pushNamed('/user-profile', arguments: id);
    }
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String? icon;
  final DateTime timestamp;
  final Map<String, dynamic>? actionData;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.icon,
    required this.timestamp,
    this.actionData,
  });
}

// Connection status indicator
class ConnectionStatusIndicator extends ConsumerWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(currentConnectionStateProvider);
    
    if (connectionState.status == ConnectionStatus.connected) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(connectionState.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(connectionState.status)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: connectionState.isConnecting
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_getStatusColor(connectionState.status)),
                  )
                : Icon(
                    _getStatusIcon(connectionState.status),
                    size: 12,
                    color: _getStatusColor(connectionState.status),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(connectionState.status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(connectionState.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.successColor;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return AppColors.warningColor;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return AppColors.errorColor;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.wifi;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        return Icons.wifi_find;
      case ConnectionStatus.disconnected:
        return Icons.wifi_off;
      case ConnectionStatus.error:
        return Icons.error_outline;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }
}

// User presence indicator widget
class UserPresenceIndicator extends ConsumerWidget {
  final int userId;
  final double size;

  const UserPresenceIndicator({
    required this.userId,
    this.size = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final isOnline = onlineUsers.contains(userId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.successColor : AppColors.gray400,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 2),
      ),
    );
  }
}

// Typing indicator widget
class TypingIndicator extends ConsumerWidget {
  final int taskId;

  const TypingIndicator({
    required this.taskId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = ref.watch(typingIndicatorsProvider.select(
      (indicators) => indicators[taskId] ?? <int>[],
    ));

    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: TypingAnimation(),
          ),
          const SizedBox(width: 6),
          Text(
            typingUsers.length == 1
                ? '1 person typing...'
                : '${typingUsers.length} people typing...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class TypingAnimation extends StatefulWidget {
  const TypingAnimation({super.key});

  @override
  TypingAnimationState createState() => TypingAnimationState();
}

class TypingAnimationState extends State<TypingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = Curves.easeInOut.transform(
              (((_controller.value - delay) % 1.0).clamp(0.0, 1.0)),
            );
            return Transform.translate(
              offset: Offset(0, -2 * animationValue),
              child: Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}