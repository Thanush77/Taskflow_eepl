import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/user.dart';
import '../providers/websocket_provider.dart';
import '../providers/auth_provider.dart';

class UserPresenceAvatar extends ConsumerWidget {
  final User user;
  final double radius;
  final bool showPresence;

  const UserPresenceAvatar({
    required this.user,
    this.radius = 20,
    this.showPresence = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final isOnline = onlineUsers.contains(user.id);

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.gray300,
          child: Text(
            _getInitials(user.fullName),
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
        if (showPresence)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.successColor : AppColors.gray400,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String fullName) {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }
}

class OnlineUsersList extends ConsumerWidget {
  final bool showCurrentUser;
  final int maxUsers;

  const OnlineUsersList({
    this.showCurrentUser = false,
    this.maxUsers = 10,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final currentUser = ref.watch(authProvider).user;
    final allUsers = ref.watch(usersProvider);

    return allUsers.when(
      data: (users) {
        final filteredUsers = users.where((user) {
          final isOnline = onlineUsers.contains(user.id);
          final includeUser = showCurrentUser || user.id != currentUser?.id;
          return isOnline && includeUser;
        }).take(maxUsers).toList();

        if (filteredUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.circle,
                      color: AppColors.successColor,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online (${filteredUsers.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...filteredUsers.map((user) => _buildUserItem(user)),
              if (onlineUsers.length > maxUsers)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${onlineUsers.length - maxUsers} more online',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildUserItem(User user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          UserPresenceAvatar(
            user: user,
            radius: 16,
            showPresence: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                ),
                if (user.role != null)
                  Text(
                    user.role!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.successColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class PresenceBadge extends ConsumerWidget {
  final int userId;
  final Widget child;

  const PresenceBadge({
    required this.userId,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final isOnline = onlineUsers.contains(userId);

    if (!isOnline) {
      return child;
    }

    return Badge(
      backgroundColor: AppColors.successColor,
      smallSize: 8,
      child: child,
    );
  }
}

class TeamPresenceIndicator extends ConsumerWidget {
  final List<int> userIds;
  final double avatarSize;
  final int maxAvatars;

  const TeamPresenceIndicator({
    required this.userIds,
    this.avatarSize = 24,
    this.maxAvatars = 5,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineUsers = ref.watch(onlineUsersProvider);
    final allUsers = ref.watch(usersProvider);

    return allUsers.when(
      data: (users) {
        final filteredUsers = users
            .where((user) => userIds.contains(user.id))
            .take(maxAvatars)
            .toList();

        if (filteredUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            SizedBox(
              height: avatarSize * 2,
              width: (avatarSize * 1.5 * (filteredUsers.length - 1)) + avatarSize * 2,
              child: Stack(
                children: filteredUsers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final isOnline = onlineUsers.contains(user.id);
                  
                  return Positioned(
                    left: index * avatarSize * 1.5,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: avatarSize,
                            backgroundColor: isOnline 
                                ? AppColors.gray300 
                                : AppColors.gray200,
                            child: Text(
                              _getInitials(user.fullName),
                              style: TextStyle(
                                fontSize: avatarSize * 0.6,
                                fontWeight: FontWeight.w600,
                                color: isOnline 
                                    ? AppColors.white 
                                    : AppColors.gray500,
                              ),
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: avatarSize * 0.4,
                                height: avatarSize * 0.4,
                                decoration: BoxDecoration(
                                  color: AppColors.successColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.white, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (userIds.length > maxAvatars)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${userIds.length - maxAvatars}',
                  style: TextStyle(
                    fontSize: avatarSize * 0.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray700,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => SizedBox(
        width: avatarSize * 2,
        height: avatarSize * 2,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  String _getInitials(String fullName) {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0].substring(0, 2).toUpperCase();
    }
    return 'U';
  }
}

// Placeholder for users provider - this will be replaced with actual implementation
final usersProvider = FutureProvider<List<User>>((ref) async {
  // This would fetch users from your API service
  return <User>[];
});

class CollaborationToolbar extends ConsumerWidget {
  final List<int> collaboratorIds;

  const CollaborationToolbar({
    required this.collaboratorIds,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineCollaborators = ref.watch(onlineUsersProvider)
        .where((userId) => collaboratorIds.contains(userId))
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamPresenceIndicator(
            userIds: collaboratorIds,
            avatarSize: 16,
            maxAvatars: 3,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: onlineCollaborators > 0 
                  ? AppColors.successColor.withValues(alpha: 0.1) 
                  : AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$onlineCollaborators online',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: onlineCollaborators > 0 
                    ? AppColors.successColor 
                    : AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}