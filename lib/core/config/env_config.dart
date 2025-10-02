import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web-specific functionality
import '_env_config_stub.dart'
    if (dart.library.html) '_env_config_web.dart' as env_web;

class EnvConfig {
  // Private constructor
  EnvConfig._();

  // Get value from runtime config (Docker) or dotenv (local dev)
  static String _getConfig(String key, String fallback) {
    // Try runtime config first (Docker deployment on web)
    if (kIsWeb) {
      try {
        final value = env_web.getRuntimeConfig(key);
        if (value != null && value.isNotEmpty && value != 'null') {
          return value;
        }
      } catch (e) {
        // Fall through to dotenv
      }
    }

    // Fallback to dotenv (local development)
    try {
      return dotenv.get(key, fallback: fallback);
    } catch (e) {
      return fallback;
    }
  }

  // Load environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // In production/Docker, .env might not exist - that's OK
      // We'll use runtime config instead
    }
  }

  // API Configuration
  static String get apiBaseUrl => _getConfig(
        'API_BASE_URL',
        'http://localhost:8000',
      );

  static int get apiTimeout => int.tryParse(
        _getConfig('FLUTTER_API_TIMEOUT', '30000'),
      ) ??
      30000;

  // Environment
  static String get environment => _getConfig(
        'FLUTTER_ENVIRONMENT',
        'development',
      );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // Debugging
  static bool get enableLogging => _getConfig(
        'FLUTTER_ENABLE_LOGGING',
        'true',
      ).toLowerCase() == 'true';

  static bool get enableDebugMode => _getConfig(
        'FLUTTER_ENABLE_DEBUG_MODE',
        'true',
      ).toLowerCase() == 'true';

  // API Keys (if needed in future)
  static String get apiKey => _getConfig(
        'API_KEY',
        'development_api_key_change_in_production',
      );

  // Analytics & Error Tracking
  static bool get sentryEnabled => _getConfig(
        'FLUTTER_SENTRY_ENABLED',
        'false',
      ).toLowerCase() == 'true';

  static String get sentryDsn => _getConfig(
        'FLUTTER_SENTRY_DSN',
        '',
      );

  static bool get firebaseAnalyticsEnabled => _getConfig(
        'FLUTTER_FIREBASE_ANALYTICS_ENABLED',
        'false',
      ).toLowerCase() == 'true';
}