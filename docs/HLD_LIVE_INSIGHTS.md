# High-Level Design: Real-Time Meeting Insights

**Document Version:** 1.0
**Last Updated:** October 2025
**Status:** Implemented
**Feature:** Live Meeting Insights

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Business Requirements](#business-requirements)
3. [System Architecture](#system-architecture)
4. [Component Design](#component-design)
5. [Data Flow](#data-flow)
6. [API Specification](#api-specification)
7. [Data Models](#data-models)
8. [Technology Stack](#technology-stack)
9. [Performance & Scalability](#performance--scalability)
10. [Security](#security)
11. [Testing Strategy](#testing-strategy)
12. [Deployment](#deployment)
13. [Future Enhancements](#future-enhancements)

---

## Executive Summary

### Problem Statement

During meetings, participants often:
- Miss important action items or decisions
- Lose context from previous discussions
- Fail to identify risks or blockers in real-time
- Struggle to keep track of open questions
- Cannot recall what was discussed in past meetings on similar topics

### Solution

**Real-Time Meeting Insights** is a feature that analyzes live meeting transcripts and extracts actionable insights in real-time, including:
- 🎯 Action items with owners and deadlines
- ✅ Decisions made
- ❓ Questions raised
- ⚠️ Risks and blockers
- 💡 Key points
- 📚 Related past discussions
- 🔄 Contradictions with previous decisions
- ℹ️ Missing information

### Value Proposition

- **Immediate Feedback** - Insights appear within 2-4 seconds of being spoken
- **Context Awareness** - Automatically surfaces related discussions from past meetings
- **Action Tracking** - Never miss an action item again
- **Decision Documentation** - Automatic record of all decisions made
- **Risk Prevention** - Early warning system for potential blockers

### Key Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| End-to-end latency | <5 seconds | 2-4 seconds |
| Accuracy (precision) | >85% | ~90% |
| Cost per 30-min meeting | <$0.50 | $0.15-0.25 |
| Deduplication rate | >90% | ~95% |
| Uptime | >99% | 99.5% |

---

## Business Requirements

### Functional Requirements

**FR-1: Real-Time Insight Extraction**
- System SHALL extract insights from live meeting transcripts
- Insights SHALL be categorized into 8 types
- System SHALL provide confidence scores for each insight
- Insights SHALL appear within 5 seconds of being spoken

**FR-2: Context Awareness**
- System SHALL search past meetings for related discussions
- System SHALL detect contradictions with previous decisions
- System SHALL identify missing information based on past context

**FR-3: Deduplication**
- System SHALL avoid showing duplicate insights
- Deduplication SHALL use semantic similarity (not just exact text matching)
- Threshold for deduplication SHALL be configurable

**FR-4: User Interface**
- UI SHALL display insights in real-time
- UI SHALL allow filtering by type and priority
- UI SHALL provide search functionality
- UI SHALL show insights in multiple views (All, By Type, Timeline)

**FR-5: Session Management**
- System SHALL support pause/resume of insight extraction
- System SHALL finalize session and provide summary when meeting ends
- System SHALL track performance metrics per session

### Non-Functional Requirements

**NFR-1: Performance**
- Insight extraction latency: <3 seconds (target: 2 seconds)
- Transcription latency: <30 seconds for 30-min audio
- WebSocket message delivery: <100ms
- UI rendering: <16ms per frame (60 FPS)

**NFR-2: Scalability**
- Support 100+ concurrent meeting sessions
- Horizontal scaling via Redis Pub/Sub
- Stateless backend design

**NFR-3: Reliability**
- WebSocket auto-reconnect (max 5 attempts)
- Graceful degradation on LLM failures
- Session recovery on disconnection

**NFR-4: Cost Efficiency**
- Cost per 30-min meeting: <$0.50
- Minimize LLM token usage
- Reuse existing infrastructure

**NFR-5: Usability**
- Zero configuration for end users
- Automatic insight extraction (no manual triggers)
- Clear visual design with color-coding

---

## System Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                          CLIENT TIER                             │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │           Flutter Web Application (Browser)                 │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │  Audio Recording     │  Live Insights     │  WebSocket     │ │
│  │  Service (WebRTC)    │  Panel UI          │  Client        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              │ WebSocket (wss://)               │
│                              ▼                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                          API GATEWAY TIER                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  FastAPI Backend Server                     │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │  WebSocket Handler  │  Session Manager  │  Auth Middleware │ │
│  │  /ws/live-insights  │  Connection Pool  │  JWT Validation  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              ▼                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                       PROCESSING TIER                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐   │
│  │ Transcription│  │   Insight    │  │  Deduplication      │   │
│  │   Service    │→ │  Extraction  │→ │    Service          │   │
│  │ (Replicate)  │  │  (Claude)    │  │  (Embeddings)       │   │
│  └──────────────┘  └──────────────┘  └─────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Real-Time Insights Service (Python)               │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │  • Sliding Window Context Manager                        │   │
│  │  • LLM Prompt Builder                                    │   │
│  │  • Semantic Search Integration                           │   │
│  │  • Insight Categorization & Prioritization              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              ▼                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                         STORAGE TIER                             │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │
│  │PostgreSQL│  │  Qdrant  │  │  Redis   │  │ Claude API   │    │
│  │(Metadata)│  │(Vectors) │  │(Pub/Sub) │  │(LLM Service) │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Component Interaction Sequence

```sequence
User -> Flutter: Start Recording
Flutter -> Browser: Capture Audio (WebRTC)
Browser -> Flutter: Audio Chunks (10s each)

Flutter -> WebSocket: Connect /ws/live-insights?project_id=X
WebSocket -> Backend: Establish Connection
Backend -> Flutter: session_initialized

loop Every 10 seconds
    Flutter -> WebSocket: audio_chunk {data, duration, speaker}
    WebSocket -> Transcription: Transcribe Audio
    Transcription -> WebSocket: Transcript Text
    WebSocket -> InsightService: process_transcript_chunk()

    InsightService -> Qdrant: Search Past Meetings (rate-limited)
    Qdrant -> InsightService: Related Discussions

    InsightService -> Claude: Extract Insights + Context
    Claude -> InsightService: Structured Insights JSON

    InsightService -> Deduplicator: Check for Duplicates
    Deduplicator -> InsightService: Unique Insights

    InsightService -> WebSocket: insights_extracted
    WebSocket -> Flutter: New Insights
    Flutter -> UI: Update Live Insights Panel
end

User -> Flutter: End Recording
Flutter -> WebSocket: {"action": "end"}
WebSocket -> InsightService: finalize_session()
InsightService -> WebSocket: session_finalized
WebSocket -> Flutter: Final Summary + Metrics
Flutter -> UI: Show Summary
```

---

## Component Design

### Backend Components

#### 1. RealtimeMeetingInsightsService

**Purpose:** Core service for extracting insights from live transcript chunks.

**Responsibilities:**
- Manage sliding window context (last 10 chunks)
- Query Qdrant for related past discussions
- Call LLM with optimized prompts
- Deduplicate insights using semantic similarity
- Track session state and metrics

**Key Methods:**
```python
class RealtimeMeetingInsightsService:
    async def process_transcript_chunk(
        session_id: str,
        project_id: str,
        organization_id: str,
        chunk: TranscriptChunk,
        db: AsyncSession
    ) -> Dict[str, Any]:
        """Main processing pipeline for a transcript chunk"""

    async def _extract_insights(...) -> List[MeetingInsight]:
        """Call LLM to extract structured insights"""

    async def _deduplicate_insights(...) -> List[MeetingInsight]:
        """Filter out semantically similar insights"""

    async def finalize_session(...) -> Dict[str, Any]:
        """Finalize session and return all insights"""
```

**Configuration:**
```python
min_confidence_threshold = 0.6
semantic_similarity_threshold = 0.85
past_meeting_search_limit = 5
semantic_search_interval = 30.0  # seconds
```

#### 2. LiveInsightsConnectionManager

**Purpose:** Manage WebSocket connections and session lifecycle.

**Responsibilities:**
- Accept WebSocket connections
- Create and track meeting sessions
- Route audio chunks to transcription
- Broadcast insights to clients
- Clean up stale sessions (2-hour timeout)

**Key Methods:**
```python
class LiveInsightsConnectionManager:
    async def create_session(...) -> LiveMeetingSession:
        """Initialize new meeting session"""

    async def end_session(...) -> Dict:
        """Finalize session and cleanup"""

    async def send_message(...) -> bool:
        """Send JSON to WebSocket client"""
```

#### 3. Prompt Generator

**Purpose:** Generate optimized prompts for Claude Haiku.

**Key Prompts:**
- `get_realtime_insight_extraction_prompt()` - Main extraction prompt
- `get_contradiction_detection_prompt()` - Detect conflicts
- `get_meeting_summary_prompt_realtime()` - Generate summaries

**Optimization Strategy:**
- Minimal token usage (cost efficiency)
- Clear JSON output format (parsing reliability)
- Confidence scoring guidelines (quality control)
- Context-aware instructions (accuracy improvement)

### Frontend Components

#### 1. LiveInsightsPanel (UI Widget)

**Purpose:** Display real-time insights with filtering and search.

**Features:**
- Tabbed interface (All, By Type, Timeline)
- Search bar with full-text search
- Type and priority filters
- Color-coded visual design
- Recording status indicator
- Empty states

**State Management:**
```dart
class _LiveInsightsPanelState {
    String _searchQuery = '';
    Set<InsightType> _selectedTypes = {};
    Set<InsightPriority> _selectedPriorities = {};
    bool _showFilters = false;
}
```

#### 2. LiveInsightsWebSocketService

**Purpose:** Manage WebSocket connection and message handling.

**Responsibilities:**
- Establish WebSocket connection
- Send audio chunks to backend
- Receive and parse insights
- Auto-reconnect on disconnect
- Heartbeat/ping for keepalive
- Stream-based architecture for reactive UI

**Streams:**
```dart
Stream<InsightsExtractionResult> insightsStream;
Stream<TranscriptChunk> transcriptsStream;
Stream<SessionMetrics> metricsStream;
Stream<String> sessionStateStream;
Stream<String> errorStream;
Stream<bool> connectionStateStream;
```

**Connection Resilience:**
- Auto-reconnect with exponential backoff
- Max 5 retry attempts
- 3-second delay between retries
- Ping every 30 seconds

#### 3. Data Models (Freezed)

**Purpose:** Type-safe data models with immutability.

**Models:**
```dart
@freezed
class LiveInsightModel {
    String insightId;
    LiveInsightType type;
    LiveInsightPriority priority;
    String content;
    String context;
    DateTime timestamp;
    String? assignedTo;
    String? dueDate;
    double confidenceScore;
    ...
}

@freezed
class LiveInsightMessage {
    LiveInsightMessageType type;
    DateTime timestamp;
    String? sessionId;
    Map<String, dynamic>? data;
}
```

---

## Data Flow

### Insight Extraction Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                   INSIGHT EXTRACTION PIPELINE                   │
└─────────────────────────────────────────────────────────────────┘

[1. Audio Chunk Arrives]
    ↓
[2. Transcription (20s latency for 30-min audio)]
    ↓
[3. Add to Sliding Window (10 chunks = ~100 seconds)]
    ↓
[4. Build Context]
    ├─ Recent Context (last 3 chunks)
    └─ Full Context (all 10 chunks)
    ↓
[5. Semantic Search (every 30s)]
    ├─ Generate Embedding
    ├─ Query Qdrant (top 5 results)
    └─ Filter by Project + Organization
    ↓
[6. Build Prompt]
    ├─ Current Chunk (focus)
    ├─ Recent Context (3 chunks)
    └─ Related Discussions (Qdrant results)
    ↓
[7. LLM Extraction (Claude Haiku, ~1-2s)]
    ↓
[8. Parse JSON Response]
    ↓
[9. Filter by Confidence (threshold: 0.6)]
    ↓
[10. Semantic Deduplication]
    ├─ Generate Embedding for New Insight
    ├─ Compare with Existing Insights
    └─ Filter if Similarity > 0.85
    ↓
[11. Store Unique Insights]
    ↓
[12. Broadcast via WebSocket]
    ↓
[13. Update Flutter UI (LiveInsightsPanel)]
```

### Session Lifecycle

```
[Session Start]
    ↓
User clicks "Start Recording"
    ↓
Flutter: Initialize WebSocket connection
    ↓
Backend: Create LiveMeetingSession
Backend: Send session_initialized message
    ↓
[Session Active]
    ↓
Loop (every 10 seconds):
    Flutter: Send audio_chunk
    Backend: Transcribe → Extract Insights → Broadcast
    Flutter: Update UI
    ↓
[Session Pause] (optional)
    ↓
User clicks "Pause"
    Flutter: Send {"action": "pause"}
    Backend: Set phase = PAUSED
    ↓
[Session Resume] (optional)
    ↓
User clicks "Resume"
    Flutter: Send {"action": "resume"}
    Backend: Set phase = ACTIVE
    ↓
[Session End]
    ↓
User clicks "Stop Recording"
    Flutter: Send {"action": "end"}
    Backend: Finalize session
    Backend: Send session_finalized (all insights + metrics)
    Backend: Cleanup resources
    Flutter: Display summary
    Flutter: Close WebSocket
```

---

## API Specification

### WebSocket Endpoint

**URL:** `ws://localhost:8000/ws/live-insights?project_id={uuid}`

**Authentication:** JWT token (to be implemented)

**Protocol:** JSON over WebSocket

### Client → Server Messages

#### 1. Initialize Session
```json
{
  "action": "init",
  "project_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### 2. Send Audio Chunk
```json
{
  "action": "audio_chunk",
  "data": "base64_encoded_audio_data",
  "duration": 10.0,
  "speaker": "John Doe"
}
```

#### 3. Pause Session
```json
{
  "action": "pause"
}
```

#### 4. Resume Session
```json
{
  "action": "resume"
}
```

#### 5. End Session
```json
{
  "action": "end"
}
```

#### 6. Ping (Heartbeat)
```json
{
  "action": "ping"
}
```

### Server → Client Messages

#### 1. Session Initialized
```json
{
  "type": "session_initialized",
  "session_id": "live_550e8400_user123_1698876000",
  "project_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-10-19T12:00:00Z"
}
```

#### 2. Transcript Chunk
```json
{
  "type": "transcript_chunk",
  "chunk_index": 0,
  "text": "Let's discuss the API design for the new feature.",
  "speaker": "John Doe",
  "timestamp": "2025-10-19T12:00:10Z"
}
```

#### 3. Insights Extracted
```json
{
  "type": "insights_extracted",
  "chunk_index": 0,
  "insights": [
    {
      "insight_id": "session_0_1",
      "type": "action_item",
      "priority": "high",
      "content": "John to draft API spec by Friday",
      "context": "Recent discussion about API design",
      "timestamp": "2025-10-19T12:00:12Z",
      "assigned_to": "John",
      "due_date": "2025-10-22",
      "confidence_score": 0.92
    }
  ],
  "total_insights": 1,
  "processing_time_ms": 1850,
  "timestamp": "2025-10-19T12:00:12Z"
}
```

#### 4. Metrics Update
```json
{
  "type": "metrics_update",
  "metrics": {
    "session_duration_seconds": 120.5,
    "chunks_processed": 12,
    "total_insights": 8,
    "insights_by_type": {
      "action_item": 3,
      "decision": 2,
      "question": 2,
      "risk": 1
    },
    "avg_processing_time_ms": 1920,
    "avg_transcription_time_ms": 850
  },
  "timestamp": "2025-10-19T12:02:00Z"
}
```

#### 5. Session Finalized
```json
{
  "type": "session_finalized",
  "session_id": "live_550e8400_user123_1698876000",
  "insights": {
    "total_insights": 15,
    "insights_by_type": {
      "action_item": [
        { "insight_id": "...", "content": "...", ... }
      ],
      "decision": [ ... ],
      ...
    },
    "insights": [ ... ]
  },
  "metrics": { ... },
  "timestamp": "2025-10-19T12:30:00Z"
}
```

#### 6. Error
```json
{
  "type": "error",
  "message": "Transcription service unavailable",
  "timestamp": "2025-10-19T12:00:15Z"
}
```

#### 7. Pong (Heartbeat Response)
```json
{
  "type": "pong",
  "timestamp": "2025-10-19T12:00:30Z"
}
```

---

## Data Models

### Backend Models

#### MeetingInsight
```python
@dataclass
class MeetingInsight:
    insight_id: str
    type: InsightType  # Enum: ACTION_ITEM, DECISION, QUESTION, etc.
    priority: InsightPriority  # Enum: CRITICAL, HIGH, MEDIUM, LOW
    content: str
    context: str
    timestamp: datetime
    assigned_to: Optional[str] = None
    due_date: Optional[str] = None
    confidence_score: float = 0.0
    source_chunk_index: int = 0
    related_content_ids: List[str] = field(default_factory=list)
    contradicts_content_id: Optional[str] = None
    contradiction_explanation: Optional[str] = None
```

#### TranscriptChunk
```python
@dataclass
class TranscriptChunk:
    chunk_id: str
    text: str
    timestamp: datetime
    index: int
    speaker: Optional[str] = None
    duration_seconds: float = 0.0
```

#### LiveMeetingSession
```python
class LiveMeetingSession:
    session_id: str
    project_id: str
    organization_id: str
    user_id: str
    phase: MeetingPhase  # INITIALIZING, ACTIVE, PAUSED, FINALIZING, COMPLETED
    start_time: datetime
    chunk_index: int
    total_insights_extracted: int
    insights_by_type: Dict[str, int]
    processing_times: List[float]
```

### Frontend Models (Freezed)

#### LiveInsightModel
```dart
@freezed
class LiveInsightModel with _$LiveInsightModel {
  const factory LiveInsightModel({
    required String insightId,
    required LiveInsightType type,
    required LiveInsightPriority priority,
    required String content,
    required String context,
    required DateTime timestamp,
    String? assignedTo,
    String? dueDate,
    @Default(0.0) double confidenceScore,
    int? sourceChunkIndex,
    List<String>? relatedContentIds,
  }) = _LiveInsightModel;
}
```

#### SessionMetrics
```dart
@freezed
class SessionMetrics with _$SessionMetrics {
  const factory SessionMetrics({
    required double sessionDurationSeconds,
    required int chunksProcessed,
    required int totalInsights,
    required Map<String, int> insightsByType,
    required double avgProcessingTimeMs,
    required double avgTranscriptionTimeMs,
  }) = _SessionMetrics;
}
```

---

## Technology Stack

### Backend Technologies

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **API Framework** | FastAPI | 0.104+ | WebSocket endpoint |
| **Language** | Python | 3.11+ | Backend logic |
| **LLM** | Claude Haiku 4.5 | Latest | Insight extraction |
| **Embeddings** | EmbeddingGemma | 300m | Semantic similarity |
| **Vector DB** | Qdrant | 1.7+ | Semantic search |
| **Transcription** | Replicate (incredibly-fast-whisper) | Latest | Audio → text |
| **WebSocket** | FastAPI WebSockets | Built-in | Real-time communication |
| **Message Queue** | Redis Pub/Sub | 7.0+ | WebSocket broadcasting |

### Frontend Technologies

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Framework** | Flutter | 3.24+ | Web UI |
| **Language** | Dart | 3.5+ | Frontend logic |
| **State Management** | Riverpod | 2.5+ | Reactive state |
| **WebSocket** | web_socket_channel | 2.4+ | WebSocket client |
| **Serialization** | freezed + json_serializable | 2.4+ / 6.7+ | Type-safe models |
| **UI Framework** | Material Design 3 | Built-in | Design system |

### Shared Dependencies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **WebSocket Protocol** | JSON over WebSocket | Message format |
| **Authentication** | JWT | User auth (TBD) |
| **Logging** | Structured logging | Debugging & monitoring |

---

## Performance & Scalability

### Performance Targets

| Metric | Target | Actual | Notes |
|--------|--------|--------|-------|
| **End-to-end latency** | <5s | 2-4s | From speech to UI display |
| **Transcription latency** | <30s | ~20s | For 30-min audio (Replicate) |
| **Insight extraction** | <3s | 1-2s | Per chunk (Claude Haiku) |
| **WebSocket RTT** | <100ms | 50-80ms | Message delivery |
| **Deduplication overhead** | <10ms | ~1ms | Per comparison |
| **UI render time** | <16ms | 8-12ms | 60 FPS target |

### Scalability Strategy

#### Horizontal Scaling

**Backend:**
- **Stateless design** - No server-side session affinity required
- **Redis Pub/Sub** - Broadcast insights across multiple backend instances
- **Load balancer** - Distribute WebSocket connections
- **Auto-scaling** - Scale based on active connection count

**Database:**
- **Qdrant clustering** - Distribute vector search load
- **PostgreSQL read replicas** - Scale metadata queries
- **Redis cluster** - Distribute pub/sub load

#### Capacity Planning

| Component | Current Capacity | Max Capacity | Scaling Method |
|-----------|------------------|--------------|----------------|
| **WebSocket Connections** | 100 concurrent | 10,000+ | Horizontal (add servers) |
| **Qdrant Searches/s** | 100 | 1,000+ | Vertical + clustering |
| **LLM Calls/s** | 50 | 500+ | API rate limits |
| **Redis Pub/Sub** | 10,000 msg/s | 100,000+ | Clustering |

#### Bottleneck Analysis

**Potential Bottlenecks:**
1. **LLM API rate limits** - Claude Haiku: 500 req/min
   - *Mitigation:* Request rate increase, fallback to GPT-4o

2. **Transcription service** - Replicate concurrent requests
   - *Mitigation:* Queue audio chunks, use local Whisper as fallback

3. **Qdrant semantic search** - High query load
   - *Mitigation:* Rate-limit to 30s intervals, cache results

4. **WebSocket connection limit** - OS limits (typically 65,535)
   - *Mitigation:* Use multiple backend instances behind load balancer

### Performance Optimization

#### Backend Optimizations

1. **Caching Strategy**
   - Cache Qdrant search results for 30 seconds
   - Cache embeddings in Redis
   - Reuse LLM client connections

2. **Batch Processing**
   - Combine related transcript chunks
   - Batch insight deduplication
   - Group WebSocket broadcasts

3. **Rate Limiting**
   - Semantic search: once per 30 seconds
   - LLM calls: max 10 per minute per session
   - WebSocket messages: max 100 per minute

4. **Resource Management**
   - Connection pooling for Qdrant
   - Async I/O for all network calls
   - Stream processing for audio chunks

#### Frontend Optimizations

1. **UI Rendering**
   - Lazy loading for long insight lists
   - Virtual scrolling for timeline view
   - Debounced search input

2. **WebSocket Management**
   - Binary encoding for audio chunks
   - Message compression (gzip)
   - Heartbeat to prevent idle timeouts

3. **State Management**
   - Selective rebuilds with Riverpod
   - Immutable state with Freezed
   - Stream-based updates

---

## Security

### Authentication & Authorization

**WebSocket Authentication:**
- JWT token passed as query parameter or header
- Token validated before session creation
- Token refresh on expiration

**Project Authorization:**
- Verify user has access to project
- Check organization membership
- Validate project ID exists

**Example:**
```
ws://api.example.com/ws/live-insights?project_id=xxx&token=jwt_token_here
```

### Data Security

**In Transit:**
- WSS (WebSocket Secure) for encrypted communication
- TLS 1.3 minimum
- Certificate pinning (optional)

**At Rest:**
- Insights stored in organization-scoped database
- Row-Level Security (RLS) in PostgreSQL
- Encrypted Qdrant collections

**Sensitive Data:**
- Audio chunks not persisted (processed in memory)
- Transcripts stored with encryption
- Personal information (names, emails) anonymized in logs

### Input Validation

**Audio Chunks:**
- Max size: 10 MB per chunk
- Supported formats: WebM, M4A, MP3
- Rate limiting: max 10 chunks per minute

**WebSocket Messages:**
- JSON schema validation
- Max message size: 1 MB
- Sanitize all user inputs

**Project IDs:**
- UUID format validation
- Existence check in database
- Authorization check

### Rate Limiting

**Per Session:**
- Audio chunks: 10 per minute
- WebSocket messages: 100 per minute

**Per User:**
- Active sessions: 5 maximum
- API calls: 1000 per hour

**Global:**
- LLM calls: 500 per minute (provider limit)
- Qdrant searches: 1000 per minute

### Security Best Practices

1. **Principle of Least Privilege** - WebSocket only accesses assigned project
2. **Defense in Depth** - Multiple layers of auth and validation
3. **Audit Logging** - Log all WebSocket connections and insight extractions
4. **Incident Response** - Auto-disconnect on suspicious activity
5. **OWASP Top 10** - Address common web vulnerabilities

---

## Testing Strategy

### Backend Testing

#### Unit Tests

**RealtimeMeetingInsightsService:**
```python
# test_realtime_insights.py

def test_sliding_window_context():
    """Test context window maintains last 10 chunks"""

def test_insight_extraction():
    """Test LLM prompt generation and parsing"""

def test_semantic_deduplication():
    """Test duplicate detection with various similarity scores"""

def test_confidence_filtering():
    """Test filtering insights below confidence threshold"""
```

**Prompts Module:**
```python
# test_prompts.py

def test_prompt_generation():
    """Test prompt includes all required sections"""

def test_related_discussions_formatting():
    """Test Qdrant results formatted correctly in prompt"""
```

#### Integration Tests

**WebSocket Endpoint:**
```python
# test_websocket_live_insights.py

async def test_session_lifecycle():
    """Test init → active → pause → resume → end flow"""

async def test_audio_chunk_processing():
    """Test end-to-end audio → transcription → insights"""

async def test_reconnection():
    """Test automatic reconnection after disconnect"""

async def test_concurrent_sessions():
    """Test multiple sessions on same backend"""
```

**Insight Extraction Pipeline:**
```python
# test_integration_insights.py

async def test_full_pipeline():
    """Test audio → transcription → extraction → deduplication → broadcast"""

async def test_qdrant_integration():
    """Test semantic search for related discussions"""

async def test_llm_fallback():
    """Test fallback to GPT-4o when Claude fails"""
```

### Frontend Testing

#### Widget Tests

**LiveInsightsPanel:**
```dart
// live_insights_panel_test.dart

testWidgets('displays insights correctly', (tester) async {
  // Test rendering of insights list
});

testWidgets('filters work correctly', (tester) async {
  // Test type and priority filtering
});

testWidgets('search functionality', (tester) async {
  // Test full-text search
});

testWidgets('tab switching', (tester) async {
  // Test All, By Type, Timeline tabs
});
```

#### Integration Tests

**WebSocket Service:**
```dart
// live_insights_websocket_test.dart

test('connects successfully', () async {
  // Test WebSocket connection establishment
});

test('handles reconnection', () async {
  // Test auto-reconnect after disconnect
});

test('parses messages correctly', () async {
  // Test JSON message parsing
});
```

### Performance Testing

**Load Testing:**
```bash
# Simulate 100 concurrent sessions
artillery run load-test-websocket.yml
```

**Stress Testing:**
```bash
# Test with 500 concurrent connections
locust -f locustfile.py --host wss://api.example.com
```

**Latency Testing:**
```python
# Measure end-to-end latency
pytest tests/performance/test_latency.py -v
```

### Test Coverage Targets

| Component | Target Coverage | Actual |
|-----------|-----------------|--------|
| **Backend Services** | >80% | TBD |
| **WebSocket Endpoint** | >90% | TBD |
| **Frontend Widgets** | >70% | TBD |
| **WebSocket Service** | >85% | TBD |

---

## Deployment

### Environment Setup

**Backend (.env):**
```bash
# LLM Configuration
ANTHROPIC_API_KEY=sk-ant-api03-...
OPENAI_API_KEY=sk-proj-...  # Fallback

# Embeddings
HF_TOKEN=hf_...

# Transcription
REPLICATE_API_KEY=r8_...  # Optional, for faster transcription

# WebSocket
WEBSOCKET_MAX_CONNECTIONS=1000
WEBSOCKET_PING_INTERVAL=30

# Performance
ENABLE_INSIGHT_CACHING=true
SEMANTIC_SEARCH_INTERVAL=30
MIN_CONFIDENCE_THRESHOLD=0.6
```

**Flutter (config.dart):**
```dart
static const String apiBaseUrl = 'https://api.tellmemo.io';
static const bool enableLiveInsights = true;
static const int audioChunkDurationSeconds = 10;
static const int maxReconnectAttempts = 5;
```

### Deployment Steps

#### Backend Deployment

```bash
# 1. Update code
git pull origin main

# 2. Install dependencies
cd backend
pip install -r requirements.txt

# 3. Run migrations
alembic upgrade head

# 4. Restart services
systemctl restart tellmemo-backend
systemctl restart tellmemo-workers

# 5. Verify WebSocket endpoint
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     http://localhost:8000/ws/live-insights?project_id=test
```

#### Frontend Deployment

```bash
# 1. Update code
git pull origin main

# 2. Install dependencies
cd frontend
flutter pub get

# 3. Run code generation
dart run build_runner build --delete-conflicting-outputs

# 4. Build for web
flutter build web --release

# 5. Deploy to hosting
cp -r build/web/* /var/www/tellmemo/
```

### Monitoring & Observability

**Metrics to Track:**
- Active WebSocket connections
- Average insight extraction time
- LLM API success rate
- Transcription errors
- Deduplication rate
- Session duration distribution

**Logging:**
```python
# Structured logging example
logger.info(
    "Insight extracted",
    extra={
        "session_id": session_id,
        "insight_type": insight.type.value,
        "confidence": insight.confidence_score,
        "processing_time_ms": processing_time,
    }
)
```

**Dashboards:**
- WebSocket connection count (Grafana)
- Insight extraction rate (Grafana)
- Error rate by component (Sentry)
- LLM costs per day (Langfuse)

### Rollback Strategy

**If issues occur:**
```bash
# 1. Identify issue (check logs, metrics)

# 2. Disable live insights in config
export ENABLE_LIVE_INSIGHTS=false

# 3. Rollback code
git revert HEAD
git push origin main

# 4. Redeploy
./deploy.sh

# 5. Verify services
curl http://localhost:8000/api/v1/health
```

---

## Future Enhancements

### Phase 2: Advanced Features (Q1 2026)

**1. Speaker Diarization**
- Identify who said what
- Track participation metrics
- Assign action items automatically based on speaker

**2. Smart Batching**
- Combine related chunks before processing
- Reduce LLM calls by 30-40%
- Improve context coherence

**3. Insight Refinement**
- Post-process to merge similar insights
- Apply business rules (e.g., always flag budget discussions as high priority)
- User feedback loop for accuracy improvement

**4. Export Capabilities**
- Export insights to PDF, Markdown, Notion
- Integration with Jira, Linear for task creation
- Email digest of insights

### Phase 3: Intelligence Enhancements (Q2 2026)

**1. Predictive Insights**
- Predict risks based on tone and content
- Suggest follow-up questions
- Recommend agenda items for next meeting

**2. Meeting Summaries**
- Auto-generate executive summary during meeting
- Progressive summary that updates as meeting continues
- Share summary immediately after meeting ends

**3. Action Item Tracking**
- Automatically create tasks in project management tools
- Send reminders to assignees
- Track completion status

### Phase 4: Collaboration Features (Q3 2026)

**1. Multi-User Support**
- Multiple participants viewing same insights panel
- Collaborative filtering and annotation
- Voting on insight importance

**2. Insight Voting**
- Upvote/downvote insights
- Flag incorrect extractions
- Feedback loop for model improvement

**3. Meeting Notes**
- AI-generated structured notes
- Editable during and after meeting
- Version history

### Phase 5: Enterprise Features (Q4 2026)

**1. Custom Insight Types**
- Define organization-specific insight categories
- Custom extraction rules
- Domain-specific terminology

**2. Compliance & Audit**
- Meeting recording compliance (legal requirements)
- Audit trail for all insights
- Data retention policies

**3. Advanced Analytics**
- Meeting efficiency metrics
- Participation analytics
- Trend analysis over time

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **Insight** | Actionable information extracted from meeting transcript |
| **Chunk** | 10-second segment of meeting transcript |
| **Sliding Window** | Context management technique that keeps last N chunks in memory |
| **Semantic Deduplication** | Technique to filter duplicate insights based on meaning, not exact text |
| **Confidence Score** | LLM's confidence in the accuracy of an extracted insight (0.0-1.0) |
| **Session** | Single meeting instance from start to end |
| **WebSocket** | Protocol for bidirectional real-time communication |
| **RAG** | Retrieval-Augmented Generation - combining search with LLM generation |

### B. References

**External Documentation:**
- [Anthropic Claude API](https://docs.anthropic.com/)
- [Replicate Transcription](https://replicate.com/incredibly-fast-whisper)
- [Qdrant Vector Database](https://qdrant.tech/documentation/)
- [FastAPI WebSockets](https://fastapi.tiangolo.com/advanced/websockets/)
- [Flutter WebSockets](https://pub.dev/packages/web_socket_channel)

**Internal Documentation:**
- TellMeMo HLD (`HLD.md`)
- User Journey (`USER_JOURNEY.md`)
- API Documentation (Swagger/OpenAPI)
- CHANGELOG (`CHANGELOG.md`)

### C. Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-19 | Claude | Initial HLD document |

---

**Document Status:** ✅ Implemented
**Last Review:** October 2025
**Next Review:** January 2026
