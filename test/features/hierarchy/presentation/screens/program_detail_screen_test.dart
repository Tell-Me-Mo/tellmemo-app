import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/screens/program_detail_screen.dart';
import 'package:pm_master_v2/features/hierarchy/domain/entities/program.dart';
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
  group('ProgramDetailScreen', () {
    const testProgramId = 'test-program-id';
    late List<Override> overrides;

    setUp(() {
      overrides = [];
    });

    // Note: Testing blocked by screen architecture
    // - Screen calls DioClient.instance in initState() which requires singleton initialization
    // - Screen makes direct API calls during build (_buildProgramSummariesList, _loadProgramActivitiesForProgram)
    // - Would require mocking DioClient singleton, ApiClient, and network layer
    // - Complexity exceeds benefit for basic widget testing
    // - Recommendation: Refactor screen to inject dependencies via constructor

  });
}
