import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_storage_factory.dart';
import './app_config.dart';

class SupabaseConfig {
  static Supabase? _instance;
  static final SecureStorage _secureStorage = SecureStorageFactory.create();

  static Supabase get instance {
    if (_instance == null) {
      throw Exception('Supabase not initialized. Call initialize() first or check AUTH_PROVIDER setting.');
    }
    return _instance!;
  }

  static SupabaseClient get client => instance.client;
  static SecureStorage get secureStorage => _secureStorage;

  /// Initialize Supabase (only if using Supabase auth)
  static Future<void> initialize() async {
    // Skip initialization if not using Supabase
    if (!AppConfig.useSupabaseAuth) {
      return;
    }

    final supabaseUrl = AppConfig.supabaseUrl;
    final supabaseAnonKey = AppConfig.supabaseAnonKey;

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase configuration is missing. Set SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.');
    }

    _instance = await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );
  }

  static Future<void> persistSession(Session session) async {
    await _secureStorage.write('access_token', session.accessToken);
    if (session.refreshToken != null) {
      await _secureStorage.write('refresh_token', session.refreshToken!);
    }
    await _secureStorage.write('expires_at', session.expiresAt.toString());
    await _secureStorage.write('user_id', session.user.id);
  }

  static Future<void> clearSession() async {
    await _secureStorage.delete('access_token');
    await _secureStorage.delete('refresh_token');
    await _secureStorage.delete('expires_at');
    await _secureStorage.delete('user_id');
  }

  static Future<Session?> getStoredSession() async {
    try {
      final accessToken = await _secureStorage.read('access_token');
      final refreshToken = await _secureStorage.read('refresh_token');

      if (accessToken == null || refreshToken == null) {
        return null;
      }

      // Return null as we'll use the auth repository's recoverSession method
      // which properly handles session restoration through Supabase's API
      return null;
    } catch (e) {
      return null;
    }
  }
}