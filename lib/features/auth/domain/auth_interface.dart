/// Abstract interface for authentication providers
/// Allows switching between Supabase, backend, or other auth providers
abstract class AuthInterface {
  /// Sign up a new user
  Future<AuthResult> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  });

  /// Sign in an existing user
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Reset password for a user
  Future<void> resetPassword(String email);

  /// Update user password
  Future<AuthResult> updatePassword(String newPassword);

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? email,
    String? phone,
    Map<String, dynamic>? data,
  });

  /// Verify OTP
  Future<void> verifyOTP({
    required String email,
    required String token,
  });

  /// Recover/refresh session
  Future<AuthSession?> recoverSession();

  /// Get current user
  AppAuthUser? get currentUser;

  /// Get current session
  AuthSession? get currentSession;

  /// Listen to auth state changes
  Stream<AuthStateChange> get authStateChanges;
}

/// Generic auth result that works with any provider
class AuthResult {
  final AppAuthUser? user;
  final AuthSession? session;

  AuthResult({this.user, this.session});
}

/// Generic auth user model
class AppAuthUser {
  final String id;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? metadata;

  AppAuthUser({
    required this.id,
    this.email,
    this.phone,
    this.metadata,
  });
}

/// Generic auth session model
class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final int? expiresAt;
  final AppAuthUser user;

  AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    required this.user,
  });
}

/// Auth state change event
class AuthStateChange {
  final AuthSession? session;
  final AppAuthUser? user;

  AuthStateChange({this.session, this.user});
}
