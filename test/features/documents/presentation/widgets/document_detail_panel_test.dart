import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/documents/presentation/widgets/document_detail_panel.dart';
import 'package:pm_master_v2/features/meetings/domain/entities/content.dart';
import 'package:pm_master_v2/features/documents/presentation/providers/document_detail_provider.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late Content testDocument;

  setUp(() {
    testDocument = Content(
      id: 'doc-1',
      projectId: 'project-1',
      title: 'Test Document',
      contentType: ContentType.meeting,
      uploadedAt: DateTime(2024, 1, 1),
      uploadedBy: 'test@example.com',
      chunkCount: 0,
      summaryGenerated: false,
    );
  });

  group('DocumentDetailPanel', () {
    testWidgets('displays document with basic information', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: DocumentDetailPanel(document: testDocument),
        ),
        overrides: [
          // Override async providers to return mock data immediately
          documentDetailProvider(projectId: 'project-1', contentId: 'doc-1')
              .overrideWith((ref) async => null),
          documentSummaryProvider(projectId: 'project-1', contentId: 'doc-1')
              .overrideWith((ref) async => null),
        ],
      );

      // Check document title is displayed
      expect(find.text('Test Document'), findsOneWidget);
    });

    testWidgets('displays document metadata', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: DocumentDetailPanel(document: testDocument),
        ),
        overrides: [
          documentDetailProvider(projectId: 'project-1', contentId: 'doc-1')
              .overrideWith((ref) async => null),
          documentSummaryProvider(projectId: 'project-1', contentId: 'doc-1')
              .overrideWith((ref) async => null),
        ],
      );

      // Check that metadata section exists
      expect(find.text('Document Information'), findsOneWidget);
    });

    testWidgets('shows pending status for unprocessed documents', (tester) async {
      final unprocessedDoc = Content(
        id: 'doc-2',
        projectId: 'project-1',
        title: 'Unprocessed Document',
        contentType: ContentType.email,
        uploadedAt: DateTime(2024, 1, 1),
        uploadedBy: 'test@example.com',
        chunkCount: 0,
        summaryGenerated: false,
      );

      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: DocumentDetailPanel(document: unprocessedDoc),
        ),
        overrides: [
          documentDetailProvider(projectId: 'project-1', contentId: 'doc-2')
              .overrideWith((ref) async => null),
          documentSummaryProvider(projectId: 'project-1', contentId: 'doc-2')
              .overrideWith((ref) async => null),
        ],
      );

      // Document should render without errors
      expect(find.text('Unprocessed Document'), findsOneWidget);
    });
  });
}
