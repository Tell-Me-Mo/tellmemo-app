import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class ContentAvailabilityService {
  final Dio _dio;

  ContentAvailabilityService(this._dio);

  /// Check content availability for an entity
  Future<ContentAvailability> checkAvailability({
    required String entityType,
    required String entityId,
    DateTime? dateStart,
    DateTime? dateEnd,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dateStart != null) {
        queryParams['date_start'] = dateStart.toIso8601String();
      }
      if (dateEnd != null) {
        queryParams['date_end'] = dateEnd.toIso8601String();
      }

      final response = await _dio.get(
        '/api/v1/content-availability/check/$entityType/$entityId',
        queryParameters: queryParams,
      );

      return ContentAvailability.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to check content availability: $e');
    }
  }

  /// Get summary generation statistics for an entity
  Future<SummaryStats> getSummaryStats({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/content-availability/stats/$entityType/$entityId',
      );

      return SummaryStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get summary stats: $e');
    }
  }

  /// Batch check availability for multiple entities
  Future<Map<String, ContentAvailability>> batchCheckAvailability({
    required List<EntityCheck> entities,
    DateTime? dateStart,
    DateTime? dateEnd,
  }) async {
    try {
      final requestData = {
        'entities': entities.map((e) => e.toJson()).toList(),
        if (dateStart != null) 'date_start': dateStart.toIso8601String(),
        if (dateEnd != null) 'date_end': dateEnd.toIso8601String(),
      };

      final response = await _dio.post(
        '/api/v1/content-availability/batch-check',
        data: requestData,
      );

      final Map<String, ContentAvailability> results = {};
      (response.data as Map<String, dynamic>).forEach((key, value) {
        results[key] = ContentAvailability.fromJson(value);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to batch check availability: $e');
    }
  }
}

/// Model for content availability check response
class ContentAvailability {
  final bool hasContent;
  final int contentCount;
  final bool canGenerateSummary;
  final String message;
  final String? latestContentDate;
  final Map<String, int>? contentBreakdown;
  final int? projectCount;
  final int? projectsWithContent;
  final int? programCount;
  final Map<String, dynamic>? programBreakdown;
  final Map<String, int>? projectContentBreakdown;
  final int? recentSummariesCount;

  ContentAvailability({
    required this.hasContent,
    required this.contentCount,
    required this.canGenerateSummary,
    required this.message,
    this.latestContentDate,
    this.contentBreakdown,
    this.projectCount,
    this.projectsWithContent,
    this.programCount,
    this.programBreakdown,
    this.projectContentBreakdown,
    this.recentSummariesCount,
  });

  factory ContentAvailability.fromJson(Map<String, dynamic> json) {
    return ContentAvailability(
      hasContent: json['has_content'] ?? false,
      contentCount: json['content_count'] ?? 0,
      canGenerateSummary: json['can_generate_summary'] ?? false,
      message: json['message'] ?? '',
      latestContentDate: json['latest_content_date'],
      contentBreakdown: json['content_breakdown'] != null
          ? Map<String, int>.from(json['content_breakdown'])
          : null,
      projectCount: json['project_count'],
      projectsWithContent: json['projects_with_content'],
      programCount: json['program_count'],
      programBreakdown: json['program_breakdown'],
      projectContentBreakdown: json['project_content_breakdown'] != null
          ? Map<String, int>.from(json['project_content_breakdown'])
          : null,
      recentSummariesCount: json['recent_summaries_count'],
    );
  }

  /// Get a severity level for UI indicators
  ContentSeverity get severity {
    if (!hasContent) return ContentSeverity.none;
    if (contentCount < 3) return ContentSeverity.limited;
    if (contentCount < 10) return ContentSeverity.moderate;
    return ContentSeverity.sufficient;
  }

  /// Get recommended action
  String get recommendedAction {
    if (!hasContent) {
      return 'Upload meeting transcripts or documents to enable summary generation';
    }
    if (contentCount < 3) {
      return 'Add more content for better summary quality';
    }
    return 'Ready to generate comprehensive summary';
  }
}

/// Model for summary statistics
class SummaryStats {
  final int totalSummaries;
  final String? lastGenerated;
  final double averageGenerationTime;
  final List<String> formatsGenerated;
  final Map<String, int>? typeBreakdown;
  final String? recentSummaryId;

  SummaryStats({
    required this.totalSummaries,
    this.lastGenerated,
    required this.averageGenerationTime,
    required this.formatsGenerated,
    this.typeBreakdown,
    this.recentSummaryId,
  });

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    return SummaryStats(
      totalSummaries: json['total_summaries'] ?? 0,
      lastGenerated: json['last_generated'],
      averageGenerationTime: (json['average_generation_time'] ?? 0).toDouble(),
      formatsGenerated: List<String>.from(json['formats_generated'] ?? []),
      typeBreakdown: json['type_breakdown'] != null
          ? Map<String, int>.from(json['type_breakdown'])
          : null,
      recentSummaryId: json['recent_summary_id'],
    );
  }

  /// Check if can regenerate (based on time since last generation)
  bool canRegenerate({Duration minInterval = const Duration(hours: 1)}) {
    if (lastGenerated == null) return true;
    final lastGen = DateTime.parse('${lastGenerated}Z').toLocal();
    return DateTime.now().difference(lastGen) > minInterval;
  }
}

/// Model for entity check in batch operations
class EntityCheck {
  final String type;
  final String id;

  EntityCheck({required this.type, required this.id});

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
      };
}

/// Enum for content severity levels
enum ContentSeverity {
  none,       // No content
  limited,    // Very little content (1-2 items)
  moderate,   // Some content (3-9 items)
  sufficient, // Good amount of content (10+ items)
}

// Singleton instance
final contentAvailabilityService = ContentAvailabilityService(DioClient.instance);