import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_storage_factory.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _organizationIdKey = 'organization_id';

  final SecureStorage _storage = SecureStorageFactory.create();

  // Cache token in memory
  String? _cachedToken;
  String? _cachedRefreshToken;
  String? _cachedUserId;
  String? _cachedOrganizationId;

  Future<String?> getToken() async {
    _cachedToken ??= await _storage.read(_tokenKey);
    return _cachedToken;
  }

  Future<String?> getRefreshToken() async {
    _cachedRefreshToken ??= await _storage.read(_refreshTokenKey);
    return _cachedRefreshToken;
  }

  Future<String?> getUserId() async {
    _cachedUserId ??= await _storage.read(_userIdKey);
    return _cachedUserId;
  }

  Future<String?> getOrganizationId() async {
    _cachedOrganizationId ??= await _storage.read(_organizationIdKey);
    return _cachedOrganizationId;
  }

  Future<void> setToken(String token) async {
    _cachedToken = token;
    await _storage.write(_tokenKey, token);
  }

  Future<void> setRefreshToken(String refreshToken) async {
    _cachedRefreshToken = refreshToken;
    await _storage.write(_refreshTokenKey, refreshToken);
  }

  Future<void> setUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(_userIdKey, userId);
  }

  Future<void> setOrganizationId(String organizationId) async {
    _cachedOrganizationId = organizationId;
    await _storage.write(_organizationIdKey, organizationId);
  }

  Future<void> clearAuth() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    _cachedUserId = null;
    _cachedOrganizationId = null;
    await _storage.deleteAll();
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // For development/testing - use a hardcoded token
  Future<void> setDevToken() async {
    // This would be replaced with actual auth flow
    await setToken('dev_token_123');
    await setUserId('user_123');
    await setOrganizationId('org_123');
  }
}