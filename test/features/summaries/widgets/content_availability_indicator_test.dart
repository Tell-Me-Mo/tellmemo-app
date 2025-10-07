import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/summaries/data/services/content_availability_service.dart';
import 'package:pm_master_v2/features/summaries/presentation/widgets/content_availability_indicator.dart';

void main() {
  group('ContentAvailabilityIndicator', () {
    testWidgets('displays sufficient content severity', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 15,
        canGenerateSummary: true,
        message: 'Great! You have sufficient content',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(availability: availability),
          ),
        ),
      );

      // Assert
      expect(find.text('Sufficient Content'), findsOneWidget);
      expect(find.text('Great! You have sufficient content'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays moderate content severity', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 5,
        canGenerateSummary: true,
        message: 'You have some content',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(availability: availability),
          ),
        ),
      );

      // Assert
      expect(find.text('Moderate Content'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('displays limited content severity', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 2,
        canGenerateSummary: false,
        message: 'Limited content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(availability: availability),
          ),
        ),
      );

      // Assert
      expect(find.text('Limited Content'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('displays no content severity', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: false,
        contentCount: 0,
        canGenerateSummary: false,
        message: 'No content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(availability: availability),
          ),
        ),
      );

      // Assert
      expect(find.text('No Content Available'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('displays recommended action when available', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 5,
        canGenerateSummary: true,
        message: 'Some content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert - Check recommended action based on severity
      expect(find.text(availability.recommendedAction), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('displays upload button when no content and callback provided', (WidgetTester tester) async {
      // Arrange
      var uploadCalled = false;
      final availability = ContentAvailability(
        hasContent: false,
        contentCount: 0,
        canGenerateSummary: false,
        message: 'No content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              onUploadContent: () => uploadCalled = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Upload Content'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);

      // Tap upload button
      await tester.tap(find.text('Upload Content'));
      expect(uploadCalled, true);
    });

    testWidgets('does not display upload button when content exists', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 5,
        canGenerateSummary: true,
        message: 'Content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              onUploadContent: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Upload Content'), findsNothing);
    });

    testWidgets('displays content stats when details enabled', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 10,
        canGenerateSummary: true,
        message: 'Content available',
        projectCount: 5,
        projectsWithContent: 3,
        recentSummariesCount: 2,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Total Content'), findsOneWidget);
      expect(find.text('10 items'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('Recent Summaries'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('compact mode displays minimal info', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 8,
        canGenerateSummary: true,
        message: 'Moderate content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              compact: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Good amount of content available'), findsOneWidget);
    });

    testWidgets('compact mode displays content breakdown', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 10,
        canGenerateSummary: true,
        message: 'Content available',
        contentBreakdown: {
          'meeting': 5,
          'email': 3,
          'document': 2,
        },
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              compact: true,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('5 meetings'), findsOneWidget);
      expect(find.textContaining('3 emails'), findsOneWidget);
      expect(find.textContaining('2 documents'), findsOneWidget);
    });

    testWidgets('does not display stats when showDetails is false', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 10,
        canGenerateSummary: true,
        message: 'Content available',
        projectCount: 5,
        projectsWithContent: 3,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityIndicator(
              availability: availability,
              showDetails: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Total Content'), findsNothing);
      expect(find.text('Projects'), findsNothing);
    });
  });

  group('ContentAvailabilityTile', () {
    testWidgets('displays entity name and content count', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 5,
        canGenerateSummary: true,
        message: 'Content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityTile(
              availability: availability,
              entityName: 'Project Alpha',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('5 content items'), findsOneWidget);
    });

    testWidgets('displays check icon when can generate summary', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 10,
        canGenerateSummary: true,
        message: 'Content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityTile(
              availability: availability,
              entityName: 'Project Beta',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays block icon when cannot generate summary', (WidgetTester tester) async {
      // Arrange
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 1,
        canGenerateSummary: false,
        message: 'Insufficient content',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityTile(
              availability: availability,
              entityName: 'Project Gamma',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (WidgetTester tester) async {
      // Arrange
      var tapped = false;
      final availability = ContentAvailability(
        hasContent: true,
        contentCount: 5,
        canGenerateSummary: true,
        message: 'Content available',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentAvailabilityTile(
              availability: availability,
              entityName: 'Project Delta',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Assert
      await tester.tap(find.byType(ContentAvailabilityTile));
      expect(tapped, true);
    });
  });
}
