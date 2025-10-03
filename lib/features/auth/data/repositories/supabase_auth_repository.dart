import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/auth_interface.dart';
import '../../../../core/config/supabase_config.dart';

// Custom auth exceptions for better error handling
class AuthInvalidCredentialsError implements Exception {
  final String message;
  AuthInvalidCredentialsError([this.message = 'Invalid email or password']);

  @override
  String toString() => message;
}

class AuthUserNotFoundError implements Exception {
  final String email;
  final String message;
  AuthUserNotFoundError(this.email, [String? customMessage])
    : message = customMessage ?? 'No account found with email: $email';

  @override
  String toString() => message;
}

class SupabaseAuthRepository implements AuthInterface {
  final SupabaseClient _client;

  SupabaseAuthRepository() : _client = SupabaseConfig.client;

  @override
  Stream<AuthStateChange> get authStateChanges =>
    _client.auth.onAuthStateChange.map((state) => AuthStateChange(
      session: state.session != null ? _mapSession(state.session!) : null,
      user: state.session?.user != null ? _mapUser(state.session!.user) : null,
    ));

  @override
  AppAuthUser? get currentUser =>
    _client.auth.currentUser != null ? _mapUser(_client.auth.currentUser!) : null;

  @override
  AuthSession? get currentSession =>
    _client.auth.currentSession != null ? _mapSession(_client.auth.currentSession!) : null;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.session != null) {
        await SupabaseConfig.persistSession(response.session!);
      }

      return AuthResult(
        user: response.user != null ? _mapUser(response.user!) : null,
        session: response.session != null ? _mapSession(response.session!) : null,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up');
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await SupabaseConfig.persistSession(response.session!);
      }

      return AuthResult(
        user: response.user != null ? _mapUser(response.user!) : null,
        session: response.session != null ? _mapSession(response.session!) : null,
      );
    } on AuthException catch (e) {
      // For sign in, we want to provide more specific error messages
      if (e.message.toLowerCase().contains('invalid login credentials') ||
          e.message.toLowerCase().contains('invalid password') ||
          e.message.toLowerCase().contains('user not found')) {
        throw AuthInvalidCredentialsError('Invalid email or password');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AuthInvalidCredentialsError) {
        rethrow;
      }
      throw Exception('An unexpected error occurred during sign in');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await SupabaseConfig.clearSession();
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during sign out');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'pm-master://reset-password',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during password reset');
    }
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return AuthResult(
        user: response.user != null ? _mapUser(response.user!) : null,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during password update');
    }
  }

  @override
  Future<AuthResult> updateProfile({
    String? email,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(
          email: email,
          phone: phone,
          data: data,
        ),
      );

      return AuthResult(
        user: response.user != null ? _mapUser(response.user!) : null,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during profile update');
    }
  }

  @override
  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred during OTP verification');
    }
  }

  @override
  Future<AuthSession?> recoverSession() async {
    try {
      // First check if we have a current valid session
      final currentSession = _client.auth.currentSession;
      if (currentSession != null) {
        // Check if session is not expired
        final expiresAt = currentSession.expiresAt;
        if (expiresAt != null) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          if (now < expiresAt) {
            // Session is still valid
            return _mapSession(currentSession);
          }
        }
      }

      // If no valid session, let Supabase handle the refresh internally
      try {
        final response = await _client.auth.refreshSession();
        if (response.session != null) {
          await SupabaseConfig.persistSession(response.session!);
          return _mapSession(response.session!);
        }
      } catch (e) {
        // If refresh fails, clear session
        await SupabaseConfig.clearSession();
        return null;
      }

      return null;
    } catch (e) {
      // Clear session on any error to avoid stale tokens
      await SupabaseConfig.clearSession();
      return null;
    }
  }

  // Helper methods to map Supabase types to our generic types
  AppAuthUser _mapUser(User user) {
    return AppAuthUser(
      id: user.id,
      email: user.email,
      phone: user.phone,
      metadata: user.userMetadata,
    );
  }

  AuthSession _mapSession(Session session) {
    return AuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
      user: _mapUser(session.user),
    );
  }

  Exception _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('email')) {
          return Exception('Invalid email address');
        } else if (e.message.contains('password')) {
          return Exception('Password must be at least 6 characters');
        }
        return Exception('Invalid credentials');
      case '422':
        return Exception('Email already registered');
      case '429':
        return Exception('Too many attempts. Please try again later');
      default:
        return Exception(e.message);
    }
  }
}
