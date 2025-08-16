import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../config/environment.dart';
import '../utils/http_client_helper.dart';

class CacheNotModifiedException implements Exception {
  final String message;
  CacheNotModifiedException([this.message = 'Content not modified (304)']);
  @override
  String toString() => message;
}

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static String get _baseUrl => Environment.apiBaseUrl;
  final Map<String, dynamic> _cache = {}; 
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Environment.connectTimeout,
      receiveTimeout: Environment.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Configure HTTP client for different platforms
    HttpClientHelper.configureHttpClient(_dio, Environment.isProduction);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
            // Navigate to login screen
          }
          handler.next(error);
        },
      ),
    );
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Trim and clean inputs
      final cleanUsername = username.trim();
      final cleanPassword = password.trim();
      
      final requestData = {
        'username': cleanUsername,
        'password': cleanPassword,
      };
      
      if (Environment.enableDebugLogs) {
        print('🔍 Login request to: $_baseUrl/auth/login');
      }
      
      final response = await _dio.post('/auth/login', data: requestData);
      
      
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      if (Environment.enableDebugLogs) {
        print('❌ Login error: ${e.response?.statusCode}');
      }
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
      });
      
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await clearToken();
    }
  }

  // User endpoints
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/profile');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<User>> getUsers() async {
    const cacheKey = 'users_all';
    
    try {
      final response = await _dio.get('/users');
      final List<dynamic> usersJson = response.data['users'];
      final users = usersJson.map((json) => User.fromJson(json)).toList();
      
      // Cache the successful response
      _cache[cacheKey] = users;
      return users;
    } on CacheNotModifiedException {
      // Return cached data for 304 responses
      if (_cache.containsKey(cacheKey)) {
        return List<User>.from(_cache[cacheKey]);
      }
      // If no cached data but we have a 304, try to fetch fresh data
      final response = await _dio.get('/users');
      final List<dynamic> usersJson = response.data['users'];
      final users = usersJson.map((json) => User.fromJson(json)).toList();
      _cache[cacheKey] = users;
      return users;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Task endpoints
  Future<List<Task>> getTasks({Map<String, dynamic>? filters}) async {
    final cacheKey = 'tasks_${filters?.toString() ?? 'all'}';
    
    try {
      final response = await _dio.get('/tasks', queryParameters: filters);
      final List<dynamic> tasksJson = response.data['tasks'];
      final tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
      
      // Cache the successful response
      _cache[cacheKey] = tasks;
      return tasks;
    } on CacheNotModifiedException {
      // Return cached data for 304 responses
      if (_cache.containsKey(cacheKey)) {
        return List<Task>.from(_cache[cacheKey]);
      }
      // If no cached data but we have a 304, try to fetch fresh data
      final response = await _dio.get('/tasks', queryParameters: filters);
      final List<dynamic> tasksJson = response.data['tasks'];
      final tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
      _cache[cacheKey] = tasks;
      return tasks;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: {
        'title': task.title,
        'description': task.description,
        'assignedTo': task.assignedTo,
        'priority': task.priority.name,
        'category': task.category.name,
        'estimatedHours': task.estimatedHours,
        'dueDate': task.dueDate?.toIso8601String(),
        'tags': task.tags,
      });
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Task> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/tasks/$taskId', data: updates);
      return Task.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      await _dio.delete('/tasks/$taskId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Dashboard endpoints
  Future<Map<String, dynamic>> getDashboardStats() async {
    const cacheKey = 'dashboard_stats';
    
    try {
      final response = await _dio.get('/users/dashboard/stats');
      
      // Cache the successful response
      _cache[cacheKey] = response.data;
      return response.data;
    } on CacheNotModifiedException {
      // Return cached data for 304 responses
      if (_cache.containsKey(cacheKey)) {
        return Map<String, dynamic>.from(_cache[cacheKey]);
      }
      // If no cached data but we have a 304, try to fetch fresh data
      final response = await _dio.get('/users/dashboard/stats');
      _cache[cacheKey] = response.data;
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Reports endpoints
  Future<Map<String, dynamic>> getReports({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final response = await _dio.get('/reports/overview-stats', 
          queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTaskStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      final response = await _dio.get('/reports/task-stats', 
          queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Time tracking endpoints
  Future<void> startTimer(int taskId) async {
    try {
      await _dio.post('/tasks/$taskId/time/start');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> pauseTimer(int taskId) async {
    try {
      await _dio.post('/tasks/$taskId/time/pause');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> stopTimer(int taskId) async {
    try {
      await _dio.post('/tasks/$taskId/time/stop');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getActiveTimer(int taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/time/active');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTimeHistory(int taskId) async {
    try {
      final response = await _dio.get('/tasks/$taskId/time/history');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // File endpoints
  Future<Map<String, dynamic>> getTaskFiles(int taskId) async {
    try {
      final response = await _dio.get('/files/task/$taskId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteFile(int fileId) async {
    try {
      final response = await _dio.delete('/files/$fileId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Getters for file provider
  Dio get dio => _dio;
  String get baseUrl => _baseUrl;
  
  // Helper method for response decoding
  Map<String, dynamic> decodeResponse(String responseBody) {
    return jsonDecode(responseBody);
  }

  // Subtask endpoints
  Future<Map<String, dynamic>> getTaskSubtasks(int parentTaskId) async {
    try {
      final response = await _dio.get('/subtasks/parent/$parentTaskId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createSubtask(Map<String, dynamic> subtaskData) async {
    try {
      final response = await _dio.post('/subtasks', data: subtaskData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateSubtask(int subtaskId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/subtasks/$subtaskId', data: updates);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteSubtask(int subtaskId) async {
    try {
      final response = await _dio.delete('/subtasks/$subtaskId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Task dependency endpoints
  Future<Map<String, dynamic>> getTaskDependencies(int taskId) async {
    try {
      final response = await _dio.get('/subtasks/$taskId/dependencies');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTaskDependency(int taskId, Map<String, dynamic> dependencyData) async {
    try {
      final response = await _dio.post('/subtasks/$taskId/dependencies', data: dependencyData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteTaskDependency(int taskId, int dependencyId) async {
    try {
      final response = await _dio.delete('/subtasks/$taskId/dependencies/$dependencyId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Recurring task endpoints
  Future<Map<String, dynamic>> getRecurringTasks() async {
    try {
      final response = await _dio.get('/recurring-tasks');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createRecurringTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/recurring-tasks', data: taskData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateRecurringTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/recurring-tasks/$taskId', data: updates);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteRecurringTask(int taskId) async {
    try {
      final response = await _dio.delete('/recurring-tasks/$taskId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateRecurringTasks() async {
    try {
      final response = await _dio.post('/recurring-tasks/generate');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Comment endpoints
  Future<Map<String, dynamic>> getTaskComments(int taskId) async {
    try {
      final response = await _dio.get('/comments/task/$taskId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTaskComment(Map<String, dynamic> commentData) async {
    try {
      final response = await _dio.post('/comments', data: commentData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTaskComment(int commentId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/comments/$commentId', data: updates);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteTaskComment(int commentId) async {
    try {
      final response = await _dio.delete('/comments/$commentId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getActivityLog(Map<String, dynamic> params) async {
    try {
      final response = await _dio.get('/activity-log', queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Template endpoints
  Future<Map<String, dynamic>> getTaskTemplates() async {
    try {
      final response = await _dio.get('/templates');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createTaskTemplate(Map<String, dynamic> templateData) async {
    try {
      final response = await _dio.post('/templates', data: templateData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateTaskTemplate(int templateId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/templates/$templateId', data: updates);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteTaskTemplate(int templateId) async {
    try {
      final response = await _dio.delete('/templates/$templateId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> instantiateTemplate(int templateId, Map<String, dynamic> overrides) async {
    try {
      final response = await _dio.post('/templates/$templateId/instantiate', data: overrides);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> incrementTemplateUsage(int templateId) async {
    try {
      final response = await _dio.post('/templates/$templateId/usage');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Saved Views endpoints
  Future<Map<String, dynamic>> getSavedViews() async {
    try {
      final response = await _dio.get('/saved-views');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createSavedView(Map<String, dynamic> viewData) async {
    try {
      final response = await _dio.post('/saved-views', data: viewData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateSavedView(int viewId, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.put('/saved-views/$viewId', data: updates);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deleteSavedView(int viewId) async {
    try {
      final response = await _dio.delete('/saved-views/$viewId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Analytics endpoints
  Future<Map<String, dynamic>> getFlutterAnalytics([Map<String, dynamic>? filters]) async {
    try {
      final response = await _dio.get('/reports/flutter-analytics', queryParameters: filters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTaskAnalytics([Map<String, dynamic>? filters]) async {
    try {
      final response = await _dio.get('/reports/task-analytics', queryParameters: filters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProductivityAnalytics([Map<String, dynamic>? filters]) async {
    try {
      final response = await _dio.get('/reports/productivity-analytics', queryParameters: filters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTeamAnalytics([Map<String, dynamic>? filters]) async {
    try {
      final response = await _dio.get('/reports/team-analytics', queryParameters: filters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProjectAnalytics([Map<String, dynamic>? filters]) async {
    try {
      final response = await _dio.get('/reports/project-analytics', queryParameters: filters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Bulk operations endpoints
  Future<Map<String, dynamic>> bulkUpdateTasks(List<int> taskIds, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.post('/tasks/bulk/update', data: {
        'taskIds': taskIds,
        'updates': updates,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> bulkDeleteTasks(List<int> taskIds) async {
    try {
      final response = await _dio.post('/tasks/bulk/delete', data: {
        'taskIds': taskIds,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> bulkAssignTasks(List<int> taskIds, int assignedTo) async {
    try {
      final response = await _dio.post('/tasks/bulk/assign', data: {
        'taskIds': taskIds,
        'assignedTo': assignedTo,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> bulkUpdateTaskStatus(List<int> taskIds, String status) async {
    try {
      final response = await _dio.post('/tasks/bulk/status', data: {
        'taskIds': taskIds,
        'status': status,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  String _handleError(DioException e) {
    if (Environment.enableDebugLogs) {
      print('API Error: ${e.type} - Status: ${e.response?.statusCode}');
    }
    
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['message'] ?? data['error'] ?? 'An error occurred';
    }
    
    if (e.response?.data is String) {
      return e.response!.data as String;
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server at $_baseUrl. Please ensure the backend is running.';
      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 304:
            // Not Modified - this is actually a success case for cached data
            throw CacheNotModifiedException();
          case 400:
            return 'Bad request. Please check your input.';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'An error occurred (${e.response?.statusCode})';
        }
      default:
        return 'An unexpected error occurred: ${e.message}';
    }
  }
}