import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/widgets/hierarchy_statistics_card.dart';
import '../helpers/hierarchy_test_fixtures.dart';

void main() {
  group('HierarchyStatisticsCard', () {
    Widget buildWidget(WidgetRef? ref) {
      final statistics = HierarchyTestFixtures.createSampleStatistics(
        portfolioCount: 3,
        programCount: 7,
        projectCount: 20,
        standaloneCount: 2,
      );

      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HierarchyStatisticsCard(statistics: statistics),
          ),
        ),
      );
    }

    testWidgets('displays overview title', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(null));

      expect(find.text('Overview'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('displays all statistic items', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(null));

      expect(find.text('Portfolios'), findsOneWidget);
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);
      expect(find.text('Standalone'), findsOneWidget);
    });

    testWidgets('displays correct counts', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(null));

      expect(find.text('3'), findsOneWidget); // portfolios
      expect(find.text('7'), findsOneWidget); // programs
      expect(find.text('20'), findsOneWidget); // projects
      expect(find.text('2'), findsOneWidget); // standalone
    });

    testWidgets('displays correct icons', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(null));

      expect(find.byIcon(Icons.business_center), findsOneWidget); // portfolio
      expect(find.byIcon(Icons.category), findsOneWidget); // program
      expect(find.byIcon(Icons.folder), findsOneWidget); // project
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget); // standalone
    });

    testWidgets('displays zero counts correctly', (WidgetTester tester) async {
      final statistics = HierarchyTestFixtures.createSampleStatistics(
        portfolioCount: 0,
        programCount: 0,
        projectCount: 0,
        standaloneCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HierarchyStatisticsCard(statistics: statistics),
            ),
          ),
        ),
      );

      expect(find.text('0'), findsNWidgets(4));
    });
  });
}
