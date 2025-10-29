"""
Stream Router Service

Routes streaming JSON objects from GPT-5-mini to appropriate handlers.
Parses NDJSON (newline-delimited JSON) objects by type and maintains state mappings.
"""

import json
import uuid
from typing import Dict, Set, Optional, Any, Callable, Awaitable
from datetime import datetime
from dataclasses import dataclass, field

from utils.logger import get_logger
from utils.exceptions import APIException

logger = get_logger(__name__)


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

    def __init__(self, session_id: str):
        """
        Initialize stream router for a specific session.

        Args:
            session_id: Unique session identifier
        """
        self.session_id = session_id

        # State mappings (text-based for matching)
        self.question_text_to_id: Dict[str, str] = {}  # Map question text → backend UUID
        self.action_text_to_id: Dict[str, str] = {}    # Map action description → backend UUID
        self.question_ids: Set[str] = set()  # Track active question IDs (backend UUIDs)
        self.action_ids: Set[str] = set()    # Track active action IDs (backend UUIDs)

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

        # Validate type-specific fields (IDs now generated by backend)
        if obj_type == "question":
            required_fields = ["text", "timestamp"]
            for field in required_fields:
                if field not in obj:
                    raise MalformedObjectException(
                        f"Question object missing required field: {field}",
                        raw_object=obj
                    )

        elif obj_type == "action":
            required_fields = ["description", "timestamp"]
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
            required_fields = ["question_text", "answer_text", "timestamp"]  # Match by question text
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

    def _normalize_text(self, text: str) -> str:
        """
        Normalize text for duplicate detection.

        Handles:
        - Case normalization (lowercase)
        - Punctuation normalization (remove trailing ?, !)
        - Whitespace normalization (collapse multiple spaces)
        - Common variations (Q4 vs q four)

        Args:
            text: Text to normalize

        Returns:
            Normalized text for comparison
        """
        # Lowercase
        normalized = text.lower().strip()

        # Remove trailing punctuation
        normalized = normalized.rstrip("?!.,;:")

        # Collapse multiple spaces
        normalized = " ".join(normalized.split())

        # Normalize common variations
        normalized = normalized.replace("q four", "q4")
        normalized = normalized.replace("q 4", "q4")
        normalized = normalized.replace("q-4", "q4")

        return normalized

    async def _route_question(self, obj: Dict[str, Any]) -> None:
        """
        Route question object to QuestionHandler.

        Generates a backend UUID and tracks by question text for answer matching.
        Includes deduplication with fuzzy matching to prevent duplicate question processing.
        """
        question_text = obj["text"]
        normalized_text = self._normalize_text(question_text)

        # Check if we've already seen this question (using normalized text)
        for existing_text, existing_id in self.question_text_to_id.items():
            if self._normalize_text(existing_text) == normalized_text:
                logger.info(
                    f"Duplicate question detected in stream router, skipping: "
                    f"'{question_text[:50]}...' (existing ID: {existing_id})"
                )
                return

        # Generate backend UUID
        backend_id = str(uuid.uuid4())
        obj["id"] = backend_id  # Add ID to object

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
        Includes deduplication with fuzzy matching to prevent duplicate action processing.
        """
        action_description = obj["description"]
        normalized_description = self._normalize_text(action_description)

        # Check if we've already seen this action (using normalized text)
        for existing_desc, existing_id in self.action_text_to_id.items():
            if self._normalize_text(existing_desc) == normalized_description:
                logger.info(
                    f"Duplicate action detected in stream router, skipping: "
                    f"'{action_description[:50]}...' (existing ID: {existing_id})"
                )
                return

        # Generate backend UUID
        backend_id = str(uuid.uuid4())
        obj["id"] = backend_id  # Add ID to object

        # Track action by ORIGINAL description and ID (for action_update matching)
        self.action_text_to_id[action_description] = backend_id
        self.action_ids.add(backend_id)

        logger.debug(f"Generated UUID for action: {backend_id}, description='{action_description[:50]}...'")

        # Route to handler
        if self._action_handler:
            await self._action_handler(obj)
            self.metrics.actions_routed += 1
        else:
            logger.warning("ActionHandler not registered - action not processed")

    async def _route_action_update(self, obj: Dict[str, Any]) -> None:
        """
        Route action_update object to ActionHandler.

        Matches action_update to existing action by action_text.
        """
        action_text = obj.get("action_text", "")

        # Try to find matching action by text
        backend_id = self.action_text_to_id.get(action_text)

        if not backend_id:
            logger.warning(
                f"Action update for unknown action text: '{action_text[:50]}...'. "
                "Action may not have been detected yet or text doesn't match exactly."
            )
            # Don't route - can't match to existing action
            return

        # Add backend ID to object
        obj["id"] = backend_id

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
        """
        question_text = obj.get("question_text", "")

        # Try to find matching question by text
        backend_id = self.question_text_to_id.get(question_text)

        if not backend_id:
            logger.warning(
                f"Answer for unknown question text: '{question_text[:50]}...'. "
                "Question may not have been detected yet or text doesn't match exactly."
            )
            # Don't route - can't match to existing question
            return

        # Add backend question_id to object
        obj["question_id"] = backend_id

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
