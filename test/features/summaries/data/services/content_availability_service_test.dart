import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pm_master_v2/features/summaries/data/services/content_availability_service.dart';

import 'content_availability_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late ContentAvailabilityService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = ContentAvailabilityService(mockDio);
  });

  group('ContentAvailability Model', () {
    group('severity getter', () {
      test('returns none when hasContent is false', () {
        final availability = ContentAvailability(
          hasContent: false,
          contentCount: 0,
          canGenerateSummary: false,
          message: 'No content',
        );

        expect(availability.severity, ContentSeverity.none);
      });

      test('returns limited when contentCount is 1-2', () {
        final availability = ContentAvailability(
          hasContent: true,
          contentCount: 2,
          canGenerateSummary: false,
          message: 'Limited content',
        );

        expect(availability.severity, ContentSeverity.limited);
      });

      test('returns moderate when contentCount is 3-9', () {
        final availability = ContentAvailability(
          hasContent: true,
          contentCount: 5,
          canGenerateSummary: true,
          message: 'Some content',
        );

        expect(availability.severity, ContentSeverity.moderate);
      });

      test('returns sufficient when contentCount is 10+', () {
        final availability = ContentAvailability(
          hasContent: true,
          contentCount: 15,
          canGenerateSummary: true,
          message: 'Sufficient content',
        );

        expect(availability.severity, ContentSeverity.sufficient);
      });
    });

    group('recommendedAction getter', () {
      test('returns upload message when hasContent is false', () {
        final availability = ContentAvailability(
          hasContent: false,
          contentCount: 0,
          canGenerateSummary: false,
          message: 'No content',
        );

        expect(
          availability.recommendedAction,
          'Upload meeting transcripts or documents to enable summary generation',
        );
      });

      test('returns add more content message when contentCount < 3', () {
        final availability = ContentAvailability(
          hasContent: true,
          contentCount: 2,
          canGenerateSummary: false,
          message: 'Limited',
        );

        expect(
          availability.recommendedAction,
          'Add more content for better summary quality',
        );
      });

      test('returns ready message when contentCount >= 3', () {
        final availability = ContentAvailability(
          hasContent: true,
          contentCount: 5,
          canGenerateSummary: true,
          message: 'Ready',
        );

        expect(
          availability.recommendedAction,
          'Ready to generate comprehensive summary',
        );
      });
    });

    group('fromJson', () {
      test('creates ContentAvailability from complete JSON', () {
        final json = {
          'has_content': true,
          'content_count': 10,
          'can_generate_summary': true,
          'message': 'Ready',
          'latest_content_date': '2024-01-15',
          'content_breakdown': {'meetings': 5, 'documents': 5},
          'project_count': 3,
          'projects_with_content': 2,
          'program_count': 1,
          'program_breakdown': {'prog-1': {'projects': 2}},
          'project_content_breakdown': {'proj-1': 5, 'proj-2': 5},
          'recent_summaries_count': 2,
        };

        final result = ContentAvailability.fromJson(json);

        expect(result.hasContent, true);
        expect(result.contentCount, 10);
        expect(result.canGenerateSummary, true);
        expect(result.message, 'Ready');
        expect(result.latestContentDate, '2024-01-15');
        expect(result.contentBreakdown, {'meetings': 5, 'documents': 5});
        expect(result.projectCount, 3);
        expect(result.projectsWithContent, 2);
        expect(result.programCount, 1);
        expect(result.programBreakdown, {'prog-1': {'projects': 2}});
        expect(result.projectContentBreakdown, {'proj-1': 5, 'proj-2': 5});
        expect(result.recentSummariesCount, 2);
      });

      test('creates ContentAvailability from minimal JSON with defaults', () {
        final json = <String, dynamic>{};

        final result = ContentAvailability.fromJson(json);

        expect(result.hasContent, false);
        expect(result.contentCount, 0);
        expect(result.canGenerateSummary, false);
        expect(result.message, '');
        expect(result.latestContentDate, null);
        expect(result.contentBreakdown, null);
        expect(result.projectCount, null);
        expect(result.projectsWithContent, null);
        expect(result.programCount, null);
        expect(result.programBreakdown, null);
        expect(result.projectContentBreakdown, null);
        expect(result.recentSummariesCount, null);
      });

      test('handles null content_breakdown', () {
        final json = {
          'has_content': true,
          'content_count': 5,
          'can_generate_summary': true,
          'message': 'OK',
          'content_breakdown': null,
        };

        final result = ContentAvailability.fromJson(json);

        expect(result.contentBreakdown, null);
      });

      test('handles null project_content_breakdown', () {
        final json = {
          'has_content': true,
          'content_count': 5,
          'can_generate_summary': true,
          'message': 'OK',
          'project_content_breakdown': null,
        };

        final result = ContentAvailability.fromJson(json);

        expect(result.projectContentBreakdown, null);
      });
    });
  });

  group('SummaryStats Model', () {
    group('fromJson', () {
      test('creates SummaryStats from complete JSON', () {
        final json = {
          'total_summaries': 5,
          'last_generated': '2024-01-15T10:30:00',
          'average_generation_time': 45.5,
          'formats_generated': ['markdown', 'pdf'],
          'type_breakdown': {'meeting': 3, 'weekly': 2},
          'recent_summary_id': 'summary-123',
        };

        final result = SummaryStats.fromJson(json);

        expect(result.totalSummaries, 5);
        expect(result.lastGenerated, '2024-01-15T10:30:00');
        expect(result.averageGenerationTime, 45.5);
        expect(result.formatsGenerated, ['markdown', 'pdf']);
        expect(result.typeBreakdown, {'meeting': 3, 'weekly': 2});
        expect(result.recentSummaryId, 'summary-123');
      });

      test('creates SummaryStats from minimal JSON with defaults', () {
        final json = <String, dynamic>{};

        final result = SummaryStats.fromJson(json);

        expect(result.totalSummaries, 0);
        expect(result.lastGenerated, null);
        expect(result.averageGenerationTime, 0.0);
        expect(result.formatsGenerated, isEmpty);
        expect(result.typeBreakdown, null);
        expect(result.recentSummaryId, null);
      });

      test('converts int average_generation_time to double', () {
        final json = {
          'average_generation_time': 30,
        };

        final result = SummaryStats.fromJson(json);

        expect(result.averageGenerationTime, 30.0);
        expect(result.averageGenerationTime, isA<double>());
      });
    });

    group('canRegenerate', () {
      test('returns true when lastGenerated is null', () {
        final stats = SummaryStats(
          totalSummaries: 0,
          lastGenerated: null,
          averageGenerationTime: 0,
          formatsGenerated: [],
        );

        expect(stats.canRegenerate(), true);
      });

      test('returns true when time since last generation exceeds minInterval', () {
        final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
        final stats = SummaryStats(
          totalSummaries: 1,
          lastGenerated: twoHoursAgo.toUtc().toIso8601String().replaceAll('Z', ''),
          averageGenerationTime: 30,
          formatsGenerated: ['markdown'],
        );

        expect(
          stats.canRegenerate(minInterval: const Duration(hours: 1)),
          true,
        );
      });

      test('returns false when time since last generation is within minInterval', () {
        final thirtyMinutesAgo = DateTime.now().subtract(const Duration(minutes: 30));
        final stats = SummaryStats(
          totalSummaries: 1,
          lastGenerated: thirtyMinutesAgo.toUtc().toIso8601String().replaceAll('Z', ''),
          averageGenerationTime: 30,
          formatsGenerated: ['markdown'],
        );

        expect(
          stats.canRegenerate(minInterval: const Duration(hours: 1)),
          false,
        );
      });

      test('uses default 1-hour minInterval', () {
        final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
        final stats = SummaryStats(
          totalSummaries: 1,
          lastGenerated: twoHoursAgo.toUtc().toIso8601String().replaceAll('Z', ''),
          averageGenerationTime: 30,
          formatsGenerated: ['markdown'],
        );

        expect(stats.canRegenerate(), true);
      });
    });
  });

  group('EntityCheck Model', () {
    test('toJson serializes correctly', () {
      final entity = EntityCheck(type: 'project', id: 'proj-123');

      final json = entity.toJson();

      expect(json['type'], 'project');
      expect(json['id'], 'proj-123');
    });
  });

  group('ContentAvailabilityService HTTP methods', () {
    test('checkAvailability makes GET request with correct path and params', () async {
      // Arrange
      final responseData = {
        'has_content': true,
        'content_count': 5,
        'can_generate_summary': true,
        'message': 'Ready',
      };

      when(mockDio.get(
        '/api/v1/content-availability/check/project/proj-123',
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/content-availability/check/project/proj-123'),
          ));

      // Act
      final result = await service.checkAvailability(
        entityType: 'project',
        entityId: 'proj-123',
      );

      // Assert
      expect(result.hasContent, true);
      expect(result.contentCount, 5);
      expect(result.canGenerateSummary, true);
      verify(mockDio.get(
        '/api/v1/content-availability/check/project/proj-123',
        queryParameters: anyNamed('queryParameters'),
      )).called(1);
    });

    test('checkAvailability includes date parameters when provided', () async {
      // Arrange
      final dateStart = DateTime(2024, 1, 1);
      final dateEnd = DateTime(2024, 12, 31);

      when(mockDio.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => Response(
            data: {'has_content': false, 'content_count': 0, 'can_generate_summary': false, 'message': 'No content'},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      // Act
      await service.checkAvailability(
        entityType: 'project',
        entityId: 'proj-123',
        dateStart: dateStart,
        dateEnd: dateEnd,
      );

      // Assert
      final captured = verify(mockDio.get(
        '/api/v1/content-availability/check/project/proj-123',
        queryParameters: captureAnyNamed('queryParameters'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['date_start'], dateStart.toIso8601String());
      expect(captured['date_end'], dateEnd.toIso8601String());
    });

    test('getSummaryStats makes GET request and parses response', () async {
      // Arrange
      final responseData = {
        'total_summaries': 10,
        'last_generated': '2024-01-15T10:30:00',
        'average_generation_time': 45.0,
        'formats_generated': ['markdown', 'pdf'],
      };

      when(mockDio.get('/api/v1/content-availability/stats/portfolio/port-456'))
          .thenAnswer((_) async => Response(
                data: responseData,
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/content-availability/stats/portfolio/port-456'),
              ));

      // Act
      final result = await service.getSummaryStats(
        entityType: 'portfolio',
        entityId: 'port-456',
      );

      // Assert
      expect(result.totalSummaries, 10);
      expect(result.averageGenerationTime, 45.0);
      verify(mockDio.get('/api/v1/content-availability/stats/portfolio/port-456')).called(1);
    });

    test('batchCheckAvailability makes POST request with entities list', () async {
      // Arrange
      final entities = [
        EntityCheck(type: 'project', id: 'proj-1'),
        EntityCheck(type: 'project', id: 'proj-2'),
      ];

      when(mockDio.post(
        '/api/v1/content-availability/batch-check',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: {
              'proj-1': {'has_content': true, 'content_count': 5, 'can_generate_summary': true, 'message': 'OK'},
              'proj-2': {'has_content': false, 'content_count': 0, 'can_generate_summary': false, 'message': 'No content'},
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/content-availability/batch-check'),
          ));

      // Act
      final result = await service.batchCheckAvailability(entities: entities);

      // Assert
      expect(result.length, 2);
      expect(result['proj-1']?.hasContent, true);
      expect(result['proj-2']?.hasContent, false);

      final captured = verify(mockDio.post(
        '/api/v1/content-availability/batch-check',
        data: captureAnyNamed('data'),
      )).captured.single as Map<String, dynamic>;

      expect(captured['entities'], hasLength(2));
    });
  });
}
