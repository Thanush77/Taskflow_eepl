import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';
import '../utils/http_client_helper.dart';

class ManagerService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ManagerService() {
    _dio = Dio(BaseOptions(
      baseUrl: Environment.apiBaseUrl,
      connectTimeout: Environment.connectTimeout,
      receiveTimeout: Environment.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Configure HTTP client for different platforms
    HttpClientHelper.configureHttpClient(_dio, Environment.isProduction);

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token from secure storage
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  // Get auth token from secure storage
  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Get dashboard overview
  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await _dio.get('/api/manager/overview');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get employee performance details
  Future<Map<String, dynamic>> getEmployeePerformance(int employeeId) async {
    try {
      final response = await _dio.get('/api/manager/employees/$employeeId/performance');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get all tasks with filters
  Future<Map<String, dynamic>> getTasks({
    String? status,
    String? priority,
    int? assignedTo,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (assignedTo != null) queryParams['assigned_to'] = assignedTo;

      final response = await _dio.get('/api/manager/tasks', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Assign task to employee
  Future<Map<String, dynamic>> assignTask({
    required int taskId,
    required int assignedTo,
    String? priority,
    String? dueDate,
  }) async {
    try {
      final data = <String, dynamic>{
        'assigned_to': assignedTo,
      };
      
      if (priority != null) data['priority'] = priority;
      if (dueDate != null) data['due_date'] = dueDate;

      final response = await _dio.post('/api/manager/tasks/$taskId/assign', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get productivity report
  Future<Map<String, dynamic>> getProductivityReport({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.get('/api/manager/reports/productivity', queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (Environment.enableDebugLogs) {
      print('Manager API Error: ${e.type} - Status: ${e.response?.statusCode}');
    }
    
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['error'] ?? 'An error occurred';
    }
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please try again.';
      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 403:
            return 'Manager access required.';
          case 404:
            return 'Resource not found.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'An error occurred (${e.response?.statusCode})';
        }
      default:
        return 'An unexpected error occurred';
    }
  }
}