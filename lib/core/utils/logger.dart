import 'dart:developer' as developer;

class Logger {
  static void debug(String message, [Object? error]) {
    developer.log(
      message,
      name: 'PMaster',
      level: 500,
      error: error,
    );
  }

  static void info(String message, [Object? error]) {
    developer.log(
      message,
      name: 'PMaster',
      level: 800,
      error: error,
    );
  }

  static void warning(String message, [Object? error]) {
    developer.log(
      message,
      name: 'PMaster',
      level: 900,
      error: error,
    );
  }

  static void error(String message, [Object? error]) {
    developer.log(
      message,
      name: 'PMaster',
      level: 1000,
      error: error,
    );
  }
}