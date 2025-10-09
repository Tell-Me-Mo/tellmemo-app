# PM Master V2 - Content Upload Flow Diagram

## End-to-End Upload Process Flow

```mermaid
sequenceDiagram
    participant U as User
    participant DS as Dashboard Screen
    participant UD as Upload Dialog
    participant UP as Upload Provider
    participant API as API Client
    participant BE as Backend API
    participant CS as Content Service
    participant RQ as Redis Queue
    participant RP as Redis Pub/Sub
    participant RW as RQ Worker
    participant WS as WebSocket
    participant DB as PostgreSQL
    participant VDB as Qdrant Vector DB
    participant AI as AI Services

    Note over U,DS: 1. INITIATION PHASE
    U->>DS: Click "Upload Document"
    DS->>UD: showDialog(UploadContentDialog)

    Note over UD: 2. USER INPUT PHASE
    UD->>U: Display Upload UI
    activate UD
    Note right of UD: Options:<br/>- Project Mode (AI/Manual)<br/>- Content Type (File/Text)<br/>- File Types: txt, pdf, doc, audio

    U->>UD: Select file/paste text
    U->>UD: Choose project mode
    U->>UD: Click "Upload"
    deactivate UD

    Note over UD,UP: 3. FRONTEND VALIDATION
    UD->>UD: Validate input
    alt Audio File
        UD->>UP: uploadAudioFile()
        Note right of UP: Route to transcription
    else Text/Document
        UD->>UP: uploadContent()
        Note right of UP: Route to content upload
    end

    Note over UP,API: 4. API CALL PREPARATION
    UP->>UP: Prepare request
    activate UP
    Note right of UP: - Generate UUID<br/>- Format metadata<br/>- Set headers

    alt AI Auto-Match Mode
        UP->>API: uploadContentWithAIMatching()
        API->>BE: POST /api/upload/with-ai-matching
    else Manual Project Mode
        UP->>API: uploadFile() or uploadTextContent()
        API->>BE: POST /api/projects/{id}/upload
    end
    deactivate UP

    Note over BE,CS: 5. BACKEND PROCESSING
    BE->>BE: Validate request
    activate BE

    alt AI Matching Required
        BE->>AI: project_matcher_service.match()
        AI-->>BE: Matched project_id
        Note right of AI: Analyzes content<br/>Suggests project
    end

    BE->>CS: create_content()
    activate CS
    CS->>CS: Validate project status
    CS->>DB: INSERT content record
    DB-->>CS: Content ID
    CS->>DB: Log activity
    deactivate CS

    BE->>RQ: Enqueue job (high priority)
    activate RQ
    RQ->>RQ: Generate job_id
    RQ->>RP: Publish job created
    RP->>WS: Broadcast job status
    WS-->>UD: Job status: PENDING
    deactivate RQ
    deactivate BE

    Note over RW,VDB: 6. ASYNC PROCESSING (RQ Worker)
    RQ->>RW: Dequeue job
    activate RW

    RW->>RP: Publish status: PROCESSING
    RP->>WS: Broadcast progress (10%)
    WS-->>UD: Update progress bar

    RW->>RW: Extract & chunk text
    Note right of RW: - Parse documents<br/>- Split into chunks<br/>- Clean text

    RW->>RP: Publish progress (30%)
    RP->>WS: Broadcast progress
    WS-->>UD: Update progress bar

    RW->>AI: Generate embeddings
    activate AI
    Note right of AI: EmbeddingGemma<br/>768-dim vectors
    AI-->>RW: Vector embeddings
    deactivate AI

    RW->>RP: Publish progress (60%)
    RP->>WS: Broadcast progress
    WS-->>UD: Update progress bar

    RW->>VDB: Store vectors
    activate VDB
    VDB->>VDB: Index vectors
    VDB-->>RW: Success
    deactivate VDB

    RW->>DB: Update content metadata

    RW->>RP: Publish progress (90%)
    RP->>WS: Broadcast progress
    WS-->>UD: Update progress bar

    opt Additional AI Processing
        RW->>AI: Extract metadata
        AI-->>RW: Tags, categories
        RW->>DB: Update metadata
    end

    RW->>RP: Publish job complete
    RP->>WS: Broadcast completion
    deactivate RW

    Note over WS,U: 7. COMPLETION & UI UPDATE
    WS-->>UD: Job status: COMPLETED
    UD->>UP: Mark upload complete
    UP->>UP: Clear upload state
    UD->>DS: Refresh content list
    DS->>U: Show success message

    Note over U: Content ready for RAG queries
```

## Component Responsibilities

### Frontend Components

| Component | File | Responsibilities |
|-----------|------|-----------------|
| **Dashboard Screen** | `dashboard_screen_v2.dart` | - Display upload buttons<br/>- Open upload dialog<br/>- Show content list |
| **Upload Dialog** | `upload_content_dialog.dart` | - User input collection<br/>- File validation<br/>- Progress display<br/>- Error handling |
| **Upload Provider** | `upload_provider.dart` | - State management<br/>- API orchestration<br/>- Progress tracking<br/>- Error recovery |
| **API Client** | `api_client.dart` | - HTTP requests<br/>- Auth headers<br/>- Response parsing |

### Backend Components

| Component | File | Responsibilities |
|-----------|------|-----------------|
| **Upload Router** | `upload.py` | - Request validation<br/>- AI matching coordination<br/>- Response formatting |
| **Content Router** | `content.py` | - Project-specific uploads<br/>- File validation<br/>- Job enqueuing |
| **Content Service** | `content_service.py` | - Business logic<br/>- Database operations<br/>- Activity logging |
| **Redis Queue** | `queue_config.py` | - Multi-priority queues (high, default, low)<br/>- Job enqueuing and management<br/>- Worker coordination |
| **Redis Pub/Sub** | `redis_cache_service.py` | - Real-time job status broadcasts<br/>- WebSocket integration<br/>- Multi-instance communication |
| **RQ Worker Tasks** | `content_tasks.py`<br/>`transcription_tasks.py`<br/>`integration_tasks.py`<br/>`summary_tasks.py` | - Async job processing<br/>- Text chunking and embedding<br/>- Vector storage<br/>- Progress updates |

## Data Flow Summary

### Upload Types
1. **Text Upload**: Direct text → Content Service → Redis Queue → RQ Worker → Vector DB
2. **File Upload**: File → Parse → Content Service → Redis Queue → RQ Worker → Vector DB
3. **Audio Upload**: Audio → Redis Queue → Transcription (Whisper/Salad/Replicate) → RQ Worker → Vector DB

### Processing Stages
1. **Validation** (Sync): File type, size, format checks
2. **Storage** (Sync): Database record creation
3. **Job Enqueuing** (Sync): Redis Queue job creation with priority
4. **Processing** (Async): RQ Worker processes chunking, embedding, indexing
5. **Notification** (Real-time): Redis Pub/Sub → WebSocket progress updates

### AI Integration Points
- **Project Matching**: Analyzes content to suggest/create projects
- **Content Classification**: Determines content type (meeting/email)
- **Metadata Extraction**: Extracts tags, topics, entities
- **Embedding Generation**: EmbeddingGemma creates 768-dim semantic vectors
- **Transcription**: Replicate (242x faster), Salad Cloud, or Local Whisper

## Error Handling Flow

```mermaid
graph TD
    A[Upload Start] --> B{Validation}
    B -->|Pass| C[Create Job]
    B -->|Fail| D[Show Error]
    C --> E{Backend Processing}
    E -->|Success| F[Async Processing]
    E -->|Fail| G[Mark Job Failed]
    F --> H{Vector Processing}
    H -->|Success| I[Complete]
    H -->|Fail| J[Retry Logic]
    J -->|Max Retries| G
    J -->|Retry| F
    G --> K[Notify User]
    D --> L[User Fixes Input]
    K --> M[Show Error Details]
```

## Performance Characteristics

- **Sync Operations**: ~200-500ms (validation + DB insert + job enqueue)
- **Job Enqueuing**: ~10-50ms (Redis Queue)
- **Async Processing**: 2-10s depending on content size
- **Transcription**:
  - Replicate: ~20s for 30-min audio (242x speedup)
  - Salad Cloud: ~5-8 minutes for 30-min audio
  - Local Whisper: ~696s for 30-min audio
- **Embedding Generation**: ~100-500ms per chunk (EmbeddingGemma)
- **Vector Storage**: ~50-100ms per batch (Qdrant)
- **Total End-to-End**: 3-15s for typical documents (text), 20s-10min for audio

## WebSocket Events

| Event | Payload | Description |
|-------|---------|-------------|
| `job.created` | `{job_id, status: "queued", priority: "high"}` | New RQ job enqueued |
| `job.processing` | `{job_id, progress: 0-100, current_step: "chunking"}` | Processing progress update via Redis Pub/Sub |
| `job.completed` | `{job_id, content_id, duration: "3.5s"}` | Upload completed successfully |
| `job.failed` | `{job_id, error, retry_count: 0}` | Upload failed with error (auto-retry enabled) |
| `content.ready` | `{content_id, project_id, chunks: 15, vectors: 15}` | Content indexed and searchable |

**Note**: All WebSocket events are powered by Redis Pub/Sub for real-time multi-instance synchronization.