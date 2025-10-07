import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/models/notification_model.dart';

void main() {
  group('AppNotification', () {
    final testCreatedAt = DateTime(2024, 1, 15, 10, 30);
    final testExpiresAt = DateTime(2024, 1, 16, 10, 30);

    group('fromJson', () {
      test('creates valid AppNotification from complete JSON', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'title': 'Test Notification',
          'message': 'This is a test message',
          'type': 'info',
          'priority': 'high',
          'position': 'topRight',
          'durationMs': 5000,
          'persistent': true,
          'isRead': false,
          'actionLabel': 'View',
          'avatarUrl': 'https://example.com/avatar.png',
          'imageUrl': 'https://example.com/image.png',
          'metadata': {'key': 'value'},
          'createdAt': testCreatedAt.toIso8601String(),
          'expiresAt': testExpiresAt.toIso8601String(),
          'showInCenter': true,
          'showAsToast': true,
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.id, 'notif-123');
        expect(notification.title, 'Test Notification');
        expect(notification.message, 'This is a test message');
        expect(notification.type, NotificationType.info);
        expect(notification.priority, NotificationPriority.high);
        expect(notification.position, NotificationPosition.topRight);
        expect(notification.durationMs, 5000);
        expect(notification.persistent, true);
        expect(notification.isRead, false);
        expect(notification.actionLabel, 'View');
        expect(notification.avatarUrl, 'https://example.com/avatar.png');
        expect(notification.imageUrl, 'https://example.com/image.png');
        expect(notification.metadata, {'key': 'value'});
        expect(notification.createdAt, testCreatedAt);
        expect(notification.expiresAt, testExpiresAt);
        expect(notification.showInCenter, true);
        expect(notification.showAsToast, true);
      });

      test('creates AppNotification with minimal required fields', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'title': 'Test',
          'type': 'info',
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.id, 'notif-123');
        expect(notification.title, 'Test');
        expect(notification.type, NotificationType.info);
        expect(notification.message, isNull);
        expect(notification.priority, NotificationPriority.normal);
        expect(notification.position, NotificationPosition.topRight);
        expect(notification.durationMs, 4000);
        expect(notification.persistent, false);
        expect(notification.isRead, false);
        expect(notification.actionLabel, isNull);
        expect(notification.avatarUrl, isNull);
        expect(notification.imageUrl, isNull);
        expect(notification.metadata, isNull);
        expect(notification.createdAt, isNull);
        expect(notification.expiresAt, isNull);
        expect(notification.showInCenter, true);
        expect(notification.showAsToast, true);
      });

      test('creates AppNotification with all notification types', () {
        // Arrange
        final types = ['info', 'success', 'warning', 'error', 'custom'];

        for (final type in types) {
          final json = {
            'id': 'notif-123',
            'title': 'Test',
            'type': type,
          };

          // Act
          final notification = AppNotification.fromJson(json);

          // Assert
          expect(notification.type.name, type);
        }
      });

      test('creates AppNotification with all priority levels', () {
        // Arrange
        final priorities = ['low', 'normal', 'high', 'critical'];

        for (final priority in priorities) {
          final json = {
            'id': 'notif-123',
            'title': 'Test',
            'type': 'info',
            'priority': priority,
          };

          // Act
          final notification = AppNotification.fromJson(json);

          // Assert
          expect(notification.priority.name, priority);
        }
      });

      test('creates AppNotification with all positions', () {
        // Arrange
        final positions = [
          'top',
          'bottom',
          'topLeft',
          'topRight',
          'bottomLeft',
          'bottomRight',
        ];

        for (final position in positions) {
          final json = {
            'id': 'notif-123',
            'title': 'Test',
            'type': 'info',
            'position': position,
          };

          // Act
          final notification = AppNotification.fromJson(json);

          // Assert
          expect(notification.position.name, position);
        }
      });
    });

    group('toJson', () {
      test('serializes complete AppNotification to JSON', () {
        // Arrange
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Test Notification',
          message: 'This is a test message',
          type: NotificationType.info,
          priority: NotificationPriority.high,
          position: NotificationPosition.topRight,
          durationMs: 5000,
          persistent: true,
          isRead: false,
          actionLabel: 'View',
          avatarUrl: 'https://example.com/avatar.png',
          imageUrl: 'https://example.com/image.png',
          metadata: {'key': 'value'},
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          showInCenter: true,
          showAsToast: true,
        );

        // Act
        final json = notification.toJson();

        // Assert
        expect(json['id'], 'notif-123');
        expect(json['title'], 'Test Notification');
        expect(json['message'], 'This is a test message');
        expect(json['type'], 'info');
        expect(json['priority'], 'high');
        expect(json['position'], 'topRight');
        expect(json['durationMs'], 5000);
        expect(json['persistent'], true);
        expect(json['isRead'], false);
        expect(json['actionLabel'], 'View');
        expect(json['avatarUrl'], 'https://example.com/avatar.png');
        expect(json['imageUrl'], 'https://example.com/image.png');
        expect(json['metadata'], {'key': 'value'});
        expect(json['createdAt'], testCreatedAt.toIso8601String());
        expect(json['expiresAt'], testExpiresAt.toIso8601String());
        expect(json['showInCenter'], true);
        expect(json['showAsToast'], true);
        // Callbacks and icons should not be serialized
        expect(json.containsKey('onAction'), false);
        expect(json.containsKey('onDismiss'), false);
        expect(json.containsKey('icon'), false);
      });

      test('serializes AppNotification with null fields', () {
        // Arrange
        final notification = AppNotification(
          id: 'notif-123',
          title: 'Test',
          type: NotificationType.info,
        );

        // Act
        final json = notification.toJson();

        // Assert
        expect(json['id'], 'notif-123');
        expect(json['title'], 'Test');
        expect(json['type'], 'info');
        expect(json['message'], isNull);
        expect(json['priority'], 'normal');
        expect(json['position'], 'topRight');
        expect(json['durationMs'], 4000);
        expect(json['persistent'], false);
        expect(json['isRead'], false);
        expect(json['actionLabel'], isNull);
        expect(json['avatarUrl'], isNull);
        expect(json['imageUrl'], isNull);
        expect(json['metadata'], isNull);
        expect(json['createdAt'], isNull);
        expect(json['expiresAt'], isNull);
        expect(json['showInCenter'], true);
        expect(json['showAsToast'], true);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'id': 'notif-123',
          'title': 'Test Notification',
          'message': 'This is a test message',
          'type': 'success',
          'priority': 'high',
          'position': 'bottomRight',
          'durationMs': 5000,
          'persistent': true,
          'isRead': false,
          'actionLabel': 'View',
          'avatarUrl': 'https://example.com/avatar.png',
          'imageUrl': 'https://example.com/image.png',
          'metadata': {'key': 'value'},
          'createdAt': testCreatedAt.toIso8601String(),
          'expiresAt': testExpiresAt.toIso8601String(),
          'showInCenter': false,
          'showAsToast': true,
        };

        // Act
        final notification = AppNotification.fromJson(originalJson);
        final finalJson = notification.toJson();

        // Assert
        expect(finalJson['id'], originalJson['id']);
        expect(finalJson['title'], originalJson['title']);
        expect(finalJson['message'], originalJson['message']);
        expect(finalJson['type'], originalJson['type']);
        expect(finalJson['priority'], originalJson['priority']);
        expect(finalJson['position'], originalJson['position']);
        expect(finalJson['durationMs'], originalJson['durationMs']);
        expect(finalJson['persistent'], originalJson['persistent']);
        expect(finalJson['isRead'], originalJson['isRead']);
        expect(finalJson['actionLabel'], originalJson['actionLabel']);
        expect(finalJson['avatarUrl'], originalJson['avatarUrl']);
        expect(finalJson['imageUrl'], originalJson['imageUrl']);
        expect(finalJson['metadata'], originalJson['metadata']);
        expect(finalJson['createdAt'], originalJson['createdAt']);
        expect(finalJson['expiresAt'], originalJson['expiresAt']);
        expect(finalJson['showInCenter'], originalJson['showInCenter']);
        expect(finalJson['showAsToast'], originalJson['showAsToast']);
      });
    });

    group('edge cases', () {
      test('handles very long title', () {
        // Arrange
        final longTitle = 'A' * 1000;
        final json = {
          'id': 'notif-123',
          'title': longTitle,
          'type': 'info',
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.title, longTitle);
      });

      test('handles very long message', () {
        // Arrange
        final longMessage = 'B' * 10000;
        final json = {
          'id': 'notif-123',
          'title': 'Test',
          'message': longMessage,
          'type': 'info',
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.message, longMessage);
      });

      test('handles special characters in text fields', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'title': 'Test & Co. <Title> "Special" émojis 🎉',
          'message': 'Message with special chars: @#\$%^&*()',
          'type': 'info',
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.title, 'Test & Co. <Title> "Special" émojis 🎉');
        expect(notification.message, 'Message with special chars: @#\$%^&*()');
      });

      test('handles empty strings', () {
        // Arrange
        final json = {
          'id': '',
          'title': '',
          'message': '',
          'type': 'info',
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.id, '');
        expect(notification.title, '');
        expect(notification.message, '');
      });

      test('handles zero and negative duration', () {
        // Arrange
        final json1 = {
          'id': 'notif-123',
          'title': 'Test',
          'type': 'info',
          'durationMs': 0,
        };

        final json2 = {
          'id': 'notif-123',
          'title': 'Test',
          'type': 'info',
          'durationMs': -1000,
        };

        // Act
        final notification1 = AppNotification.fromJson(json1);
        final notification2 = AppNotification.fromJson(json2);

        // Assert
        expect(notification1.durationMs, 0);
        expect(notification2.durationMs, -1000);
      });

      test('handles very large duration', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'title': 'Test',
          'type': 'info',
          'durationMs': 999999999,
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.durationMs, 999999999);
      });

      test('handles complex metadata', () {
        // Arrange
        final json = {
          'id': 'notif-123',
          'title': 'Test',
          'type': 'info',
          'metadata': {
            'string': 'value',
            'number': 42,
            'bool': true,
            'null': null,
            'list': [1, 2, 3],
            'nested': {'key': 'value'},
          },
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.metadata!['string'], 'value');
        expect(notification.metadata!['number'], 42);
        expect(notification.metadata!['bool'], true);
        expect(notification.metadata!['null'], isNull);
        expect(notification.metadata!['list'], [1, 2, 3]);
        expect(notification.metadata!['nested'], {'key': 'value'});
      });

      test('handles past and future dates', () {
        // Arrange
        final pastDate = DateTime(2020, 1, 1);
        final futureDate = DateTime(2030, 12, 31);

        final json = {
          'id': 'notif-123',
          'title': 'Test',
          'type': 'info',
          'createdAt': pastDate.toIso8601String(),
          'expiresAt': futureDate.toIso8601String(),
        };

        // Act
        final notification = AppNotification.fromJson(json);

        // Assert
        expect(notification.createdAt, pastDate);
        expect(notification.expiresAt, futureDate);
      });
    });
  });

  group('NotificationTypeExtension', () {
    testWidgets('getColor returns correct colors for each type',
        (WidgetTester tester) async {
      // Build a widget to get BuildContext
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test each notification type
              final infoColor = NotificationType.info.getColor(context);
              final successColor = NotificationType.success.getColor(context);
              final warningColor = NotificationType.warning.getColor(context);
              final errorColor = NotificationType.error.getColor(context);
              final customColor = NotificationType.custom.getColor(context);

              // Assert
              expect(infoColor, isA<Color>());
              expect(successColor, Colors.green);
              expect(warningColor, Colors.orange);
              expect(errorColor, isA<Color>());
              expect(customColor, isA<Color>());

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    test('getDefaultIcon returns correct icons for each type', () {
      // Assert
      expect(
        NotificationType.info.getDefaultIcon(),
        Icons.info_outline,
      );
      expect(
        NotificationType.success.getDefaultIcon(),
        Icons.check_circle_outline,
      );
      expect(
        NotificationType.warning.getDefaultIcon(),
        Icons.warning_amber_outlined,
      );
      expect(
        NotificationType.error.getDefaultIcon(),
        Icons.error_outline,
      );
      expect(
        NotificationType.custom.getDefaultIcon(),
        Icons.notifications_outlined,
      );
    });

    test('getSoundName returns correct sound names for each type', () {
      // Assert
      expect(NotificationType.info.getSoundName(), 'info');
      expect(NotificationType.success.getSoundName(), 'success');
      expect(NotificationType.warning.getSoundName(), 'warning');
      expect(NotificationType.error.getSoundName(), 'error');
      expect(NotificationType.custom.getSoundName(), 'default');
    });
  });

  group('NotificationPriorityExtension', () {
    test('value returns correct integer for each priority', () {
      // Assert
      expect(NotificationPriority.low.value, 0);
      expect(NotificationPriority.normal.value, 1);
      expect(NotificationPriority.high.value, 2);
      expect(NotificationPriority.critical.value, 3);
    });

    test('shouldPlaySound returns true for high and critical', () {
      // Assert
      expect(NotificationPriority.low.shouldPlaySound, false);
      expect(NotificationPriority.normal.shouldPlaySound, false);
      expect(NotificationPriority.high.shouldPlaySound, true);
      expect(NotificationPriority.critical.shouldPlaySound, true);
    });

    test('shouldVibrate returns true only for critical', () {
      // Assert
      expect(NotificationPriority.low.shouldVibrate, false);
      expect(NotificationPriority.normal.shouldVibrate, false);
      expect(NotificationPriority.high.shouldVibrate, false);
      expect(NotificationPriority.critical.shouldVibrate, true);
    });
  });
}
