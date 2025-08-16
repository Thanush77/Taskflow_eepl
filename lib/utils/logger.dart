import 'dart:developer' as developer;
import '../config/environment.dart';

class Logger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (Environment.enableDebugLogs) {
      developer.log(
        message,
        name: 'TaskFlow',
        error: error,
        stackTrace: stackTrace,
        level: 500, // DEBUG level
      );
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'TaskFlow',
      error: error,
      stackTrace: stackTrace,
      level: 800, // INFO level
    );
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'TaskFlow',
      error: error,
      stackTrace: stackTrace,
      level: 900, // WARNING level
    );
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'TaskFlow',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // ERROR level
    );
  }
}