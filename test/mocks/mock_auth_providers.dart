import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/auth/domain/auth_interface.dart';
import 'package:pm_master_v2/features/auth/presentation/providers/auth_provider.dart';
import 'package:pm_master_v2/core/services/auth_service.dart';
import 'mock_auth.dart';

/// Mock AuthService for testing
class MockAuthService extends AuthService {
  String? _mockToken;
  String? _mockRefreshToken;
  String? _mockUserId;
  String? _mockOrganizationId;

  MockAuthService({
    String? token,
    String? refreshToken,
    String? userId,
    String? organizationId,
  })  : _mockToken = token,
        _mockRefreshToken = refreshToken,
        _mockUserId = userId,
        _mockOrganizationId = organizationId;

  @override
  Future<String?> getToken() async => _mockToken;

  @override
  Future<String?> getRefreshToken() async => _mockRefreshToken;

  @override
  Future<String?> getUserId() async => _mockUserId;

  @override
  Future<String?> getOrganizationId() async => _mockOrganizationId;

  @override
  Future<void> setToken(String token) async {
    _mockToken = token;
  }

  @override
  Future<void> setRefreshToken(String refreshToken) async {
    _mockRefreshToken = refreshToken;
  }

  @override
  Future<void> setUserId(String userId) async {
    _mockUserId = userId;
  }

  @override
  Future<void> setOrganizationId(String organizationId) async {
    _mockOrganizationId = organizationId;
  }

  @override
  Future<void> clearAuth() async {
    _mockToken = null;
    _mockRefreshToken = null;
    _mockUserId = null;
    _mockOrganizationId = null;
  }

  @override
  Future<bool> isAuthenticated() async {
    return _mockToken != null && _mockToken!.isNotEmpty;
  }

  @override
  Future<void> setDevToken() async {
    await setToken('dev_token_123');
    await setUserId('user_123');
    await setOrganizationId('org_123');
  }
}

/// Mock AuthRepository for testing
class MockAuthRepository implements AuthInterface {
  final AppAuthUser? _mockUser;
  final AuthSession? _mockSession;
  final StreamController<AuthStateChange> _authStateController = StreamController.broadcast();

  MockAuthRepository({AppAuthUser? user, AuthSession? session})
      : _mockUser = user,
        _mockSession = session ?? (user != null ? createMockSession(user: user) : null);

  @override
  AppAuthUser? get currentUser => _mockUser;

  @override
  AuthSession? get currentSession => _mockSession;

  @override
  Stream<AuthStateChange> get authStateChanges => _authStateController.stream;

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    final user = _mockUser ?? createMockUser(email: email);
    final session = createMockSession(user: user);
    _authStateController.add(AuthStateChange(user: user, session: session));
    return createMockAuthResult(user: user, session: session);
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _mockUser ?? createMockUser(email: email, metadata: metadata);
    final session = createMockSession(user: user);
    _authStateController.add(AuthStateChange(user: user, session: session));
    return createMockAuthResult(user: user, session: session);
  }

  @override
  Future<void> signOut() async {
    _authStateController.add(AuthStateChange(user: null, session: null));
  }

  @override
  Future<AuthSession?> recoverSession() async {
    if (_mockUser != null) {
      return createMockSession(user: _mockUser);
    }
    return null;
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    return createMockAuthResult(user: _mockUser, session: _mockSession);
  }

  @override
  Future<AuthResult> updateProfile({
    String? email,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    return createMockAuthResult(user: _mockUser, session: _mockSession);
  }

  @override
  Future<void> verifyOTP({required String email, required String token}) async {}

  void dispose() {
    _authStateController.close();
  }
}

/// Override for authenticated user
final mockAuthenticatedUserOverride = authRepositoryProvider.overrideWith((ref) {
  return MockAuthRepository(user: createMockUser());
});

/// Override for unauthenticated user
final mockUnauthenticatedUserOverride = authRepositoryProvider.overrideWith((ref) {
  return MockAuthRepository(user: null);
});

/// Override with custom user
Override mockAuthWithUser(AppAuthUser? user) {
  return authRepositoryProvider.overrideWith((ref) {
    return MockAuthRepository(user: user);
  });
}

/// Override authServiceProvider with mock
final mockAuthServiceOverride = authServiceProvider.overrideWith((ref) {
  return MockAuthService(token: 'mock-token');
});

/// Create a complete set of auth overrides for testing
List<Override> createMockAuthOverrides({AppAuthUser? user, String? token}) {
  return [
    authRepositoryProvider.overrideWith((ref) {
      return MockAuthRepository(user: user);
    }),
    authServiceProvider.overrideWith((ref) {
      return MockAuthService(token: token ?? (user != null ? 'mock-token' : null));
    }),
  ];
}

/// Helper to create ProviderContainer with auth mocks
ProviderContainer createAuthenticatedContainer({
  AppAuthUser? user,
  List<Override>? additionalOverrides,
}) {
  final authUser = user ?? createMockUser();
  return ProviderContainer(
    overrides: [
      ...createMockAuthOverrides(user: authUser, token: 'mock-token'),
      ...?additionalOverrides,
    ],
  );
}

/// Helper to create ProviderContainer without auth
ProviderContainer createUnauthenticatedContainer({
  List<Override>? additionalOverrides,
}) {
  return ProviderContainer(
    overrides: [
      ...createMockAuthOverrides(user: null, token: null),
      ...?additionalOverrides,
    ],
  );
}
