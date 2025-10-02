import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/api_client_provider.dart';

part 'document_detail_provider.g.dart';

@riverpod
Future<Map<String, dynamic>?> documentDetail(
  DocumentDetailRef ref, {
  required String projectId,
  required String contentId,
}) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.getContent(projectId, contentId);
    return response as Map<String, dynamic>;
  } catch (e) {
    print('Error fetching document detail: $e');
    return null;
  }
}

@riverpod
Future<Map<String, dynamic>?> documentSummary(
  DocumentSummaryRef ref, {
  required String projectId,
  required String contentId,
}) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    // Try to get summaries for the project and find the one for this content
    final summaries = await apiClient.listSummaries(
      entityType: 'project',
      entityId: projectId,
    );

    // Debug logging
    print('Looking for summary with content_id: $contentId');
    print('Total summaries found: ${summaries.length}');

    // Find summary that matches this content ID
    for (final summary in summaries) {
      final summaryContentId = summary['content_id'];
      if (summaryContentId == contentId) {
        print('Found matching summary for content $contentId');
        return summary as Map<String, dynamic>;
      }
    }

    print('No matching summary found for content $contentId');
    return null;
  } catch (e) {
    print('Error fetching document summary: $e');
    return null;
  }
}