# Live Insights Feature - Completion Tasks

**Document Version:** 1.0
**Last Updated:** October 19, 2025
**Current Status:** 🟡 In Progress (70% Complete)
**Estimated Time to Production:** 12-17 hours

---

## Table of Contents

1. [Current Status](#current-status)
2. [Critical Tasks (Must Fix)](#critical-tasks-must-fix)
3. [Important Tasks (Should Fix)](#important-tasks-should-fix)
4. [Nice to Have Tasks (Can Do Later)](#nice-to-have-tasks-can-do-later)
5. [Testing Checklist](#testing-checklist)
6. [Pre-Production Checklist](#pre-production-checklist)
7. [Task Tracking](#task-tracking)

---

## Current Status

### ✅ Completed (70%)

- [x] Backend real-time insight extraction service
- [x] WebSocket endpoint for live meeting streaming
- [x] Insight aggregation and deduplication logic
- [x] Flutter live insights panel UI component
- [x] Flutter WebSocket service for live insights
- [x] Comprehensive documentation (HLD + implementation guide)
- [x] Error handling and reconnection logic (partial)

### ⏳ In Progress (0%)

- [ ] Integration with existing recording flow
- [ ] End-to-end testing

### ❌ Not Started (30%)

- [ ] Flutter code generation (freezed/json_serializable)
- [ ] Real transcription implementation
- [ ] Authentication and authorization
- [ ] Dependency verification
- [ ] Unit and integration tests
- [ ] Performance validation
- [ ] Security hardening
- [ ] Monitoring and observability

---

## Critical Tasks (Must Fix)

These tasks **MUST** be completed before the feature can be tested or used.

### C1. Flutter Code Generation
**Priority:** 🔴 CRITICAL
**Estimated Time:** 5 minutes
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Generate Freezed and json_serializable code for Flutter data models.

**Steps:**
1. Ensure `freezed` and `json_serializable` are in `pubspec.yaml`
2. Run code generation:
   ```bash
   cd /root/tellmemo-app
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
3. Verify generated files exist:
   - `lib/features/live_insights/domain/models/live_insight_model.freezed.dart`
   - `lib/features/live_insights/domain/models/live_insight_model.g.dart`
4. Fix any compilation errors

**Acceptance Criteria:**
- [ ] Code generation completes without errors
- [ ] Generated files are committed to git
- [ ] `flutter analyze` shows no errors in live insights files

**Blockers:** None

**Dependencies:** None

---

### C2. Implement Real Transcription
**Priority:** 🔴 CRITICAL
**Estimated Time:** 30-60 minutes
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Replace placeholder transcription with actual Replicate or Whisper service call.

**Current Code (Placeholder):**
```python
# backend/routers/websocket_live_insights.py:463
transcript_text = f"[Placeholder transcript for chunk {session.chunk_index}]"
```

**Implementation Options:**

**Option A: Replicate (Recommended - Fast)**
```python
async def handle_audio_chunk(session, data, db):
    audio_data = data.get('data')  # Base64

    # Decode base64 audio
    import base64
    audio_bytes = base64.b64decode(audio_data)

    # Save to temp file
    import tempfile
    with tempfile.NamedTemporaryFile(delete=False, suffix='.webm') as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        # Call Replicate transcription
        from services.transcription.replicate_transcription_service import replicate_transcription_service

        result = await replicate_transcription_service.transcribe_audio(
            audio_file_path=tmp_path,
            language='en'
        )

        transcript_text = result.get('text', '')

    finally:
        # Clean up temp file
        import os
        os.unlink(tmp_path)
```

**Option B: Whisper (Local - Free)**
```python
async def handle_audio_chunk(session, data, db):
    from services.transcription.whisper_service import whisper_service

    audio_data = data.get('data')
    audio_bytes = base64.b64decode(audio_data)

    with tempfile.NamedTemporaryFile(delete=False, suffix='.webm') as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        result = await whisper_service.transcribe_audio_file(
            audio_file_path=tmp_path,
            language='en'
        )
        transcript_text = result.get('text', '')
    finally:
        os.unlink(tmp_path)
```

**Steps:**
1. Choose transcription service (Replicate recommended)
2. Import service in `websocket_live_insights.py`
3. Replace placeholder code (line ~463)
4. Handle errors gracefully
5. Add transcription time tracking
6. Test with actual audio chunk

**Acceptance Criteria:**
- [ ] Audio chunks are transcribed to text
- [ ] Transcription errors are handled gracefully
- [ ] Transcription time is tracked in metrics
- [ ] Works with WebM, M4A, MP3 formats

**Blockers:** None

**Dependencies:** C1 (code generation)

---

### C3. Implement Authentication
**Priority:** 🔴 CRITICAL
**Estimated Time:** 1-2 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add proper JWT authentication to WebSocket endpoint and verify user has access to project.

**Current Code (Insecure):**
```python
# backend/routers/websocket_live_insights.py:398-399
user_id = "test_user"  # ❌ Hardcoded
organization_id = "test_org"  # ❌ Hardcoded
```

**Implementation:**

```python
from dependencies.auth import get_current_user_ws
from models.user import User

@router.websocket("/live-insights")
async def websocket_live_insights(
    websocket: WebSocket,
    project_id: str = Query(...),
    token: str = Query(...),  # JWT token
    db: AsyncSession = Depends(get_db)
):
    # Authenticate user
    try:
        user = await get_current_user_ws(token, db)
        if not user:
            await websocket.close(code=1008, reason="Authentication failed")
            return
    except Exception as e:
        await websocket.close(code=1008, reason=f"Auth error: {e}")
        return

    # Verify project access
    project = await db.get(Project, project_id)
    if not project:
        await websocket.close(code=1008, reason="Project not found")
        return

    # Verify user has access to organization
    org_member = await db.execute(
        select(OrganizationMember).where(
            OrganizationMember.user_id == user.id,
            OrganizationMember.organization_id == project.organization_id
        )
    )
    if not org_member.scalar_one_or_none():
        await websocket.close(code=1008, reason="Unauthorized")
        return

    # Now we have verified: user, project, organization
    user_id = str(user.id)
    organization_id = str(project.organization_id)

    # ... rest of code
```

**Steps:**
1. Check if `get_current_user_ws` exists in `dependencies/auth.py`
   - If not, create it based on `get_current_user`
2. Add JWT token parameter to WebSocket endpoint
3. Implement authentication logic
4. Verify project access
5. Verify organization membership
6. Update frontend to send JWT token in WebSocket connection
7. Test authentication flow

**Frontend Changes:**
```dart
// lib/features/live_insights/domain/services/live_insights_websocket_service.dart

String _getWsUrl(String projectId) {
  final baseUrl = ApiConfig.baseUrl;
  final token = AuthService.currentToken; // Get JWT token
  final wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
  final host = baseUrl.replaceAll(RegExp(r'^https?://'), '');
  return '$wsProtocol://$host/ws/live-insights?project_id=$projectId&token=$token';
}
```

**Acceptance Criteria:**
- [ ] WebSocket requires valid JWT token
- [ ] Invalid tokens are rejected with proper error code
- [ ] User must have access to project's organization
- [ ] Authentication errors are logged
- [ ] Frontend includes token in connection URL

**Blockers:** None

**Dependencies:** None

---

### C4. Verify and Add Dependencies
**Priority:** 🔴 CRITICAL
**Estimated Time:** 30 minutes
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Verify all required dependencies are in requirements.txt and pubspec.yaml.

**Backend Dependencies to Check:**

```bash
# Check if numpy is in requirements.txt
grep "numpy" backend/requirements.txt

# If not, add it:
echo "numpy>=1.24.0" >> backend/requirements.txt
```

**Required for:**
- `numpy` - Cosine similarity calculation in deduplication

**Flutter Dependencies to Check:**

```yaml
# pubspec.yaml should have:
dependencies:
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  web_socket_channel: ^2.4.0

dev_dependencies:
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

**Steps:**
1. Check backend requirements.txt for numpy
2. Add if missing
3. Run `pip install -r requirements.txt`
4. Check Flutter pubspec.yaml for all packages
5. Add if missing
6. Run `flutter pub get`
7. Verify no dependency conflicts

**Acceptance Criteria:**
- [ ] All backend dependencies are in requirements.txt
- [ ] All Flutter dependencies are in pubspec.yaml
- [ ] `pip install -r requirements.txt` succeeds
- [ ] `flutter pub get` succeeds
- [ ] No version conflicts

**Blockers:** None

**Dependencies:** None

---

### C5. Integrate with Recording Flow
**Priority:** 🔴 CRITICAL
**Estimated Time:** 2-3 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Wire live insights WebSocket service to existing audio recording flow.

**Files to Modify:**

**1. Recording Provider** (`lib/features/audio_recording/presentation/providers/recording_provider.dart`)

```dart
// Add state for live insights
class RecordingStateModel {
  // ... existing fields
  final bool liveInsightsEnabled;
  final String? liveInsightsSessionId;

  RecordingStateModel({
    // ... existing params
    this.liveInsightsEnabled = false,
    this.liveInsightsSessionId,
  });
}

// Add LiveInsightsWebSocketService
@riverpod
class RecordingNotifier extends _$RecordingNotifier {
  LiveInsightsWebSocketService? _liveInsightsService;
  Timer? _audioChunkTimer;

  // Start recording with optional live insights
  Future<void> startRecording({
    required String projectId,
    String? meetingTitle,
    bool enableLiveInsights = false,
  }) async {
    // ... existing code

    if (enableLiveInsights) {
      // Initialize live insights service
      _liveInsightsService = LiveInsightsWebSocketService();
      await _liveInsightsService!.connect(projectId);

      // Start chunking audio every 10 seconds
      _startAudioChunking();

      state = state.copyWith(
        liveInsightsEnabled: true,
        liveInsightsSessionId: _liveInsightsService!.sessionId,
      );
    }
  }

  void _startAudioChunking() {
    _audioChunkTimer?.cancel();
    _audioChunkTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      if (state.state == RecordingState.recording) {
        await _sendAudioChunk();
      }
    });
  }

  Future<void> _sendAudioChunk() async {
    // Get last 10 seconds of audio
    // This requires buffering audio in AudioRecordingService

    // For now, placeholder:
    // TODO: Implement audio buffering and chunking

    final audioData = await _getAudioChunk();
    if (audioData != null && _liveInsightsService != null) {
      await _liveInsightsService!.sendAudioChunk(
        audioData: audioData,
        duration: 10.0,
        speaker: null,
      );
    }
  }

  @override
  void dispose() {
    _audioChunkTimer?.cancel();
    _liveInsightsService?.dispose();
    super.dispose();
  }
}
```

**2. Record Meeting Dialog** (`lib/shared/widgets/record_meeting_dialog.dart`)

```dart
// Add checkbox for live insights
bool _enableLiveInsights = false;

// In build method:
CheckboxListTile(
  title: Text('Enable Live Insights'),
  subtitle: Text('Extract action items, decisions, and risks in real-time'),
  value: _enableLiveInsights,
  onChanged: (value) {
    setState(() {
      _enableLiveInsights = value ?? false;
    });
  },
),

// When starting recording:
await recordingProvider.startRecording(
  projectId: selectedProjectId,
  meetingTitle: titleController.text,
  enableLiveInsights: _enableLiveInsights,
);
```

**3. Add Live Insights Panel to Recording Screen**

Create new file: `lib/features/audio_recording/presentation/screens/recording_screen_with_insights.dart`

```dart
class RecordingScreenWithInsights extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingNotifierProvider);

    return Row(
      children: [
        // Left: Recording controls
        Expanded(
          flex: 2,
          child: RecordingControls(),
        ),

        // Right: Live insights panel
        if (recordingState.liveInsightsEnabled)
          LiveInsightsPanel(
            insights: [], // TODO: Get from provider
            isRecording: recordingState.state == RecordingState.recording,
            onClose: () {
              // Disable live insights
            },
          ),
      ],
    );
  }
}
```

**Steps:**
1. Add live insights toggle to recording state
2. Create LiveInsightsWebSocketService instance in recording provider
3. Implement audio chunking (every 10 seconds)
4. Add checkbox to record meeting dialog
5. Create recording screen with insights panel
6. Wire up insights stream to UI
7. Test end-to-end flow

**Acceptance Criteria:**
- [ ] User can enable/disable live insights when starting recording
- [ ] Audio chunks are sent to backend every 10 seconds
- [ ] Live insights panel appears when enabled
- [ ] Insights appear in real-time as they are extracted
- [ ] Panel closes when recording stops

**Blockers:**
- C1 (code generation must be done first)
- C2 (transcription must work)

**Dependencies:** C1, C2, C3

---

## Important Tasks (Should Fix)

These tasks should be completed before production deployment.

### I1. Add Unit Tests for Backend
**Priority:** 🟡 HIGH
**Estimated Time:** 3-4 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add comprehensive unit tests for backend services.

**Tests to Write:**

**File:** `backend/tests/unit/test_realtime_insights.py`

```python
import pytest
from services.intelligence.realtime_meeting_insights import (
    RealtimeMeetingInsightsService,
    SlidingWindowContext,
    TranscriptChunk,
    MeetingInsight,
    InsightType,
    InsightPriority
)

class TestSlidingWindowContext:
    def test_adds_chunks_correctly(self):
        context = SlidingWindowContext(max_chunks=3)

        chunk1 = TranscriptChunk("id1", "Hello", datetime.now(), 0)
        chunk2 = TranscriptChunk("id2", "World", datetime.now(), 1)

        context.add_chunk(chunk1)
        context.add_chunk(chunk2)

        assert len(context.chunks) == 2
        assert context.chunks[0] == chunk1

    def test_maintains_max_chunks(self):
        context = SlidingWindowContext(max_chunks=2)

        for i in range(5):
            chunk = TranscriptChunk(f"id{i}", f"Text {i}", datetime.now(), i)
            context.add_chunk(chunk)

        assert len(context.chunks) == 2
        assert context.chunks[0].index == 3  # Oldest kept
        assert context.chunks[1].index == 4  # Most recent

    def test_get_context_text(self):
        context = SlidingWindowContext()
        chunk1 = TranscriptChunk("id1", "Hello", datetime.now(), 0, speaker="John")
        chunk2 = TranscriptChunk("id2", "World", datetime.now(), 1, speaker="Jane")

        context.add_chunk(chunk1)
        context.add_chunk(chunk2)

        text = context.get_context_text(include_speakers=True)
        assert "[John]: Hello" in text
        assert "[Jane]: World" in text

class TestRealtimeMeetingInsightsService:
    @pytest.fixture
    def service(self):
        return RealtimeMeetingInsightsService()

    @pytest.mark.asyncio
    async def test_process_transcript_chunk(self, service, mocker):
        # Mock LLM client
        mock_llm = mocker.patch.object(service.llm_client, 'create_message')
        mock_llm.return_value = self._mock_llm_response()

        # Mock embedding service
        mock_embed = mocker.patch('services.rag.embedding_service.generate_embedding')
        mock_embed.return_value = [0.1] * 768

        # Create test chunk
        chunk = TranscriptChunk(
            chunk_id="test_1",
            text="John will send the report by Friday",
            timestamp=datetime.now(),
            index=0,
            speaker="John"
        )

        # Process chunk
        result = await service.process_transcript_chunk(
            session_id="test_session",
            project_id="test_project",
            organization_id="test_org",
            chunk=chunk,
            db=mock_db
        )

        # Assertions
        assert result['session_id'] == "test_session"
        assert result['chunk_index'] == 0
        assert len(result['insights']) > 0
        assert result['insights'][0]['type'] == 'action_item'

    def _mock_llm_response(self):
        return type('obj', (object,), {
            'content': [type('obj', (object,), {
                'text': json.dumps({
                    'insights': [{
                        'type': 'action_item',
                        'priority': 'high',
                        'content': 'John to send report',
                        'assigned_to': 'John',
                        'due_date': '2025-10-22',
                        'confidence': 0.9
                    }]
                })
            })()]
        })()

    @pytest.mark.asyncio
    async def test_semantic_deduplication(self, service, mocker):
        # Mock embedding service
        mock_embed = mocker.patch('services.rag.embedding_service.generate_embedding')

        # Create similar insights
        insight1 = MeetingInsight(
            insight_id="1",
            type=InsightType.ACTION_ITEM,
            priority=InsightPriority.HIGH,
            content="John to review API docs",
            context="",
            timestamp=datetime.now()
        )

        insight2 = MeetingInsight(
            insight_id="2",
            type=InsightType.ACTION_ITEM,
            priority=InsightPriority.HIGH,
            content="John should review the API documentation",
            context="",
            timestamp=datetime.now()
        )

        # First embedding (stored)
        mock_embed.return_value = [0.1] * 768
        session_id = "test"
        service.extracted_insights[session_id] = [insight1]
        service.insight_embeddings[session_id] = [[0.1] * 768]

        # Second embedding (very similar)
        mock_embed.return_value = [0.11] * 768  # Similarity > 0.85

        # Deduplicate
        unique = await service._deduplicate_insights(session_id, [insight2])

        # Should filter out duplicate
        assert len(unique) == 0
```

**File:** `backend/tests/unit/test_prompts.py`

```python
from services.prompts.realtime_insights_prompts import (
    get_realtime_insight_extraction_prompt,
    get_contradiction_detection_prompt
)

def test_realtime_prompt_includes_all_sections():
    prompt = get_realtime_insight_extraction_prompt(
        current_chunk="Test chunk",
        recent_context="Recent context",
        related_discussions=[],
        speaker_info="Speaker: John"
    )

    assert "Current Segment" in prompt
    assert "Recent Conversation Context" in prompt
    assert "Test chunk" in prompt
    assert "Speaker: John" in prompt
    assert "action_item" in prompt.lower()
    assert "decision" in prompt.lower()

def test_prompt_with_related_discussions():
    discussions = [
        {
            'title': 'Past Meeting',
            'snippet': 'We discussed API design',
            'similarity_score': 0.85
        }
    ]

    prompt = get_realtime_insight_extraction_prompt(
        current_chunk="Let's finalize the API",
        recent_context="",
        related_discussions=discussions
    )

    assert "Related Past Discussions" in prompt
    assert "Past Meeting" in prompt
    assert "85%" in prompt or "0.85" in prompt
```

**Steps:**
1. Create test files in `backend/tests/unit/`
2. Write tests for SlidingWindowContext
3. Write tests for RealtimeMeetingInsightsService
4. Write tests for prompt generation
5. Write tests for deduplication logic
6. Run tests: `pytest backend/tests/unit/ -v`
7. Aim for >80% code coverage

**Acceptance Criteria:**
- [ ] All unit tests pass
- [ ] Code coverage >80% for realtime_meeting_insights.py
- [ ] Tests run in <10 seconds
- [ ] No flaky tests

**Blockers:** None

**Dependencies:** None

---

### I2. Add Integration Tests for WebSocket
**Priority:** 🟡 HIGH
**Estimated Time:** 2-3 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add integration tests for WebSocket endpoint and full pipeline.

**File:** `backend/tests/integration/test_websocket_live_insights.py`

```python
import pytest
from fastapi.testclient import TestClient
from main import app
import json

@pytest.fixture
def client():
    return TestClient(app)

def test_websocket_connection(client):
    """Test WebSocket connection establishment"""
    with client.websocket_connect("/ws/live-insights?project_id=test") as websocket:
        # Send init message
        websocket.send_json({"action": "init", "project_id": "test"})

        # Expect session_initialized
        data = websocket.receive_json()
        assert data['type'] == 'session_initialized'
        assert 'session_id' in data

def test_audio_chunk_processing(client, mocker):
    """Test full audio chunk processing pipeline"""
    # Mock transcription service
    mock_transcribe = mocker.patch(
        'services.transcription.replicate_transcription_service.transcribe_audio'
    )
    mock_transcribe.return_value = {'text': 'John will send the report'}

    with client.websocket_connect("/ws/live-insights?project_id=test") as websocket:
        # Init
        websocket.send_json({"action": "init", "project_id": "test"})
        init_msg = websocket.receive_json()

        # Send audio chunk
        import base64
        fake_audio = base64.b64encode(b"fake audio data").decode()
        websocket.send_json({
            "action": "audio_chunk",
            "data": fake_audio,
            "duration": 10.0,
            "speaker": "John"
        })

        # Expect transcript_chunk
        transcript_msg = websocket.receive_json()
        assert transcript_msg['type'] == 'transcript_chunk'

        # Expect insights_extracted
        insights_msg = websocket.receive_json()
        assert insights_msg['type'] == 'insights_extracted'
        assert 'insights' in insights_msg

def test_session_lifecycle(client):
    """Test pause, resume, end flow"""
    with client.websocket_connect("/ws/live-insights?project_id=test") as websocket:
        websocket.send_json({"action": "init", "project_id": "test"})
        websocket.receive_json()  # init

        # Pause
        websocket.send_json({"action": "pause"})
        pause_msg = websocket.receive_json()
        assert pause_msg['type'] == 'session_paused'

        # Resume
        websocket.send_json({"action": "resume"})
        resume_msg = websocket.receive_json()
        assert resume_msg['type'] == 'session_resumed'

        # End
        websocket.send_json({"action": "end"})
        final_msg = websocket.receive_json()
        assert final_msg['type'] == 'session_finalized'
```

**Steps:**
1. Create integration test file
2. Write WebSocket connection test
3. Write audio chunk processing test (with mocked transcription)
4. Write session lifecycle test
5. Write concurrent sessions test
6. Run tests: `pytest backend/tests/integration/ -v`

**Acceptance Criteria:**
- [ ] All integration tests pass
- [ ] Tests cover main WebSocket flows
- [ ] Tests run in <30 seconds
- [ ] Can run in CI/CD pipeline

**Blockers:** C2 (transcription implementation)

**Dependencies:** C2

---

### I3. Add Flutter Widget Tests
**Priority:** 🟡 HIGH
**Estimated Time:** 2 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add widget tests for LiveInsightsPanel.

**File:** `test/features/live_insights/presentation/widgets/live_insights_panel_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('LiveInsightsPanel', () {
    testWidgets('displays insights correctly', (tester) async {
      final insights = [
        MeetingInsight(
          insightId: '1',
          type: InsightType.actionItem,
          priority: InsightPriority.high,
          content: 'Test action item',
          context: 'Test context',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LiveInsightsPanel(
                insights: insights,
                isRecording: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test action item'), findsOneWidget);
      expect(find.text('Live Insights'), findsOneWidget);
    });

    testWidgets('filters work correctly', (tester) async {
      final insights = [
        MeetingInsight(
          insightId: '1',
          type: InsightType.actionItem,
          priority: InsightPriority.high,
          content: 'Action item',
          context: '',
          timestamp: DateTime.now(),
        ),
        MeetingInsight(
          insightId: '2',
          type: InsightType.decision,
          priority: InsightPriority.medium,
          content: 'Decision made',
          context: '',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LiveInsightsPanel(insights: insights),
            ),
          ),
        ),
      );

      // Open filters
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Filter by action_item
      await tester.tap(find.text('action item'));
      await tester.pumpAndSettle();

      // Should only show action item
      expect(find.text('Action item'), findsOneWidget);
      expect(find.text('Decision made'), findsNothing);
    });

    testWidgets('search works correctly', (tester) async {
      final insights = [
        MeetingInsight(
          insightId: '1',
          type: InsightType.actionItem,
          priority: InsightPriority.high,
          content: 'Send email to client',
          context: '',
          timestamp: DateTime.now(),
        ),
        MeetingInsight(
          insightId: '2',
          type: InsightType.actionItem,
          priority: InsightPriority.high,
          content: 'Review code',
          context: '',
          timestamp: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LiveInsightsPanel(insights: insights),
            ),
          ),
        ),
      );

      // Enter search
      await tester.enterText(find.byType(TextField), 'email');
      await tester.pumpAndSettle();

      // Should only show matching insight
      expect(find.text('Send email to client'), findsOneWidget);
      expect(find.text('Review code'), findsNothing);
    });
  });
}
```

**Steps:**
1. Create widget test file
2. Write test for displaying insights
3. Write test for filtering
4. Write test for search
5. Write test for tab switching
6. Run tests: `flutter test`

**Acceptance Criteria:**
- [ ] All widget tests pass
- [ ] Tests cover main UI interactions
- [ ] Tests run in <10 seconds

**Blockers:** C1 (code generation)

**Dependencies:** C1

---

### I4. Add Error Handling
**Priority:** 🟡 HIGH
**Estimated Time:** 2 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add comprehensive error handling for external service failures.

**Locations to Add Error Handling:**

**1. Backend - Qdrant Failures**
```python
# In realtime_meeting_insights.py:_get_related_discussions()

try:
    results = await multi_tenant_vector_store.search(...)
except Exception as e:
    logger.warning(f"Qdrant search failed: {e}")
    # Continue without related discussions
    return []
```

**2. Backend - LLM Failures**
```python
# In realtime_meeting_insights.py:_extract_insights()

try:
    response = await self.llm_client.create_message(...)
    if not response:
        logger.warning("LLM returned empty response")
        return []
except Exception as e:
    logger.error(f"LLM extraction failed: {e}")
    # Return empty insights, don't crash the session
    return []
```

**3. Backend - Transcription Failures**
```python
# In websocket_live_insights.py:handle_audio_chunk()

try:
    result = await replicate_transcription_service.transcribe_audio(...)
    transcript_text = result.get('text', '')
except Exception as e:
    logger.error(f"Transcription failed: {e}")
    await live_insights_manager.send_message(session, {
        'type': 'error',
        'message': 'Transcription service unavailable'
    })
    return
```

**4. Frontend - WebSocket Connection Failures**
```dart
// In live_insights_websocket_service.dart

void _handleError(dynamic error) {
  debugPrint('[LiveInsightsWS] WebSocket error: $error');

  // Determine if error is recoverable
  if (_isRecoverableError(error)) {
    _errorController.add('Connection interrupted, reconnecting...');
    _scheduleReconnect();
  } else {
    _errorController.add('Fatal error: $error. Please restart recording.');
    disconnect();
  }
}

bool _isRecoverableError(dynamic error) {
  // Check if it's a network error vs authentication error
  final errorStr = error.toString().toLowerCase();
  return !errorStr.contains('unauthorized') &&
         !errorStr.contains('forbidden');
}
```

**Steps:**
1. Add try/catch blocks for all external service calls
2. Log errors with context
3. Send user-friendly error messages to frontend
4. Implement graceful degradation (continue with reduced functionality)
5. Test error scenarios manually

**Acceptance Criteria:**
- [ ] Qdrant failures don't crash session
- [ ] LLM failures don't crash session
- [ ] Transcription failures are reported to user
- [ ] WebSocket errors trigger reconnection
- [ ] All errors are logged with context

**Blockers:** None

**Dependencies:** C2, C3

---

### I5. Add Insight Persistence
**Priority:** 🟡 MEDIUM
**Estimated Time:** 2-3 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Store insights in PostgreSQL after session ends for historical access.

**Database Schema:**

Create migration: `backend/alembic/versions/xxx_add_live_insights_table.py`

```python
def upgrade():
    op.create_table(
        'live_meeting_insights',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('session_id', sa.String(255), nullable=False, index=True),
        sa.Column('project_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('insight_type', sa.String(50), nullable=False),
        sa.Column('priority', sa.String(20), nullable=False),
        sa.Column('content', sa.Text, nullable=False),
        sa.Column('context', sa.Text),
        sa.Column('assigned_to', sa.String(255)),
        sa.Column('due_date', sa.String(50)),
        sa.Column('confidence_score', sa.Float),
        sa.Column('chunk_index', sa.Integer),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('metadata', postgresql.JSONB),
    )

    op.create_index(
        'idx_live_insights_project',
        'live_meeting_insights',
        ['project_id', 'created_at']
    )
```

**Backend Implementation:**

```python
# In realtime_meeting_insights.py:finalize_session()

async def finalize_session(self, session_id: str, db: AsyncSession) -> Dict[str, Any]:
    # ... existing code ...

    # Persist insights to database
    try:
        for insight in insights:
            db_insight = LiveMeetingInsightModel(
                id=uuid.uuid4(),
                session_id=session_id,
                project_id=project_id,
                organization_id=organization_id,
                insight_type=insight.type.value,
                priority=insight.priority.value,
                content=insight.content,
                context=insight.context,
                assigned_to=insight.assigned_to,
                due_date=insight.due_date,
                confidence_score=insight.confidence_score,
                chunk_index=insight.source_chunk_index,
                metadata={'related_content_ids': insight.related_content_ids}
            )
            db.add(db_insight)

        await db.commit()
        logger.info(f"Persisted {len(insights)} insights to database")
    except Exception as e:
        logger.error(f"Failed to persist insights: {e}")
        await db.rollback()
```

**API Endpoint:**

```python
# backend/routers/live_insights.py (new file)

@router.get("/api/v1/projects/{project_id}/live-insights")
async def get_live_insights(
    project_id: str,
    session_id: Optional[str] = None,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get historical live insights for a project"""
    query = select(LiveMeetingInsightModel).where(
        LiveMeetingInsightModel.project_id == project_id
    )

    if session_id:
        query = query.where(LiveMeetingInsightModel.session_id == session_id)

    query = query.order_by(LiveMeetingInsightModel.created_at.desc()).limit(limit)

    result = await db.execute(query)
    insights = result.scalars().all()

    return {'insights': [insight.to_dict() for insight in insights]}
```

**Steps:**
1. Create database migration
2. Run migration: `alembic upgrade head`
3. Add persistence logic to finalize_session()
4. Create API endpoint to retrieve historical insights
5. Test persistence and retrieval

**Acceptance Criteria:**
- [ ] Insights are stored in PostgreSQL after session ends
- [ ] API endpoint returns historical insights
- [ ] Insights are filterable by session_id
- [ ] Database indexes are created for performance

**Blockers:** None

**Dependencies:** None

---

## Nice to Have Tasks (Can Do Later)

These tasks improve the feature but aren't blocking for MVP.

### N1. Add Performance Monitoring
**Priority:** 🟢 LOW
**Estimated Time:** 2 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add structured logging and metrics collection.

**Implementation:**

```python
# In realtime_meeting_insights.py

import time
from utils.metrics import track_metric

async def process_transcript_chunk(self, ...):
    start_time = time.time()

    try:
        # ... existing code ...

        processing_time = time.time() - start_time

        # Track metrics
        track_metric('live_insights.processing_time', processing_time)
        track_metric('live_insights.chunk_processed', 1)
        track_metric(f'live_insights.insights_extracted.{insight.type.value}', 1)

    except Exception as e:
        track_metric('live_insights.errors', 1)
        raise
```

**Metrics to Track:**
- `live_insights.processing_time` - Histogram
- `live_insights.chunk_processed` - Counter
- `live_insights.insights_extracted.{type}` - Counter
- `live_insights.deduplication_rate` - Gauge
- `live_insights.websocket_connections` - Gauge
- `live_insights.errors` - Counter

**Steps:**
1. Add metrics tracking library (prometheus-client)
2. Add metric tracking to key points
3. Create Grafana dashboard
4. Set up alerts for anomalies

**Acceptance Criteria:**
- [ ] Key metrics are tracked
- [ ] Metrics are exportable to Prometheus
- [ ] Grafana dashboard created
- [ ] Alerts configured for errors

**Blockers:** None

**Dependencies:** None

---

### N2. Add Performance Testing
**Priority:** 🟢 LOW
**Estimated Time:** 3-4 hours
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Load test and stress test the live insights feature.

**Load Test Script:**

```python
# backend/tests/performance/test_load.py

import asyncio
import websockets
import json
import time
from concurrent.futures import ThreadPoolExecutor

async def simulate_session(session_num: int):
    """Simulate a single live insights session"""
    uri = "ws://localhost:8000/ws/live-insights?project_id=test"

    start_time = time.time()

    async with websockets.connect(uri) as websocket:
        # Init
        await websocket.send(json.dumps({"action": "init", "project_id": "test"}))
        await websocket.recv()

        # Send 10 audio chunks
        for i in range(10):
            await websocket.send(json.dumps({
                "action": "audio_chunk",
                "data": "fake_audio_base64",
                "duration": 10.0
            }))

            # Receive responses
            await websocket.recv()  # transcript
            await websocket.recv()  # insights

            await asyncio.sleep(1)  # Simulate real-time

        # End
        await websocket.send(json.dumps({"action": "end"}))
        await websocket.recv()

    duration = time.time() - start_time
    print(f"Session {session_num} completed in {duration:.2f}s")
    return duration

async def load_test(num_sessions: int):
    """Run load test with N concurrent sessions"""
    tasks = [simulate_session(i) for i in range(num_sessions)]
    results = await asyncio.gather(*tasks)

    avg_duration = sum(results) / len(results)
    max_duration = max(results)

    print(f"\nLoad Test Results ({num_sessions} sessions):")
    print(f"  Average duration: {avg_duration:.2f}s")
    print(f"  Max duration: {max_duration:.2f}s")

if __name__ == "__main__":
    # Test with 10 concurrent sessions
    asyncio.run(load_test(10))
```

**Tests to Run:**
1. 10 concurrent sessions
2. 50 concurrent sessions
3. 100 concurrent sessions
4. Measure latency at each level

**Steps:**
1. Create load test script
2. Run with 10, 50, 100 concurrent sessions
3. Measure latency and throughput
4. Identify bottlenecks
5. Optimize if needed

**Acceptance Criteria:**
- [ ] Can handle 50 concurrent sessions with <5s latency
- [ ] No memory leaks during sustained load
- [ ] CPU usage is reasonable (<80%)
- [ ] Database connections don't leak

**Blockers:** C2, C3, C4, C5

**Dependencies:** All critical tasks

---

### N3. Add Rate Limiting
**Priority:** 🟢 LOW
**Estimated Time:** 1 hour
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Add rate limiting to prevent abuse.

**Implementation:**

```python
# backend/routers/websocket_live_insights.py

from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.websocket("/live-insights")
@limiter.limit("10/minute")  # Max 10 audio chunks per minute
async def websocket_live_insights(...):
    # ... existing code ...
```

**Rate Limits:**
- Audio chunks: 10 per minute per IP
- WebSocket connections: 5 active per user
- Total sessions: 1000 globally

**Steps:**
1. Add slowapi dependency
2. Add rate limiting decorator
3. Configure limits
4. Test rate limiting

**Acceptance Criteria:**
- [ ] Rate limiting works correctly
- [ ] User receives clear error message when rate limited
- [ ] Rate limits are configurable via environment variables

**Blockers:** None

**Dependencies:** None

---

### N4. Add Input Validation
**Priority:** 🟢 MEDIUM
**Estimated Time:** 1 hour
**Assignee:** TBD
**Status:** ❌ Not Started

**Description:**
Validate all input data from WebSocket messages.

**Implementation:**

```python
from pydantic import BaseModel, Field, validator

class AudioChunkMessage(BaseModel):
    action: str = Field(..., regex="^audio_chunk$")
    data: str = Field(..., min_length=1, max_length=10_000_000)  # 10MB max
    duration: float = Field(..., gt=0, le=60)  # 0-60 seconds
    speaker: Optional[str] = Field(None, max_length=255)

    @validator('data')
    def validate_base64(cls, v):
        import base64
        try:
            base64.b64decode(v)
        except Exception:
            raise ValueError('Invalid base64 data')
        return v

# In WebSocket handler
try:
    validated = AudioChunkMessage(**data)
except ValidationError as e:
    await send_error(client_id, f"Invalid message: {e}")
    return
```

**Validations to Add:**
- Audio data is valid base64
- Audio size < 10MB
- Duration is 0-60 seconds
- Project ID is valid UUID
- Speaker name < 255 characters

**Steps:**
1. Create Pydantic models for all message types
2. Add validation in WebSocket handler
3. Return clear error messages
4. Test with invalid inputs

**Acceptance Criteria:**
- [ ] Invalid base64 is rejected
- [ ] Oversized audio is rejected
- [ ] Invalid UUIDs are rejected
- [ ] Clear error messages returned

**Blockers:** None

**Dependencies:** None

---

## Testing Checklist

### Manual Testing

**Before marking feature as complete, test:**

- [ ] **Basic Flow**
  - [ ] Start recording with live insights enabled
  - [ ] Speak into microphone
  - [ ] See transcript chunks appear
  - [ ] See insights appear in panel
  - [ ] Stop recording
  - [ ] See final summary

- [ ] **Search & Filters**
  - [ ] Search for specific keywords
  - [ ] Filter by insight type
  - [ ] Filter by priority
  - [ ] Clear filters

- [ ] **Tab Switching**
  - [ ] Switch to "By Type" tab
  - [ ] Switch to "Timeline" tab
  - [ ] Switch back to "All" tab

- [ ] **Session Management**
  - [ ] Pause recording
  - [ ] Resume recording
  - [ ] End session

- [ ] **Error Handling**
  - [ ] Disconnect WiFi (test reconnection)
  - [ ] Invalid project ID (test error message)
  - [ ] Backend down (test graceful degradation)

- [ ] **Performance**
  - [ ] Test with 30-minute recording
  - [ ] Verify latency is <5 seconds
  - [ ] Check memory usage doesn't grow unbounded

### Automated Testing

- [ ] All backend unit tests pass
- [ ] All backend integration tests pass
- [ ] All Flutter widget tests pass
- [ ] Code coverage >70%

---

## Pre-Production Checklist

Before deploying to production:

### Code Quality
- [ ] Code review completed
- [ ] All tests passing
- [ ] Code coverage >70%
- [ ] No critical security issues (run `bandit` on Python code)
- [ ] No linting errors (`flutter analyze`, `flake8`)

### Documentation
- [ ] API documentation updated
- [ ] User guide created
- [ ] Developer setup instructions
- [ ] Troubleshooting guide

### Security
- [ ] Authentication implemented
- [ ] Authorization checks in place
- [ ] Input validation added
- [ ] Rate limiting configured
- [ ] CORS configured
- [ ] Secrets not hardcoded

### Performance
- [ ] Load tested (50+ concurrent users)
- [ ] Latency validated (<5s)
- [ ] Memory leaks checked
- [ ] Database indexes created

### Monitoring
- [ ] Structured logging in place
- [ ] Metrics collection configured
- [ ] Error tracking (Sentry) enabled
- [ ] Alerts configured

### Deployment
- [ ] Database migration tested
- [ ] Environment variables documented
- [ ] Rollback plan documented
- [ ] Staged deployment (dev → staging → prod)

---

## Task Tracking

### Sprint 1: Core Implementation (Week 1)

| Task | Priority | Estimated | Status | Assignee | Notes |
|------|----------|-----------|--------|----------|-------|
| C1. Flutter Code Generation | 🔴 | 5 min | ❌ | TBD | |
| C2. Real Transcription | 🔴 | 1 hr | ❌ | TBD | Use Replicate |
| C3. Authentication | 🔴 | 2 hrs | ❌ | TBD | JWT validation |
| C4. Dependencies | 🔴 | 30 min | ❌ | TBD | Verify numpy |
| C5. Integration | 🔴 | 3 hrs | ❌ | TBD | Wire to recording |

**Total Estimated Time:** ~6.5 hours

### Sprint 2: Testing & Polish (Week 2)

| Task | Priority | Estimated | Status | Assignee | Notes |
|------|----------|-----------|--------|----------|-------|
| I1. Backend Unit Tests | 🟡 | 4 hrs | ❌ | TBD | >80% coverage |
| I2. Integration Tests | 🟡 | 3 hrs | ❌ | TBD | WebSocket tests |
| I3. Widget Tests | 🟡 | 2 hrs | ❌ | TBD | UI tests |
| I4. Error Handling | 🟡 | 2 hrs | ❌ | TBD | All services |
| I5. Persistence | 🟡 | 3 hrs | ❌ | TBD | PostgreSQL |

**Total Estimated Time:** ~14 hours

### Sprint 3: Production Readiness (Week 3)

| Task | Priority | Estimated | Status | Assignee | Notes |
|------|----------|-----------|--------|----------|-------|
| N1. Monitoring | 🟢 | 2 hrs | ❌ | TBD | Metrics |
| N2. Load Testing | 🟢 | 4 hrs | ❌ | TBD | 50+ concurrent |
| N3. Rate Limiting | 🟢 | 1 hr | ❌ | TBD | Prevent abuse |
| N4. Input Validation | 🟢 | 1 hr | ❌ | TBD | Pydantic models |

**Total Estimated Time:** ~8 hours

---

## Summary

**Total Estimated Time to Production:** 28.5 hours (3.5 weeks at 8 hrs/week)

**Critical Path:**
1. Sprint 1 (6.5 hrs) → Feature works
2. Sprint 2 (14 hrs) → Feature is tested
3. Sprint 3 (8 hrs) → Feature is production-ready

**Current Completion:** 70%
**To MVP (basic functionality):** 6.5 hours (Sprint 1)
**To Production (full quality):** 28.5 hours (All sprints)

---

**Last Updated:** October 19, 2025
**Document Owner:** Development Team
**Next Review:** After Sprint 1 completion
