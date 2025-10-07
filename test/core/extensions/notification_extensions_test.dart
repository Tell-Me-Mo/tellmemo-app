import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/extensions/notification_extensions.dart';
import 'package:pm_master_v2/core/models/notification_model.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';

void main() {
  group('NotificationContextExtension', () {
    group('showNotification()', () {
      testWidgets('throws UnimplementedError when called', (tester) async {
        var threw = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    try {
                      ctx.showNotification(title: 'Test');
                    } catch (e) {
                      threw = e is UnimplementedError;
                    }
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(threw, true);
      });
    });

    group('showError()', () {
      testWidgets('throws UnimplementedError when called', (tester) async {
        var threw = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    try {
                      ctx.showError('Test error');
                    } catch (e) {
                      threw = e is UnimplementedError;
                    }
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(threw, true);
      });
    });

    group('showSuccess()', () {
      testWidgets('throws UnimplementedError when called', (tester) async {
        var threw = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    try {
                      ctx.showSuccess('Test success');
                    } catch (e) {
                      threw = e is UnimplementedError;
                    }
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(threw, true);
      });
    });

    group('showWarning()', () {
      testWidgets('throws UnimplementedError when called', (tester) async {
        var threw = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    try {
                      ctx.showWarning('Test warning');
                    } catch (e) {
                      threw = e is UnimplementedError;
                    }
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(threw, true);
      });
    });

    group('showInfo()', () {
      testWidgets('throws UnimplementedError when called', (tester) async {
        var threw = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    try {
                      ctx.showInfo('Test info');
                    } catch (e) {
                      threw = e is UnimplementedError;
                    }
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(threw, true);
      });
    });
  });

  group('NotificationWidgetRefExtension', () {
    group('notifications getter', () {
      test('returns NotificationService instance', () {
        final container = ProviderContainer();
        final service = container.read(notificationServiceProvider.notifier);
        expect(service, isA<NotificationService>());
        container.dispose();
      });

      test('returns same instance on multiple calls', () {
        final container = ProviderContainer();
        final service1 = container.read(notificationServiceProvider.notifier);
        final service2 = container.read(notificationServiceProvider.notifier);
        expect(identical(service1, service2), true);
        container.dispose();
      });
    });

    group('showNotification()', () {
      test('calls NotificationService.show() with correct parameters', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).show(
          title: 'Test Title',
          message: 'Test Message',
          type: NotificationType.info,
          priority: NotificationPriority.normal,
        );

        // Wait for microtasks
        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.title, 'Test Title');
        expect(state.active.first.message, 'Test Message');
        expect(state.active.first.type, NotificationType.info);
        expect(state.active.first.priority, NotificationPriority.normal);

        container.dispose();
      });

      test('supports persistent notifications', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).show(
          title: 'Persistent',
          persistent: true,
        );

        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);
        expect(state.active.first.persistent, true);

        container.dispose();
      });
    });

    group('showError()', () {
      test('creates error notification with default title', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showError('Something went wrong');

        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.title, 'Error');
        expect(state.active.first.message, 'Something went wrong');
        expect(state.active.first.type, NotificationType.error);
        expect(state.active.first.priority, NotificationPriority.high);

        container.dispose();
      });

      test('creates error notification with custom title', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showError(
          'Failed',
          title: 'API Error',
        );

        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);

        expect(state.active.first.title, 'API Error');
        expect(state.active.first.message, 'Failed');

        container.dispose();
      });
    });

    group('showSuccess()', () {
      test('creates success notification with default title', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showSuccess('Operation completed');

        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.title, 'Success');
        expect(state.active.first.message, 'Operation completed');
        expect(state.active.first.type, NotificationType.success);

        container.dispose();
      });
    });

    group('showWarning()', () {
      test('creates warning notification with default title', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showWarning('Check your input');

        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.title, 'Warning');
        expect(state.active.first.message, 'Check your input');
        expect(state.active.first.type, NotificationType.warning);

        container.dispose();
      });
    });

    group('showInfo()', () {
      test('creates info notification with default title', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showInfo('New update available');

        await Future.microtask(() {});

        final state = container.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.title, 'Info');
        expect(state.active.first.message, 'New update available');
        expect(state.active.first.type, NotificationType.info);

        container.dispose();
      });
    });

    group('dismissNotification()', () {
      test('dismisses notification by id', () async {
        final container = ProviderContainer();

        final id = container.read(notificationServiceProvider.notifier).show(title: 'Test');

        await Future.microtask(() {});

        var state = container.read(notificationServiceProvider);
        expect(state.active.length, 1);

        container.read(notificationServiceProvider.notifier).dismiss(id);

        await Future.microtask(() {});

        state = container.read(notificationServiceProvider);
        expect(state.active.length, 0);
        expect(state.history.length, 1);

        container.dispose();
      });
    });

    group('clearAllNotifications()', () {
      test('clears all notifications', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showInfo('Notification 1');
        container.read(notificationServiceProvider.notifier).showInfo('Notification 2');
        container.read(notificationServiceProvider.notifier).showInfo('Notification 3');

        // Wait for all queued notifications to be processed
        await Future.microtask(() {});
        await Future.microtask(() {});
        await Future.microtask(() {});

        var state = container.read(notificationServiceProvider);
        expect(state.active.length, greaterThan(0));

        container.read(notificationServiceProvider.notifier).clearAll();

        state = container.read(notificationServiceProvider);
        expect(state.active.length, 0);
        expect(state.history.length, 0);

        container.dispose();
      });
    });

    group('markNotificationAsRead()', () {
      test('marks notification as read', () async {
        final container = ProviderContainer();

        final id = container.read(notificationServiceProvider.notifier).show(title: 'Unread');

        await Future.microtask(() {});

        var state = container.read(notificationServiceProvider);
        expect(state.unreadCount, 1);
        expect(state.active.first.isRead, false);

        container.read(notificationServiceProvider.notifier).markAsRead(id);

        state = container.read(notificationServiceProvider);
        expect(state.unreadCount, 0);
        expect(state.active.first.isRead, true);

        container.dispose();
      });
    });

    group('markAllNotificationsAsRead()', () {
      test('marks all notifications as read', () async {
        final container = ProviderContainer();

        container.read(notificationServiceProvider.notifier).showInfo('Notification 1');
        container.read(notificationServiceProvider.notifier).showInfo('Notification 2');
        container.read(notificationServiceProvider.notifier).showInfo('Notification 3');

        // Wait for all queued notifications to be processed
        await Future.microtask(() {});
        await Future.microtask(() {});
        await Future.microtask(() {});

        var state = container.read(notificationServiceProvider);
        expect(state.unreadCount, greaterThan(0));

        container.read(notificationServiceProvider.notifier).markAllAsRead();

        state = container.read(notificationServiceProvider);
        expect(state.unreadCount, 0);
        expect(state.active.every((n) => n.isRead), true);

        container.dispose();
      });
    });
  });

  group('AsyncValueNotificationExtension', () {
    group('showErrorIfFailed()', () {
      testWidgets('shows error when AsyncValue is in error state', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.error('Test error', StackTrace.empty);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showErrorIfFailed(ref);
                      },
                      child: const Text('Check Error'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Error'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.type, NotificationType.error);
        expect(state.active.first.message, 'Test error');
        expect(state.active.first.title, 'Operation Failed');

        localContainer.dispose();
      });

      testWidgets('shows error with custom title', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.error('API failed', StackTrace.empty);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showErrorIfFailed(ref, title: 'Network Error');
                      },
                      child: const Text('Check Error'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Error'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.first.title, 'Network Error');
        expect(state.active.first.message, 'API failed');

        localContainer.dispose();
      });

      testWidgets('does not show notification when AsyncValue is data', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.data('Success');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showErrorIfFailed(ref);
                      },
                      child: const Text('Check Error'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Error'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.length, 0);

        localContainer.dispose();
      });
    });

    group('showSuccessIfData()', () {
      testWidgets('shows success when AsyncValue has data', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.data('Success');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showSuccessIfData(ref, 'Operation completed');
                      },
                      child: const Text('Check Success'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Success'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.type, NotificationType.success);
        expect(state.active.first.message, 'Operation completed');
        expect(state.active.first.title, 'Success');

        localContainer.dispose();
      });

      testWidgets('does not show notification when AsyncValue is error', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.error('Error', StackTrace.empty);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showSuccessIfData(ref, 'Success');
                      },
                      child: const Text('Check Success'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Success'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.length, 0);

        localContainer.dispose();
      });
    });

    group('showLoadingNotification()', () {
      testWidgets('shows loading notification when AsyncValue is loading', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.loading();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showLoadingNotification(ref, 'Loading data');
                      },
                      child: const Text('Check Loading'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Loading'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.length, 1);
        expect(state.active.first.type, NotificationType.info);
        expect(state.active.first.message, 'Loading data');
        expect(state.active.first.title, 'Loading');

        localContainer.dispose();
      });

      testWidgets('does not show notification when AsyncValue has data', (tester) async {
        final localContainer = ProviderContainer();
        final asyncValue = AsyncValue<String>.data('Success');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: localContainer,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        asyncValue.showLoadingNotification(ref, 'Loading');
                      },
                      child: const Text('Check Loading'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Check Loading'));
        await tester.pump();

        final state = localContainer.read(notificationServiceProvider);

        expect(state.active.length, 0);

        localContainer.dispose();
      });
    });
  });
}
