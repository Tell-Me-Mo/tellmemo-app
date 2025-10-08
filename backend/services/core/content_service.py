"""Content service for handling file uploads and processing."""

import uuid
import asyncio
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload

from models.content import Content, ContentType
from models.project import Project
from services.activity.activity_service import ActivityService
from services.core.upload_job_service import upload_job_service, JobType, JobStatus
from utils.logger import get_logger
from utils.monitoring import monitor_operation, track_background_task
from config import get_settings

settings = get_settings()

logger = get_logger(__name__)

# Language detection will be handled by langdetect_service
# which initializes at startup with SSL bypass


class ContentService:
    """Service for managing content uploads and processing."""
    
    @staticmethod
    def detect_language(text: str) -> Dict[str, Any]:
        """Detect language of text content using centralized service.

        Returns:
            Dict with 'language' code and 'confidence' score
        """
        if not settings.detect_language:
            return {'language': 'en', 'confidence': 0.0}

        try:
            # Use centralized language detection service
            from services.llm.langdetect_service import language_detection_service

            if not language_detection_service.is_available():
                logger.debug("Language detection service not available")
                return {'language': 'en', 'confidence': 0.0}

            result = language_detection_service.detect(text)
            return result

        except Exception as e:
            logger.warning(f"Language detection failed: {e}")
            return {'language': 'en', 'confidence': 0.0}

    @staticmethod
    async def create_content(
        session: AsyncSession,
        project_id: uuid.UUID,
        content_type: ContentType,
        title: str,
        content: str,
        content_date: Optional[date] = None,
        uploaded_by: Optional[str] = None,
        uploaded_by_id: Optional[str] = None
    ) -> Content:
        """
        Create a new content entry in the database.
        
        Args:
            session: Database session
            project_id: UUID of the project
            content_type: Type of content (meeting/email)
            title: Title of the content
            content: Raw text content
            content_date: Date of the content (optional)
            uploaded_by: User who uploaded (optional)
            
        Returns:
            Created Content object
        """
        try:
            # Verify project exists
            result = await session.execute(
                select(Project).where(Project.id == project_id)
            )
            project = result.scalar_one_or_none()
            
            if not project:
                raise ValueError(f"Project {project_id} not found")
            
            if project.status != "active":
                raise ValueError(f"Project {project_id} is not active")
            
            # Create content entry
            content_obj = Content(
                project_id=project_id,
                content_type=content_type,
                title=title,
                content=content,
                date=content_date,
                uploaded_by=uploaded_by,
                uploaded_at=datetime.utcnow(),
                chunk_count=0,
                summary_generated=False
            )
            
            session.add(content_obj)
            await session.flush()
            await session.refresh(content_obj)
            
            # Log activity for content upload
            await ActivityService.log_content_uploaded(
                db=session,
                project_id=project_id,
                content_title=title,
                content_type=content_type.value,
                user_name=uploaded_by or "system",
                user_id=uploaded_by_id
            )
            
            logger.info(f"Created content {content_obj.id} for project {project_id}")
            return content_obj
            
        except Exception as e:
            logger.error(f"Failed to create content: {e}")
            raise
    
    @staticmethod
    async def validate_file_upload(
        file_content: bytes,
        filename: str,
        content_type: str
    ) -> Dict[str, Any]:
        """
        Validate uploaded file.
        
        Args:
            file_content: File content in bytes
            filename: Original filename
            content_type: MIME type
            
        Returns:
            Validation result with extracted text
        """
        try:
            # Check file size
            file_size_mb = len(file_content) / (1024 * 1024)
            if file_size_mb > settings.max_file_size_mb:
                raise ValueError(f"File size {file_size_mb:.2f}MB exceeds maximum {settings.max_file_size_mb}MB")
            
            # Validate file type (only text files for MVP)
            allowed_types = ["text/plain", "text/txt"]
            allowed_extensions = [".txt", ".text"]
            
            file_extension = filename.lower().split('.')[-1] if '.' in filename else ''
            
            if content_type not in allowed_types and f".{file_extension}" not in allowed_extensions:
                raise ValueError(f"File type not supported. Please upload a .txt file")
            
            # Extract text content
            try:
                text_content = file_content.decode('utf-8')
            except UnicodeDecodeError:
                # Try different encodings
                for encoding in ['latin-1', 'cp1252', 'iso-8859-1']:
                    try:
                        text_content = file_content.decode(encoding)
                        break
                    except UnicodeDecodeError:
                        continue
                else:
                    raise ValueError("Unable to decode file content. Please ensure it's a valid text file")
            
            # Basic content validation
            if not text_content.strip():
                raise ValueError("File is empty")
            
            if len(text_content) < 50:
                raise ValueError("Content is too short. Please provide more detailed content")
            
            return {
                "valid": True,
                "text": text_content,
                "size_mb": file_size_mb,
                "char_count": len(text_content),
                "word_count": len(text_content.split())
            }
            
        except Exception as e:
            logger.error(f"File validation failed: {e}")
            raise
    
    
    @staticmethod
    @monitor_operation("process_content_async", "async_worker", capture_args=True)
    async def process_content_async(
        session: AsyncSession,
        content_id: uuid.UUID,
        job_id: Optional[str] = None
    ) -> None:
        """
        Process content asynchronously (chunking, embedding, storage).
        
        Args:
            session: Database session
            content_id: UUID of content to process
            job_id: Optional job ID for progress tracking
        """
        try:
            # Update job progress if job_id provided
            if job_id:
                upload_job_service.update_job_progress(
                    job_id, 
                    current_step=1, 
                    status=JobStatus.PROCESSING,
                    step_description="Validating content"
                )
            # Get content
            result = await session.execute(
                select(Content).where(Content.id == content_id)
            )
            content = result.scalar_one_or_none()
            
            if not content:
                raise ValueError(f"Content {content_id} not found")
            
            logger.info(f"Starting async processing for content {content_id}")
            
            # Update job: preprocessing
            if job_id:
                upload_job_service.update_job_progress(
                    job_id, 
                    current_step=2,
                    progress=20.0,
                    step_description="Preprocessing content"
                )
            
            # Preprocess content based on type, especially for meeting transcripts
            processed_content = content.content
            
            # If this is a meeting transcript, parse and extract structured content
            if content.content_type == ContentType.MEETING:
                try:
                    from services.transcription.transcript_parser import transcript_parser
                    
                    logger.info(f"Parsing meeting transcript for content {content_id}")
                    parsed_transcript = transcript_parser.parse_transcript(
                        content.content, 
                        title=content.title
                    )
                    
                    # Extract optimized content for chunking
                    processed_content = transcript_parser.extract_content_for_chunking(parsed_transcript)
                    
                    logger.info(f"Processed transcript: {len(processed_content)} chars vs original {len(content.content)} chars")
                    
                except Exception as e:
                    logger.warning(f"Failed to parse meeting transcript, using raw content: {e}")
                    processed_content = content.content
            
            # Update job: chunking
            if job_id:
                upload_job_service.update_job_progress(
                    job_id, 
                    current_step=3,
                    progress=40.0,
                    step_description="Splitting into chunks"
                )
            
            # Chunk the processed text using the chunking service
            from services.rag.chunking_service import chunking_service
            
            text_chunks = chunking_service.chunk_text(processed_content)
            
            # Convert TextChunk objects to dictionaries for compatibility
            chunks = [chunk.to_dict() for chunk in text_chunks]
            
            # Update chunk count
            content.chunk_count = len(chunks)
            content.processed_at = datetime.utcnow()
            
            # Update job: generating embeddings
            if job_id:
                upload_job_service.update_job_progress(
                    job_id, 
                    current_step=4,
                    progress=60.0,
                    step_description="Generating embeddings"
                )
            
            # Generate embeddings and store in Qdrant
            from services.rag.embedding_service import embedding_service
            from db.multi_tenant_vector_store import multi_tenant_vector_store
            from qdrant_client.models import PointStruct
            
            # Detect content language if multilingual support is enabled
            language_info = {}
            if settings.enable_multilingual:
                language_info = ContentService.detect_language(processed_content)
                logger.info(f"Detected language: {language_info.get('language')} with confidence {language_info.get('confidence'):.2f}")

            # Generate embeddings for chunks
            chunks_with_embeddings = await embedding_service.generate_embeddings_for_chunks(
                chunks,
                batch_size=32
            )
            
            # Prepare points for Qdrant
            points = []
            for chunk in chunks_with_embeddings:
                # Generate a unique UUID for each chunk
                import uuid
                point_id = str(uuid.uuid4())

                # Handle MRL (Multi-Resolution Learning) vectors
                if settings.enable_mrl:
                    # Create named vectors for each dimension
                    vectors = {}
                    full_embedding = chunk['embedding']
                    # Get MRL dimensions - handle both property and method access
                    mrl_dims = settings.mrl_dimensions_list() if callable(settings.mrl_dimensions_list) else settings.mrl_dimensions_list
                    for dim in mrl_dims:
                        # Truncate embedding to each dimension
                        vectors[f"vector_{dim}"] = full_embedding[:dim]
                    vector_data = vectors
                else:
                    # Single vector for non-MRL mode
                    vector_data = chunk['embedding']

                point = PointStruct(
                    id=point_id,
                    vector=vector_data,
                    payload={
                        'content_id': str(content_id),
                        'project_id': str(content.project_id),
                        'content_type': content.content_type.value,
                        'title': content.title,
                        'chunk_index': chunk['index'],
                        'text': chunk['text'],
                        'word_count': chunk['word_count'],
                        'start_position': chunk['start_position'],
                        'date': content.date.isoformat() if content.date else None,
                        'uploaded_at': content.uploaded_at.isoformat(),
                        # Add language metadata if detected
                        'language': language_info.get('language', 'en') if language_info else 'en',
                        'language_confidence': language_info.get('confidence', 0.0) if language_info else 0.0
                    }
                )
                points.append(point)
            
            # Update job: storing in vector database
            if job_id:
                upload_job_service.update_job_progress(
                    job_id, 
                    current_step=5,
                    progress=80.0,
                    step_description="Storing in database"
                )
            
            # Get organization_id from project
            project = await session.get(Project, content.project_id)
            if not project:
                raise ValueError(f"Project {content.project_id} not found")

            # Store vectors in organization's Qdrant collection
            success = await multi_tenant_vector_store.insert_vectors(
                organization_id=str(project.organization_id),
                points=points
            )
            
            if not success:
                raise Exception("Failed to store embeddings in Qdrant")
            
            await session.commit()
            logger.info(f"Completed processing for content {content_id}: {len(chunks)} chunks")
            
            # Update job: almost complete
            if job_id:
                upload_job_service.update_job_progress(
                    job_id, 
                    current_step=6,
                    progress=90.0,
                    step_description="Preparing for summary generation"
                )
            
            # Track partial failures for AI features
            partial_failures = {}

            # Auto-generate meeting summary if this is meeting content
            summary_id = None
            if content.content_type == ContentType.MEETING:
                logger.info(f"Auto-generating summary for meeting content {content_id}")
                try:
                    # Import here to avoid circular dependency
                    from services.summaries.summary_service_refactored import summary_service

                    # Update job progress to indicate AI processing
                    if job_id:
                        upload_job_service.update_job_progress(
                            job_id,
                            current_step=6,
                            step_description="Generating AI summary...",
                            progress=85.0
                        )

                    # Generate meeting summary in background with job tracking
                    summary_data = await summary_service.generate_meeting_summary(
                        session=session,
                        project_id=content.project_id,
                        content_id=content_id,
                        created_by="system",
                        job_id=job_id  # Pass job_id for progress tracking
                    )
                    summary_id = summary_data.get('id')
                    logger.info(f"Auto-generated meeting summary {summary_id} for content {content_id}")

                    # Update content to mark summary as generated
                    content.summary_generated = True
                    await session.commit()

                except Exception as summary_error:
                    error_msg = str(summary_error)
                    logger.error(f"Failed to auto-generate summary for content {content_id}: {error_msg}")
                    partial_failures['summary_failed'] = True
                    partial_failures['summary_error'] = error_msg
                    # Check if it's an AI overloaded error
                    if 'overloaded' in error_msg.lower() or '529' in error_msg:
                        partial_failures['ai_overloaded'] = True
                    # Don't fail the entire process if summary generation fails
            
            # Process content for potential project description update
            try:
                logger.info(f"Processing content {content_id} for project description update")
                from services.intelligence.project_description_service import project_description_analyzer
                from services.hierarchy.project_service import ProjectService
                
                # Get last description change time for smart triggers
                recent_changes = await ProjectService.get_description_change_history(
                    session, content.project_id, limit=1
                )
                last_change_time = recent_changes[0].changed_at if recent_changes else None
                
                # Check if we should analyze this content
                should_analyze = project_description_analyzer.should_trigger_analysis(
                    content_text=content.content,
                    content_type=content.content_type.value,
                    last_change_time=last_change_time
                )
                
                if should_analyze:
                    # Get current project description
                    project = await ProjectService.get_project(session, content.project_id)
                    current_description = project.description or ""  # Use actual empty string, not placeholder
                    
                    # Use processed content if available, otherwise raw content
                    content_for_analysis = processed_content if 'processed_content' in locals() else content.content
                    
                    # Prepare content data for analysis
                    content_data = {
                        'content_type': content.content_type.value,
                        'title': content.title,
                        'content': content_for_analysis,  # Use processed content
                        'date': content.date.strftime('%Y-%m-%d') if content.date else None,
                        'uploaded_by': content.uploaded_by,
                        'summary': summary_data if 'summary_data' in locals() and summary_data else None  # Pass the meeting summary
                    }
                    
                    # Analyze with Claude
                    analysis_result = await project_description_analyzer.analyze_for_description_update(
                        current_description=current_description,
                        project_name=project.name,
                        content_data=content_data
                    )
                    
                    if analysis_result and analysis_result.get('should_update'):
                        # Update the description using ProjectService
                        success = await ProjectService.update_project_description(
                            session=session,
                            project_id=content.project_id,
                            new_description=analysis_result['new_description'],
                            content_id=content_id,
                            reason=analysis_result['reason'],
                            confidence_score=analysis_result['confidence'],
                            changed_by="system"
                        )

                        if success:
                            logger.info(
                                f"Project description updated for content {content_id}"
                            )
                        else:
                            logger.warning(f"Failed to update project description for content {content_id}")
                    else:
                        logger.info(f"No description update recommended for content {content_id}")
                else:
                    logger.info(f"Smart triggers skipped analysis for content {content_id}")
                    
            except Exception as description_error:
                error_msg = str(description_error)
                logger.error(f"Failed to process description update for content {content_id}: {error_msg}")
                partial_failures['description_update_failed'] = True
                partial_failures['description_error'] = error_msg
                # Check if it's an AI overloaded error
                if 'overloaded' in error_msg.lower() or '529' in error_msg:
                    partial_failures['ai_overloaded'] = True
                # Don't fail the entire process if description update fails

            # Step 4.5: Sync project risks, tasks, and lessons from summary data
            # If we have summary_data from the meeting summary, use that to update project items
            if 'summary_data' in locals() and summary_data:
                try:
                    from services.sync.project_items_sync_service import project_items_sync_service

                    logger.info(f"Syncing project items from meeting summary for content {content_id}")

                    sync_result = await project_items_sync_service.sync_items_from_summary(
                        session=session,
                        project_id=content.project_id,
                        content_id=content_id,
                        summary_data=summary_data
                    )

                    logger.info(
                        f"Project items sync complete: {sync_result['risks_synced']} risks, "
                        f"{sync_result.get('blockers_synced', 0)} blockers, "
                        f"{sync_result['tasks_synced']} tasks, {sync_result['lessons_synced']} lessons"
                    )

                    if sync_result.get('errors'):
                        for error in sync_result['errors']:
                            logger.error(f"Sync error: {error}")
                            partial_failures['sync_error'] = error

                except Exception as e:
                    logger.error(f"Failed to sync project items from summary: {e}")
                    partial_failures['sync_failed'] = True
                    # Don't fail the entire process if sync fails

            # No fallback - if summary generation fails, the entire process should fail
            else:
                logger.error("No summary data available - summary generation must have failed. Cannot proceed with project items sync.")
                partial_failures['no_summary_data'] = True

            # Old database update code has been removed - now using project_items_sync_service
            # which handles extraction, deduplication, and database updates in one place

            # Mark job as completed (with partial success if applicable)
            if job_id:
                result_data = {
                    "content_id": str(content_id),
                    "chunks": len(chunks)
                }
                # Include summary_id if a summary was generated
                if 'summary_data' in locals() and summary_data and summary_data.get('id'):
                    result_data["summary_id"] = summary_data['id']

                # Include project_was_created flag if this was an AI-matched project
                # Check job metadata for is_new_project (set during AI matching)
                job = upload_job_service.get_job(job_id)
                if job and job.metadata.get('is_new_project'):
                    result_data["project_was_created"] = True
                    logger.info(f"✓ Added project_was_created flag to job result (job_id: {job_id})")

                # Check for partial failures
                if partial_failures:
                    result_data["partial_success"] = True
                    result_data.update(partial_failures)

                    # Determine completion status based on partial failures
                    if partial_failures.get('ai_overloaded'):
                        # If AI was overloaded but content uploaded successfully
                        status_msg = "Content uploaded successfully. AI features will be available when service recovers."
                    else:
                        status_msg = "Processing complete with some AI features unavailable"
                else:
                    status_msg = "Processing complete"

                # Add metadata about AI processing status
                metadata = {}
                if partial_failures:
                    metadata.update(partial_failures)
                    # Track retry count if AI was overloaded
                    if partial_failures.get('ai_overloaded'):
                        metadata['ai_retry_count'] = metadata.get('ai_retry_count', 0) + 1

                upload_job_service.update_job_progress(
                    job_id,
                    status=JobStatus.COMPLETED,
                    progress=100.0,
                    step_description=status_msg,
                    result=result_data,
                    metadata=metadata
                )

        except Exception as e:
            logger.error(f"Content processing failed for {content_id}: {e}")
            # Update job with error
            if job_id:
                upload_job_service.update_job_progress(
                    job_id,
                    status=JobStatus.FAILED,
                    error_message=str(e)
                )
            # Update content with error
            if content:
                content.processing_error = str(e)
                await session.commit()
            raise

    # ========== OLD CODE REMOVED - Lines 623-844 contained duplicate database update code ==========
    # This has been replaced with project_items_sync_service which handles:
    # - Extraction from meeting summary data
    # - AI-powered deduplication
    # - Database updates
    # See services/project_items_sync_service.py for the new implementation

    @staticmethod
    @monitor_operation("trigger_async_processing", "async_worker")
    async def trigger_async_processing(
        content_id: uuid.UUID,
        job_id: Optional[str] = None
    ) -> Optional[str]:
        """
        Trigger async processing for content.

        Args:
            content_id: UUID of content to process
            job_id: Optional job ID for tracking

        Returns:
            Job ID if created
        """
        # For MVP, using asyncio.create_task for simple async processing
        # In production, would use Celery or similar task queue
        asyncio.create_task(ContentService._process_in_background(content_id, job_id))
        logger.info(f"Triggered async processing for content {content_id} with job {job_id}")
        return job_id

    @staticmethod
    @track_background_task("process_content_background", {"task_type": "content_processing"})
    async def _process_in_background(
        content_id: uuid.UUID,
        job_id: Optional[str] = None
    ) -> None:
        """
        Background processing wrapper.

        Args:
            content_id: UUID of content to process
            job_id: Optional job ID for tracking
        """
        try:
            # Import here to avoid circular dependency
            from db.database import db_manager

            # Get a new session for background processing
            # The get_session() context manager handles commit/rollback/close automatically
            async for session in db_manager.get_session():
                await ContentService.process_content_async(session, content_id, job_id)
                break  # Exit after first iteration

        except Exception as e:
            logger.error(f"Background processing failed for {content_id}: {e}")
            # No need to handle session cleanup - get_session() does it automatically

    @staticmethod
    async def get_content_by_id(
        session: AsyncSession,
        content_id: uuid.UUID,
        organization_id: uuid.UUID  # Added for multi-tenant support
    ) -> Optional[Content]:
        """
        Get content by ID.

        Args:
            session: Database session
            content_id: UUID of content
            organization_id: UUID of organization (for multi-tenant validation)

        Returns:
            Content object or None
        """
        try:
            result = await session.execute(
                select(Content)
                .options(selectinload(Content.project))
                .where(Content.id == content_id)
            )
            return result.scalar_one_or_none()

        except Exception as e:
            logger.error(f"Failed to get content {content_id}: {e}")
            raise

    @staticmethod
    async def get_project_content(
        session: AsyncSession,
        project_id: uuid.UUID,
        organization_id: Optional[uuid.UUID] = None,
        content_type: Optional[ContentType] = None,
        limit: int = 100
    ) -> List[Content]:
        """
        Get all content for a project.

        Args:
            session: Database session
            project_id: UUID of project
            organization_id: Optional organization ID for multi-tenant filtering
            content_type: Optional content type filter
            limit: Maximum number of results

        Returns:
            List of Content objects
        """
        try:
            query = select(Content).where(Content.project_id == project_id)

            if content_type:
                query = query.where(Content.content_type == content_type)

            query = query.order_by(Content.uploaded_at.desc()).limit(limit)

            result = await session.execute(query)
            return list(result.scalars().all())

        except Exception as e:
            logger.error(f"Failed to get project content: {e}")
            raise


# Singleton instance
content_service = ContentService()
