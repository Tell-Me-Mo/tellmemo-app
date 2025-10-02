import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../data/models/content_model.dart';
import '../../domain/entities/content.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';

part 'meetings_provider.g.dart';

@riverpod
Future<List<Content>> meetingsList(MeetingsListRef ref) async {
  // Watch organization changes to auto-refresh when organization switches
  ref.watch(organizationChangedProvider);

  // Keep provider alive for 5 minutes to avoid refetching on navigation
  ref.keepAlive();
  Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });

  final selectedProject = ref.watch(selectedProjectProvider);
  final apiClient = ref.read(apiClientProvider);

  try {
    List<Content> contentList = [];
    
    if (selectedProject != null) {
      // Fetch content for specific project
      final response = await apiClient.getProjectContent(
        selectedProject.id,
        limit: 100,
      );
      
      contentList = response
          .map((json) => ContentModel.fromJson(json).toEntity())
          .toList();
    } else {
      // Fetch all content across all projects
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
    }
    
    // Sort by date (newest first)
    contentList.sort((a, b) {
      final dateA = a.date ?? a.uploadedAt;
      final dateB = b.date ?? b.uploadedAt;
      return dateB.compareTo(dateA);
    });
    
    return contentList;
  } catch (e) {
    throw Exception('Failed to load meetings: $e');
  }
}

@riverpod
Future<List<Content>> filteredMeetings(
  FilteredMeetingsRef ref, {
  ContentType? filterType,
  String searchQuery = '',
}) async {
  final meetings = await ref.watch(meetingsListProvider.future);
  
  var filtered = meetings;
  
  // Filter by content type
  if (filterType != null) {
    filtered = filtered.where((m) => m.contentType == filterType).toList();
  }
  
  // Filter by search query
  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    filtered = filtered.where((m) => 
      m.title.toLowerCase().contains(query)
    ).toList();
  }
  
  return filtered;
}

@riverpod
class MeetingsFilter extends _$MeetingsFilter {
  @override
  ({ContentType? type, String searchQuery}) build() {
    return (type: null, searchQuery: '');
  }
  
  void setContentType(ContentType? type) {
    state = (type: type, searchQuery: state.searchQuery);
  }
  
  void setSearchQuery(String query) {
    state = (type: state.type, searchQuery: query);
  }
  
  void clearFilters() {
    state = (type: null, searchQuery: '');
  }
}

@riverpod
Future<Content?> meetingDetail(MeetingDetailRef ref, String contentId) async {
  final meetings = await ref.watch(meetingsListProvider.future);
  
  try {
    return meetings.firstWhere((m) => m.id == contentId);
  } catch (e) {
    return null;
  }
}

@riverpod
Future<Map<String, int>> meetingsStatistics(MeetingsStatisticsRef ref) async {
  final meetings = await ref.watch(meetingsListProvider.future);
  
  return {
    'total': meetings.length,
    'meetings': meetings.where((m) => m.contentType == ContentType.meeting).length,
    'emails': meetings.where((m) => m.contentType == ContentType.email).length,
    'processed': meetings.where((m) => m.isProcessed).length,
    'processing': meetings.where((m) => m.isProcessing).length,
    'errors': meetings.where((m) => m.hasError).length,
  };
}