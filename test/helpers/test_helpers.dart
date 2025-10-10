import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/app/theme/app_theme.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import 'package:pm_master_v2/core/models/notification_model.dart';

/// Creates a test app with necessary providers and routing
/// Wraps a widget with MaterialApp and ProviderScope for testing
Widget createTestApp({
  required Widget child,
  List<Override>? overrides,
  bool wrapInScaffold = false,
}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: wrapInScaffold ? Scaffold(body: child) : child,
    ),
  );
}

/// Pump a widget with providers and wait for all animations to settle
Future<void> pumpWidgetWithProviders(
  WidgetTester tester,
  Widget widget, {
  List<Override>? overrides,
  bool settle = true,
  bool wrapInScaffold = false,
  Size? screenSize,
}) async {
  // Set screen size if provided
  if (screenSize != null) {
    await tester.binding.setSurfaceSize(screenSize);
  }

  await tester.pumpWidget(
    createTestApp(
      child: widget,
      overrides: overrides,
      wrapInScaffold: wrapInScaffold,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Find a widget by its text content
Finder findText(String text) => find.text(text);

/// Find a widget by its type
Finder findByType<T>() => find.byType(T);

/// Find a widget by its key
Finder findByKey(Key key) => find.byKey(key);

/// Tap on a widget and wait for animations
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Enter text into a text field and wait for animations
Future<void> enterTextAndSettle(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Wait for a specific condition to be true
Future<void> waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration pollInterval = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (condition()) return;
    await tester.pump(pollInterval);
  }
  throw TimeoutException('Condition not met within timeout', timeout);
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}

/// Mock NotificationService for testing
/// Tracks all notifications that are shown during tests
class MockNotificationService extends NotificationService {
  final List<Map<String, dynamic>> showCalls = [];
  final List<String> errorCalls = [];
  final List<String> successCalls = [];
  final List<String> warningCalls = [];
  final List<String> infoCalls = [];

  @override
  String show({
    required String title,
    String? message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationPosition position = NotificationPosition.topRight,
    int? durationMs,
    bool persistent = false,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    IconData? icon,
    String? avatarUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool showInCenter = true,
    bool showAsToast = true,
  }) {
    showCalls.add({
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
    });
    return 'mock-id-${showCalls.length}';
  }

  @override
  void showError(String message, {String? title, VoidCallback? onAction}) {
    errorCalls.add(message);
    show(
      title: title ?? 'Error',
      message: message,
      type: NotificationType.error,
    );
  }

  @override
  void showSuccess(String message, {String? title}) {
    successCalls.add(message);
    show(
      title: title ?? 'Success',
      message: message,
      type: NotificationType.success,
    );
  }

  @override
  void showWarning(String message, {String? title}) {
    warningCalls.add(message);
    show(
      title: title ?? 'Warning',
      message: message,
      type: NotificationType.warning,
    );
  }

  @override
  void showInfo(String message, {String? title}) {
    infoCalls.add(message);
    show(
      title: title ?? 'Info',
      message: message,
      type: NotificationType.info,
    );
  }

  void reset() {
    showCalls.clear();
    errorCalls.clear();
    successCalls.clear();
    warningCalls.clear();
    infoCalls.clear();
  }

  bool hasNotification(String message) {
    return showCalls.any((call) =>
      call['message'] == message ||
      infoCalls.contains(message) ||
      successCalls.contains(message) ||
      errorCalls.contains(message) ||
      warningCalls.contains(message)
    );
  }
}

/// Creates an override for the notification service provider with a mock
MockNotificationService createMockNotificationService() {
  return MockNotificationService();
}
