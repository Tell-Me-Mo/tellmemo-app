import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/core/widgets/notifications/notification_overlay.dart';
import 'package:pm_master_v2/core/widgets/notifications/notification_toast.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import 'package:pm_master_v2/core/models/notification_model.dart';

void main() {
  group('NotificationOverlay Widget', () {
    testWidgets('displays child widget', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: Text('Child Widget'),
            ),
          ),
        ),
      );

      expect(find.text('Child Widget'), findsOneWidget);
    });

    testWidgets('displays no toasts when no notifications exist', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: Text('Child'),
            ),
          ),
        ),
      );

      expect(find.byType(NotificationToast), findsNothing);
    });

    testWidgets('displays toast when notification is shown', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: Text('Child'),
            ),
          ),
        ),
      );

      service.show(
        title: 'Test Notification',
        message: 'Test message',
        showAsToast: true,
      );
      await tester.pump();

      expect(find.byType(NotificationToast), findsOneWidget);
      expect(find.text('Test Notification'), findsOneWidget);
    });

    testWidgets('does not display toast when showAsToast is false', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: Text('Child'),
            ),
          ),
        ),
      );

      service.show(
        title: 'Test Notification',
        showAsToast: false,
      );
      await tester.pump();

      expect(find.byType(NotificationToast), findsNothing);
    });

    testWidgets('displays toast for persistent notifications', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: Text('Child'),
            ),
          ),
        ),
      );

      service.show(
        title: 'Persistent Notification',
        persistent: true,
        showAsToast: true,
      );
      await tester.pump();

      expect(find.byType(NotificationToast), findsOneWidget);
      expect(find.text('Persistent Notification'), findsOneWidget);
    });

    testWidgets('removes toast when notification is dismissed', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: Text('Child'),
            ),
          ),
        ),
      );

      final id = service.show(
        title: 'Test Notification',
        showAsToast: true,
      );
      await tester.pump();

      expect(find.byType(NotificationToast), findsOneWidget);

      service.dismiss(id);
      await tester.pump();

      expect(find.byType(NotificationToast), findsNothing);
    });

    testWidgets('wraps in Directionality when not in widget tree', (tester) async {
      final service = NotificationService();

      // Create widget without MaterialApp (no Directionality)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const NotificationOverlay(
            child: SizedBox(),
          ),
        ),
      );

      expect(find.byType(Directionality), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
    });

    testWidgets('uses existing Directionality when available', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const Directionality(
            textDirection: TextDirection.rtl,
            child: NotificationOverlay(
              child: SizedBox(),
            ),
          ),
        ),
      );

      // Should have exactly one Directionality (the one we provided)
      expect(find.byType(Directionality), findsOneWidget);

      final directionality = tester.widget<Directionality>(find.byType(Directionality));
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('positions notifications at top right', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: SizedBox(),
            ),
          ),
        ),
      );

      service.show(
        title: 'Test',
        position: NotificationPosition.topRight,
        showAsToast: true,
      );
      await tester.pump();

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.top, 0);
      expect(positioned.right, 0);
      expect(positioned.bottom, isNull);
      expect(positioned.left, isNull);
    });

    testWidgets('positions notifications at bottom left', (tester) async {
      final service = NotificationService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWith((ref) => service),
          ],
          child: const MaterialApp(
            home: NotificationOverlay(
              child: SizedBox(),
            ),
          ),
        ),
      );

      service.show(
        title: 'Test',
        position: NotificationPosition.bottomLeft,
        showAsToast: true,
      );
      await tester.pump();

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(Stack),
          matching: find.byType(Positioned),
        ),
      );

      expect(positioned.top, isNull);
      expect(positioned.right, isNull);
      // Bottom should be safeAreaPadding.bottom + 16 (test environment has 0 safe area padding)
      expect(positioned.bottom, 16.0);
      expect(positioned.left, 0);
    });
  });
}
