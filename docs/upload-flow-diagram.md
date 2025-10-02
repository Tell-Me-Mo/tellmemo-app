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
    participant JS as Job Service
    participant WS as WebSocket
    participant DB as PostgreSQL
    participant VDB as Qdrant Vector DB
    participant AI as AI Services
    participant BG as Background Tasks

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

    BE->>JS: create_job()
    activate JS
    JS->>JS: Generate job_id
    JS->>WS: Notify job created
    WS-->>UD: Job status: PENDING
    deactivate JS
    deactivate BE

    Note over BG,VDB: 6. ASYNC PROCESSING
    BE->>BG: trigger_async_processing()
    activate BG

    BG->>JS: Update status: PROCESSING
    JS->>WS: Notify progress (10%)
    WS-->>UD: Update progress bar

    BG->>BG: Extract & chunk text
    Note right of BG: - Parse documents<br/>- Split into chunks<br/>- Clean text

    BG->>JS: Update progress (30%)
    JS->>WS: Notify progress
    WS-->>UD: Update progress bar

    BG->>AI: Generate embeddings
    activate AI
    Note right of AI: SentenceTransformers<br/>all-MiniLM-L6-v2
    AI-->>BG: Vector embeddings
    deactivate AI

    BG->>JS: Update progress (60%)
    JS->>WS: Notify progress
    WS-->>UD: Update progress bar

    BG->>VDB: Store vectors
    activate VDB
    VDB->>VDB: Index vectors
    VDB-->>BG: Success
    deactivate VDB

    BG->>DB: Update content metadata

    BG->>JS: Update progress (90%)
    JS->>WS: Notify progress
    WS-->>UD: Update progress bar

    opt Additional AI Processing
        BG->>AI: Extract metadata
        AI-->>BG: Tags, categories
        BG->>DB: Update metadata
    end

    BG->>JS: Complete job
    JS->>WS: Notify completion
    deactivate BG

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
| **Content Router** | `content.py` | - Project-specific uploads<br/>- File validation<br/>- Job creation |
| **Content Service** | `content_service.py` | - Business logic<br/>- Database operations<br/>- Activity logging |
| **Job Service** | `upload_job_service.py` | - Job lifecycle<br/>- Progress tracking<br/>- WebSocket notifications |
| **Background Tasks** | Various | - Text processing<br/>- Embedding generation<br/>- Vector storage |

## Data Flow Summary

### Upload Types
1. **Text Upload**: Direct text → Content Service → Vector DB
2. **File Upload**: File → Parse → Content Service → Vector DB
3. **Audio Upload**: Audio → Transcription → Content Service → Vector DB

### Processing Stages
1. **Validation** (Sync): File type, size, format checks
2. **Storage** (Sync): Database record creation
3. **Processing** (Async): Chunking, embedding, indexing
4. **Notification** (Real-time): WebSocket progress updates

### AI Integration Points
- **Project Matching**: Analyzes content to suggest/create projects
- **Content Classification**: Determines content type (meeting/email)
- **Metadata Extraction**: Extracts tags, topics, entities
- **Embedding Generation**: Creates semantic vectors for search

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

- **Sync Operations**: ~200-500ms (validation + DB insert)
- **Async Processing**: 2-10s depending on content size
- **Embedding Generation**: ~100-500ms per chunk
- **Vector Storage**: ~50-100ms per batch
- **Total End-to-End**: 3-15s for typical documents

## WebSocket Events

| Event | Payload | Description |
|-------|---------|-------------|
| `job.created` | `{job_id, status: "pending"}` | New upload job created |
| `job.processing` | `{job_id, progress: 0-100}` | Processing progress update |
| `job.completed` | `{job_id, content_id}` | Upload completed successfully |
| `job.failed` | `{job_id, error}` | Upload failed with error |
| `content.ready` | `{content_id, project_id}` | Content indexed and searchable |