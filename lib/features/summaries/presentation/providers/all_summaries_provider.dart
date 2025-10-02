import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../data/models/summary_model.dart';

final allSummariesProvider = FutureProvider<List<SummaryModel>>((ref) async {
  final projectsAsync = await ref.watch(projectsListProvider.future);

  if (projectsAsync.isEmpty) {
    return [];
  }

  final List<SummaryModel> allSummaries = [];
  final apiService = ref.read(apiServiceProvider);
  final client = apiService.client;

  // Load summaries from all projects using unified endpoint
  for (final project in projectsAsync) {
    try {
      final response = await client.listSummaries(
        entityType: 'project',
        entityId: project.id,
      );

      final summaries = response
          .map((json) => SummaryModel.fromJson(json))
          .toList();

      allSummaries.addAll(summaries);
    } catch (e) {
      // Continue loading from other projects even if one fails
    }
  }

  // Sort by created date (newest first)
  allSummaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return allSummaries;
});