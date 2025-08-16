import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/manager_service.dart';
import '../services/websocket_service.dart';
import '../models/manager_models.dart';
import '../models/websocket_events.dart';

final managerServiceProvider = Provider<ManagerService>((ref) {
  return ManagerService();
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

class ManagerDashboardState {
  final ManagerDashboardData? data;
  final bool isLoading;
  final String? error;

  ManagerDashboardState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  ManagerDashboardState copyWith({
    ManagerDashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return ManagerDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ManagerDashboardNotifier extends StateNotifier<ManagerDashboardState> {
  final ManagerService _managerService;
  final WebSocketService _webSocketService;

  ManagerDashboardNotifier(this._managerService, this._webSocketService) 
      : super(ManagerDashboardState()) {
    _initWebSocketListeners();
  }

  void _initWebSocketListeners() {
    _webSocketService.events.listen((event) {
      switch (event.type) {
        case WebSocketEventType.taskUpdated:
        case WebSocketEventType.taskCreated:
        case WebSocketEventType.taskDeleted:
        case WebSocketEventType.taskStatusChanged:
        case WebSocketEventType.taskAssigned:
          // Refresh dashboard when task-related events occur
          if (state.data != null) {
            refresh();
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await _managerService.getDashboardOverview();
      state = state.copyWith(
        data: ManagerDashboardData.fromJson(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}

final managerDashboardProvider = StateNotifierProvider<ManagerDashboardNotifier, ManagerDashboardState>((ref) {
  final managerService = ref.watch(managerServiceProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  return ManagerDashboardNotifier(managerService, webSocketService);
});


class ManagerTasksState {
  final List<ManagerTaskDetailed> tasks;
  final TasksPagination? pagination;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? priorityFilter;
  final int? assignedToFilter;

  ManagerTasksState({
    this.tasks = const [],
    this.pagination,
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.priorityFilter,
    this.assignedToFilter,
  });

  ManagerTasksState copyWith({
    List<ManagerTaskDetailed>? tasks,
    TasksPagination? pagination,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? priorityFilter,
    int? assignedToFilter,
  }) {
    return ManagerTasksState(
      tasks: tasks ?? this.tasks,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      assignedToFilter: assignedToFilter ?? this.assignedToFilter,
    );
  }
}

class ManagerTasksNotifier extends StateNotifier<ManagerTasksState> {
  final ManagerService _managerService;
  final WebSocketService _webSocketService;

  ManagerTasksNotifier(this._managerService, this._webSocketService) 
      : super(ManagerTasksState()) {
    _initWebSocketListeners();
  }

  void _initWebSocketListeners() {
    _webSocketService.events.listen((event) {
      switch (event.type) {
        case WebSocketEventType.taskUpdated:
        case WebSocketEventType.taskCreated:
        case WebSocketEventType.taskDeleted:
        case WebSocketEventType.taskStatusChanged:
        case WebSocketEventType.taskAssigned:
          // Refresh tasks list when task-related events occur
          if (state.tasks.isNotEmpty) {
            loadTasks();
          }
          break;
        default:
          break;
      }
    });
  }

  Future<void> loadTasks({
    String? status,
    String? priority,
    int? assignedTo,
    String? search,
    int page = 1,
    int limit = 20,
    String sort = 'created_at',
    String order = 'DESC',
    bool append = false,
  }) async {
    if (!append) {
      state = state.copyWith(isLoading: true, error: null);
    }
    
    try {
      final response = await _managerService.getTasks(
        status: status ?? state.statusFilter,
        priority: priority ?? state.priorityFilter,
        assignedTo: assignedTo ?? state.assignedToFilter,
        page: page,
        limit: limit,
      );
      
      final tasksResponse = TasksResponse.fromJson(response);
      
      state = state.copyWith(
        tasks: append ? [...state.tasks, ...tasksResponse.tasks] : tasksResponse.tasks,
        pagination: tasksResponse.pagination,
        isLoading: false,
        statusFilter: status ?? state.statusFilter,
        priorityFilter: priority ?? state.priorityFilter,
        assignedToFilter: assignedTo ?? state.assignedToFilter,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setFilters({
    String? status,
    String? priority,
    int? assignedTo,
  }) async {
    state = state.copyWith(
      statusFilter: status,
      priorityFilter: priority,
      assignedToFilter: assignedTo,
    );
    await loadTasks();
  }

  Future<void> assignTask({
    required int taskId,
    required int assignedTo,
    String? priority,
    String? dueDate,
  }) async {
    try {
      await _managerService.assignTask(
        taskId: taskId,
        assignedTo: assignedTo,
        priority: priority,
        dueDate: dueDate,
      );
      // Reload tasks to reflect changes
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final managerTasksProvider = StateNotifierProvider<ManagerTasksNotifier, ManagerTasksState>((ref) {
  final managerService = ref.watch(managerServiceProvider);
  final webSocketService = ref.watch(webSocketServiceProvider);
  return ManagerTasksNotifier(managerService, webSocketService);
});

class EmployeePerformanceState {
  final EmployeePerformance? data;
  final bool isLoading;
  final String? error;

  EmployeePerformanceState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  EmployeePerformanceState copyWith({
    EmployeePerformance? data,
    bool? isLoading,
    String? error,
  }) {
    return EmployeePerformanceState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class EmployeePerformanceNotifier extends StateNotifier<EmployeePerformanceState> {
  final ManagerService _managerService;

  EmployeePerformanceNotifier(this._managerService) : super(EmployeePerformanceState());

  Future<void> loadEmployeePerformance(int employeeId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await _managerService.getEmployeePerformance(employeeId);
      state = state.copyWith(
        data: EmployeePerformance.fromJson(data),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final employeePerformanceProvider = StateNotifierProvider<EmployeePerformanceNotifier, EmployeePerformanceState>((ref) {
  final managerService = ref.watch(managerServiceProvider);
  return EmployeePerformanceNotifier(managerService);
});

class ProductivityReportState {
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;

  ProductivityReportState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  ProductivityReportState copyWith({
    Map<String, dynamic>? data,
    bool? isLoading,
    String? error,
  }) {
    return ProductivityReportState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ProductivityReportNotifier extends StateNotifier<ProductivityReportState> {
  final ManagerService _managerService;

  ProductivityReportNotifier(this._managerService) : super(ProductivityReportState());

  Future<void> loadProductivityReport({
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final data = await _managerService.getProductivityReport(
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final productivityReportProvider = StateNotifierProvider<ProductivityReportNotifier, ProductivityReportState>((ref) {
  final managerService = ref.watch(managerServiceProvider);
  return ProductivityReportNotifier(managerService);
});