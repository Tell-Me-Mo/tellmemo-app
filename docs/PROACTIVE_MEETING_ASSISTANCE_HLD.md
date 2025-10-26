# TellMeMo Real-Time Meeting Intelligence System
## High-Level Design Document

**Version:** 1.0  
**Date:** October 2025  
**Status:** Design Phase

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose
This document describes the high-level architecture for TellMeMo's real-time meeting intelligence system that automatically detects questions, finds answers, and tracks action items during live meetings.

### 1.2 Scope
The system provides:
- Real-time question detection with **four-tier answer discovery** (RAG → Meeting Context → Live Monitoring → GPT-Generated)
- Automatic action item extraction and tracking
- Progressive UI updates via streaming architecture with clear answer source attribution
- Post-meeting summaries with actionable insights

### 1.3 Key Benefits
- **Time Savings**: 3-5 minutes per meeting through automated answer discovery
- **Information Retention**: No questions or action items slip through
- **Knowledge Surfacing**: Institutional knowledge automatically presented when relevant
- **Meeting Continuity**: References to earlier discussion prevent repetition

### 1.4 Success Metrics
- Question answer rate: 90%+ (across all four tiers, including GPT-generated fallback)
- Answer source clarity: 100% of answers must clearly indicate their source
- Action item detection accuracy: 90%+
- Latency to first result: <500ms
- Cost per meeting: <$0.18 (with GPT-5-mini efficiency gains + Tier 4 generation)
- User satisfaction: 80%+ find results helpful
- GPT-generated answer usage: <15% of total questions (should be rare fallback)

---

## 2. SYSTEM OVERVIEW

### 2.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     Client Layer                         │
│                  (Flutter Mobile App)                    │
│                                                          │
│  ┌──────────────────────────────────────────┐          │
│  │       Recording Right Panel              │          │
│  │  ┌────────────────────────────────────┐  │          │
│  │  │  Recording Controls & Status       │  │          │
│  │  │  Audio Capture (PCM 16kHz mono)    │  │          │
│  │  └────────────────────────────────────┘  │          │
│  │  ┌────────────────────────────────────┐  │          │
│  │  │  AI Assistant (when enabled)       │  │          │
│  │  │  - Questions Cards                 │  │          │
│  │  │  - Actions Cards                   │  │          │
│  │  └────────────────────────────────────┘  │          │
│  └──────────────────────────────────────────┘          │
└───────────────────────┬──────────────────────────────────┘
                        │ WebSocket (Binary Audio + JSON Events)
                        │
┌───────────────────────▼──────────────────────────────────┐
│                   API Gateway Layer                      │
│                 (WebSocket Server)                       │
│                                                          │
│  - Audio reception (binary frames)                       │
│  - Connection management & state sync                    │
│  - Authentication                                        │
│  - Message routing                                       │
└───┬───────────────────────────────┬──────────────────────┘
    │                               │
    │ Audio Stream            JSON Events
    │                               │
┌───▼───────────────────────┐  ┌───▼──────────────────────┐
│   AssemblyAI Service      │  │  Intelligence Layer      │
│   (Real-Time STT)         │  │                          │
│                           │  │  ┌────────────────────┐  │
│  - Speaker diarization    │  │  │  Transcription     │  │
│  - Partial transcripts◄───┼──┼──┤  Buffer (60s)      │  │
│  - Final transcripts      │  │  └────────┬───────────┘  │
└───────────────────────────┘  │           │              │
                               │  ┌────────▼───────────┐  │
                               │  │  GPT-5-mini        │  │
                               │  │  (Streaming NDJSON)│  │
                               │  └────────┬───────────┘  │
                               │           │              │
                               │  ┌────────▼───────────┐  │
                               │  │  Stream Router     │  │
                               │  └────────┬───────────┘  │
                               │           │              │
                               │  ┌────────┴───────────┐  │
                               │  │  Question │ Action │  │
                               │  │  Handler  │ Handler│  │
                               │  │           │ Answer │  │
                               │  │           │ Handler│  │
                               │  └────────────────────┘  │
                               │                          │
                               │  Parallel Services:      │
                               │  ┌──────────────────┐   │
                               │  │ RAG Search       │   │
                               │  │ Meeting Context  │   │
                               │  │ GPT Generator    │   │
                               │  └──────────────────┘   │
                               └──────────────────────────┘
                                          │
┌─────────────────────────────────────────▼─────────────────┐
│                   Data Layer                              │
│                                                           │
│  ┌────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Redis    │  │ PostgreSQL  │  │  Vector Store   │  │
│  │  (Hot      │  │(Persistent  │  │  (RAG/Docs)     │  │
│  │   State)   │  │  + Speaker) │  │                 │  │
│  └────────────┘  └─────────────┘  └─────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### 2.1.1 Audio Streaming Architecture

**Flutter → Backend Flow:**
1. Capture audio: PCM 16kHz, 16-bit, mono
2. Chunk audio: 100-200ms chunks (1600-3200 bytes)
3. Send via WebSocket binary frames
4. Backend buffers and forwards to AssemblyAI

**AssemblyAI → Intelligence Flow:**
1. Real-time transcription (partial + final)
2. Speaker diarization (Speaker A, B, C...)
3. Final transcripts → Transcription Buffer
4. Transcription Buffer → GPT-5-mini streaming

**GPT Streaming Output:**
- Newline-delimited JSON (NDJSON)
- Objects: {type: "question"|"action"|"answer", ...}
- Stream Router parses and routes to handlers

### 2.2 Core Design Principles

**Streaming-First**
- All processing happens in real-time with immediate results
- No batching delays or waiting for complete responses
- Progressive disclosure of information as it arrives

**Simplicity**
- Single AI model (GPT-5-mini) handles all intelligence
- Minimal state management (only transcript buffer)
- Linear data flow with no complex state machines

**Parallel Processing**
- Question answering tiers run concurrently
- RAG search and GPT analysis happen simultaneously
- Multiple streams converge at the UI

**Graceful Degradation**
- System continues operating if any tier fails
- Partial results always shown to user
- No blocking on external service calls


---

## 3. FUNCTIONAL REQUIREMENTS

### 3.1 Question Detection & Answering

**FR-Q1: Real-Time Question Detection**
- System shall detect questions as they are spoken
- Detection latency shall be <500ms from transcription completion
- Questions shall be classified by type: factual, opinion, action-seeking, clarification

**FR-Q2: Four-Tier Answer Discovery**

**Tier 1: Knowledge Base Search (RAG)**
- Search organization's document repository (RAG)
- Return top 3-5 relevant documents
- Stream results progressively as found
- Timeout: 2 seconds maximum
- Display with "📚 From Documents" label

**Tier 2: Meeting Context Search**
- Search earlier in the current meeting transcript
- Identify if question was already answered
- Provide timestamp for reference
- Timeout: 1.5 seconds maximum
- Display with "💬 Earlier in Meeting" label

**Tier 3: Live Conversation Monitoring**
- Monitor subsequent conversation for answers
- Duration: 15 seconds after question detection
- Match answers semantically to questions
- Mark resolved when confident answer detected
- Display with "👂 Answered Live" label

**Tier 4: GPT-Generated Answer (Fallback)**
- Trigger only when Tiers 1-3 fail to find answers
- GPT-5-mini generates answer based on general knowledge
- Include confidence score (>70% threshold)
- Add prominent disclaimer: "AI-generated, not from documents or meeting"
- Timeout: 3 seconds maximum
- Display with "🤖 AI Answer" label and warning badge

**FR-Q3: Answer Presentation**
- Display results progressively as each tier completes
- Prioritize: RAG results > Meeting context > Live monitoring > GPT-generated
- **Clear source attribution:** Each answer must indicate its source (documents/meeting/live/AI)
- For GPT-generated answers: Show disclaimer badge and confidence score
- Provide actionable links (documents, timestamps)
- Allow user to mark as answered or needs follow-up

### 3.2 Action Item Tracking

**FR-A1: Action Detection**
- Detect commitments, tasks, and assignments in conversation
- Identify action verbs and commitment phrases
- Extract structured information: description, owner, deadline
- Show tracking badge immediately upon detection

**FR-A2: Action Accumulation**
- Merge related statements into single action items
- Update action details as more information emerges
- Track completeness: clarity, assignability, timeline
- Support cross-reference resolution (pronouns, implicit subjects)

**FR-A3: Action Alerting**
- Alert only at natural meeting breakpoints (segment transitions, meeting end)
- Prompt for missing critical information (owner, deadline)
- Prioritize high-confidence, incomplete actions
- Avoid alert fatigue through intelligent timing

**FR-A4: Meeting Summary**
- Generate comprehensive action item list at meeting end
- Indicate completeness level for each action
- Highlight unassigned or unclear items
- Provide export to task management systems

### 3.3 User Interface

**FR-U1: Recording Panel Integration**
- Add toggle for "AI Assistant" feature in existing recording right panel
- When enabled, questions and actions cards appear directly within the recording panel
- Questions and actions sections are stacked vertically below recording controls
- Minimize screen real estate when inactive (collapsed cards)
- Expandable cards for detailed view
- Non-blocking, dismissible alerts

**FR-U2: Question Display**
- Show question text, speaker, timestamp
- Progressive display of search results from all four tiers
- **Clear source labeling:**
  - RAG results: "📚 From Documents" with document names
  - Meeting context: "💬 Earlier in Meeting" with timestamp link
  - Live monitoring: "👂 Answered Live" with conversation excerpt
  - GPT-generated: "🤖 AI Answer" with disclaimer badge and confidence score
- Status indicators: searching, found, monitoring, unanswered
- Visual distinction for each answer source (colors, icons, borders)
- User actions: mark as answered, needs follow-up, dismiss

**FR-U3: Action Item Display**
- Show action description with completeness indicator
- Display owner and deadline when available
- Badge color coding: green (complete), yellow (partial), gray (tracking)
- User actions: assign, set deadline, mark complete, dismiss

**FR-U4: Real-Time Updates**
- Update UI within 100ms of receiving new information
- Smooth animations for state transitions
- Preserve user scroll position during updates
- Handle rapid updates without UI flicker

---


---

## 4. DETAILED COMPONENT DESIGN

### 4.1 Client Layer (Flutter App)

**5.1.1 Recording Right Panel**
- Existing panel component that displays recording controls and status
- Manages audio recording and transcription
- Sends transcription chunks via WebSocket
- **Extended to include AI Assistant toggle and content area**
- When AI Assistant is enabled, displays questions and actions cards directly within the panel
- Maintains existing recording functionality alongside AI features

**5.1.2 AI Assistant Content Section**
- New content section rendered within the recording right panel
- Displays questions and actions as cards in separate sections
- Only visible when AI Assistant toggle is enabled
- Supports expand/collapse, scroll, dismiss interactions
- Updates reactively based on WebSocket events
- Integrated seamlessly with recording controls in the same panel

**5.1.3 WebSocket Client**
- Maintains persistent bidirectional connection
- Sends: transcription chunks, user feedback
- Receives: questions, actions, answers, updates
- Auto-reconnection with exponential backoff

**5.1.4 State Management**
- Maintains list of active questions and actions
- Updates state based on streaming events
- Persists state locally for offline viewing
- Minimal state (no complex business logic)

### 4.2 API Gateway Layer

**5.2.1 WebSocket Server**
- Handles WebSocket connections per meeting
- Authenticates users via JWT tokens
- Routes messages between client and processing layer
- Implements rate limiting and connection pooling

**5.2.2 Connection Manager**
- Tracks active connections per meeting
- Implements heartbeat mechanism (30-second interval)
- Handles disconnection and reconnection
- Broadcasts updates to all participants in same meeting

**5.2.3 Authentication Service**
- Validates JWT tokens on connection
- Integrates with OAuth providers (Google, Microsoft)
- Enforces user permissions per meeting
- Session management and token refresh

### 4.3 Intelligence Processing Layer

**5.3.1 Streaming Intelligence Engine**

**Transcription Buffer**
- Maintains rolling window of last 60 seconds
- Timestamps each sentence for reference
- Trims old content automatically
- Provides formatted context for GPT

**GPT Streaming Interface**
- Sends transcription context to GPT-5-mini API
- Leverages GPT-5-mini's optimized streaming architecture:
  - Lower first-token latency (<200ms typical)
  - More consistent token-per-second rate
  - Better structured JSON output stability
- Enables streaming mode for real-time responses
- Parses newline-delimited JSON objects from stream
- Handles incomplete JSON and stream interruptions with GPT-5-mini's improved error recovery

**Stream Router**
- Receives objects from GPT stream
- Routes to appropriate handler based on object type
- Maintains mapping of question/action IDs to state
- Sends updates to WebSocket clients immediately

**5.3.2 Question Handler**
- Processes question detection events from GPT
- Triggers parallel RAG and meeting context searches
- Manages question lifecycle (searching → answered/unanswered)
- Aggregates results from multiple sources

**5.3.3 Action Handler**
- Processes action and action_update events from GPT
- Maintains active action state
- Calculates completeness scores
- Generates alerts at segment boundaries

**5.3.4 Answer Handler**
- Processes answer events from GPT (live conversation)
- Matches answers to active questions
- Updates question status and removes from tracking
- Sends resolution updates to clients

**5.3.5 RAG Search Service**
- Receives search queries from Question Handler
- Queries vector database for relevant documents
- Streams results back as they're found
- Ranks by relevance and returns top 5

**5.3.6 Meeting Context Search Service**
- Searches current meeting transcript for answers
- Uses GPT-5-mini for semantic search with enhanced understanding:
  - Better implicit reference detection
  - Improved semantic matching between questions and answers
  - More accurate speaker attribution
- Returns exact quotes with speaker and timestamp
- Faster processing: timeout after 1.2 seconds (vs 1.5s with GPT-4o-mini)
- Higher accuracy in identifying relevant passages

**5.3.7 Segment Detector**
- Identifies natural meeting breakpoints
- Heuristics: long pauses, transition phrases, time intervals
- Triggers action item review at segment end
- Signals meeting end for summary generation

### 4.4 Data Layer

**5.4.1 Redis (Hot State)**
- Stores meeting transcript buffer (TTL: meeting duration + 2 hours)
- Caches active questions and actions per meeting
- Stores user preferences (TTL: 7 days)
- Provides pub/sub for multi-instance coordination

**5.4.2 PostgreSQL (Persistent Storage)**

**Meetings Table**
- Meeting metadata: ID, user, start/end time, participants
- Summary statistics: total questions, resolved, actions, etc.
- Meeting type classification (if applicable)

**Questions Table**
- Question text, speaker, timestamp, type, priority
- Resolution status: answered, unanswered, dismissed
- Answer source: RAG, meeting context, live conversation, GPT-generated
- Answer confidence score (for GPT-generated answers)
- User feedback: helpful, false positive

**Actions Table**
- Action description, owner, deadline, detected timestamp
- Completeness score and missing information
- Segment ID for context
- Post-meeting status: pending, in progress, completed

**User Preferences Table**
- Alert sensitivity settings
- Notification style preferences
- Auto-assignment rules
- Feature enablement flags

**5.4.3 Vector Store (RAG)**
- Document embeddings for semantic search
- Metadata: title, URL, last updated, access permissions
- Supports streaming search results
- Integration with existing document management system

---


---

## 5. DATA FLOW DIAGRAMS

### 5.1 Question Detection and Answering Flow

```
User speaks question
    ↓
Audio → Transcription (existing system)
    ↓
Transcription chunk sent to backend via WebSocket
    ↓
Backend adds to transcript buffer
    ↓
Context sent to GPT-5-mini (streaming enabled)
    ↓
GPT detects question, outputs JSON object
    ↓
Backend parses object, identifies as question
    ↓
[Four-tier answer discovery starts]
    │
    ├─→ Tier 1: RAG Search Service (parallel, 2s timeout)
    │   └─→ Stream results to client with "📚 From Documents" label
    │
    ├─→ Tier 2: Meeting Context Search Service (parallel, 1.5s timeout)
    │   └─→ Send result to client with "💬 Earlier in Meeting" label
    │
    ├─→ Tier 3: Live Conversation Monitoring (15s window)
    │   └─→ Send resolution with "👂 Answered Live" label if answer detected
    │
    └─→ Tier 4: GPT Answer Generator (3s timeout, only if Tiers 1-3 fail)
        └─→ Send AI-generated answer with "🤖 AI Answer" label + disclaimer
    ↓
Client receives updates progressively with clear source attribution
    ↓
UI renders question with available information and source labels
    ↓
After all tiers complete or answer found: finalize status
    ↓
User can mark as answered, needs follow-up, or dismiss
    ↓
Feedback sent to backend and stored
```

### 5.2 Action Item Tracking Flow

```
User mentions action/commitment
    ↓
Transcription chunk sent to backend
    ↓
GPT detects action, outputs JSON object
    ↓
Backend parses, creates or updates action state
    ↓
Calculates completeness score
    ↓
Sends tracking badge to client
    ↓
UI displays subtle action indicator
    ↓
[Accumulation phase - continues as conversation flows]
    │
    └─→ More details mentioned (owner, deadline)
        ↓
        GPT outputs action_update object
        ↓
        Backend updates action state
        ↓
        Recalculates completeness
        ↓
        Updates UI badge
    ↓
Segment boundary detected
    ↓
Backend reviews actions in segment
    ↓
For incomplete actions: send alert to client
    ↓
User can assign, set deadline, or dismiss
    ↓
Meeting ends
    ↓
Generate comprehensive summary
    ↓
Display all actions with completeness indicators
    ↓
User can export to task management system
```

### 5.3 WebSocket Communication Flow

```
Client → Server:
- Connection request with JWT token
- Audio stream chunks (continuous)
- User feedback (mark as answered, assign action, etc.)

Server → Client:
- QUESTION_DETECTED: New question found
- RAG_RESULT: Document found (progressive) - labeled "📚 From Documents"
- ANSWER_FROM_MEETING: Answer from earlier discussion - labeled "💬 Earlier in Meeting"
- QUESTION_ANSWERED_LIVE: Answer in current conversation - labeled "👂 Answered Live"
- GPT_GENERATED_ANSWER: AI-generated answer (fallback) - labeled "🤖 AI Answer" + disclaimer
- QUESTION_UNANSWERED: No answer after all tiers exhausted
- ACTION_TRACKED: New action detected
- ACTION_UPDATED: Action details updated
- ACTION_ALERT: Prompt for missing information
- SEGMENT_TRANSITION: Meeting topic changed
- MEETING_SUMMARY: Final summary with all items
```

---


---

## 6. TECHNOLOGY STACK & ARCHITECTURE DECISIONS

### 6.1 Audio & Transcription Stack

**Audio Format:**
- **Format:** PCM (Pulse Code Modulation)
- **Sample Rate:** 16kHz (industry standard for speech recognition)
- **Bit Depth:** 16-bit
- **Channels:** Mono
- **Chunk Size:** 100-200ms (1600-3200 bytes per chunk)
- **Rationale:** Optimized for real-time streaming and compatibility with AssemblyAI

**Transcription Service: AssemblyAI Real-Time API**
- **Chosen:** AssemblyAI Real-Time Transcription
- **Why:**
  - ✅ Real-time transcription with low latency (<500ms)
  - ✅ Built-in speaker diarization (identifies who spoke)
  - ✅ Partial + final transcripts for progressive updates
  - ✅ High accuracy for business conversations
  - ✅ Simple WebSocket integration
- **Cost:** $0.00025/second = $0.015/minute = $0.90/hour
- **Alternative Considered:** OpenAI Whisper API (lacks real-time streaming + diarization)

**Audio Streaming Protocol:**
- **Transport:** WebSocket binary frames (not Base64)
- **Buffering:** 300-500ms client-side buffer before sending
- **Synchronization:** Client timestamps with server-side offset calculation
- **Quality Monitoring:** Amplitude tracking for silence/clipping detection

### 6.2 Intelligence & LLM Stack

**Primary LLM: GPT-5-mini (OpenAI)**
- **Model:** `gpt-5-mini` (latest stable version)
- **Why:**
  - ✅ Excellent structured output generation
  - ✅ Native streaming support with NDJSON
  - ✅ 128K context window (sufficient for meeting buffer)
  - ✅ Lower latency with optimized streaming (~200ms first token)
  - ✅ Improved consistency in JSON output vs GPT-4o-mini
  - ✅ Cost-effective: $0.150/1M input tokens, $0.600/1M output tokens (estimated)
- **Configuration:**
  - Temperature: 0.3 (consistent structured output)
  - Max tokens: 1000 per request
  - Streaming: enabled with usage tracking
  - Format: Newline-delimited JSON (NDJSON)

**Token Budget (per meeting hour):**
- Transcript buffer: ~1200 tokens/request
- Context (questions/actions): ~500 tokens/request
- System prompt: ~300 tokens/request
- Total input: ~2000 tokens/request
- Requests per hour: ~100 (one per transcription update)
- **Total cost:** ~$0.03/hour input + ~$0.12/hour output = **$0.15/hour** (estimated)

### 6.3 State Management Stack

**Hot State: Redis**
- **Purpose:** Real-time meeting state (transcript buffer, active questions/actions)
- **TTL:** Meeting duration + 2 hours
- **Features:** Pub/sub for multi-instance coordination
- **Fallback:** In-memory state if Redis unavailable

**Persistent State: PostgreSQL**
- **Purpose:** Long-term storage of insights, speaker metadata, recordings
- **Schema:** `live_meeting_insights` table with JSONB for flexibility
- **Indexes:** Optimized for session_id, speaker, timestamp queries

**Vector Database: (Existing RAG Infrastructure)**
- **Purpose:** Semantic document search for Tier 1 answers
- **Integration:** Existing Qdrant or equivalent

### 6.4 Communication Protocol

**WebSocket Message Types:**
- **Binary Frames:** Audio chunks (PCM data)
- **JSON Events:** Questions, actions, answers, state sync
- **Bidirectional:** Client sends audio + feedback, server sends insights

**State Synchronization:**
- **Reconnection:** SYNC_STATE message with full meeting state
- **Multi-device:** Same user on multiple devices gets synchronized state
- **Late join:** Full history from meeting start
- **Conflict resolution:** Last-write-wins with timestamps

---

## 7. INTEGRATION POINTS

### 7.1 External Services

**AssemblyAI Real-Time API**
- **Purpose:** Speech-to-text with speaker diarization
- **Endpoint:** `wss://api.assemblyai.com/v2/realtime/ws`
- **Authentication:** API key in connection request
- **Features Used:**
  - Real-time transcription (partial + final)
  - Speaker labeling (automatic diarization)
  - Word-level timestamps
- **Error Handling:** Exponential backoff, fallback to silence
- **Monitoring:** Track accuracy, latency, speaker detection quality

**OpenAI GPT-5-mini API**
- Purpose: All intelligence processing
- Model: gpt-5-mini (latest stable version)
- Integration: REST API with streaming support
- Key Features:
  - Enhanced streaming performance and reliability
  - Improved structured output generation
  - Better context understanding (up to 128K tokens)
  - Lower latency and higher throughput vs previous models
- Authentication: API key in request header
- Rate limits: 
  - TPM (tokens per minute): Monitored and auto-scaled
  - RPM (requests per minute): Handled with backoff and retry
  - Built-in rate limit handling with exponential backoff
- Fallback: Degraded mode with regex-based detection if API unavailable
- Monitoring: Track latency, error rates, and token usage per request

**Vector Database (RAG)**
- Purpose: Semantic document search
- Integration: REST API or direct client
- Options: Pinecone, Weaviate, or custom solution
- Authentication: API key or internal network
- Fallback: Skip RAG tier if unavailable

### 6.2 Internal Systems

**Existing TellMeMo Recording System**
- Integration: Recording right panel extension
- Data flow: Audio transcription to AI assistant
- Maintains independence: AI assistant is optional add-on

---


---

## APPENDIX B: REFERENCES

**Technologies**
- GPT-5-mini Model: https://platform.openai.com/docs/models/gpt-5-mini
- GPT-5-mini Streaming API: https://platform.openai.com/docs/api-reference/streaming
- OpenAI Rate Limits: https://platform.openai.com/docs/guides/rate-limits
- WebSocket Protocol: https://datatracker.ietf.org/doc/html/rfc6455
- Flutter Framework: https://flutter.dev/docs
- Redis: https://redis.io/documentation
- PostgreSQL: https://www.postgresql.org/docs/

**Standards**
- OAuth 2.0: https://oauth.net/2/
- JWT: https://jwt.io/
- TLS 1.3: https://tools.ietf.org/html/rfc8446
- GDPR: https://gdpr.eu/

**Best Practices**
- OpenAI Streaming: https://platform.openai.com/docs/api-reference/streaming
- WebSocket at Scale: Industry whitepapers
- Mobile App Security: OWASP Mobile Security Guide

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | October 2025 | Architecture Team | Initial version |

**Approval**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Technical Lead | | | |
| Product Manager | | | |
| Engineering Manager | | | |

---

*End of High-Level Design Document*