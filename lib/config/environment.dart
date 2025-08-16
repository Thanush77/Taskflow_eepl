class Environment {
  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  static bool get isDevelopment => _env == 'development';
  static bool get isProduction => _env == 'production';

  // API Configuration  
  static String get apiBaseUrl {
    switch (_env) {
      case 'development':
        return 'http://localhost:3000/api';
      case 'staging':
        return 'http://54.80.7.27/api';  // Through nginx proxy
      case 'production':
      default:
        // Temporarily use HTTP until HTTPS is configured
        return 'http://54.80.7.27/api';  // Using HTTP for now
    }
  }

  static String get websocketUrl {
    switch (_env) {
      case 'development':
        return 'ws://localhost:3000';
      case 'staging':
        return 'ws://54.80.7.27/ws';     // Through nginx proxy
      case 'production':
      default:
        // Use WS until HTTPS is configured
        return 'ws://54.80.7.27/ws';     // Using WS for now
    }
  }

  // Fallback API URL for CORS issues or HTTPS failures
  static String get fallbackApiBaseUrl => 'http://54.80.7.27/api';

  // Feature Flags
  static bool get enableDebugLogs => isDevelopment;
  static bool get enableCrashlytics => isProduction;
  
  // API Timeouts
  static Duration get connectTimeout => const Duration(seconds: 30);
  static Duration get receiveTimeout => const Duration(seconds: 30);
}