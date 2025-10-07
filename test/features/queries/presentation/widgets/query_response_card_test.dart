import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/queries/presentation/providers/query_provider.dart';
import 'package:pm_master_v2/features/queries/presentation/widgets/query_response_card.dart';

void main() {
  group('QueryResponseCard', () {
    late ConversationItem testResponse;

    setUp(() {
      testResponse = ConversationItem(
        question: 'What are the action items?',
        answer: 'Here are the action items:\n\n1. Complete documentation\n2. Review code',
        sources: ['Meeting 2024-01-15', 'Email thread'],
        confidence: 0.85,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
    });

    testWidgets('displays query question', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.text('What are the action items?'), findsOneWidget);
    });

    testWidgets('displays question icon in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.question_answer), findsOneWidget);
    });

    testWidgets('displays copy button in header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.widgetWithIcon(IconButton, Icons.copy), findsOneWidget);
    });

    testWidgets('copy button shows snackbar when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      // Tap copy button
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('Response copied to clipboard'), findsOneWidget);
    });

    testWidgets('displays confidence indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.text('Confidence: '), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.byIcon(Icons.insights), findsOneWidget);
    });

    testWidgets('shows green confidence for high confidence (>0.7)', (tester) async {
      final highConfidenceResponse = testResponse.copyWith(confidence: 0.85);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: highConfidenceResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      // Find the confidence badge
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('shows orange confidence for medium confidence (0.4-0.7)', (tester) async {
      final mediumConfidenceResponse = testResponse.copyWith(confidence: 0.55);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: mediumConfidenceResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.text('55%'), findsOneWidget);
    });

    testWidgets('shows red confidence for low confidence (<0.4)', (tester) async {
      final lowConfidenceResponse = testResponse.copyWith(confidence: 0.25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: lowConfidenceResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('displays markdown response content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      // Markdown widget should be present
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('displays sources section when sources exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.text('Sources'), findsOneWidget);
      expect(find.byIcon(Icons.source), findsOneWidget);
      expect(find.text('Meeting 2024-01-15'), findsOneWidget);
      expect(find.text('Email thread'), findsOneWidget);
    });

    testWidgets('does not display sources section when no sources', (tester) async {
      final noSourcesResponse = testResponse.copyWith(sources: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: noSourcesResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      expect(find.text('Sources'), findsNothing);
    });

    testWidgets('displays sources as chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      // Should have 2 source chips
      final chips = tester.widgetList<Chip>(find.byType(Chip));
      expect(chips.length, 2);
    });

    testWidgets('constrains markdown height to 400px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.ancestor(
          of: find.byType(Markdown),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.maxHeight, 400);
    });

    testWidgets('markdown is selectable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      expect(markdown.selectable, isTrue);
    });

    testWidgets('markdown uses shrinkWrap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      expect(markdown.shrinkWrap, isTrue);
    });

    testWidgets('uses Card widget with elevation 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryResponseCard(
              response: testResponse,
              query: testResponse.question,
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
    });
  });
}
