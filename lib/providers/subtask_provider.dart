import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subtask.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Subtask state
class SubtaskState {
  final Map<int, List<Subtask>> subtasks; // taskId -> List<Subtask>
  final Map<int, List<TaskDependency>> dependencies; // taskId -> List<TaskDependency>
  final bool isLoading;
  final String? error;

  const SubtaskState({
    this.subtasks = const {},
    this.dependencies = const {},
    this.isLoading = false,
    this.error,
  });

  SubtaskState copyWith({
    Map<int, List<Subtask>>? subtasks,
    Map<int, List<TaskDependency>>? dependencies,
    bool? isLoading,
    String? error,
  }) {
    return SubtaskState(
      subtasks: subtasks ?? this.subtasks,
      dependencies: dependencies ?? this.dependencies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Subtask notifier
class SubtaskNotifier extends StateNotifier<SubtaskState> {
  final ApiService _apiService;

  SubtaskNotifier(this._apiService) : super(const SubtaskState());

  // Load subtasks for a task
  Future<void> loadTaskSubtasks(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.getTaskSubtasks(taskId);
      if (response['success'] == true) {
        final List<dynamic> subtasksJson = response['data'] ?? [];
        final subtasks = subtasksJson.map((json) => Subtask.fromJson(json)).toList();
        
        final updatedSubtasks = Map<int, List<Subtask>>.from(state.subtasks);
        updatedSubtasks[taskId] = subtasks;
        
        state = state.copyWith(
          subtasks: updatedSubtasks,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load subtasks',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create a subtask
  Future<bool> createSubtask(Subtask subtask) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.createSubtask({
        'parentTaskId': subtask.parentTaskId,
        'title': subtask.title,
        'description': subtask.description,
        'assignedTo': subtask.assignedTo,
        'dueDate': subtask.dueDate?.toIso8601String(),
        'sortOrder': subtask.sortOrder,
      });

      if (response['success'] == true) {
        // Reload subtasks for this task
        await loadTaskSubtasks(subtask.parentTaskId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to create subtask',
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

  // Update a subtask
  Future<bool> updateSubtask(Subtask subtask) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.updateSubtask(subtask.id!, {
        'title': subtask.title,
        'description': subtask.description,
        'isCompleted': subtask.isCompleted,
        'assignedTo': subtask.assignedTo,
        'dueDate': subtask.dueDate?.toIso8601String(),
        'sortOrder': subtask.sortOrder,
      });

      if (response['success'] == true) {
        // Update local state
        final updatedSubtasks = Map<int, List<Subtask>>.from(state.subtasks);
        final taskSubtasks = updatedSubtasks[subtask.parentTaskId] ?? [];
        final index = taskSubtasks.indexWhere((s) => s.id == subtask.id);
        
        if (index >= 0) {
          taskSubtasks[index] = subtask;
          updatedSubtasks[subtask.parentTaskId] = taskSubtasks;
        }

        state = state.copyWith(
          subtasks: updatedSubtasks,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to update subtask',
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

  // Toggle subtask completion
  Future<bool> toggleSubtask(int subtaskId) async {
    try {
      // Find the subtask
      Subtask? targetSubtask;
      int? taskId;
      
      for (final entry in state.subtasks.entries) {
        final subtask = entry.value.where((s) => s.id == subtaskId).firstOrNull;
        if (subtask != null) {
          targetSubtask = subtask;
          taskId = entry.key;
          break;
        }
      }

      if (targetSubtask == null || taskId == null) return false;

      final updatedSubtask = targetSubtask.copyWith(
        isCompleted: !targetSubtask.isCompleted,
        completedAt: !targetSubtask.isCompleted ? DateTime.now() : null,
      );

      return await updateSubtask(updatedSubtask);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Delete a subtask
  Future<bool> deleteSubtask(int subtaskId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteSubtask(subtaskId);
      if (response['success'] == true) {
        // Remove subtask from local state
        final updatedSubtasks = Map<int, List<Subtask>>.from(state.subtasks);
        
        for (final taskId in updatedSubtasks.keys) {
          updatedSubtasks[taskId] = updatedSubtasks[taskId]!
              .where((subtask) => subtask.id != subtaskId)
              .toList();
        }

        state = state.copyWith(
          subtasks: updatedSubtasks,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete subtask',
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

  // Load task dependencies
  Future<void> loadTaskDependencies(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.getTaskDependencies(taskId);
      if (response['success'] == true) {
        final List<dynamic> dependenciesJson = response['data'] ?? [];
        final dependencies = dependenciesJson.map((json) => TaskDependency.fromJson(json)).toList();
        
        final updatedDependencies = Map<int, List<TaskDependency>>.from(state.dependencies);
        updatedDependencies[taskId] = dependencies;
        
        state = state.copyWith(
          dependencies: updatedDependencies,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load dependencies',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create a task dependency
  Future<bool> createDependency(int taskId, int dependsOnTaskId, String dependencyType) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.createTaskDependency(taskId, {
        'prerequisiteTaskId': dependsOnTaskId,
        'dependencyType': dependencyType,
      });

      if (response['success'] == true) {
        // Reload dependencies for this task
        await loadTaskDependencies(taskId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to create dependency',
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

  // Delete a task dependency
  Future<bool> deleteDependency(int taskId, int dependencyId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteTaskDependency(taskId, dependencyId);
      if (response['success'] == true) {
        // Remove dependency from local state
        final updatedDependencies = Map<int, List<TaskDependency>>.from(state.dependencies);
        
        for (final taskId in updatedDependencies.keys) {
          updatedDependencies[taskId] = updatedDependencies[taskId]!
              .where((dep) => dep.id != dependencyId)
              .toList();
        }

        state = state.copyWith(
          dependencies: updatedDependencies,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete dependency',
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

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh all data
  Future<void> refresh() async {
    for (final taskId in state.subtasks.keys) {
      await loadTaskSubtasks(taskId);
    }
    for (final taskId in state.dependencies.keys) {
      await loadTaskDependencies(taskId);
    }
  }
}

// Subtask provider
final subtaskProvider = StateNotifierProvider<SubtaskNotifier, SubtaskState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SubtaskNotifier(apiService);
});