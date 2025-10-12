/// Flutter App Configuration
///
/// EDIT THIS FILE DIRECTLY - Change the values below for your environment
/// Then just run or build the app normally

class Config {
  // ============================================
  // MAIN CONFIGURATION - Edit these values
  // ============================================

  // API Backend URL - Uncomment the one you need:
  static const String apiBaseUrl = 'http://localhost:8000'; // Local development
  // static const String apiBaseUrl = 'https://api.tellmemo.io'; // Production

  // Environment
  static const String environment = 'development'; // development | production

  // Authentication Provider
  static const String authProvider = 'backend'; // backend | supabase

  // ============================================
  // OPTIONAL FEATURES - Enable as needed
  // ============================================

  // Debugging & Logging
  static const bool enableLogging = true; // Set to false in production
  static const bool enableDebugMode = true; // Set to false in production

  // Sentry Error Tracking
  static const bool sentryEnabled = false; // Set to true in production
  static const String sentryDsn =
      'https://4b881d36553907c1293df1e416a7ee01@o4507007486394368.ingest.us.sentry.io/4510112239452160'; // Add your Sentry DSN here

  // Firebase Analytics
  static const bool firebaseAnalyticsEnabled =
      false; // Set to true if using Firebase

  // Supabase (only if authProvider = 'supabase')
  static const String supabaseUrl = ''; // Add your Supabase URL
  static const String supabaseAnonKey = ''; // Add your Supabase anon key
  static const int apiTimeout = 30000; // milliseconds

  // ============================================
  // COMPUTED VALUES - Don't edit these
  // ============================================

  static const bool isDevelopment = environment == 'development';
  static const bool isProduction = environment == 'production';
  static const bool useSupabaseAuth = authProvider == 'supabase';
  static const bool useBackendAuth = authProvider == 'backend';
}
