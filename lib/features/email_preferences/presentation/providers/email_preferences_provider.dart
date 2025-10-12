import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../data/models/email_digest_preferences.dart';
import '../../data/services/email_preferences_api_service.dart';

/// Provider for email preferences API service
final emailPreferencesApiServiceProvider = Provider<EmailPreferencesApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EmailPreferencesApiService(apiClient.dio);
});

/// State for email digest preferences
class EmailPreferencesState {
  final EmailDigestPreferences? preferences;
  final bool isLoading;
  final String? error;
  final bool hasUnsavedChanges;

  const EmailPreferencesState({
    this.preferences,
    this.isLoading = false,
    this.error,
    this.hasUnsavedChanges = false,
  });

  EmailPreferencesState copyWith({
    EmailDigestPreferences? preferences,
    bool? isLoading,
    String? error,
    bool? hasUnsavedChanges,
  }) {
    return EmailPreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

/// Controller for email preferences
class EmailPreferencesController extends StateNotifier<EmailPreferencesState> {
  final EmailPreferencesApiService _apiService;

  EmailPreferencesController(this._apiService)
      : super(const EmailPreferencesState());

  /// Load current preferences from API
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final preferences = await _apiService.getDigestPreferences();
      state = state.copyWith(
        preferences: preferences,
        isLoading: false,
        hasUnsavedChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update preferences locally (mark as unsaved)
  void updateLocal(EmailDigestPreferences preferences) {
    state = state.copyWith(
      preferences: preferences,
      hasUnsavedChanges: true,
      error: null,
    );
  }

  /// Save preferences to API
  Future<void> savePreferences() async {
    if (state.preferences == null) {
      state = state.copyWith(error: 'No preferences to save');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updated = await _apiService.updateDigestPreferences(
        state.preferences!,
      );
      state = state.copyWith(
        preferences: updated,
        isLoading: false,
        hasUnsavedChanges: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle enabled status
  void toggleEnabled() {
    if (state.preferences != null) {
      updateLocal(
        state.preferences!.copyWith(enabled: !state.preferences!.enabled),
      );
    }
  }

  /// Update frequency
  void updateFrequency(String frequency) {
    if (state.preferences != null) {
      updateLocal(
        state.preferences!.copyWith(frequency: frequency),
      );
    }
  }

  /// Toggle content type
  void toggleContentType(String contentType) {
    if (state.preferences != null) {
      final currentTypes = List<String>.from(state.preferences!.contentTypes);

      if (currentTypes.contains(contentType)) {
        currentTypes.remove(contentType);
      } else {
        currentTypes.add(contentType);
      }

      updateLocal(
        state.preferences!.copyWith(contentTypes: currentTypes),
      );
    }
  }

  /// Toggle portfolio rollup
  void togglePortfolioRollup() {
    if (state.preferences != null) {
      updateLocal(
        state.preferences!.copyWith(
          includePortfolioRollup: !state.preferences!.includePortfolioRollup,
        ),
      );
    }
  }

  /// Discard unsaved changes
  Future<void> discardChanges() async {
    await loadPreferences();
  }

  /// Reset error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for email preferences controller
final emailPreferencesControllerProvider =
    StateNotifierProvider<EmailPreferencesController, EmailPreferencesState>((ref) {
  final apiService = ref.watch(emailPreferencesApiServiceProvider);
  return EmailPreferencesController(apiService);
});

/// Provider for digest preview
final digestPreviewProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, digestType) async {
  final apiService = ref.watch(emailPreferencesApiServiceProvider);
  return apiService.previewDigest(digestType: digestType);
});

/// Provider for sending test digest
final sendTestDigestProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(emailPreferencesApiServiceProvider);
  return apiService.sendTestDigest();
});
