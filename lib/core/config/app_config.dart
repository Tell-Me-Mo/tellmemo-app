import '../../config.dart';

/// Simple configuration wrapper that uses values from config.dart
///
/// To change configuration:
/// 1. Edit lib/config.dart with your values
/// 2. Run or build the app
///
/// No environment variables, no build arguments - just edit and run!
class AppConfig {
  // Prevent instantiation
  AppConfig._();

  // Re-export all values from Config for backward compatibility
  static const String apiBaseUrl = Config.apiBaseUrl;
  static const int apiTimeout = Config.apiTimeout;
  static const String environment = Config.environment;
  static const bool isDevelopment = Config.isDevelopment;
  static const bool isProduction = Config.isProduction;
  static const bool enableLogging = Config.enableLogging;
  static const bool enableDebugMode = Config.enableDebugMode;
  static const bool sentryEnabled = Config.sentryEnabled;
  static const String sentryDsn = Config.sentryDsn;
  static const bool firebaseAnalyticsEnabled = Config.firebaseAnalyticsEnabled;
  static const String authProvider = Config.authProvider;
  static const bool useSupabaseAuth = Config.useSupabaseAuth;
  static const bool useBackendAuth = Config.useBackendAuth;
  static const String supabaseUrl = Config.supabaseUrl;
  static const String supabaseAnonKey = Config.supabaseAnonKey;

  // No initialization needed - all values are compile-time constants
  // Debug helper - only use in development
  static void debugPrint() {
    // ignore: avoid_print
    print('=== AppConfig ===');
    // ignore: avoid_print
    print('API Base URL: $apiBaseUrl');
    // ignore: avoid_print
    print('Environment: $environment');
    // ignore: avoid_print
    print('Auth Provider: $authProvider');
    // ignore: avoid_print
    print('Sentry Enabled: $sentryEnabled');
    // ignore: avoid_print
    print('Firebase Analytics: $firebaseAnalyticsEnabled');
    // ignore: avoid_print
    print('=================');
  }
}