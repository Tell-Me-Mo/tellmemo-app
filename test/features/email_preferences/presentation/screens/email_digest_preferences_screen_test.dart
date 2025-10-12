import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/email_preferences/presentation/screens/email_digest_preferences_screen.dart';
import 'package:pm_master_v2/features/email_preferences/presentation/providers/email_preferences_provider.dart';
import 'package:pm_master_v2/features/email_preferences/data/models/email_digest_preferences.dart';
import 'package:pm_master_v2/features/email_preferences/data/services/email_preferences_api_service.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import 'package:dio/dio.dart';

// Mock API service for testing
class MockEmailPreferencesApiService extends EmailPreferencesApiService {
  bool shouldFail = false;
  EmailDigestPreferences? lastSavedPreferences;
  bool testEmailSent = false;

  MockEmailPreferencesApiService() : super(Dio());

  @override
  Future<EmailDigestPreferences> getDigestPreferences() async {
    if (shouldFail) {
      throw Exception('Failed to load preferences');
    }
    return EmailDigestPreferences(
      enabled: true,
      frequency: DigestFrequency.weekly,
      contentTypes: const [
        DigestContentType.summaries,
        DigestContentType.tasksAssigned,
      ],
      includePortfolioRollup: true,
    );
  }

  @override
  Future<EmailDigestPreferences> updateDigestPreferences(
    EmailDigestPreferences preferences,
  ) async {
    if (shouldFail) {
      throw Exception('Failed to save preferences');
    }
    lastSavedPreferences = preferences;
    return preferences;
  }

  @override
  Future<Map<String, dynamic>> sendTestDigest() async {
    if (shouldFail) {
      throw Exception('Failed to send test email');
    }
    testEmailSent = true;
    return {'success': true, 'message': 'Test email sent'};
  }
}

// Mock notification service for testing
class MockNotificationService extends NotificationService {
  final List<String> errorCalls = [];
  final List<String> successCalls = [];

  @override
  void showError(String message, {String? title, VoidCallback? onAction}) {
    errorCalls.add(message);
  }

  @override
  void showSuccess(String message, {String? title}) {
    successCalls.add(message);
  }
}

void main() {
  group('EmailDigestPreferencesScreen', () {
    late MockEmailPreferencesApiService mockApiService;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockApiService = MockEmailPreferencesApiService();
      mockNotificationService = MockNotificationService();
    });

    Widget createScreen() {
      return ProviderScope(
        overrides: [
          emailPreferencesApiServiceProvider.overrideWith((ref) => mockApiService),
          notificationServiceProvider.overrideWith((ref) => mockNotificationService),
        ],
        child: const MaterialApp(
          home: EmailDigestPreferencesScreen(),
        ),
      );
    }

    testWidgets('renders screen and displays preferences', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Should show screen title and enable section
      expect(find.text('Email Digest'), findsAtLeastNWidgets(1));
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('displays frequency options when enabled', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('displays content type options', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Content to Include'), findsOneWidget);
      expect(find.text('Meeting Summaries'), findsOneWidget);
      expect(find.text('Tasks Assigned to Me'), findsOneWidget);
      expect(find.text('Critical Risks'), findsOneWidget);
    });

    testWidgets('can toggle email digest enabled', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Find and tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Content sections should be hidden when disabled
      expect(find.text('Frequency'), findsNothing);
      expect(find.text('Content to Include'), findsNothing);
    });

    testWidgets('displays Portfolio Rollup option', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Include Portfolio Rollup'), findsOneWidget);
    });

    testWidgets('wraps content in scrollable view', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('displays back button', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      mockApiService.shouldFail = true;
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('Error loading preferences'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays info section', (tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('About Email Digests'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });
}
