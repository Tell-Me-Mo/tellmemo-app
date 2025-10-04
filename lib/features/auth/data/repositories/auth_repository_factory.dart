import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/auth_interface.dart';
import './supabase_auth_repository.dart';
import './backend_auth_repository.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_service.dart';

/// Factory for creating the appropriate auth repository based on configuration
class AuthRepositoryFactory {
  static AuthInterface? _instance;

  /// Get the configured auth repository instance
  static AuthInterface getInstance({
    required Dio dio,
    required AuthService authService,
  }) {
    if (_instance != null) {
      debugPrint('🏭 AuthRepositoryFactory: Returning existing instance');
      return _instance!;
    }

    debugPrint('🏭 AuthRepositoryFactory: Creating new auth repository instance');
    debugPrint('🏭 AuthRepositoryFactory: AUTH_PROVIDER from env: ${AppConfig.authProvider}');
    debugPrint('🏭 AuthRepositoryFactory: useSupabaseAuth: ${AppConfig.useSupabaseAuth}');
    debugPrint('🏭 AuthRepositoryFactory: useBackendAuth: ${AppConfig.useBackendAuth}');

    if (AppConfig.useSupabaseAuth) {
      debugPrint('🏭 AuthRepositoryFactory: Creating SupabaseAuthRepository');
      _instance = SupabaseAuthRepository();
    } else {
      debugPrint('🏭 AuthRepositoryFactory: Creating BackendAuthRepository');
      _instance = BackendAuthRepository(dio, authService);
    }

    return _instance!;
  }

  /// Reset the instance (useful for testing or auth provider switching)
  static void reset() {
    _instance = null;
  }
}
