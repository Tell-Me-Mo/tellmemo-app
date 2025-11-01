"""
Stream Router Service

Routes streaming JSON objects from GPT-5-mini to appropriate handlers.
Parses NDJSON (newline-delimited JSON) objects by type and maintains state mappings.
Includes semantic duplicate detection using sentence embeddings.
"""

import json
import uuid
from typing import Dict, Set, Optional, Any, Callable, Awaitable, Tuple
from datetime import datetime
from dataclasses import dataclass, field

import numpy as np

from utils.logger import get_logger
from utils.exceptions import APIException
from services.rag.embedding_service import embedding_service
from config import get_settings

# Lazy-load zero-shot validator to avoid circular imports
_zeroshot_validator = None
_validator_loaded = False

logger = get_logger(__name__)


def _get_zeroshot_validator():
    """
    Lazy-load the zero-shot validator service.

    Returns:
        ZeroShotValidatorService instance or None if disabled/unavailable
    """
    global _zeroshot_validator, _validator_loaded

    if not _validator_loaded:
        _validator_loaded = True
        settings = get_settings()

        if settings.enable_zeroshot_validation:
            try:
                from services.intelligence.zeroshot_validator_service import zeroshot_validator_service
                _zeroshot_validator = zeroshot_validator_service
                logger.debug("Zero-shot validator loaded successfully")
            except Exception as e:
                logger.warning(f"Failed to load zero-shot validator: {e}")
                _zeroshot_validator = None
        else:
            logger.debug("Zero-shot validation disabled in configuration")

    return _zeroshot_validator


class StreamRouterException(APIException):
    """Exception raised when stream routing fails."""

    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            status_code=500,
            error_code="STREAM_ROUTER_ERROR",
            details=details or {}
        )


class MalformedObjectException(StreamRouterException):
    """Exception raised when an object from GPT stream is malformed."""

    def __init__(self, message: str, raw_object: Dict[str, Any]):
        super().__init__(
            message=message,
            details={"raw_object": raw_object}
        )


@dataclass
class RouterMetrics:
    """Metrics for stream router performance."""
    total_objects_processed: int = 0
    questions_routed: int = 0
    actions_routed: int = 0
    action_updates_routed: int = 0
    answers_routed: int = 0
    malformed_objects: int = 0
    routing_errors: int = 0
    total_latency_ms: float = 0.0

    def add_latency(self, latency_ms: float):
        """Add latency measurement."""
        self.total_latency_ms += latency_ms

    @property
    def average_latency_ms(self) -> float:
        """Calculate average latency."""
        if self.total_objects_processed == 0:
            return 0.0
        return self.total_latency_ms / self.total_objects_processed


class StreamRouter:
    """
    Routes streaming intelligence objects to appropriate handlers.

    Responsibilities:
    - Parse NDJSON objects by type (question, action, action_update, answer)
    - Validate object structure and IDs
    - Maintain mappings of question/action IDs to session state
    - Route to QuestionHandler, ActionHandler, AnswerHandler
    - Collect metrics (latency, throughput, error rate)
    - Handle malformed objects gracefully
    """

    SUPPORTED_TYPES = {"question", "action", "action_update", "answer"}

    def __init__(self, session_id: str, similarity_threshold: float = 0.80):
        """
        Initialize stream router for a specific session.

        Args:
            session_id: Unique session identifier
            similarity_threshold: Cosine similarity threshold for duplicate detection (default: 0.80)
                                0.80 = 80% similar questions/actions are considered duplicates
                                Tuned to catch typos/paraphrases while allowing different items
        """
        self.session_id = session_id
        self.similarity_threshold = similarity_threshold

        # State mappings (text-based for matching)
        self.question_text_to_id: Dict[str, str] = {}  # Map question text → backend UUID
        self.action_text_to_id: Dict[str, str] = {}    # Map action description → backend UUID
        self.question_ids: Set[str] = set()  # Track active question IDs (backend UUIDs)
        self.action_ids: Set[str] = set()    # Track active action IDs (backend UUIDs)

        # Embeddings for semantic duplicate detection (using EmbeddingGemma)
        self.question_embeddings: Dict[str, np.ndarray] = {}  # Map question text → embedding vector
        self.action_embeddings: Dict[str, np.ndarray] = {}    # Map action description → embedding vector

        # Handler callbacks (to be registered)
        self._question_handler: Optional[Callable[[Dict[str, Any]], Awaitable[None]]] = None
        self._action_handler: Optional[Callable[[Dict[str, Any]], Awaitable[None]]] = None
        self._action_update_handler: Optional[Callable[[Dict[str, Any]], Awaitable[None]]] = None
        self._answer_handler: Optional[Callable[[Dict[str, Any]], Awaitable[None]]] = None

        # Metrics
        self.metrics = RouterMetrics()

        logger.info(f"StreamRouter initialized for session: {session_id}")

    def register_question_handler(
        self,
        handler: Callable[[Dict[str, Any]], Awaitable[None]]
    ):
        """Register handler for question objects."""
        self._question_handler = handler
        logger.debug("Question handler registered")

    def register_action_handler(
        self,
        handler: Callable[[Dict[str, Any]], Awaitable[None]]
    ):
        """Register handler for action objects."""
        self._action_handler = handler
        logger.debug("Action handler registered")

    def register_action_update_handler(
        self,
        handler: Callable[[Dict[str, Any]], Awaitable[None]]
    ):
        """Register handler for action_update objects."""
        self._action_update_handler = handler
        logger.debug("Action update handler registered")

    def register_answer_handler(
        self,
        handler: Callable[[Dict[str, Any]], Awaitable[None]]
    ):
        """Register handler for answer objects."""
        self._answer_handler = handler
        logger.debug("Answer handler registered")

    async def route_object(self, obj: Dict[str, Any]) -> None:
        """
        Route a single object to the appropriate handler.

        Args:
            obj: Parsed JSON object from GPT stream

        Raises:
            MalformedObjectException: If object structure is invalid
            StreamRouterException: If routing fails
        """
        routing_start = datetime.utcnow()

        try:
            # Validate object structure
            self._validate_object(obj)

            obj_type = obj.get("type")
            obj_id = obj.get("id") or obj.get("question_id")  # answer uses question_id

            # Route to appropriate handler
            if obj_type == "question":
                await self._route_question(obj)
            elif obj_type == "action":
                await self._route_action(obj)
            elif obj_type == "action_update":
                await self._route_action_update(obj)
            elif obj_type == "answer":
                await self._route_answer(obj)
            else:
                # Should not reach here due to validation
                raise MalformedObjectException(
                    f"Unsupported object type: {obj_type}",
                    raw_object=obj
                )

            # Update metrics
            self.metrics.total_objects_processed += 1
            latency_ms = (datetime.utcnow() - routing_start).total_seconds() * 1000
            self.metrics.add_latency(latency_ms)

            logger.debug(
                f"Routed {obj_type} object - ID: {obj_id}, "
                f"Latency: {latency_ms:.2f}ms"
            )

        except MalformedObjectException as e:
            self.metrics.malformed_objects += 1
            logger.warning(
                f"Malformed object from GPT: {e.message} - "
                f"Raw: {str(e.details.get('raw_object', ''))[:200]}"
            )
            # Don't re-raise - graceful degradation

        except Exception as e:
            self.metrics.routing_errors += 1
            logger.error(
                f"Error routing object (type={obj.get('type', 'unknown')}): {str(e)}",
                exc_info=True
            )
            raise StreamRouterException(
                f"Failed to route object: {str(e)}",
                details={"object_type": obj.get("type")}
            )

    def _validate_object(self, obj: Dict[str, Any]) -> None:
        """
        Validate object structure.

        Args:
            obj: Object to validate

        Raises:
            MalformedObjectException: If validation fails
        """
        # Check if object is a dictionary
        if not isinstance(obj, dict):
            raise MalformedObjectException(
                f"Object must be a dictionary, got {type(obj)}",
                raw_object={"value": str(obj)}
            )

        # Check for type field
        if "type" not in obj:
            raise MalformedObjectException(
                "Object missing required 'type' field",
                raw_object=obj
            )

        obj_type = obj.get("type")

        # Validate type is supported
        if obj_type not in self.SUPPORTED_TYPES:
            raise MalformedObjectException(
                f"Unsupported type: {obj_type}. Must be one of {self.SUPPORTED_TYPES}",
                raw_object=obj
            )

        # Validate type-specific fields (IDs and timestamps now generated by backend)
        # NOTE: We do NOT require "timestamp" from GPT - backend will inject it
        if obj_type == "question":
            required_fields = ["text"]
            for field in required_fields:
                if field not in obj:
                    raise MalformedObjectException(
                        f"Question object missing required field: {field}",
                        raw_object=obj
                    )

        elif obj_type == "action":
            required_fields = ["description"]
            for field in required_fields:
                if field not in obj:
                    raise MalformedObjectException(
                        f"Action object missing required field: {field}",
                        raw_object=obj
                    )

        elif obj_type == "action_update":
            required_fields = ["action_text"]  # Need text to match to existing action
            for field in required_fields:
                if field not in obj:
                    raise MalformedObjectException(
                        f"Action update object missing required field: {field}",
                        raw_object=obj
                    )

        elif obj_type == "answer":
            required_fields = ["question_text", "answer_text"]  # Match by question text
            for field in required_fields:
                if field not in obj:
                    raise MalformedObjectException(
                        f"Answer object missing required field: {field}",
                        raw_object=obj
                    )

    def _validate_id(self, obj_id: str, context: str) -> None:
        """
        Validate UUID format from GPT.

        GPT system prompt instructs to use format: q_{uuid} or a_{uuid}
        We validate the UUID part and log warning if invalid.

        Args:
            obj_id: ID to validate
            context: Context for error message (e.g., "question", "action")

        Raises:
            MalformedObjectException: If ID format is invalid
        """
        if not obj_id or not isinstance(obj_id, str):
            raise MalformedObjectException(
                f"Invalid ID in {context}: ID must be a non-empty string",
                raw_object={"id": obj_id, "context": context}
            )

        # Extract UUID part (after prefix like "q_" or "a_")
        if "_" in obj_id:
            parts = obj_id.split("_", 1)
            if len(parts) == 2:
                prefix, uuid_part = parts
                try:
                    # Validate UUID format
                    uuid.UUID(uuid_part)
                    return  # Valid format
                except ValueError:
                    logger.warning(
                        f"Invalid UUID format in {context}: {obj_id}. "
                        "Expected format: prefix_uuid (e.g., q_3f8a9b2c-1d4e-4f9a-b8c3-2a1b4c5d6e7f)"
                    )
                    # Don't raise - allow backend to generate new UUID if needed
                    return

        # If no underscore or validation failed, log warning but don't block
        logger.warning(
            f"Unexpected ID format in {context}: {obj_id}. "
            "Expected format: prefix_uuid (e.g., q_{uuid}, a_{uuid})"
        )

    async def _find_duplicate_question(self, question_text: str) -> Tuple[bool, Optional[str], float]:
        """
        Find semantically similar duplicate question using EmbeddingGemma.

        Args:
            question_text: New question to check

        Returns:
            Tuple of (is_duplicate, existing_question_id, similarity_score)
        """
        if not self.question_text_to_id:
            return False, None, 0.0

        # Get embedding for new question using EmbeddingGemma
        new_embedding_list = await embedding_service.generate_embedding(question_text, normalize=True)
        new_embedding = np.array(new_embedding_list)

        # Compare with all existing questions
        max_similarity = 0.0
        most_similar_text = None
        most_similar_id = None

        for existing_text, existing_id in self.question_text_to_id.items():
            existing_embedding = self.question_embeddings[existing_text]

            # Cosine similarity (already normalized, so just dot product)
            similarity = float(np.dot(new_embedding, existing_embedding))

            if similarity > max_similarity:
                max_similarity = similarity
                most_similar_text = existing_text
                most_similar_id = existing_id

        # Check if above threshold
        if max_similarity >= self.similarity_threshold:
            logger.info(
                f"Duplicate question detected (similarity={max_similarity:.3f}): "
                f"New: '{question_text[:50]}...' matches "
                f"Existing: '{most_similar_text[:50]}...'"
            )
            return True, most_similar_id, max_similarity

        return False, None, max_similarity

    async def _find_duplicate_action(self, action_description: str) -> Tuple[bool, Optional[str], float]:
        """
        Find semantically similar duplicate action using EmbeddingGemma.

        Args:
            action_description: New action description to check

        Returns:
            Tuple of (is_duplicate, existing_action_id, similarity_score)
        """
        if not self.action_text_to_id:
            return False, None, 0.0

        # Get embedding for new action using EmbeddingGemma
        new_embedding_list = await embedding_service.generate_embedding(action_description, normalize=True)
        new_embedding = np.array(new_embedding_list)

        # Compare with all existing actions
        max_similarity = 0.0
        most_similar_text = None
        most_similar_id = None

        for existing_text, existing_id in self.action_text_to_id.items():
            existing_embedding = self.action_embeddings[existing_text]

            # Cosine similarity (already normalized, so just dot product)
            similarity = float(np.dot(new_embedding, existing_embedding))

            if similarity > max_similarity:
                max_similarity = similarity
                most_similar_text = existing_text
                most_similar_id = existing_id

        # Check if above threshold
        if max_similarity >= self.similarity_threshold:
            logger.info(
                f"Duplicate action detected (similarity={max_similarity:.3f}): "
                f"New: '{action_description[:50]}...' matches "
                f"Existing: '{most_similar_text[:50]}...'"
            )
            return True, most_similar_id, max_similarity

        return False, None, max_similarity

    async def _route_question(self, obj: Dict[str, Any]) -> None:
        """
        Route question object to QuestionHandler.

        Generates a backend UUID and tracks by question text for answer matching.
        Uses semantic embeddings to detect duplicate questions.
        Uses zero-shot classification to filter false positives.
        """
        question_text = obj["text"]

        # ========================================================================
        # STEP 1: Validate question with zero-shot classifier (filter false positives)
        # ========================================================================
        validator = _get_zeroshot_validator()
        if validator:
            try:
                is_meaningful, confidence = await validator.validate_question(question_text)

                if not is_meaningful:
                    logger.info(
                        f"❌ Filtered non-meaningful question (confidence={confidence:.3f}): "
                        f"'{question_text[:80]}...'"
                    )
                    # Don't route this question - it's a false positive
                    return

                logger.debug(
                    f"✅ Question validated as meaningful (confidence={confidence:.3f}): "
                    f"'{question_text[:50]}...'"
                )
            except Exception as validation_error:
                logger.warning(f"Zero-shot validation failed, accepting question by default: {validation_error}")
                # Fail-open: if validation fails, accept the question

        # ========================================================================
        # STEP 2: Check for semantic duplicates using embeddings
        # ========================================================================
        is_duplicate, existing_id, similarity = await self._find_duplicate_question(question_text)
        if is_duplicate:
            logger.info(
                f"Skipping duplicate question (similarity={similarity:.3f}): "
                f"'{question_text[:50]}...' (existing ID: {existing_id})"
            )
            return

        # Generate backend UUID
        backend_id = str(uuid.uuid4())
        obj["id"] = backend_id  # Add ID to object

        # IMPORTANT: Override GPT-provided timestamp with current server time
        # GPT often copies example timestamps from prompts (e.g., "2025-10-26")
        # We must use the actual current time for accurate "time ago" display
        obj["timestamp"] = datetime.utcnow().isoformat() + "Z"

        # Generate and store embedding for this question using EmbeddingGemma
        embedding_list = await embedding_service.generate_embedding(question_text, normalize=True)
        self.question_embeddings[question_text] = np.array(embedding_list)

        # Track question by ORIGINAL text and ID (for answer matching)
        self.question_text_to_id[question_text] = backend_id
        self.question_ids.add(backend_id)

        logger.debug(f"Generated UUID for question: {backend_id}, text='{question_text[:50]}...'")

        # Route to handler
        if self._question_handler:
            await self._question_handler(obj)
            self.metrics.questions_routed += 1
        else:
            logger.warning("QuestionHandler not registered - question not processed")

    async def _route_action(self, obj: Dict[str, Any]) -> None:
        """
        Route action object to ActionHandler.

        Generates a backend UUID and tracks by description for action_update matching.
        Uses semantic embeddings to detect duplicate actions.
        Uses zero-shot classification to filter false positives.
        If duplicate action detected, treats it as an action update.
        """
        action_description = obj["description"]

        # ========================================================================
        # STEP 1: Validate action with zero-shot classifier (filter false positives)
        # ========================================================================
        validator = _get_zeroshot_validator()
        if validator:
            try:
                is_meaningful, confidence = await validator.validate_action(action_description)

                if not is_meaningful:
                    logger.info(
                        f"❌ Filtered non-meaningful action (confidence={confidence:.3f}): "
                        f"'{action_description[:80]}...'"
                    )
                    # Don't route this action - it's a false positive
                    return

                logger.debug(
                    f"✅ Action validated as meaningful (confidence={confidence:.3f}): "
                    f"'{action_description[:50]}...'"
                )
            except Exception as validation_error:
                logger.warning(f"Zero-shot validation failed, accepting action by default: {validation_error}")
                # Fail-open: if validation fails, accept the action

        # ========================================================================
        # STEP 2: Check for semantic duplicates using embeddings
        # ========================================================================
        is_duplicate, existing_id, similarity = await self._find_duplicate_action(action_description)

        if is_duplicate:
            # Treat as action update - route through action_update_handler
            # The ActionHandler.handle_action_update() will merge the new information (owner, deadline)
            obj["id"] = existing_id

            # Override GPT timestamp with current time
            obj["timestamp"] = datetime.utcnow().isoformat() + "Z"

            logger.info(
                f"Routing duplicate action as update (similarity={similarity:.3f}): "
                f"'{action_description[:50]}...' (existing ID: {existing_id})"
            )

            # Route to action_update_handler for proper update handling
            if self._action_update_handler:
                await self._action_update_handler(obj)
                self.metrics.action_updates_routed += 1
            else:
                logger.warning("ActionUpdateHandler not registered - update not processed")
        else:
            # Generate backend UUID for new action
            backend_id = str(uuid.uuid4())
            obj["id"] = backend_id  # Add ID to object

            # IMPORTANT: Override GPT-provided timestamp with current server time
            # GPT often copies example timestamps from prompts (e.g., "2025-10-26")
            # We must use the actual current time for accurate "time ago" display
            obj["timestamp"] = datetime.utcnow().isoformat() + "Z"

            # Generate and store embedding for this action using EmbeddingGemma
            embedding_list = await embedding_service.generate_embedding(action_description, normalize=True)
            self.action_embeddings[action_description] = np.array(embedding_list)

            # Track action by ORIGINAL description and ID (for action_update matching)
            self.action_text_to_id[action_description] = backend_id
            self.action_ids.add(backend_id)

            logger.debug(f"Generated UUID for action: {backend_id}, description='{action_description[:50]}...'")

            # Route to action_handler for new action creation
            if self._action_handler:
                await self._action_handler(obj)
                self.metrics.actions_routed += 1
            else:
                logger.warning("ActionHandler not registered - action not processed")

    async def _route_action_update(self, obj: Dict[str, Any]) -> None:
        """
        Route action_update object to ActionHandler.

        Matches action_update to existing action by action_text.
        Uses semantic embeddings to handle text variations from GPT.
        """
        action_text = obj.get("action_text", "")

        # Try exact match first (fast path)
        backend_id = self.action_text_to_id.get(action_text)

        # If exact match fails, use semantic similarity with embeddings
        if not backend_id and self.action_text_to_id:
            # Generate embedding for action_update text
            update_embedding_list = await embedding_service.generate_embedding(action_text, normalize=True)
            update_embedding = np.array(update_embedding_list)

            # Find best matching action using cosine similarity
            max_similarity = 0.0
            best_match_text = None
            best_match_id = None

            for stored_text, stored_id in self.action_text_to_id.items():
                stored_embedding = self.action_embeddings[stored_text]
                similarity = float(np.dot(update_embedding, stored_embedding))

                if similarity > max_similarity:
                    max_similarity = similarity
                    best_match_text = stored_text
                    best_match_id = stored_id

            # Use a slightly lower threshold (0.70) for matching updates
            # Updates often have minor wording differences from the original action
            if max_similarity >= 0.70:
                backend_id = best_match_id
                logger.debug(
                    f"Embedding matched action_update (similarity={max_similarity:.3f}): "
                    f"'{action_text[:30]}...' to stored action '{best_match_text[:30]}...'"
                )

        if not backend_id:
            logger.debug(
                f"Action update for action text not yet tracked: '{action_text[:50]}...'. "
                "Action may not have been detected yet in this stream cycle. "
                "This is normal during streaming - will be matched in next cycle."
            )
            # Don't route - can't match to existing action yet
            # This is normal during streaming - action may appear in next chunk
            return

        # Add backend ID and timestamp to object
        obj["id"] = backend_id

        # IMPORTANT: Override GPT-provided timestamp with current server time
        # GPT often copies example timestamps from prompts (e.g., "2025-10-26")
        # We must use the actual current time for accurate "time ago" display
        obj["timestamp"] = datetime.utcnow().isoformat() + "Z"

        logger.debug(f"Matched action_update to action {backend_id}")

        # Route to handler
        if self._action_update_handler:
            await self._action_update_handler(obj)
            self.metrics.action_updates_routed += 1
        else:
            logger.warning("ActionUpdateHandler not registered - action update not processed")

    async def _route_answer(self, obj: Dict[str, Any]) -> None:
        """
        Route answer object to AnswerHandler.

        Matches answer to existing question by question_text.
        Uses semantic embeddings to handle text variations from GPT.
        """
        question_text = obj.get("question_text", "")

        # Try exact match first (fast path)
        backend_id = self.question_text_to_id.get(question_text)

        # If exact match fails, use semantic similarity with embeddings
        if not backend_id and self.question_text_to_id:
            # Generate embedding for answer's question text
            answer_embedding_list = await embedding_service.generate_embedding(question_text, normalize=True)
            answer_embedding = np.array(answer_embedding_list)

            # Find best matching question using cosine similarity
            max_similarity = 0.0
            best_match_text = None
            best_match_id = None

            for stored_text, stored_id in self.question_text_to_id.items():
                stored_embedding = self.question_embeddings[stored_text]
                similarity = float(np.dot(answer_embedding, stored_embedding))

                if similarity > max_similarity:
                    max_similarity = similarity
                    best_match_text = stored_text
                    best_match_id = stored_id

            # Use a slightly lower threshold (0.70) for matching answers
            # Answers often paraphrase the original question
            if max_similarity >= 0.70:
                backend_id = best_match_id
                logger.debug(
                    f"Embedding matched answer (similarity={max_similarity:.3f}): "
                    f"'{question_text[:30]}...' to stored question '{best_match_text[:30]}...'"
                )

        if not backend_id:
            logger.debug(
                f"Answer for question text not yet tracked: '{question_text[:50]}...'. "
                "Question may not have been detected yet in this stream cycle. "
                "This is normal during streaming - will be matched in next cycle."
            )
            # Don't route - can't match to existing question yet
            # This is normal during streaming - question may appear in next chunk
            return

        # Add backend question_id to object
        obj["question_id"] = backend_id

        # IMPORTANT: Override GPT-provided timestamp with current server time
        obj["timestamp"] = datetime.utcnow().isoformat() + "Z"

        logger.debug(f"Matched answer to question {backend_id}")

        # Route to handler
        if self._answer_handler:
            await self._answer_handler(obj)
            self.metrics.answers_routed += 1
        else:
            logger.warning("AnswerHandler not registered - answer not processed")

    def get_metrics(self) -> Dict[str, Any]:
        """
        Get current router metrics.

        Returns:
            Dictionary with metric data
        """
        return {
            "session_id": self.session_id,
            "total_objects_processed": self.metrics.total_objects_processed,
            "questions_routed": self.metrics.questions_routed,
            "actions_routed": self.metrics.actions_routed,
            "action_updates_routed": self.metrics.action_updates_routed,
            "answers_routed": self.metrics.answers_routed,
            "malformed_objects": self.metrics.malformed_objects,
            "routing_errors": self.metrics.routing_errors,
            "average_latency_ms": round(self.metrics.average_latency_ms, 2),
            "active_questions": len(self.question_ids),
            "active_actions": len(self.action_ids)
        }

    def clear_state(self) -> None:
        """Clear all state mappings (for session cleanup)."""
        logger.info(
            f"Clearing stream router state for session {self.session_id}. "
            f"Questions: {len(self.question_ids)}, Actions: {len(self.action_ids)}"
        )
        self.question_ids.clear()
        self.action_ids.clear()
        self.question_text_to_id.clear()
        self.action_text_to_id.clear()


# Singleton instances per session
_router_instances: Dict[str, StreamRouter] = {}


def get_stream_router(session_id: str) -> StreamRouter:
    """
    Get or create stream router instance for a session.

    Args:
        session_id: Session identifier

    Returns:
        StreamRouter instance for the session
    """
    if session_id not in _router_instances:
        _router_instances[session_id] = StreamRouter(session_id)
        logger.info(f"Created new StreamRouter for session: {session_id}")

    return _router_instances[session_id]


def cleanup_stream_router(session_id: str) -> None:
    """
    Clean up and remove stream router for a session.

    Args:
        session_id: Session identifier
    """
    if session_id in _router_instances:
        router = _router_instances[session_id]
        router.clear_state()
        del _router_instances[session_id]
        logger.info(f"Cleaned up StreamRouter for session: {session_id}")
