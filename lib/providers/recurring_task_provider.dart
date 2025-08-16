import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_task.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Recurring task state
class RecurringTaskState {
  final List<RecurringTask> recurringTasks;
  final bool isLoading;
  final String? error;

  const RecurringTaskState({
    this.recurringTasks = const [],
    this.isLoading = false,
    this.error,
  });

  RecurringTaskState copyWith({
    List<RecurringTask>? recurringTasks,
    bool? isLoading,
    String? error,
  }) {
    return RecurringTaskState(
      recurringTasks: recurringTasks ?? this.recurringTasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Computed getters
  List<RecurringTask> get activeRecurringTasks => 
      recurringTasks.where((rt) => rt.isActive && !rt.shouldStop).toList();
  
  List<RecurringTask> get dueRecurringTasks => 
      activeRecurringTasks.where((rt) => rt.isDue).toList();
  
  List<RecurringTask> get pausedRecurringTasks => 
      recurringTasks.where((rt) => !rt.isActive).toList();
  
  List<RecurringTask> get completedRecurringTasks => 
      recurringTasks.where((rt) => rt.shouldStop).toList();
}

// Recurring task notifier
class RecurringTaskNotifier extends StateNotifier<RecurringTaskState> {
  final ApiService _apiService;

  RecurringTaskNotifier(this._apiService) : super(const RecurringTaskState());

  // Load all recurring tasks
  Future<void> loadRecurringTasks() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.getRecurringTasks();
      if (response['success'] == true) {
        final List<dynamic> tasksJson = response['data'] ?? [];
        final recurringTasks = tasksJson.map((json) => RecurringTask.fromJson(json)).toList();
        
        state = state.copyWith(
          recurringTasks: recurringTasks,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load recurring tasks',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create a recurring task
  Future<bool> createRecurringTask(RecurringTask recurringTask) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.createRecurringTask({
        'title': recurringTask.title,
        'description': recurringTask.description,
        'assignedTo': recurringTask.assignedTo,
        'priority': recurringTask.priority.name,
        'category': recurringTask.category.name,
        'estimatedHours': recurringTask.estimatedHours,
        'recurrencePattern': recurringTask.recurrencePattern.toJson(),
        'startDate': recurringTask.startDate.toIso8601String(),
        'tags': recurringTask.tags,
      });

      if (response['success'] == true) {
        // Reload recurring tasks
        await loadRecurringTasks();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to create recurring task',
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

  // Update a recurring task
  Future<bool> updateRecurringTask(int taskId, Map<String, dynamic> updates) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.updateRecurringTask(taskId, updates);
      if (response['success'] == true) {
        // Update local state
        final updatedTasks = state.recurringTasks.map((rt) {
          if (rt.id == taskId) {
            // Create updated recurring task with new data
            return RecurringTask.fromJson({
              ...rt.toJson(),
              ...updates,
            });
          }
          return rt;
        }).toList();

        state = state.copyWith(
          recurringTasks: updatedTasks,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to update recurring task',
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

  // Toggle recurring task active status
  Future<bool> toggleRecurringTaskStatus(int taskId) async {
    final recurringTask = state.recurringTasks.where((rt) => rt.id == taskId).firstOrNull;
    if (recurringTask == null) return false;

    return await updateRecurringTask(taskId, {'isActive': !recurringTask.isActive});
  }

  // Delete a recurring task
  Future<bool> deleteRecurringTask(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteRecurringTask(taskId);
      if (response['success'] == true) {
        // Remove from local state
        final updatedTasks = state.recurringTasks
            .where((rt) => rt.id != taskId)
            .toList();

        state = state.copyWith(
          recurringTasks: updatedTasks,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete recurring task',
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

  // Generate tasks for due recurring tasks
  Future<bool> generateRecurringTasks() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.generateRecurringTasks();
      if (response['success'] == true) {
        // Reload recurring tasks to get updated next due dates
        await loadRecurringTasks();
        
        final generatedCount = response['generated'] as int? ?? 0;
        if (generatedCount > 0) {
          // Optionally show success message with count
        }
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to generate recurring tasks',
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

  // Calculate next due date for a recurring task
  DateTime? calculateNextDueDate(RecurringTask recurringTask) {
    final pattern = recurringTask.recurrencePattern;
    final lastDate = recurringTask.lastGenerated ?? recurringTask.startDate;

    switch (pattern.type) {
      case RecurrenceType.daily:
        return lastDate.add(Duration(days: pattern.interval));
      
      case RecurrenceType.weekly:
        return lastDate.add(Duration(days: 7 * pattern.interval));
      
      case RecurrenceType.monthly:
        return DateTime(
          lastDate.year,
          lastDate.month + pattern.interval,
          pattern.dayOfMonth ?? lastDate.day,
        );
      
      case RecurrenceType.yearly:
        return DateTime(
          lastDate.year + pattern.interval,
          pattern.monthOfYear ?? lastDate.month,
          pattern.dayOfMonth ?? lastDate.day,
        );
      
      case RecurrenceType.custom:
        // Custom logic would go here
        return null;
    }
  }

  // Preview upcoming instances
  List<DateTime> previewUpcomingInstances(RecurringTask recurringTask, {int count = 5}) {
    final instances = <DateTime>[];
    var currentDate = recurringTask.nextDue ?? recurringTask.startDate;

    for (int i = 0; i < count; i++) {
      if (recurringTask.recurrencePattern.endDate != null &&
          currentDate.isAfter(recurringTask.recurrencePattern.endDate!)) {
        break;
      }

      instances.add(currentDate);
      final nextDate = calculateNextDueDate(
        recurringTask.copyWith(lastGenerated: currentDate)
      );
      
      if (nextDate == null) break;
      currentDate = nextDate;
    }

    return instances;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh
  Future<void> refresh() async {
    await loadRecurringTasks();
  }
}

// Recurring task provider
final recurringTaskProvider = StateNotifierProvider<RecurringTaskNotifier, RecurringTaskState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RecurringTaskNotifier(apiService);
});