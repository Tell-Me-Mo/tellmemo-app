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
- **Intelligent Orchestration**: Fast tiers respond in <2s, while background monitoring continues for 60s

### 1.4 Success Metrics
- Question answer rate: 90%+ (across all four tiers, including GPT-generated fallback)
- Answer source clarity: 100% of answers must clearly indicate their source
- Action item detection accuracy: 90%+
- Latency to first result: <500ms (fast tiers)
- Latency to Tier 3 result: <5s (if fast tiers fail)
- Tier 4 monitoring window: 60 seconds
- Cost per meeting: <$0.18 (with GPT-5-mini efficiency gains)
- User satisfaction: 80%+ find results helpful
- GPT-generated answer usage: <15% of total questions (should be rare fallback)
- RAG relevance threshold: 50% (filters low-confidence results)
- GPT confidence threshold: 70% (ensures quality fallback answers)

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
                               │  │  + Zero-Shot       │  │
                               │  │    Validator       │  │
                               │  └────────┬───────────┘  │
                               │           │              │
                               │  ┌────────▼───────────┐  │
                               │  │  ModernBERT        │  │
                               │  │  Classification    │  │
                               │  │  (False Positive   │  │
                               │  │   Filtering)       │  │
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

**Tier 1: Knowledge Base Search (RAG) - Fast Tier**
- Search organization's document repository (RAG)
- Return top 3-5 relevant documents
- Stream results progressively as found
- Timeout: 2 seconds maximum
- Confidence threshold: 50% (minimum relevance score)
- Display with "📚 From Documents" label
- Execution: Runs in parallel with Tier 2

**Tier 2: Meeting Context Search - Fast Tier**
- Search earlier in the current meeting transcript
- Identify if question was already answered
- Provide timestamp for reference
- Timeout: 1.5 seconds maximum
- Uses GPT-5-mini for semantic matching
- Display with "💬 Earlier in Meeting" label
- Execution: Runs in parallel with Tier 1

**Tier 4: Live Conversation Monitoring - Background Tier**
- Monitor subsequent conversation for answers
- Duration: 60 seconds after question detection (configurable)
- Match answers semantically to questions
- Mark resolved when confident answer detected
- Display with "👂 Answered Live" label
- Execution: Starts immediately in parallel with Tiers 1-2, runs in background
- Does NOT block Tier 3 execution

**Tier 3: GPT-Generated Answer (Fallback) - Conditional Tier**
- Triggers ONLY when Tiers 1-2 fail (does NOT wait for Tier 4)
- GPT-5-mini generates answer based on general knowledge
- Confidence threshold: 70% minimum
- Add prominent disclaimer: "AI-generated, not from documents or meeting"
- Timeout: 3 seconds maximum
- Display with "🤖 AI Answer" label and warning badge
- Execution: Conditional - only runs if fast tiers (1-2) return no results

**FR-Q3: Answer Presentation**
- Display results progressively as each tier completes
- Prioritize: RAG results > Meeting context > GPT-generated > Live monitoring
- **Clear source attribution:** Each answer must indicate its source (documents/meeting/AI/live)
- For GPT-generated answers: Show disclaimer badge and confidence score (≥70%)
- For RAG results: Show relevance score (≥50% threshold)
- Provide actionable links (documents, timestamps)
- Allow user to mark as answered or needs follow-up
- Tier 4 (Live) can override earlier results if confident answer detected

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

**FR-U5: Real-Time Transcription Display**

**Layout Specification:**

The recording panel will be divided into sections:

```
┌─────────────────────────────────────────────────────┐
│  Recording Panel (Right Side of Screen)             │
├─────────────────────────────────────────────────────┤
│  Section 1: Recording Controls                      │
│  ┌───────────────────────────────────────────────┐ │
│  │ ⏺ Recording... 15:23                          │ │
│  │ [Pause] [Stop] [AI Assistant: ON]             │ │
│  │ Audio Level: ████████░░ 80%                   │ │
│  └───────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────┤
│  Section 2: Live Transcription (when AI enabled)   │
│  ┌───────────────────────────────────────────────┐ │
│  │ 🎤 Live Transcript                            │ │
│  │ ─────────────────────────────────────────────  │ │
│  │ [10:15] Speaker A: "What's the budget for..." │ │
│  │         [FINAL]                                │ │
│  │                                                │ │
│  │ [10:16] Speaker B: "I think it's around..."   │ │
│  │         [PARTIAL - transcribing...]            │ │
│  │                                                │ │
│  │ Auto-scrolls to latest transcript              │ │
│  └───────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────┤
│  Section 3: AI Assistant Content (when enabled)    │
│  ┌───────────────────────────────────────────────┐ │
│  │ ❓ Questions (3)                              │ │
│  │ ───────────────────────────────────────────    │ │
│  │ [LiveQuestionCard 1]                          │ │
│  │ [LiveQuestionCard 2]                          │ │
│  │ [LiveQuestionCard 3]                          │ │
│  │                                                │ │
│  │ ✅ Actions (2)                                │ │
│  │ ───────────────────────────────────────────    │ │
│  │ [LiveActionCard 1]                            │ │
│  │ [LiveActionCard 2]                            │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

**Transcription Display Requirements:**

1. **Speaker Attribution:**
   - Show speaker label from AssemblyAI: "Speaker A", "Speaker B", etc.
   - If speaker mapping exists, show actual name: "Sarah", "John"
   - Color-code speakers for easy visual tracking

2. **Transcript State Indicators:**
   - **[PARTIAL]**: Light gray text, italic - "transcribing..."
   - **[FINAL]**: Normal text, bold timestamp - stable transcription
   - Partial transcripts update in-place when final version arrives

3. **Auto-Scroll Behavior:**
   - Auto-scroll to latest transcript by default
   - If user manually scrolls up, pause auto-scroll
   - Show "New transcript ↓" button to resume auto-scroll
   - Resume auto-scroll after 5 seconds of inactivity

4. **Timestamp Format:**
   - Relative time: "[2m ago]" for recent
   - Absolute time: "[10:15]" for older (>5 minutes)
   - Clickable timestamps to jump in recording playback

5. **Visibility Control:**
   - Collapsible transcription panel (minimize button)
   - Collapsed state shows only latest 2 lines
   - Expanded state shows full scrollable history

6. **Performance Optimization:**
   - Render only visible transcripts (virtualized list)
   - Keep last 100 transcript segments in memory
   - Older segments loaded on-demand from backend

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

**4.2.4 WebSocket Connection Lifecycle**

**Connection URL Format:**
```
wss://{host}/ws/live-insights/{session_id}?token={jwt}
```

**When to Connect:**
- **Recommended Approach:** Client connects WebSocket at recording start
- Client sends audio stream only when AI Assistant is enabled
- This allows for seamless toggle ON/OFF without reconnection
- If AI Assistant is disabled, client continues connection but stops sending audio

**Connection States:**
1. **Recording Started, AI OFF:**
   - WebSocket connected
   - No audio sent to backend
   - No transcription or intelligence processing
   - Connection idle (minimal bandwidth)

2. **Recording Started, AI ON:**
   - WebSocket connected
   - Audio streaming active (binary frames)
   - Backend forwards to AssemblyAI
   - Intelligence processing active
   - Insights streamed back to client

3. **AI Toggled OFF Mid-Meeting:**
   - WebSocket remains connected
   - Client stops sending audio
   - Backend stops AssemblyAI streaming
   - Existing insights remain visible (read-only)
   - State preserved in Redis for potential re-enable

4. **AI Toggled ON Mid-Meeting:**
   - WebSocket already connected (no reconnection needed)
   - Client resumes audio streaming
   - Backend reconnects to AssemblyAI
   - Intelligence processing resumes
   - New insights append to existing list

**Alternative Approach (Not Recommended):**
- Connect WebSocket only when AI Assistant is enabled
- Disconnect when AI is disabled
- Requires reconnection and state sync on re-enable
- More complex state management

**WebSocket Message Flow:**
```
Client → Server (Binary Frames):
- Audio chunks (PCM 16kHz, 16-bit, mono)
- Metadata: timestamp, sequence_number, audio_level

Client → Server (JSON):
- User feedback: mark_answered, assign_action, dismiss
- Toggle events: ai_enabled, ai_disabled

Server → Client (JSON):
- QUESTION_DETECTED
- RAG_RESULT (progressive)
- ANSWER_FROM_MEETING
- QUESTION_ANSWERED_LIVE
- GPT_GENERATED_ANSWER
- ACTION_TRACKED
- ACTION_UPDATED
- SYNC_STATE (on reconnect)
```

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

**Stream Router with Zero-Shot Validation**
- Receives objects from GPT stream
- **Two-stage validation pipeline** before routing:
  - **Stage 1: Zero-Shot Classification (ModernBERT)**
    - Validates questions using "meaningful_question" vs "non_meaningful_question" categories
    - Validates actions using "action_item" vs "not_an_action" categories
    - Configurable thresholds: 0.70 (questions), 0.60 (actions)
    - Filters false positives: greetings, acknowledgments, rhetorical questions, non-actionable statements
    - Reduces false positives by ~60-70% compared to raw GPT output
  - **Stage 2: Semantic Duplicate Detection (EmbeddingGemma)**
    - Uses 768-dim embeddings for cosine similarity matching
    - Threshold: 0.80 (80% similarity = duplicate)
    - Prevents duplicate questions/actions during streaming
- Routes validated objects to appropriate handler based on type
- Maintains mapping of question/action IDs to state
- Sends updates to WebSocket clients immediately
- Graceful degradation: Accepts items on validation errors (fail-open strategy)

**5.3.2 Question Handler**
- Processes question detection events from GPT
- Executes four-tier answer discovery with intelligent orchestration:
  - **Phase 1**: Tiers 1-2 run in parallel (fast tiers, <2s combined)
  - **Phase 2**: Tier 4 starts immediately in background (60s monitoring window)
  - **Phase 3**: Tier 3 triggers conditionally if Tiers 1-2 fail (without waiting for Tier 4)
  - **Phase 4**: Tier 4 continues monitoring and can provide answer even after Tier 3
- Manages question lifecycle (searching → found/monitoring → answered/unanswered)
- Aggregates results from multiple sources with priority-based overriding
- Fail-open strategy: Graceful degradation if tiers fail

**Tier Execution Strategy (Actual Implementation):**

The system uses intelligent orchestration to balance speed, accuracy, and completeness:

1. **Fast Tiers (Tier 1 + Tier 2) - Parallel Execution:**
   - Both tiers start immediately in parallel
   - System waits for BOTH to complete (or timeout)
   - Combined latency: max(2s, 1.5s) = 2 seconds
   - Decision point: If either tier succeeds → mark as answered

2. **Background Tier (Tier 4) - Non-Blocking:**
   - Starts immediately alongside fast tiers
   - Does NOT block Tier 3 execution
   - Runs for 60 seconds monitoring live conversation
   - Can override earlier results if confident match found
   - Uses asyncio.Event for answer signaling

3. **Conditional Tier (Tier 3) - Fallback Only:**
   - Triggers ONLY if fast tiers (1-2) both fail
   - Does NOT wait for Tier 4 to complete
   - Provides AI-generated answer as last resort
   - 70% confidence threshold ensures quality

4. **Final Resolution:**
   - After all tiers complete (including Tier 4's 60s window):
     - Check database status to prevent race conditions
     - If still unanswered → broadcast QUESTION_UNANSWERED
   - Tier 4 can "late-answer" questions even after Tier 3 responded

**Example Timeline:**
```
t=0s:    Question detected → Tier 1, 2, 4 start
t=1.5s:  Tier 2 completes (no answer)
t=2.0s:  Tier 1 completes (no answer) → Trigger Tier 3
t=3.0s:  Tier 3 generates AI answer (displayed to user)
t=15s:   Tier 4 detects live answer → Override Tier 3 result
t=60s:   Tier 4 monitoring window expires
```

**5.3.3 Action Handler**
- Processes action and action_update events from GPT
- Maintains active action state
- Calculates completeness scores
- Generates alerts at segment boundaries

**5.3.4 Answer Handler**
- Processes answer events from GPT (live conversation)
- Matches answers to active questions using semantic similarity
- Signals Tier 4 monitoring tasks when answer detected
- Updates question status and removes from tracking
- Sends resolution updates to clients
- Can override earlier tier results if confident match found

**5.3.5 RAG Search Service (Tier 1)**
- Receives search queries from Question Handler
- Queries vector database for relevant documents
- Streams results back as they're found (progressive updates)
- Ranks by relevance and returns top 5
- Filters results below 50% confidence threshold
- 3-phase broadcast: progressive results → completion → enriched (with DB data)

**5.3.6 Meeting Context Search Service (Tier 2)**
- Searches current meeting transcript for answers
- Uses GPT-5-mini for semantic search with enhanced understanding:
  - Better implicit reference detection
  - Improved semantic matching between questions and answers
  - More accurate speaker attribution
- Returns exact quotes with speaker and timestamp
- Timeout: 1.5 seconds maximum
- Higher accuracy in identifying relevant passages
- 3-phase broadcast: immediate result → DB persistence → enriched event

**5.3.7 Segment Detector**
- Identifies natural meeting breakpoints
- Heuristics: long pauses, transition phrases, time intervals
- Triggers action item review at segment end
- Signals meeting end for summary generation

**4.3.8 Session and Recording Lifecycle**

**Session Creation Flow:**

1. **User Starts Recording (No AI Assistant):**
   ```
   Recording Start Button Clicked
       ↓
   Backend creates Recording record in PostgreSQL
       ↓
   recording_id = UUID generated
   session_id = recording_id (same value)
       ↓
   Recording status = "recording"
   AI Assistant status = "disabled"
   ```

2. **User Starts Recording with AI Assistant Enabled:**
   ```
   Recording Start Button Clicked + AI Toggle ON
       ↓
   Backend creates Recording record in PostgreSQL
       ↓
   recording_id = UUID generated
   session_id = recording_id (same value)
       ↓
   Recording status = "recording"
   AI Assistant status = "enabled"
       ↓
   Initialize Redis state for session_id:
       - transcription_buffer = []
       - active_questions = []
       - active_actions = []
       - TTL = 24 hours
       ↓
   Connect to AssemblyAI (if AI enabled)
   ```

3. **User Toggles AI Assistant Mid-Recording:**
   ```
   AI Toggle ON (mid-recording):
       ↓
   session_id already exists (from recording_id)
       ↓
   Initialize Redis state if not exists
   Connect to AssemblyAI
   Start streaming intelligence

   AI Toggle OFF (mid-recording):
       ↓
   session_id remains active
       ↓
   Disconnect from AssemblyAI
   Stop streaming intelligence
   Preserve Redis state (read-only access)
   ```

4. **Recording End:**
   ```
   Recording Stop Button Clicked
       ↓
   Recording status = "completed"
   AI Assistant status = "disabled"
       ↓
   Disconnect from AssemblyAI (if connected)
   Stop streaming intelligence
       ↓
   Persist final insights to PostgreSQL:
       - Copy all questions from Redis → live_meeting_insights table
       - Copy all actions from Redis → live_meeting_insights table
       - Link via recording_id foreign key
       ↓
   Redis state TTL extended to +2 hours for late access
       ↓
   Generate meeting summary (existing flow)
   ```

**Key Design Decisions:**

- `session_id` = `recording_id` (simplicity, 1:1 mapping)
- Recording record is created immediately on recording start, regardless of AI Assistant state
- AI Assistant can be enabled/disabled at any time during recording
- Redis state is initialized only when AI Assistant is first enabled
- WebSocket connection recommended at recording start (even if AI is OFF initially)
- AssemblyAI connection is created/destroyed based on AI Assistant state
- All live insights are persisted to PostgreSQL at recording end for historical access

**Database Schema Linkage:**

```sql
-- recordings table (already exists)
CREATE TABLE recordings (
    id UUID PRIMARY KEY,
    -- ... existing fields ...
    ai_assistant_enabled BOOLEAN DEFAULT FALSE,
    ai_session_started_at TIMESTAMP,
    ai_session_ended_at TIMESTAMP
);

-- live_meeting_insights table (new)
CREATE TABLE live_meeting_insights (
    id UUID PRIMARY KEY,
    session_id VARCHAR,  -- matches recording_id
    recording_id UUID REFERENCES recordings(id) ON DELETE CASCADE,
    -- ... other fields ...
);
```

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
[Two-stage validation pipeline]
    │
    ├─→ Stage 1: Zero-Shot Classification (ModernBERT, ~50-100ms)
    │   - Validate as "meaningful_question" vs "non_meaningful_question"
    │   - If confidence < 0.70 → Filter out (don't route)
    │   - Filters: greetings, acknowledgments, rhetorical questions
    │
    └─→ Stage 2: Semantic Duplicate Detection (EmbeddingGemma)
        - Generate 768-dim embedding
        - Compare with existing questions (cosine similarity)
        - If similarity ≥ 0.80 → Skip as duplicate
    ↓
[Validated question routed to handler]
    ↓
[Four-tier answer discovery starts - intelligent orchestration]
    │
    ├─→ PHASE 1: Fast Tiers (parallel execution, wait for both)
    │   ├─→ Tier 1: RAG Search Service (2s timeout, 50% confidence)
    │   │   └─→ Stream results to client with "📚 From Documents" label
    │   │
    │   └─→ Tier 2: Meeting Context Search Service (1.5s timeout, GPT-5-mini)
    │       └─→ Send result to client with "💬 Earlier in Meeting" label
    │
    ├─→ PHASE 2: Background Tier (parallel from start, does NOT block)
    │   └─→ Tier 4: Live Conversation Monitoring (60s window)
    │       └─→ Send resolution with "👂 Answered Live" label if answer detected
    │       └─→ Can override earlier results if confident match found
    │
    └─→ PHASE 3: Conditional Fallback (only if Phase 1 fails, does NOT wait for Phase 2)
        └─→ Tier 3: GPT Answer Generator (3s timeout, 70% confidence)
            └─→ Send AI-generated answer with "🤖 AI Answer" label + disclaimer
            └─→ Note: Tier 4 continues monitoring even after Tier 3 responds
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
Backend parses action object
    ↓
[Two-stage validation pipeline]
    │
    ├─→ Stage 1: Zero-Shot Classification (ModernBERT, ~50-100ms)
    │   - Validate as "action_item" vs "not_an_action"
    │   - If confidence < 0.60 → Filter out (don't route)
    │   - Filters: comments, opinions, non-actionable statements
    │
    └─→ Stage 2: Semantic Duplicate Detection (EmbeddingGemma)
        - Generate 768-dim embedding
        - Compare with existing actions (cosine similarity)
        - If similarity ≥ 0.80 → Treat as action_update (merge details)
    ↓
[Validated action routed to handler]
    ↓
Backend creates or updates action state
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

**AssemblyAI Connection Architecture:**

**Recommended Approach: Single Connection Per Session (Shared by All Clients)**

```
                    ┌──────────────────────┐
                    │  AssemblyAI Service  │
                    │  (wss://...)         │
                    └──────────┬───────────┘
                               │ Single WebSocket Connection
                               │ (per session_id)
                    ┌──────────▼───────────┐
                    │  Backend Server      │
                    │  Audio Mixer         │
                    │  (session_id: abc)   │
                    └──────────┬───────────┘
                               │ Broadcast transcripts
                   ┌───────────┼───────────┐
                   │           │           │
            ┌──────▼─────┐ ┌──▼──────┐ ┌─▼────────┐
            │ Client 1   │ │Client 2 │ │Client 3  │
            │ (Phone)    │ │(Laptop) │ │(Tablet)  │
            └────────────┘ └─────────┘ └──────────┘
```

**Why Single Connection Per Session:**
1. **Cost Efficiency:** AssemblyAI charges per audio stream. One connection = $0.90/hour regardless of participant count
2. **Speaker Diarization Accuracy:** AssemblyAI needs full audio context to identify speakers correctly
3. **Audio Mixing:** Backend mixes audio from all participants before sending to AssemblyAI
4. **Transcript Consistency:** All participants see identical transcripts with synchronized speaker labels

**Connection Lifecycle:**
1. **First client enables AI Assistant:**
   - Backend creates AssemblyAI WebSocket connection for `session_id`
   - Connection stored in Redis: `assemblyai:connection:{session_id}`
   - Audio buffer initialized

2. **Additional clients join:**
   - Backend reuses existing AssemblyAI connection
   - Client audio is mixed into shared stream
   - All clients receive same transcripts via WebSocket broadcast

3. **Client disconnects:**
   - Backend continues AssemblyAI connection if other clients still active
   - Audio mixing adjusts to remove disconnected client

4. **Last client disables AI or disconnects:**
   - Backend closes AssemblyAI connection
   - Redis connection reference deleted

5. **Client re-enables AI mid-meeting:**
   - If AssemblyAI connection exists: resume using existing
   - If no connection: create new connection, continue from current audio

**Audio Mixing Strategy:**
- If multiple clients send audio simultaneously, backend mixes audio before forwarding
- Use silence detection to avoid sending empty audio chunks
- Tag each audio chunk with client_id for debugging

**Alternative Approach (Not Recommended):**
- One AssemblyAI connection per client
- Higher cost: $0.90/hour × number of clients
- Speaker diarization may be inconsistent across clients

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

**Zero-Shot Classifier: ModernBERT-base-zeroshot-v2.0 (Hugging Face)**
- **Model:** `MoritzLaurer/ModernBERT-base-zeroshot-v2.0`
- **Purpose:** Post-processing validation of GPT-detected questions and actions
- **Why:**
  - ✅ Fast inference on CPU (~50-100ms per classification)
  - ✅ No training data required (zero-shot learning)
  - ✅ High accuracy for text classification tasks
  - ✅ Filters false positives from GPT streaming output
  - ✅ Free (runs locally, no API costs)
- **Classification Categories:**
  - Questions: "meaningful_question" (needs tracking) vs "non_meaningful_question" (greeting, acknowledgment, rhetorical)
  - Actions: "action_item" (task/assignment) vs "not_an_action" (comment, opinion, statement)
- **Configuration:**
  - Question threshold: 0.70 (70% confidence)
  - Action threshold: 0.60 (60% confidence)
  - Device: CPU (optimized for production deployment)
  - Dtype: bfloat16 (GPU) or float32 (CPU)
  - Fail-open strategy: Accepts items on errors
- **Performance Impact:**
  - Reduces false positives by ~60-70%
  - Adds ~50-100ms latency per item (acceptable for streaming)
  - Initialized at app startup (blocks startup if model fails to load)

**Token Budget (per meeting hour):**
- Transcript buffer: ~1200 tokens/request
- Context (questions/actions): ~500 tokens/request
- System prompt: ~300 tokens/request
- Total input: ~2000 tokens/request
- Requests per hour: ~100 (one per transcription update)
- **Total cost:** ~$0.03/hour input + ~$0.12/hour output = **$0.15/hour** (estimated)

**Tier Configuration:**
- Tier 1 timeout: 2.0 seconds (RAG search)
- Tier 2 timeout: 1.5 seconds (Meeting context)
- Tier 3 timeout: 3.0 seconds (GPT generation)
- Tier 4 timeout: 60 seconds (Live monitoring, configurable)
- RAG confidence threshold: 0.50 (50%)
- GPT confidence threshold: 0.70 (70%)

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

**Hugging Face ModernBERT Zero-Shot Classifier**
- Purpose: Post-processing validation of GPT-detected questions and actions
- Model: MoritzLaurer/ModernBERT-base-zeroshot-v2.0
- Integration: Local inference via Transformers library
- Key Features:
  - Zero-shot classification (no training data required)
  - Fast CPU inference (~50-100ms per classification)
  - Filters false positives from GPT streaming output
  - Configurable confidence thresholds
- Authentication: HF_TOKEN for model download (gated model)
- Requirements:
  - Hugging Face account with model access
  - ~500MB disk space for model weights
  - Network connectivity for initial download
- Deployment:
  - Model loaded at app startup (blocking)
  - Cached locally after first download
  - CPU-optimized for production
- Monitoring: Track classification latency, accuracy, and false positive reduction rate

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

## APPENDIX C: GPT-5-MINI PROMPT SPECIFICATIONS

### System Prompt for Streaming Intelligence

```
You are a real-time meeting intelligence assistant. Your job is to analyze live meeting transcripts as they stream in and detect questions, action items, and answers.

OUTPUT FORMAT: Newline-delimited JSON (NDJSON)
- Each detection must be a complete JSON object on a single line
- Followed by a newline character
- No markdown formatting, no code blocks, no explanations

DETECTION TYPES:

1. QUESTION:
{
  "type": "question",
  "id": "q_{uuid}",
  "text": "The exact question as spoken",
  "speaker": "Speaker A",
  "timestamp": "2025-10-26T10:30:05Z",
  "category": "factual|opinion|action-seeking|clarification",
  "confidence": 0.95
}

2. ACTION:
{
  "type": "action",
  "id": "a_{uuid}",
  "description": "Clear action description",
  "owner": "John" OR null,
  "deadline": "2025-10-30" OR null,
  "speaker": "Speaker B",
  "timestamp": "2025-10-26T10:31:00Z",
  "completeness": 0.7,
  "confidence": 0.92
}

3. ACTION_UPDATE (when more details emerge):
{
  "type": "action_update",
  "id": "a_{uuid}",
  "owner": "Sarah",
  "deadline": "2025-11-05",
  "completeness": 1.0,
  "confidence": 0.88
}

4. ANSWER (when answer appears in conversation):
{
  "type": "answer",
  "question_id": "q_{uuid}",
  "answer_text": "The answer as spoken",
  "speaker": "Speaker C",
  "timestamp": "2025-10-26T10:32:15Z",
  "confidence": 0.90
}

DETECTION RULES:

Questions:
- Detect explicit questions (ending with "?")
- Detect implicit questions ("I'm wondering about...", "Does anyone know...")
- Ignore rhetorical questions
- Ignore questions already answered in the same transcript
- Include speaker attribution if available

Actions:
- Detect commitments ("I will...", "We should...", "Let's...")
- Detect task assignments ("John, can you...", "Sarah will...")
- Detect deadlines ("by Friday", "before Q4", "next week")
- Calculate completeness: 0.0-1.0 based on clarity of description, owner, and deadline
  - Description only: 0.4
  - Description + owner OR deadline: 0.7
  - Description + owner + deadline: 1.0
- Track action updates as more information emerges

Answers:
- Detect when a question is answered in subsequent conversation
- Match semantically (not just keyword matching)
- Confidence >0.85 required to mark as answered
- Include the actual answer text, not just a flag

IMPORTANT:
- Generate UUIDs for IDs (e.g., "q_3f8a9b2c-1d4e-4f9a-b8c3-2a1b4c5d6e7f")
- Keep JSON compact (no unnecessary whitespace)
- Each object must be on exactly one line
- Do not output explanations or commentary
- If no detections in a transcript chunk, output nothing (empty response)
```

### Example Input Transcript

```
[10:15:30] Speaker A: "Hello everyone, thanks for joining. I wanted to discuss our Q4 infrastructure budget. Does anyone have the latest numbers?"

[10:16:05] Speaker B: "I think Sarah sent that in an email last week. Let me check."

[10:16:45] Speaker C: "The budget is $250,000 for infrastructure, including cloud costs and new servers."

[10:17:20] Speaker A: "Perfect, thank you. John, can you update the spreadsheet with those numbers by Friday?"

[10:17:35] Speaker D (John): "Sure, I'll update it by end of week."
```

### Example Output (NDJSON)

```json
{"type":"question","id":"q_a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d","text":"Does anyone have the latest numbers?","speaker":"Speaker A","timestamp":"2025-10-26T10:15:30Z","category":"factual","confidence":0.98}
{"type":"action","id":"a_f1e2d3c4-b5a6-4978-8c9d-0a1b2c3d4e5f","description":"Update the spreadsheet with infrastructure budget numbers","owner":"John","deadline":"2025-10-30","speaker":"Speaker A","timestamp":"2025-10-26T10:17:20Z","completeness":1.0,"confidence":0.95}
{"type":"answer","question_id":"q_a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d","answer_text":"The budget is $250,000 for infrastructure, including cloud costs and new servers.","speaker":"Speaker C","timestamp":"2025-10-26T10:16:45Z","confidence":0.97}
```

### Prompt for GPT-Generated Answers (Tier 4)

**Used only when Tiers 1-3 fail to find an answer**

```
You are a knowledgeable assistant helping answer questions that were not found in documents or meeting discussion.

CONTEXT:
Question: "{question_text}"
Asked by: {speaker}
Meeting context: {brief_meeting_summary}

TASK:
Generate a helpful answer based on your general knowledge. If you cannot answer confidently, say so.

OUTPUT FORMAT (JSON):
{
  "answer": "Your detailed answer here",
  "confidence": 0.75,
  "sources": "general knowledge",
  "disclaimer": "This answer is AI-generated and not from your documents or meeting. Please verify accuracy."
}

RULES:
- Only answer if confidence >70%
- Be concise (2-3 sentences max)
- Acknowledge uncertainty when appropriate
- Do not fabricate specific company data or internal information
- Suggest where to find authoritative information if possible
```

### Example GPT-Generated Answer

**Question:** "What's the typical ROI timeline for infrastructure investments?"

**GPT Response:**
```json
{
  "answer": "Typical infrastructure investments show ROI within 18-36 months, depending on the scope. Cloud infrastructure often delivers faster returns (12-18 months) compared to on-premises hardware (24-36 months). However, this varies significantly based on organization size and usage patterns.",
  "confidence": 0.78,
  "sources": "general knowledge",
  "disclaimer": "This answer is AI-generated and not from your documents or meeting. Please verify accuracy."
}
```

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