import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_filter.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'task_provider.dart';

class FilterState {
  final List<SavedView> savedViews;
  final TaskFilter? activeFilter;
  final bool isLoading;
  final String? error;

  const FilterState({
    this.savedViews = const [],
    this.activeFilter,
    this.isLoading = false,
    this.error,
  });

  FilterState copyWith({
    List<SavedView>? savedViews,
    TaskFilter? activeFilter,
    bool? isLoading,
    String? error,
  }) {
    return FilterState(
      savedViews: savedViews ?? this.savedViews,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  final ApiService _apiService;
  final Ref _ref;

  FilterNotifier(this._apiService, this._ref) : super(const FilterState()) {
    _loadDefaultFilters();
  }

  void _loadDefaultFilters() {
    final authState = _ref.read(authProvider);
    final userId = authState.user?.id;
    
    final defaultViews = <SavedView>[
      SavedView(
        name: 'All Tasks',
        description: 'Show all tasks',
        filter: TaskFilter(
          name: 'All Tasks',
          conditions: {},
        ),
        isDefault: true,
      ),
      if (userId != null)
        SavedView(
          name: 'My Tasks',
          description: 'Tasks assigned to me',
          filter: TaskFilter.myTasks(userId),
          isDefault: true,
        ),
      SavedView(
        name: 'Overdue',
        description: 'Tasks past their due date',
        filter: TaskFilter.overdueTasks(),
        isDefault: true,
      ),
      SavedView(
        name: 'This Week',
        description: 'Tasks due this week',
        filter: TaskFilter.thisWeekTasks(),
        isDefault: true,
      ),
      SavedView(
        name: 'High Priority',
        description: 'High and critical priority tasks',
        filter: TaskFilter.highPriorityTasks(),
        isDefault: true,
      ),
      SavedView(
        name: 'Recently Completed',
        description: 'Tasks completed in the last 7 days',
        filter: TaskFilter.recentlyCompleted(),
        isDefault: true,
      ),
    ];

    state = state.copyWith(savedViews: defaultViews);
  }

  Future<void> loadSavedViews() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.getSavedViews();
      
      if (response['success'] == true && response['data'] != null) {
        final viewsData = response['data'] as List;
        final customViews = viewsData
            .map((json) => SavedView.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Combine default views with custom views
        final allViews = [..._getDefaultViews(), ...customViews];
        
        state = state.copyWith(
          savedViews: allViews,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load saved views',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createSavedView(SavedView view) async {
    try {
      final response = await _apiService.createSavedView(view.toJson());
      
      if (response['success'] == true && response['data'] != null) {
        final newView = SavedView.fromJson(response['data']);
        
        state = state.copyWith(
          savedViews: [...state.savedViews, newView],
        );
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Failed to create saved view',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateSavedView(int id, SavedView view) async {
    try {
      final response = await _apiService.updateSavedView(id, view.toJson());
      
      if (response['success'] == true && response['data'] != null) {
        final updatedView = SavedView.fromJson(response['data']);
        
        final updatedViews = state.savedViews
            .map((v) => v.id == id ? updatedView : v)
            .toList();
        
        state = state.copyWith(savedViews: updatedViews);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Failed to update saved view',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteSavedView(int id) async {
    try {
      final response = await _apiService.deleteSavedView(id);
      
      if (response['success'] == true) {
        final updatedViews = state.savedViews
            .where((view) => view.id != id)
            .toList();
        
        state = state.copyWith(savedViews: updatedViews);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Failed to delete saved view',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void setActiveFilter(TaskFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void clearActiveFilter() {
    state = state.copyWith(activeFilter: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await loadSavedViews();
  }

  List<SavedView> _getDefaultViews() {
    final authState = _ref.read(authProvider);
    final userId = authState.user?.id;
    
    return [
      SavedView(
        name: 'All Tasks',
        description: 'Show all tasks',
        filter: TaskFilter(
          name: 'All Tasks',
          conditions: {},
        ),
        isDefault: true,
      ),
      if (userId != null)
        SavedView(
          name: 'My Tasks',
          description: 'Tasks assigned to me',
          filter: TaskFilter.myTasks(userId),
          isDefault: true,
        ),
      SavedView(
        name: 'Overdue',
        description: 'Tasks past their due date',
        filter: TaskFilter.overdueTasks(),
        isDefault: true,
      ),
      SavedView(
        name: 'This Week',
        description: 'Tasks due this week',
        filter: TaskFilter.thisWeekTasks(),
        isDefault: true,
      ),
      SavedView(
        name: 'High Priority',
        description: 'High and critical priority tasks',
        filter: TaskFilter.highPriorityTasks(),
        isDefault: true,
      ),
      SavedView(
        name: 'Recently Completed',
        description: 'Tasks completed in the last 7 days',
        filter: TaskFilter.recentlyCompleted(),
        isDefault: true,
      ),
    ];
  }

  List<SavedView> getPersonalViews() {
    return state.savedViews.where((view) => !view.isShared && !view.isDefault).toList();
  }

  List<SavedView> getSharedViews() {
    return state.savedViews.where((view) => view.isShared).toList();
  }

  List<SavedView> getDefaultViews() {
    return state.savedViews.where((view) => view.isDefault).toList();
  }
}

// Providers
final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FilterNotifier(apiService, ref);
});

// Computed providers
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  final filterState = ref.watch(filterProvider);
  
  if (filterState.activeFilter == null) {
    return taskState.tasks;
  }
  
  return filterState.activeFilter!.apply(taskState.tasks);
});

final personalViewsProvider = Provider<List<SavedView>>((ref) {
  final filterState = ref.watch(filterProvider);
  return filterState.savedViews.where((view) => !view.isShared && !view.isDefault).toList();
});

final sharedViewsProvider = Provider<List<SavedView>>((ref) {
  final filterState = ref.watch(filterProvider);
  return filterState.savedViews.where((view) => view.isShared).toList();
});

final defaultViewsProvider = Provider<List<SavedView>>((ref) {
  final filterState = ref.watch(filterProvider);
  return filterState.savedViews.where((view) => view.isDefault).toList();
});

// Quick filter providers
final quickFiltersProvider = Provider<List<TaskFilter>>((ref) {
  return QuickFilters.getDefaultFilters();
});

final dateRangeFilterProvider = Provider.family<TaskFilter, DateRangeType>((ref, rangeType) {
  return QuickFilters.getDateRangeFilter(rangeType);
});

// Active saved view provider
final activeSavedViewProvider = StateProvider<SavedView?>((ref) => null);

// Combined filtered tasks with saved view
final savedViewFilteredTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  final activeSavedView = ref.watch(activeSavedViewProvider);
  
  if (activeSavedView == null) {
    return taskState.tasks;
  }
  
  return activeSavedView.apply(taskState.tasks);
});