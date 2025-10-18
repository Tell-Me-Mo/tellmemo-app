import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/services/firebase_analytics_service.dart';

part 'query_provider.freezed.dart';

@freezed
class QueryState with _$QueryState {
  const factory QueryState({
    @Default(false) bool isLoading,
    @Default([]) List<ConversationItem> conversation,
    @Default(null) String? error,
    @Default([]) List<String> queryHistory,
    @Default(null) String? pendingQuestion,
    @Default([]) List<ConversationSession> sessions,
    @Default(null) String? activeSessionId,
    @Default(null) String? activeConversationId, // Backend conversation ID for RAG context
    @Default(null) String? currentEntityId,      // Entity ID (e.g., 'organization', uuid)
    @Default(null) String? currentEntityType,    // 'organization', 'portfolio', 'program', 'project'
    @Default(null) String? currentContextId,     // Context ID (e.g., 'task_{id}' for item-specific conversations)
  }) = _QueryState;
}

@freezed
class ConversationItem with _$ConversationItem {
  const factory ConversationItem({
    required String question,
    required String answer,
    required List<String> sources,
    required double confidence,
    required DateTime timestamp,
    @Default(false) bool isAnswerPending,
  }) = _ConversationItem;
}

@freezed
class ConversationSession with _$ConversationSession {
  const factory ConversationSession({
    required String id,
    required String title,
    required DateTime createdAt,
    required List<ConversationItem> items,
    DateTime? lastAccessedAt,
  }) = _ConversationSession;
}

class QueryNotifier extends StateNotifier<QueryState> {
  final ApiService _apiService;

  QueryNotifier(this._apiService) : super(const QueryState());

  // Load conversations from backend with entity-aware clearing
  Future<void> loadConversations(
    String projectId, {
    String? entityType,
    String? contextId,  // For task/risk/blocker/lesson specific conversations
  }) async {
    // Determine if we're switching entities
    final isContextSwitch = contextId != null && state.currentContextId != contextId;
    final isEntitySwitch = (state.currentEntityId != projectId ||
                            state.currentEntityType != entityType) &&
                           contextId == null;  // Don't check entity switch for item dialogs

    if (isContextSwitch || isEntitySwitch) {
      // Clear active conversation when switching contexts
      state = state.copyWith(
        conversation: [],
        activeConversationId: null,
        activeSessionId: null,  // Clear active session
        currentEntityId: projectId,
        currentEntityType: entityType,
        currentContextId: contextId,
      );
    } else {
      // Same entity, just update tracking but clear active session for fresh start
      state = state.copyWith(
        conversation: [],
        activeConversationId: null,
        activeSessionId: null,  // Clear active session for fresh start
        currentEntityId: projectId,
        currentEntityType: entityType,
        currentContextId: contextId,
      );
    }

    // Load historical sessions for this entity
    try {
      final conversationsData = await _apiService.client.getConversations(
        projectId,
        contextId: contextId,  // Pass context_id for filtering
      );

      final sessions = conversationsData.map((data) {
        final messages = (data['messages'] as List?)?.map((msgData) {
          return ConversationItem(
            question: msgData['question'] ?? '',
            answer: msgData['answer'] ?? '',
            sources: List<String>.from(msgData['sources'] ?? []),
            confidence: (msgData['confidence'] ?? 0.0).toDouble(),
            timestamp: DateTime.parse(msgData['timestamp']).toLocal(),  // Convert UTC to local time
            isAnswerPending: msgData['isAnswerPending'] ?? false,
          );
        }).toList() ?? <ConversationItem>[];

        return ConversationSession(
          id: data['id'],
          title: data['title'],
          createdAt: DateTime.parse(data['created_at']).toLocal(),  // Convert UTC to local time
          items: messages,
          lastAccessedAt: DateTime.parse(data['last_accessed_at']).toLocal(),  // Convert UTC to local time
        );
      }).toList();

      state = state.copyWith(sessions: sessions);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load conversations: $e');
    }
  }
  
  Future<void> submitQuery({
    required String projectId,
    required String question,
    bool isFollowUp = false,
    String entityType = 'project',
    String? contextId,  // Optional context for item-specific conversations
  }) async {
    // Update current entity tracking
    state = state.copyWith(
      currentEntityId: projectId,
      currentEntityType: entityType,
      currentContextId: contextId,
    );

    // No need to create session ID here - backend will provide it

    // Log query asked
    final startTime = DateTime.now();
    await FirebaseAnalyticsService().logQueryAsked(
      projectId: projectId,
      queryLength: question.length,
      queryType: isFollowUp ? 'follow_up' : 'new',
    );

    // Immediately add question to conversation with pending answer
    final pendingItem = ConversationItem(
      question: question,
      answer: '',
      sources: [],
      confidence: 0.0,
      timestamp: DateTime.now(),
      isAnswerPending: true,
    );

    state = state.copyWith(
      isLoading: true,
      error: null,
      conversation: [...state.conversation, pendingItem],
      pendingQuestion: question,
    );

    try {
      // Build request with conversation_id for backend RAG context
      final Map<String, dynamic> requestBody = {
        'question': question,
      };

      // Include conversation_id for follow-up queries to enable backend context
      if (isFollowUp && state.activeConversationId != null) {
        requestBody['conversation_id'] = state.activeConversationId;
      }

      final response = entityType == 'program'
          ? await _apiService.client.queryProgram(projectId, requestBody)
          : entityType == 'portfolio'
              ? await _apiService.client.queryPortfolio(projectId, requestBody)
              : entityType == 'organization'
                  ? await _apiService.client.queryOrganization(requestBody)
                  : await _apiService.client.queryProject(projectId, requestBody);

      // Extract backend conversation context fields
      final conversationId = response['conversation_id'] as String?;
      final answer = response['answer'] ?? '';
      final sources = List<String>.from(response['sources'] ?? []);

      // Log query completed
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await FirebaseAnalyticsService().logQueryCompleted(
        projectId: projectId,
        responseTime: responseTime,
        sourcesCount: sources.length,
        responseLength: answer.length,
      );

      // Update the pending item with the actual answer
      final updatedItem = ConversationItem(
        question: question,
        answer: answer,
        sources: sources,
        confidence: (response['confidence'] ?? 0.0).toDouble(),
        timestamp: pendingItem.timestamp,
        isAnswerPending: false,
      );

      // Replace the pending item with the completed one
      final updatedConversation = [...state.conversation];
      updatedConversation[updatedConversation.length - 1] = updatedItem;

      // Update history
      final updatedHistory = [question, ...state.queryHistory]
          .take(10)
          .toList();

      // Use the backend conversation_id as our session ID
      // This eliminates the need for temporary IDs and complex syncing
      final newSessionId = conversationId ?? state.activeSessionId;

      state = state.copyWith(
        isLoading: false,
        conversation: updatedConversation,
        queryHistory: updatedHistory,
        pendingQuestion: null,
        activeConversationId: conversationId,
        activeSessionId: newSessionId, // Use backend ID directly
      );

      // Update local sessions list with the new/updated conversation
      if (newSessionId != null) {
        final title = question.length > 50 ? '${question.substring(0, 50)}...' : question;
        final session = ConversationSession(
          id: newSessionId,
          title: title,
          createdAt: DateTime.now(),
          items: updatedConversation,
          lastAccessedAt: DateTime.now(),
        );

        final sessions = [...state.sessions];
        final existingIndex = sessions.indexWhere((s) => s.id == newSessionId);

        if (existingIndex >= 0) {
          sessions[existingIndex] = session;
        } else {
          sessions.insert(0, session);
        }

        state = state.copyWith(sessions: sessions);
      }
    } catch (e) {
      // Log query failed
      await FirebaseAnalyticsService().logQueryFailed(
        projectId: projectId,
        errorReason: e.toString(),
      );

      // Remove the pending item on error
      final updatedConversation = [...state.conversation];
      if (updatedConversation.isNotEmpty &&
          updatedConversation.last.isAnswerPending) {
        updatedConversation.removeLast();
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to process query: ${e.toString()}',
        conversation: updatedConversation,
        pendingQuestion: null,
      );
    }
  }
  
  void clearConversation() {
    state = state.copyWith(
      conversation: [],
      error: null,
      activeConversationId: null, // Reset backend conversation context
    );
  }

  void removeConversationItem(int index) {
    if (index >= 0 && index < state.conversation.length) {
      final updatedConversation = [...state.conversation];
      updatedConversation.removeAt(index);
      state = state.copyWith(conversation: updatedConversation);
    }
  }

  Future<void> createNewSession(String projectId) async {
    // Simply clear the current conversation
    // New session ID will be assigned by backend when user sends first message
    state = state.copyWith(
      conversation: [],
      error: null,
      activeSessionId: null,
      activeConversationId: null,
    );
  }

  Future<void> switchToSession(String projectId, String sessionId) async {
    // Find and load the requested session
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => ConversationSession(
        id: sessionId,
        title: 'New conversation',
        createdAt: DateTime.now(),
        items: [],
      ),
    );

    state = state.copyWith(
      conversation: session.items,
      activeSessionId: sessionId,
      activeConversationId: sessionId, // Backend conversation ID is the same
      error: null,
    );
  }


  Future<void> deleteSession(String projectId, String sessionId) async {
    try {
      // Delete from backend
      await _apiService.client.deleteConversation(projectId, sessionId);
    } catch (e) {
      // Continue with local deletion even if backend fails
    }

    final updatedSessions = state.sessions
        .where((s) => s.id != sessionId)
        .toList();

    // If deleting the active session, clear the conversation
    if (state.activeSessionId == sessionId) {
      state = state.copyWith(
        sessions: updatedSessions,
        conversation: [],
        activeSessionId: null,
      );
    } else {
      state = state.copyWith(sessions: updatedSessions);
    }
  }
}

final queryProvider = StateNotifierProvider<QueryNotifier, QueryState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return QueryNotifier(apiService);
});

// Query suggestions based on common patterns
final querySuggestionsProvider = Provider<List<String>>((ref) => [
  'What were the key decisions made this week?',
  'Show me all action items from recent meetings',
  'What are the current blockers for this project?',
  'Summarize the project status',
  'What did we discuss about [topic]?',
  'Who is responsible for [task]?',
  'When is the deadline for [deliverable]?',
  'What are the next steps?',
  'Show me the project timeline',
  'What risks have been identified?',
]);

// Generate context-aware follow-up suggestions based on the response
List<String> generateFollowUpSuggestions(String answer, String question) {
  final suggestions = <String>[];
  final answerLower = answer.toLowerCase();

  // Context-based suggestions
  if (answerLower.contains('action') || answerLower.contains('task')) {
    suggestions.add('Who is responsible for these tasks?');
    suggestions.add('What are the deadlines?');
    suggestions.add('Show task dependencies');
  }

  if (answerLower.contains('risk') || answerLower.contains('issue')) {
    suggestions.add('What is the mitigation plan?');
    suggestions.add('What is the impact assessment?');
    suggestions.add('Who owns these risks?');
  }

  if (answerLower.contains('decision') || answerLower.contains('agreed')) {
    suggestions.add('What are the next steps?');
    suggestions.add('Who needs to be informed?');
    suggestions.add('What is the timeline?');
  }

  if (answerLower.contains('meeting') || answerLower.contains('discussion')) {
    suggestions.add('Who attended this meeting?');
    suggestions.add('What were the action items?');
    suggestions.add('When is the next meeting?');
  }

  if (answerLower.contains('deadline') || answerLower.contains('timeline')) {
    suggestions.add('What could cause delays?');
    suggestions.add('What are the dependencies?');
    suggestions.add('Show critical path');
  }

  if (answerLower.contains('budget') || answerLower.contains('cost')) {
    suggestions.add('What is the budget breakdown?');
    suggestions.add('Are we on track financially?');
    suggestions.add('What are the cost risks?');
  }

  // Add generic follow-ups if no specific context
  if (suggestions.isEmpty) {
    suggestions.add('Can you provide more details?');
    suggestions.add('What are the implications?');
    suggestions.add('What should we prioritize?');
  }

  // Limit to 3 suggestions
  return suggestions.take(3).toList();
}

// Query history provider for a specific project
final projectQueryHistoryProvider = StateProvider.family<List<String>, String>(
  (ref, projectId) => [],
);