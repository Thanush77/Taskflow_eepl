import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/websocket_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/debug/api_test_screen.dart';
import 'widgets/loading_widget.dart';
import 'widgets/notification_widget.dart';
import 'config/environment.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  runApp(const ProviderScope(child: TaskFlowApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoginRoute = state.uri.path == '/login';

      Logger.debug('🔍 Router redirect - isAuthenticated: $isAuthenticated, currentRoute: ${state.uri.path}');

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      
      if (isAuthenticated && isLoginRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => const ApiTestScreen(),
      ),
    ],
  );
});

class TaskFlowApp extends ConsumerStatefulWidget {
  const TaskFlowApp({super.key});

  @override
  ConsumerState<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends ConsumerState<TaskFlowApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize real-time features when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRealTimeFeatures();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final autoNotificationHandler = ref.read(autoNotificationHandlerProvider);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // App is in background, enable push notifications
        autoNotificationHandler.setBackgroundState(true);
        break;
      case AppLifecycleState.resumed:
        // App is in foreground, disable push notifications
        autoNotificationHandler.setBackgroundState(false);
        break;
      default:
        break;
    }
  }

  void _initializeRealTimeFeatures() async {
    final authState = ref.read(authProvider);
    
    if (authState.isAuthenticated) {
      // Connect to WebSocket for real-time features
      final webSocketActions = ref.read(webSocketActionsProvider);
      await webSocketActions.connect();
      
      // Initialize real-time task synchronization
      ref.read(realTimeTaskSyncProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);

    return NotificationOverlay(
      child: MaterialApp.router(
        title: 'TaskFlow',
        theme: AppTheme.theme,
        routerConfig: router,
        builder: (context, child) {
          if (authState.isLoading) {
            return const LoadingScreen(message: 'Initializing...');
          }
          return child ?? const SizedBox();
        },
      ),
    );
  }
}