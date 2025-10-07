import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/features/auth/domain/auth_interface.dart';

/// Mock implementation of AuthInterface for testing
class MockAuthRepository extends Mock implements AuthInterface {}

/// Mock Auth User for testing
AppAuthUser createMockUser({
  String id = 'test-user-id',
  String? email = 'test@example.com',
  String? phone,
  Map<String, dynamic>? metadata,
}) {
  return AppAuthUser(
    id: id,
    email: email,
    phone: phone,
    metadata: metadata,
  );
}

/// Mock Auth Session for testing
AuthSession createMockSession({
  String accessToken = 'mock-access-token',
  String? refreshToken = 'mock-refresh-token',
  int? expiresAt,
  AppAuthUser? user,
}) {
  return AuthSession(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    user: user ?? createMockUser(),
  );
}

/// Mock Auth Result for testing
AuthResult createMockAuthResult({
  AppAuthUser? user,
  AuthSession? session,
}) {
  final mockUser = user ?? createMockUser();
  return AuthResult(
    user: mockUser,
    session: session ?? createMockSession(user: mockUser),
  );
}

/// Common Auth Exceptions for testing
class AuthInvalidCredentialsError implements Exception {
  final String message;
  AuthInvalidCredentialsError([this.message = 'Invalid credentials']);

  @override
  String toString() => message;
}

class AuthEmailAlreadyExistsError implements Exception {
  final String message;
  AuthEmailAlreadyExistsError([this.message = 'Email already registered']);

  @override
  String toString() => message;
}

class AuthWeakPasswordError implements Exception {
  final String message;
  AuthWeakPasswordError([this.message = 'Weak password']);

  @override
  String toString() => message;
}

class AuthNetworkError implements Exception {
  final String message;
  AuthNetworkError([this.message = 'Network error']);

  @override
  String toString() => message;
}

class AuthEmailNotConfirmedError implements Exception {
  final String message;
  AuthEmailNotConfirmedError([this.message = 'Email not confirmed']);

  @override
  String toString() => message;
}
