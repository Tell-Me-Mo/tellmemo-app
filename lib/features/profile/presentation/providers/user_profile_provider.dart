import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileController extends _$UserProfileController {
  @override
  FutureOr<UserProfile?> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return null;

    return _mapUserToProfile(user);
  }

  UserProfile _mapUserToProfile(User user) {
    final metadata = user.userMetadata ?? {};

    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      name: metadata['name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
      bio: metadata['bio'] as String?,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(user.updatedAt ?? user.createdAt) ?? DateTime.now(),
      preferences: metadata['preferences'] as Map<String, dynamic>?,
      userMetadata: metadata,
    );
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final currentUser = await ref.read(authControllerProvider.future);
    if (currentUser == null) throw Exception('No authenticated user');

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await ref.read(authControllerProvider.notifier).updateProfile(
      additionalData: updates,
    );

    // Refresh the profile
    ref.invalidateSelf();
  }

  Future<void> updatePreferences(UserPreferences preferences) async {
    final currentUser = await ref.read(authControllerProvider.future);
    if (currentUser == null) throw Exception('No authenticated user');

    await ref.read(authControllerProvider.notifier).updateProfile(
      additionalData: {
        'preferences': preferences.toJson(),
      },
    );

    // Refresh the profile
    ref.invalidateSelf();
  }

  Future<void> updateEmail(String newEmail) async {
    await ref.read(authControllerProvider.notifier).updateProfile(
      email: newEmail,
    );

    // Refresh the profile
    ref.invalidateSelf();
  }

  Future<void> updatePassword(String newPassword) async {
    await ref.read(authControllerProvider.notifier).updatePassword(newPassword);
  }

  UserPreferences get preferences {
    final profile = state.value;
    if (profile?.preferences == null) {
      return const UserPreferences();
    }

    try {
      return UserPreferences.fromJson(profile!.preferences!);
    } catch (e) {
      return const UserPreferences();
    }
  }
}