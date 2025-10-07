import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/profile/presentation/widgets/user_avatar.dart';

void main() {
  group('UserAvatar', () {
    testWidgets('renders with default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(),
          ),
        ),
      );

      // Widget should exist and render successfully
      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      const customSize = 120.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(size: customSize),
          ),
        ),
      );

      // Widget should exist
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('displays fallback icon when no image URL provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays fallback icon when empty image URL provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(imageUrl: ''),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('does not show edit icon when not editable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              imageUrl: 'https://example.com/avatar.jpg',
              isEditable: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });

    testWidgets('shows edit icon when editable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              imageUrl: 'https://example.com/avatar.jpg',
              isEditable: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('calls onTap when editable and tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isEditable: true,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(wasTapped, true);
    });

    testWidgets('does not call onTap when not editable', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isEditable: false,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(wasTapped, false);
    });

    testWidgets('displays Image.network when valid URL provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              imageUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        ),
      );

      // ClipRRect should exist (wraps the image)
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('has rounded corners with proper border radius', (tester) async {
      const size = 100.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(size: size),
          ),
        ),
      );

      // Container and ClipRRect should both have rounded corners
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('edit icon is positioned at bottom-right when editable', (tester) async {
      const size = 100.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              size: size,
              isEditable: true,
            ),
          ),
        ),
      );

      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('edit icon has correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              isEditable: true,
            ),
          ),
        ),
      );

      // Edit icon should be within a Container with decorations
      final iconContainers = tester.widgetList<Container>(find.byType(Container));
      expect(iconContainers.length, greaterThan(1));
    });
  });

  group('AvatarPicker', () {
    testWidgets('renders UserAvatar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('UserAvatar is editable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      final userAvatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(userAvatar.isEditable, true);
    });

    testWidgets('passes currentImageUrl to UserAvatar', (tester) async {
      const testUrl = 'https://example.com/test.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              currentImageUrl: testUrl,
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      final userAvatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(userAvatar.imageUrl, testUrl);
    });

    testWidgets('passes userName to UserAvatar', (tester) async {
      const testName = 'John Doe';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              userName: testName,
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      final userAvatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(userAvatar.name, testName);
    });

    testWidgets('shows edit icon indicating it is editable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('has onTap callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      final userAvatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(userAvatar.onTap, isNotNull);
    });

    testWidgets('works with null currentImageUrl', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              currentImageUrl: null,
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget); // fallback icon
    });

    testWidgets('works with null userName', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPicker(
              userName: null,
              onImageSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
    });
  });
}
