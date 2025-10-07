import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/features/documents/presentation/widgets/empty_documents_widget.dart';

void main() {
  group('EmptyDocumentsWidget', () {
    testWidgets('displays folder icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDocumentsWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('displays "No Documents Yet" title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDocumentsWidget(),
          ),
        ),
      );

      expect(find.text('No Documents Yet'), findsOneWidget);
    });

    testWidgets('displays helpful description text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDocumentsWidget(),
          ),
        ),
      );

      expect(find.text('Upload documents or emails to get started'), findsOneWidget);
    });

    testWidgets('displays upload button with icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDocumentsWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.text('Upload Your First Document'), findsOneWidget);
    });

    testWidgets('button navigates to upload route when tapped', (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: EmptyDocumentsWidget(),
            ),
          ),
          GoRoute(
            path: '/upload',
            builder: (context, state) {
              navigatedRoute = '/upload';
              return Scaffold(
                body: Text('Upload Screen'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Find and tap the upload button by text
      await tester.tap(find.text('Upload Your First Document'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(navigatedRoute, '/upload');
      expect(find.text('Upload Screen'), findsOneWidget);
    });

    testWidgets('widget displays all expected elements', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDocumentsWidget(),
          ),
        ),
      );

      // Verify all key elements are present
      expect(find.byType(EmptyDocumentsWidget), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('No Documents Yet'), findsOneWidget);
      expect(find.text('Upload documents or emails to get started'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.text('Upload Your First Document'), findsOneWidget);
    });
  });
}
