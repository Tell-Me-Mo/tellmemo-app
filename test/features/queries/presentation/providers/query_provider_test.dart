import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pm_master_v2/core/network/api_service.dart';
import 'package:pm_master_v2/features/queries/presentation/providers/query_provider.dart';

import '../../../../mocks/mock_api_client.dart';

void main() {
  group('QueryNotifier', () {
    late ProviderContainer container;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(mockApiClient)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has empty conversation and no error', () {
      final state = container.read(queryProvider);

      expect(state.isLoading, false);
      expect(state.conversation, isEmpty);
      expect(state.error, null);
      expect(state.queryHistory, isEmpty);
      expect(state.activeSessionId, null);
      expect(state.sessions, isEmpty);
    });

    test('loadConversations loads sessions from backend', () async {
      // Arrange
      final conversationsData = [
        {
          'id': 'session-1',
          'title': 'First conversation',
          'created_at': '2024-01-01T10:00:00Z',
          'last_accessed_at': '2024-01-01T11:00:00Z',
          'messages': [
            {
              'question': 'What is the status?',
              'answer': 'Everything is on track',
              'sources': ['meeting-1', 'meeting-2'],
              'confidence': 0.9,
              'timestamp': '2024-01-01T10:00:00Z',
              'isAnswerPending': false,
            },
          ],
        },
      ];

      mockApiClient.getConversationsResponse = conversationsData;

      // Act
      await container.read(queryProvider.notifier).loadConversations('project-1');

      // Assert
      final state = container.read(queryProvider);
      expect(state.sessions.length, 1);
      expect(state.sessions.first.id, 'session-1');
      expect(state.sessions.first.title, 'First conversation');
      expect(state.sessions.first.items.length, 1);
      expect(state.sessions.first.items.first.question, 'What is the status?');
      expect(state.sessions.first.items.first.sources, ['meeting-1', 'meeting-2']);
    });

    test('loadConversations clears conversation when switching contexts', () async {
      // Arrange - set up initial conversation
      mockApiClient.queryProjectResponse = {
        'answer': 'Initial answer',
        'sources': [],
        'confidence': 0.8,
        'conversation_id': 'conv-1',
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'First question',
      );

      expect(container.read(queryProvider).conversation.length, 1);

      // Act - load conversations for different context
      mockApiClient.getConversationsResponse = [];
      await container.read(queryProvider.notifier).loadConversations(
        'project-1',
        contextId: 'task_123',
      );

      // Assert
      final state = container.read(queryProvider);
      expect(state.conversation, isEmpty);
      expect(state.activeConversationId, null);
      expect(state.currentContextId, 'task_123');
    });

    test('loadConversations handles error gracefully', () async {
      // Arrange
      mockApiClient.shouldThrowError = true;

      // Act
      await container.read(queryProvider.notifier).loadConversations('project-1');

      // Assert
      final state = container.read(queryProvider);
      expect(state.error, isNotNull);
      expect(state.error, contains('Failed to load conversations'));
    });

    test('submitQuery adds conversation item with answer', () async {
      // Arrange
      mockApiClient.queryProjectResponse = {
        'answer': 'Test answer',
        'sources': [],
        'confidence': 0.8,
      };

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Test question',
      );

      // Assert - conversation contains the item
      final state = container.read(queryProvider);
      expect(state.conversation.length, 1);
      expect(state.conversation.first.question, 'Test question');
      expect(state.conversation.first.answer, 'Test answer');
      expect(state.isLoading, false);
    });

    test('submitQuery updates conversation with answer on success', () async {
      // Arrange
      mockApiClient.queryProjectResponse = {
        'answer': 'Test answer',
        'sources': ['source-1', 'source-2'],
        'confidence': 0.9,
        'conversation_id': 'conv-1',
      };

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Test question',
      );

      // Assert
      final state = container.read(queryProvider);
      expect(state.isLoading, false);
      expect(state.conversation.length, 1);
      expect(state.conversation.first.question, 'Test question');
      expect(state.conversation.first.answer, 'Test answer');
      expect(state.conversation.first.sources, ['source-1', 'source-2']);
      expect(state.conversation.first.confidence, 0.9);
      expect(state.conversation.first.isAnswerPending, false);
      expect(state.activeConversationId, 'conv-1');
      expect(state.error, null);
    });

    test('submitQuery updates query history', () async {
      // Arrange
      mockApiClient.queryProjectResponse = {
        'answer': 'Answer 1',
        'sources': [],
        'confidence': 0.8,
      };

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Question 1',
      );

      mockApiClient.queryProjectResponse = {
        'answer': 'Answer 2',
        'sources': [],
        'confidence': 0.8,
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Question 2',
      );

      // Assert
      final state = container.read(queryProvider);
      expect(state.queryHistory.length, 2);
      expect(state.queryHistory[0], 'Question 2'); // Most recent first
      expect(state.queryHistory[1], 'Question 1');
    });

    test('submitQuery limits history to 10 items', () async {
      // Arrange
      mockApiClient.queryProjectResponse = {
        'answer': 'Answer',
        'sources': [],
        'confidence': 0.8,
      };

      // Act - submit 12 queries
      for (int i = 1; i <= 12; i++) {
        await container.read(queryProvider.notifier).submitQuery(
          projectId: 'project-1',
          question: 'Question $i',
        );
      }

      // Assert
      final state = container.read(queryProvider);
      expect(state.queryHistory.length, 10);
      expect(state.queryHistory.first, 'Question 12'); // Most recent
      expect(state.queryHistory.last, 'Question 3'); // Oldest kept
    });

    test('submitQuery calls queryProgram for program entity type', () async {
      // Arrange
      mockApiClient.queryProgramResponse = {
        'answer': 'Program answer',
        'sources': [],
        'confidence': 0.8,
      };

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'program-1',
        question: 'Test question',
        entityType: 'program',
      );

      // Assert
      expect(mockApiClient.queryProgramCalled, true);
      expect(mockApiClient.queryProjectCalled, false);
    });

    test('submitQuery calls queryPortfolio for portfolio entity type', () async {
      // Arrange
      mockApiClient.queryPortfolioResponse = {
        'answer': 'Portfolio answer',
        'sources': [],
        'confidence': 0.8,
      };

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'portfolio-1',
        question: 'Test question',
        entityType: 'portfolio',
      );

      // Assert
      expect(mockApiClient.queryPortfolioCalled, true);
      expect(mockApiClient.queryProjectCalled, false);
    });

    test('submitQuery calls queryOrganization for organization entity type', () async {
      // Arrange
      mockApiClient.queryOrganizationResponse = {
        'answer': 'Organization answer',
        'sources': [],
        'confidence': 0.8,
      };

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'org-1',
        question: 'Test question',
        entityType: 'organization',
      );

      // Assert
      expect(mockApiClient.queryOrganizationCalled, true);
      expect(mockApiClient.queryProjectCalled, false);
    });

    test('submitQuery includes conversation_id for follow-up queries', () async {
      // Arrange - first query
      mockApiClient.queryProjectResponse = {
        'answer': 'First answer',
        'sources': [],
        'confidence': 0.8,
        'conversation_id': 'conv-123',
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'First question',
      );

      // Act - follow-up query
      mockApiClient.queryProjectResponse = {
        'answer': 'Follow-up answer',
        'sources': [],
        'confidence': 0.8,
        'conversation_id': 'conv-123',
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Follow-up question',
        isFollowUp: true,
      );

      // Assert
      expect(mockApiClient.lastQueryProjectRequest, isNotNull);
      expect(mockApiClient.lastQueryProjectRequest!['conversation_id'], 'conv-123');
    });

    test('submitQuery removes pending item on error', () async {
      // Arrange
      mockApiClient.shouldThrowError = true;

      // Act
      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Test question',
      );

      // Assert
      final state = container.read(queryProvider);
      expect(state.isLoading, false);
      expect(state.conversation, isEmpty); // Pending item removed
      expect(state.error, isNotNull);
      expect(state.error, contains('Failed to process query'));
    });

    test('clearConversation clears conversation and resets state', () async {
      // Arrange
      mockApiClient.queryProjectResponse = {
        'answer': 'Test answer',
        'sources': [],
        'confidence': 0.8,
        'conversation_id': 'conv-1',
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Test question',
      );

      expect(container.read(queryProvider).conversation.isNotEmpty, true);

      // Act
      container.read(queryProvider.notifier).clearConversation();

      // Assert
      final state = container.read(queryProvider);
      expect(state.conversation, isEmpty);
      expect(state.error, null);
      expect(state.activeConversationId, null);
    });

    test('removeConversationItem removes item at valid index', () async {
      // Arrange
      mockApiClient.queryProjectResponse = {
        'answer': 'Answer 1',
        'sources': [],
        'confidence': 0.8,
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Question 1',
      );

      mockApiClient.queryProjectResponse = {
        'answer': 'Answer 2',
        'sources': [],
        'confidence': 0.8,
      };

      await container.read(queryProvider.notifier).submitQuery(
        projectId: 'project-1',
        question: 'Question 2',
      );

      expect(container.read(queryProvider).conversation.length, 2);

      // Act
      container.read(queryProvider.notifier).removeConversationItem(0);

      // Assert
      final state = container.read(queryProvider);
      expect(state.conversation.length, 1);
      expect(state.conversation.first.question, 'Question 2');
    });

    test('removeConversationItem does nothing for invalid index', () {
      // Act
      container.read(queryProvider.notifier).removeConversationItem(99);

      // Assert
      final state = container.read(queryProvider);
      expect(state.conversation, isEmpty);
    });

    test('createNewSession creates new session with unique ID', () async {
      // Act
      await container.read(queryProvider.notifier).createNewSession('project-1');

      // Assert
      final state = container.read(queryProvider);
      // Session ID is assigned by backend when first message is sent, so it's null initially
      expect(state.activeSessionId, isNull);
      expect(state.conversation, isEmpty);
      expect(state.error, null);
    });

    test('switchToSession loads session conversation', () async {
      // Arrange
      mockApiClient.getConversationsResponse = [
        {
          'id': 'session-1',
          'title': 'Test session',
          'created_at': '2024-01-01T10:00:00Z',
          'last_accessed_at': '2024-01-01T11:00:00Z',
          'messages': [
            {
              'question': 'Session question',
              'answer': 'Session answer',
              'sources': [],
              'confidence': 0.8,
              'timestamp': '2024-01-01T10:00:00Z',
              'isAnswerPending': false,
            },
          ],
        },
      ];

      await container.read(queryProvider.notifier).loadConversations('project-1');

      // Act
      await container.read(queryProvider.notifier).switchToSession('project-1', 'session-1');

      // Assert
      final state = container.read(queryProvider);
      expect(state.activeSessionId, 'session-1');
      expect(state.conversation.length, 1);
      expect(state.conversation.first.question, 'Session question');
    });

    test('deleteSession removes session from list', () async {
      // Arrange
      mockApiClient.getConversationsResponse = [
        {
          'id': 'session-1',
          'title': 'Test session',
          'created_at': '2024-01-01T10:00:00Z',
          'last_accessed_at': '2024-01-01T11:00:00Z',
          'messages': [],
        },
      ];

      await container.read(queryProvider.notifier).loadConversations('project-1');
      expect(container.read(queryProvider).sessions.length, 1);

      // Act
      await container.read(queryProvider.notifier).deleteSession('project-1', 'session-1');

      // Assert
      final state = container.read(queryProvider);
      expect(state.sessions, isEmpty);
    });

    test('deleteSession clears conversation if deleting active session', () async {
      // Arrange
      mockApiClient.getConversationsResponse = [
        {
          'id': 'session-1',
          'title': 'Test session',
          'created_at': '2024-01-01T10:00:00Z',
          'last_accessed_at': '2024-01-01T11:00:00Z',
          'messages': [
            {
              'question': 'Test',
              'answer': 'Test answer',
              'sources': [],
              'confidence': 0.8,
              'timestamp': '2024-01-01T10:00:00Z',
              'isAnswerPending': false,
            },
          ],
        },
      ];

      await container.read(queryProvider.notifier).loadConversations('project-1');
      await container.read(queryProvider.notifier).switchToSession('project-1', 'session-1');

      expect(container.read(queryProvider).conversation.isNotEmpty, true);

      // Act
      await container.read(queryProvider.notifier).deleteSession('project-1', 'session-1');

      // Assert
      final state = container.read(queryProvider);
      expect(state.conversation, isEmpty);
      expect(state.activeSessionId, null);
    });
  });

  group('generateFollowUpSuggestions', () {
    test('suggests task-related follow-ups for action items', () {
      final answer = 'The main action items are: complete testing and deploy to production.';
      final question = 'What are the next steps?';

      final suggestions = generateFollowUpSuggestions(answer, question);

      expect(suggestions.length, greaterThan(0));
      expect(
        suggestions.any((s) => s.toLowerCase().contains('responsible') || s.toLowerCase().contains('deadline')),
        true,
      );
    });

    test('suggests risk-related follow-ups for risks', () {
      final answer = 'The main risk is potential delays due to dependencies.';
      final question = 'What are the risks?';

      final suggestions = generateFollowUpSuggestions(answer, question);

      expect(suggestions.length, greaterThan(0));
      expect(
        suggestions.any((s) => s.toLowerCase().contains('mitigation') || s.toLowerCase().contains('impact')),
        true,
      );
    });

    test('suggests decision-related follow-ups for decisions', () {
      final answer = 'The team agreed to proceed with the new framework for the project.';
      final question = 'What decisions were made?';

      final suggestions = generateFollowUpSuggestions(answer, question);

      expect(suggestions.length, greaterThan(0));
      expect(
        suggestions.any((s) =>
          s.toLowerCase().contains('next') ||
          s.toLowerCase().contains('timeline') ||
          s.toLowerCase().contains('informed')
        ),
        true,
      );
    });

    test('suggests meeting-related follow-ups for meetings', () {
      final answer = 'In the last meeting, we discussed the project timeline.';
      final question = 'What was discussed?';

      final suggestions = generateFollowUpSuggestions(answer, question);

      expect(suggestions.length, greaterThan(0));
      expect(
        suggestions.any((s) => s.toLowerCase().contains('attended') || s.toLowerCase().contains('action items')),
        true,
      );
    });

    test('suggests generic follow-ups when no specific context', () {
      final answer = 'The project is progressing well.';
      final question = 'How is the project?';

      final suggestions = generateFollowUpSuggestions(answer, question);

      expect(suggestions.length, 3);
      expect(
        suggestions.any((s) => s.toLowerCase().contains('details') || s.toLowerCase().contains('implications')),
        true,
      );
    });

    test('limits suggestions to 3 items', () {
      final answer = 'We have action items, risks, decisions, and meeting notes to discuss.';
      final question = 'What do we need to address?';

      final suggestions = generateFollowUpSuggestions(answer, question);

      expect(suggestions.length, lessThanOrEqualTo(3));
    });
  });

  group('querySuggestionsProvider', () {
    test('provides list of default suggestions', () {
      final container = ProviderContainer();

      final suggestions = container.read(querySuggestionsProvider);

      expect(suggestions, isNotEmpty);
      expect(suggestions.length, greaterThan(5));
      expect(suggestions.first, contains('key decisions'));
    });
  });
}
