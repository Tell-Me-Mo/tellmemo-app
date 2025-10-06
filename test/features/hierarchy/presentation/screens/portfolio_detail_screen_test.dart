import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/screens/portfolio_detail_screen.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/portfolio.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/hierarchy_providers.dart';

import '../../../../mocks/mock_providers.dart';

// Helper to create MaterialApp with GoRouter for testing
Widget createTestApp(Widget child, List<Override> overrides) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  group('PortfolioDetailScreen', () {
    const testPortfolioId = 'test-portfolio-id';
    late List<Override> overrides;

    setUp(() {
      overrides = [];
    });

    testWidgets('displays loading indicator while loading portfolio', (tester) async {
      overrides.add(
        createPortfolioOverride(testPortfolioId),
      );

      await tester.pumpWidget(createTestApp(
        const PortfolioDetailScreen(portfolioId: testPortfolioId),
        overrides,
      ));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Note: Further testing blocked by screen complexity
    // - Screen makes direct API calls during build (_buildPortfolioSummariesList, _buildActivitiesList)
    // - Would require mocking ApiClient, DioClient, and network layer
    // - Complexity exceeds benefit for basic widget testing
  });
}
