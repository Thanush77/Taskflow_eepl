import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Comment state
class CommentState {
  final Map<int, List<TaskComment>> taskComments; // taskId -> List<TaskComment>
  final List<ActivityLogEntry> activityLog;
  final bool isLoading;
  final String? error;

  const CommentState({
    this.taskComments = const {},
    this.activityLog = const [],
    this.isLoading = false,
    this.error,
  });

  CommentState copyWith({
    Map<int, List<TaskComment>>? taskComments,
    List<ActivityLogEntry>? activityLog,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      taskComments: taskComments ?? this.taskComments,
      activityLog: activityLog ?? this.activityLog,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Comment notifier
class CommentNotifier extends StateNotifier<CommentState> {
  final ApiService _apiService;

  CommentNotifier(this._apiService) : super(const CommentState());

  // Load comments for a task
  Future<void> loadTaskComments(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.getTaskComments(taskId);
      if (response['success'] == true) {
        final List<dynamic> commentsJson = response['data'] ?? [];
        final comments = commentsJson.map((json) => TaskComment.fromJson(json)).toList();
        
        // Sort comments by creation date (oldest first)
        comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        final updatedComments = Map<int, List<TaskComment>>.from(state.taskComments);
        updatedComments[taskId] = comments;
        
        state = state.copyWith(
          taskComments: updatedComments,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load comments',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Add a comment to a task
  Future<bool> addComment(int taskId, String content) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.createTaskComment({
        'taskId': taskId,
        'content': content,
        'type': CommentType.comment.name,
      });

      if (response['success'] == true) {
        // Reload comments for this task to get the new comment
        await loadTaskComments(taskId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to add comment',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update a comment
  Future<bool> updateComment(int commentId, String content) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.updateTaskComment(commentId, {
        'content': content,
        'isEdited': true,
      });

      if (response['success'] == true) {
        // Update local state
        final updatedComments = Map<int, List<TaskComment>>.from(state.taskComments);
        
        for (final taskId in updatedComments.keys) {
          final comments = updatedComments[taskId]!;
          final index = comments.indexWhere((c) => c.id == commentId);
          
          if (index >= 0) {
            updatedComments[taskId]![index] = comments[index].copyWith(
              content: content,
              isEdited: true,
              updatedAt: DateTime.now(),
            );
            break;
          }
        }

        state = state.copyWith(
          taskComments: updatedComments,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to update comment',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(int commentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteTaskComment(commentId);
      if (response['success'] == true) {
        // Remove comment from local state
        final updatedComments = Map<int, List<TaskComment>>.from(state.taskComments);
        
        for (final taskId in updatedComments.keys) {
          updatedComments[taskId] = updatedComments[taskId]!
              .where((comment) => comment.id != commentId)
              .toList();
        }

        state = state.copyWith(
          taskComments: updatedComments,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete comment',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Add system comment (for tracking changes)
  Future<void> addSystemComment(
    int taskId, 
    CommentType type, 
    String content, 
    {Map<String, dynamic>? metadata}
  ) async {
    try {
      await _apiService.createTaskComment({
        'taskId': taskId,
        'content': content,
        'type': type.name,
        'metadata': metadata,
      });

      // Reload comments to show the system comment
      await loadTaskComments(taskId);
    } catch (e) {
      // System comments failing shouldn't block the main operation
      print('Failed to add system comment: $e');
    }
  }

  // Load activity log
  Future<void> loadActivityLog({int? taskId, int? userId, int limit = 50}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (taskId != null) queryParams['taskId'] = taskId;
      if (userId != null) queryParams['userId'] = userId;

      final response = await _apiService.getActivityLog(queryParams);
      if (response['success'] == true) {
        final List<dynamic> activitiesJson = response['data'] ?? [];
        final activities = activitiesJson.map((json) => ActivityLogEntry.fromJson(json)).toList();
        
        // Sort activities by creation date (newest first)
        activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        state = state.copyWith(
          activityLog: activities,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load activity log',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get comments for a specific task
  List<TaskComment> getTaskComments(int taskId) {
    return state.taskComments[taskId] ?? [];
  }

  // Get comment count for a task
  int getCommentCount(int taskId) {
    final comments = state.taskComments[taskId] ?? [];
    return comments.where((c) => c.type == CommentType.comment).length;
  }

  // Get activity count for a task
  int getActivityCount(int taskId) {
    final comments = state.taskComments[taskId] ?? [];
    return comments.where((c) => c.isSystemComment).length;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh comments for a task
  Future<void> refreshTaskComments(int taskId) async {
    await loadTaskComments(taskId);
  }

  // Refresh activity log
  Future<void> refreshActivityLog() async {
    await loadActivityLog();
  }
}

// Comment provider
final commentProvider = StateNotifierProvider<CommentNotifier, CommentState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CommentNotifier(apiService);
});