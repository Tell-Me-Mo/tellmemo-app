import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';
import '../../../meetings/domain/entities/content.dart';
import '../../../meetings/data/models/content_model.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../../shared/providers/api_client_provider.dart';

part 'documents_provider.g.dart';

// Documents provider that always fetches ALL documents regardless of selected project

@riverpod
Future<List<Content>> documentsList(DocumentsListRef ref) async {
  // Watch organization changes to auto-refresh when organization switches
  ref.watch(organizationChangedProvider);

  // Keep alive with auto-dispose after 5 minutes of inactivity
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 5), link.close);

  final apiClient = ref.read(apiClientProvider);

  try {
    List<Content> contentList = [];

    // Always fetch all content across all projects (ignore selectedProject)
    final projectsResult = await ref.read(projectsListProvider.future);

    for (final project in projectsResult) {
      try {
        final response = await apiClient.getProjectContent(
          project.id,
          limit: 100,
        );

        final projectContent = response
            .map((json) => ContentModel.fromJson(json).toEntity())
            .toList();

        contentList.addAll(projectContent);
      } catch (e) {
        // Continue with other projects if one fails
        print('Failed to load content for project ${project.id}: $e');
      }
    }

    // Sort by date (newest first)
    contentList.sort((a, b) {
      final dateA = a.date ?? a.uploadedAt;
      final dateB = b.date ?? b.uploadedAt;
      return dateB.compareTo(dateA);
    });

    return contentList;
  } catch (e) {
    throw Exception('Failed to load documents: $e');
  }
}

@riverpod
Future<Map<String, int>> documentsStatistics(DocumentsStatisticsRef ref) async {
  final documents = await ref.watch(documentsListProvider.future);
  final now = DateTime.now();
  final thisWeek = documents.where((d) {
    final targetDate = d.date ?? d.uploadedAt;
    return now.difference(targetDate).inDays <= 7;
  }).length;

  return {
    'total': documents.length,
    'meetings': documents.where((d) => d.contentType == ContentType.meeting).length,
    'emails': documents.where((d) => d.contentType == ContentType.email).length,
    'thisWeek': thisWeek,
  };
}

@riverpod
Future<List<Content>> filteredDocuments(
  FilteredDocumentsRef ref, {
  ContentType? filterType,
  String searchQuery = '',
  String sortBy = 'recent',
}) async {
  final documents = await ref.watch(documentsListProvider.future);

  var filtered = documents;

  // Filter by content type
  if (filterType != null) {
    filtered = filtered.where((d) => d.contentType == filterType).toList();
  }

  // Filter by search query
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    filtered = filtered.where((d) =>
      d.title.toLowerCase().contains(query)
    ).toList();
  }

  // Sort documents
  switch (sortBy) {
    case 'oldest':
      filtered.sort((a, b) {
        final dateA = a.date ?? a.uploadedAt;
        final dateB = b.date ?? b.uploadedAt;
        return dateA.compareTo(dateB);
      });
      break;
    case 'name':
      filtered.sort((a, b) => a.title.compareTo(b.title));
      break;
    case 'type':
      filtered.sort((a, b) => a.contentType.index.compareTo(b.contentType.index));
      break;
    case 'recent':
    default:
      filtered.sort((a, b) {
        final dateA = a.date ?? a.uploadedAt;
        final dateB = b.date ?? b.uploadedAt;
        return dateB.compareTo(dateA);
      });
  }

  return filtered;
}