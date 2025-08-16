import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/websocket_events.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Task State
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? filters;
  final Task? activeTask;
  final bool isCreating;
  final bool isUpdating;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filters,
    this.activeTask,
    this.isCreating = false,
    this.isUpdating = false,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? filters,
    Task? activeTask,
    bool? isCreating,
    bool? isUpdating,
    bool clearError = false,
    bool clearActiveTask = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
      activeTask: clearActiveTask ? null : (activeTask ?? this.activeTask),
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

// Task Notifier
class TaskNotifier extends StateNotifier<TaskState> {
  final ApiService _apiService;

  TaskNotifier(this._apiService) : super(const TaskState());

  // Load tasks with optional filters
  Future<void> loadTasks({Map<String, dynamic>? filters}) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final tasks = await _apiService.getTasks(filters: filters);
      
      // Debug logging to track data loading
      print('🔍 TaskProvider - Loaded ${tasks.length} tasks');
      if (tasks.isNotEmpty) {
        print('🔍 TaskProvider - Sample task: ${tasks.first.title}');
      }
      
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        filters: filters,
      );
    } catch (e) {
      print('❌ TaskProvider - Error loading tasks: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Create a new task
  Future<bool> createTask(Task task) async {
    try {
      state = state.copyWith(isCreating: true, clearError: true);
      
      final createdTask = await _apiService.createTask(task);
      
      state = state.copyWith(
        tasks: [...state.tasks, createdTask],
        isCreating: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update an existing task
  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      state = state.copyWith(isUpdating: true, clearError: true);
      
      final updatedTask = await _apiService.updateTask(taskId, updates);
      
      final updatedTasks = state.tasks.map((task) {
        return task.id == taskId ? updatedTask : task;
      }).toList();
      
      state = state.copyWith(
        tasks: updatedTasks,
        isUpdating: false,
        activeTask: updatedTask,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Delete a task
  Future<bool> deleteTask(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      await _apiService.deleteTask(taskId);
      
      final updatedTasks = state.tasks.where((task) => task.id != taskId).toList();
      
      state = state.copyWith(
        tasks: updatedTasks,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Set active task for editing
  void setActiveTask(Task? task) {
    state = state.copyWith(
      activeTask: task,
      clearActiveTask: task == null,
    );
  }

  // Apply filters
  void applyFilters(Map<String, dynamic> filters) {
    loadTasks(filters: filters);
  }

  // Clear filters
  void clearFilters() {
    loadTasks();
  }

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return state.tasks.where((task) => task.status == status).toList();
  }

  // Get tasks by priority
  List<Task> getTasksByPriority(TaskPriority priority) {
    return state.tasks.where((task) => task.priority == priority).toList();
  }

  // Get tasks assigned to current user
  List<Task> getMyTasks(int userId) {
    return state.tasks.where((task) => task.assignedTo == userId).toList();
  }

  // Get overdue tasks
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return state.tasks.where((task) {
      return task.dueDate != null && 
             task.dueDate!.isBefore(now) && 
             task.status != TaskStatus.completed;
    }).toList();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Refresh tasks
  Future<void> refresh() async {
    await loadTasks(filters: state.filters);
  }

  // Real-time event handlers for WebSocket integration
  Future<void> updateTaskFromEvent(TaskUpdatedEvent event) async {
    final updatedTasks = state.tasks.map((task) {
      return task.id == event.task.id ? event.task : task;
    }).toList();
    
    state = state.copyWith(tasks: updatedTasks);
  }

  Future<void> addTaskFromEvent(TaskCreatedEvent event) async {
    final existingTaskIndex = state.tasks.indexWhere((task) => task.id == event.task.id);
    
    if (existingTaskIndex == -1) {
      state = state.copyWith(tasks: [...state.tasks, event.task]);
    }
  }

  Future<void> removeTaskFromEvent(TaskDeletedEvent event) async {
    final updatedTasks = state.tasks.where((task) => task.id != event.taskId).toList();
    state = state.copyWith(tasks: updatedTasks);
  }

  Future<void> updateTaskStatusFromEvent(TaskStatusChangedEvent event) async {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == event.taskId) {
        return task.copyWith(status: event.newStatus);
      }
      return task;
    }).toList();
    
    state = state.copyWith(tasks: updatedTasks);
  }

  Future<void> updateTaskAssignmentFromEvent(TaskAssignedEvent event) async {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == event.taskId) {
        return task.copyWith(assignedTo: event.newAssignee);
      }
      return task;
    }).toList();
    
    state = state.copyWith(tasks: updatedTasks);
  }

  // Optimistic updates for better UX
  void optimisticUpdate(int taskId, Map<String, dynamic> updates) {
    final updatedTasks = state.tasks.map((task) {
      if (task.id == taskId) {
        return _applyUpdatesToTask(task, updates);
      }
      return task;
    }).toList();
    
    state = state.copyWith(tasks: updatedTasks);
  }

  Task _applyUpdatesToTask(Task task, Map<String, dynamic> updates) {
    return task.copyWith(
      title: updates['title'] ?? task.title,
      description: updates['description'] ?? task.description,
      status: updates['status'] is String 
          ? TaskStatus.values.firstWhere((s) => s.name == updates['status'])
          : updates['status'] ?? task.status,
      priority: updates['priority'] is String
          ? TaskPriority.values.firstWhere((p) => p.name == updates['priority'])
          : updates['priority'] ?? task.priority,
      category: updates['category'] is String
          ? TaskCategory.values.firstWhere((c) => c.name == updates['category'])
          : updates['category'] ?? task.category,
      assignedTo: updates['assignedTo'] ?? task.assignedTo,
      dueDate: updates['dueDate'] is String
          ? DateTime.parse(updates['dueDate'])
          : updates['dueDate'] ?? task.dueDate,
      estimatedHours: updates['estimatedHours'] ?? task.estimatedHours,
      tags: updates['tags'] ?? task.tags,
    );
  }
}

// Time Tracking State
class TimeTrackingState {
  final Map<int, DateTime?> activeTimers;
  final Map<int, Duration> totalTimes;
  final bool isLoading;
  final String? error;

  const TimeTrackingState({
    this.activeTimers = const {},
    this.totalTimes = const {},
    this.isLoading = false,
    this.error,
  });

  TimeTrackingState copyWith({
    Map<int, DateTime?>? activeTimers,
    Map<int, Duration>? totalTimes,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TimeTrackingState(
      activeTimers: activeTimers ?? this.activeTimers,
      totalTimes: totalTimes ?? this.totalTimes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Time Tracking Notifier
class TimeTrackingNotifier extends StateNotifier<TimeTrackingState> {
  final ApiService _apiService;

  TimeTrackingNotifier(this._apiService) : super(const TimeTrackingState());

  // Start timer for a task
  Future<void> startTimer(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      await _apiService.startTimer(taskId);
      
      final newActiveTimers = Map<int, DateTime?>.from(state.activeTimers);
      newActiveTimers[taskId] = DateTime.now();
      
      state = state.copyWith(
        activeTimers: newActiveTimers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Pause timer for a task
  Future<void> pauseTimer(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      await _apiService.pauseTimer(taskId);
      
      final newActiveTimers = Map<int, DateTime?>.from(state.activeTimers);
      newActiveTimers.remove(taskId);
      
      state = state.copyWith(
        activeTimers: newActiveTimers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Stop timer for a task
  Future<void> stopTimer(int taskId) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      await _apiService.stopTimer(taskId);
      
      final newActiveTimers = Map<int, DateTime?>.from(state.activeTimers);
      newActiveTimers.remove(taskId);
      
      state = state.copyWith(
        activeTimers: newActiveTimers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get active timer status
  bool isTimerActive(int taskId) {
    return state.activeTimers.containsKey(taskId);
  }

  // Get timer duration
  Duration getTimerDuration(int taskId) {
    final startTime = state.activeTimers[taskId];
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime);
  }
}

// Team State for user management
class TeamState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const TeamState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  TeamState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TeamState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Team Notifier
class TeamNotifier extends StateNotifier<TeamState> {
  final ApiService _apiService;

  TeamNotifier(this._apiService) : super(const TeamState());

  Future<void> loadUsers() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      
      final users = await _apiService.getUsers();
      
      // Debug logging to track user data loading
      print('🔍 TeamProvider - Loaded ${users.length} users');
      if (users.isNotEmpty) {
        print('🔍 TeamProvider - Sample user: ${users.first.fullName}');
        print('🔍 TeamProvider - Full user data: ${users.first.toJson()}');
      } else {
        print('🔍 TeamProvider - No users returned from API');
      }
      
      state = state.copyWith(
        users: users,
        isLoading: false,
      );
    } catch (e) {
      print('❌ TeamProvider - Error loading users: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  User? getUserById(int id) {
    return state.users.where((user) => user.id == id).firstOrNull;
  }
}

// Providers
final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TaskNotifier(apiService);
});

final timeTrackingProvider = StateNotifierProvider<TimeTrackingNotifier, TimeTrackingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TimeTrackingNotifier(apiService);
});

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TeamNotifier(apiService);
});

// Helper providers for computed state
final myTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user == null) return [];
  
  return taskState.tasks.where((task) => task.assignedTo == authState.user!.id).toList();
});

final overdueTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  final now = DateTime.now();
  
  return taskState.tasks.where((task) {
    return task.dueDate != null && 
           task.dueDate!.isBefore(now) && 
           task.status != TaskStatus.completed;
  }).toList();
});

final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final taskState = ref.watch(taskProvider);
  final tasks = taskState.tasks;
  
  return {
    'total': tasks.length,
    'pending': tasks.where((t) => t.status == TaskStatus.pending).length,
    'inProgress': tasks.where((t) => t.status == TaskStatus.inProgress).length,
    'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
    'cancelled': tasks.where((t) => t.status == TaskStatus.cancelled).length,
    'overdue': ref.watch(overdueTasksProvider).length,
  };
});