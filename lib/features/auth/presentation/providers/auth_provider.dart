import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/auth_interface.dart';
import '../../data/repositories/auth_repository_factory.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/auth_service.dart';

part 'auth_provider.g.dart';

@riverpod
AuthInterface authRepository(Ref ref) {
  final authService = ref.watch(authServiceProvider);
  // Initialize DioClient with authService for token management
  final dio = DioClient.getInstance(authService: authService);
  return AuthRepositoryFactory.getInstance(
    dio: dio,
    authService: authService,
  );
}

@riverpod
Stream<AuthStateChange> authStateChanges(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}

@riverpod
class AuthController extends _$AuthController {
  late final AuthInterface _repository;

  @override
  FutureOr<AppAuthUser?> build() async {
    _repository = ref.watch(authRepositoryProvider);

    // Try to recover session on initialization
    try {
      final session = await _repository.recoverSession();
      if (session != null) {
        return session.user;
      }
    } catch (e) {
      // If session recovery fails, just return null
      // This handles cases where refresh tokens are invalid
      // Silent failure is OK here as user will be redirected to login
    }

    // Listen to auth state changes
    ref.listen(authStateChangesProvider, (previous, next) {
      next.whenData((authState) {
        // Only update state if we're not already in an error state
        // This prevents auth errors from overwriting the current state
        if (!state.hasError) {
          state = AsyncData(authState.user);
        }
      });
    });

    return _repository.currentUser;
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    // Don't set loading state here to avoid triggering navigation
    // The UI will handle its own loading state
    final result = await AsyncValue.guard(() async {
      final authResult = await _repository.signUp(
        email: email,
        password: password,
        metadata: name != null ? {'name': name} : null,
      );
      return authResult.user;
    });

    // Only update state if successful
    if (!result.hasError) {
      state = result;
    } else {
      // Throw the error to be caught by the UI
      throw result.error!;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Don't set loading state here to avoid triggering navigation
    // The UI will handle its own loading state
    final result = await AsyncValue.guard(() async {
      final authResult = await _repository.signIn(
        email: email,
        password: password,
      );
      return authResult.user;
    });

    // Only update state if successful
    if (!result.hasError) {
      state = result;
    } else {
      // Throw the error to be caught by the UI
      throw result.error!;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await _repository.signOut();
    state = const AsyncData(null);
  }

  Future<void> resetPassword(String email) async {
    await _repository.resetPassword(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _repository.updatePassword(newPassword);
  }

  Future<void> updateProfile({
    String? email,
    String? name,
    Map<String, dynamic>? additionalData,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (additionalData != null) data.addAll(additionalData);

    await _repository.updateProfile(
      email: email,
      data: data.isNotEmpty ? data : null,
    );

    // Refresh the current user
    ref.invalidateSelf();
  }

  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    await _repository.verifyOTP(email: email, token: token);
    ref.invalidateSelf();
  }
}