import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_template.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class TemplateState {
  final List<TaskTemplate> templates;
  final bool isLoading;
  final String? error;

  const TemplateState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });

  TemplateState copyWith({
    List<TaskTemplate>? templates,
    bool? isLoading,
    String? error,
  }) {
    return TemplateState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TemplateNotifier extends StateNotifier<TemplateState> {
  final ApiService _apiService;

  TemplateNotifier(this._apiService) : super(const TemplateState());

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.getTaskTemplates();
      
      if (response['success'] == true && response['data'] != null) {
        final templatesData = response['data'] as List;
        final templates = templatesData
            .map((json) => TaskTemplate.fromJson(json as Map<String, dynamic>))
            .toList();
        
        state = state.copyWith(
          templates: templates,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load templates',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createTemplate(TaskTemplate template) async {
    try {
      final response = await _apiService.createTaskTemplate(template.toJson());
      
      if (response['success'] == true && response['data'] != null) {
        final newTemplate = TaskTemplate.fromJson(response['data']);
        
        state = state.copyWith(
          templates: [...state.templates, newTemplate],
        );
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Failed to create template',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateTemplate(int id, TaskTemplate template) async {
    try {
      final response = await _apiService.updateTaskTemplate(id, template.toJson());
      
      if (response['success'] == true && response['data'] != null) {
        final updatedTemplate = TaskTemplate.fromJson(response['data']);
        
        final updatedTemplates = state.templates
            .map((t) => t.id == id ? updatedTemplate : t)
            .toList();
        
        state = state.copyWith(templates: updatedTemplates);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Failed to update template',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTemplate(int id) async {
    try {
      final response = await _apiService.deleteTaskTemplate(id);
      
      if (response['success'] == true) {
        final updatedTemplates = state.templates
            .where((template) => template.id != id)
            .toList();
        
        state = state.copyWith(templates: updatedTemplates);
        return true;
      }
      
      state = state.copyWith(
        error: response['message'] ?? 'Failed to delete template',
      );
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> incrementUsageCount(int templateId) async {
    try {
      final response = await _apiService.incrementTemplateUsage(templateId);
      
      if (response['success'] == true) {
        final updatedTemplates = state.templates.map((template) {
          if (template.id == templateId) {
            return template.copyWith(usageCount: (template.usageCount ?? 0) + 1);
          }
          return template;
        }).toList();
        
        state = state.copyWith(templates: updatedTemplates);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await loadTemplates();
  }

  List<TaskTemplate> getTemplatesByCategory(TemplateCategory category) {
    return state.templates
        .where((template) => template.category == category && template.isActive)
        .toList();
  }

  List<TaskTemplate> getPopularTemplates({int limit = 5}) {
    final templates = state.templates.where((t) => t.isActive).toList();
    templates.sort((a, b) => (b.usageCount ?? 0).compareTo(a.usageCount ?? 0));
    return templates.take(limit).toList();
  }

  List<TaskTemplate> searchTemplates(String query) {
    if (query.isEmpty) return state.templates.where((t) => t.isActive).toList();
    
    final lowercaseQuery = query.toLowerCase();
    return state.templates.where((template) {
      return template.isActive &&
          (template.name.toLowerCase().contains(lowercaseQuery) ||
           template.description.toLowerCase().contains(lowercaseQuery) ||
           template.defaultTags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)));
    }).toList();
  }
}

// Providers
final templateProvider = StateNotifierProvider<TemplateNotifier, TemplateState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TemplateNotifier(apiService);
});

// Computed providers
final popularTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateState = ref.watch(templateProvider);
  final templates = templateState.templates.where((t) => t.isActive).toList();
  templates.sort((a, b) => (b.usageCount ?? 0).compareTo(a.usageCount ?? 0));
  return templates.take(5).toList();
});

final templatesByCategoryProvider = Provider.family<List<TaskTemplate>, TemplateCategory>((ref, category) {
  final templateState = ref.watch(templateProvider);
  return templateState.templates
      .where((template) => template.category == category && template.isActive)
      .toList();
});

// Filter provider for template search
final templateSearchProvider = StateProvider<String>((ref) => '');

final filteredTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templateState = ref.watch(templateProvider);
  final searchQuery = ref.watch(templateSearchProvider);
  
  if (searchQuery.isEmpty) {
    return templateState.templates.where((t) => t.isActive).toList();
  }
  
  final lowercaseQuery = searchQuery.toLowerCase();
  return templateState.templates.where((template) {
    return template.isActive &&
        (template.name.toLowerCase().contains(lowercaseQuery) ||
         template.description.toLowerCase().contains(lowercaseQuery) ||
         template.defaultTags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)));
  }).toList();
});