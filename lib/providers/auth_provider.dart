import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(const AuthState()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    final token = await _apiService.getToken();
    if (token != null) {
      try {
        state = state.copyWith(isLoading: true);
        final user = await _apiService.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false);
      } catch (e) {
        await _apiService.clearToken();
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final response = await _apiService.login(username, password);
      print('🔍 Auth Provider - Login response: $response');
      print('🔍 Auth Provider - User data: ${response['user']}');
      
      final user = User.fromJson(response['user']);
      print('🔍 Auth Provider - Parsed user: ${user.fullName}');
      
      state = state.copyWith(user: user, isLoading: false);
      print('🔍 Auth Provider - New auth state isAuthenticated: ${state.isAuthenticated}');
      return true;
    } catch (e) {
      print('❌ Auth Provider - Login error: $e');
      state = state.copyWith(
        isLoading: false, 
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final response = await _apiService.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
      final user = User.fromJson(response['user']);
      
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});