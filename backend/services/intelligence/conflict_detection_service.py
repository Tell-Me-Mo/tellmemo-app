"""
Conflict Detection Service

Detects when current meeting discussions conflict with past decisions.
Part of Phase 3: Real-Time Conflict Detection (Active Meeting Intelligence)

This service uses semantic similarity and LLM reasoning to identify when
a current statement contradicts or conflicts with previous decisions.
"""

from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


@dataclass
class ConflictAlert:
    """Alert for a detected conflict with past decisions"""
    current_statement: str
    current_type: str  # 'decision', 'action_item'
    conflicting_content_id: str
    conflicting_title: str
    conflicting_snippet: str
    conflicting_date: datetime
    conflict_severity: str  # 'high', 'medium', 'low'
    confidence: float  # 0.0 to 1.0
    reasoning: str
    resolution_suggestions: List[str]
    timestamp: datetime


class ConflictDetectionService:
    """
    Service for detecting conflicts between current meeting discussions
    and past decisions using RAG and LLM reasoning.
    """

    SIMILARITY_THRESHOLD = 0.75  # High similarity indicates potential conflict
    MIN_CONFIDENCE_THRESHOLD = 0.7

    def __init__(
        self,
        vector_store,
        llm_client,
        embedding_service,
        search_cache=None
    ):
        self.vector_store = vector_store
        self.llm_client = llm_client
        self.embedding_service = embedding_service
        self.search_cache = search_cache  # Shared search cache for optimization

    async def detect_conflicts(
        self,
        statement: str,
        statement_type: str,
        project_id: str,
        organization_id: str,
        context: str = "",
        session_id: Optional[str] = None
    ) -> Optional[ConflictAlert]:
        """
        Detect if a statement conflicts with past decisions.
        Returns None if no conflict is detected.

        Args:
            statement: Current meeting statement
            statement_type: Type of statement ('decision', 'action_item')
            project_id: Project UUID
            organization_id: Organization UUID
            context: Recent meeting context
            session_id: Optional session ID for cache optimization

        Returns:
            ConflictAlert if conflict detected, None otherwise
        """

        # Step 1: Search for semantically similar past decisions
        similar_decisions = await self._search_similar_decisions(
            statement=statement,
            project_id=project_id,
            organization_id=organization_id,
            session_id=session_id
        )

        if not similar_decisions:
            logger.info(f"No similar past decisions found for: {statement[:50]}")
            return None

        # Step 2: Use LLM to determine if there's an actual conflict
        conflict_analysis = await self._analyze_conflict(
            current_statement=statement,
            statement_type=statement_type,
            similar_decisions=similar_decisions,
            context=context
        )

        if not conflict_analysis or not conflict_analysis.get('is_conflict'):
            logger.info(f"No conflict detected for: {statement[:50]}")
            return None

        # Step 3: Check confidence threshold
        if conflict_analysis['confidence'] < self.MIN_CONFIDENCE_THRESHOLD:
            logger.info(
                f"Conflict confidence {conflict_analysis['confidence']} "
                f"below threshold {self.MIN_CONFIDENCE_THRESHOLD}"
            )
            return None

        # Step 4: Build ConflictAlert
        conflicting_decision = similar_decisions[0]  # Highest similarity
        payload = conflicting_decision.get('payload', {})

        alert = ConflictAlert(
            current_statement=statement,
            current_type=statement_type,
            conflicting_content_id=conflicting_decision['id'],
            conflicting_title=payload.get('title', 'Untitled'),
            conflicting_snippet=payload.get('text', '')[:300],
            conflicting_date=datetime.fromisoformat(
                payload.get('created_at', datetime.now().isoformat())
            ),
            conflict_severity=conflict_analysis['severity'],
            confidence=conflict_analysis['confidence'],
            reasoning=conflict_analysis['reasoning'],
            resolution_suggestions=conflict_analysis.get('suggestions', []),
            timestamp=datetime.now()
        )

        logger.info(
            f"Conflict detected! Severity: {alert.conflict_severity}, "
            f"Confidence: {alert.confidence:.2f}"
        )

        return alert

    async def _search_similar_decisions(
        self,
        statement: str,
        project_id: str,
        organization_id: str,
        session_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[dict]:
        """
        Search vector database for semantically similar past decisions.

        Uses shared search cache if available and session_id is provided.

        Returns:
            List of similar decision documents with scores
        """

        try:
            # Use shared cache if available
            if self.search_cache and session_id:
                logger.debug(f"[Phase 3] Attempting to use shared search cache for session {session_id[:8]}...")
                search_results = await self.search_cache.get_or_search(
                    session_id=session_id,
                    query=statement,
                    project_id=project_id,
                    organization_id=organization_id,
                    embedding_service=self.embedding_service,
                    vector_store=self.vector_store,
                    search_params={
                        'limit': top_k,
                        'filter_dict': {
                            "project_id": project_id
                        },
                        'score_threshold': self.SIMILARITY_THRESHOLD
                    }
                )
            else:
                # Fallback to direct search if no cache
                logger.debug("[Phase 3] No cache available, performing direct search")
                statement_embedding = await self.embedding_service.generate_embedding(statement)
                search_results = await self.vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=statement_embedding,
                    collection_type="content",
                    limit=top_k,
                    filter_dict={
                        "project_id": project_id
                    },
                    score_threshold=self.SIMILARITY_THRESHOLD
                )

            # Filter by similarity threshold
            relevant_results = [
                r for r in search_results
                if r['score'] >= self.SIMILARITY_THRESHOLD
            ]

            logger.info(
                f"Found {len(relevant_results)} similar decisions "
                f"(threshold: {self.SIMILARITY_THRESHOLD})"
            )

            return relevant_results

        except Exception as e:
            logger.error(f"Error searching similar decisions: {e}")
            return []

    async def _analyze_conflict(
        self,
        current_statement: str,
        statement_type: str,
        similar_decisions: List[dict],
        context: str
    ) -> Optional[dict]:
        """
        Use LLM to analyze whether current statement conflicts with past decisions.

        Returns:
            dict with conflict analysis or None
        """

        # Build prompt with similar decisions
        past_decisions_text = "\n\n".join([
            f"[Decision {i+1}] {result.get('payload', {}).get('title', 'Untitled')} "
            f"({result.get('payload', {}).get('created_at', '')[:10]})\n"
            f"{result.get('payload', {}).get('text', '')[:400]}..."
            for i, result in enumerate(similar_decisions[:3])
        ])

        prompt = f"""
You are analyzing a meeting for potential conflicts with past decisions.

Current Meeting Context:
{context}

Current Statement ({statement_type}):
"{current_statement}"

Past Similar Decisions:
{past_decisions_text}

Task:
Determine if the current statement conflicts with, contradicts, or reverses any of the past decisions.

Important:
- A conflict means a direct contradiction or reversal of a previous decision
- Similar but compatible decisions are NOT conflicts
- Refinements or additions to past decisions are NOT conflicts
- Only flag genuine contradictions

Response Format (JSON):
{{
    "is_conflict": true/false,
    "confidence": 0.0-1.0,
    "severity": "high/medium/low",  // Only if is_conflict is true
    "reasoning": "Brief explanation of the conflict",
    "conflicting_decision_index": 0-2,  // Which past decision conflicts (0-2)
    "suggestions": [
        "Suggestion 1 for resolving the conflict",
        "Suggestion 2 for resolving the conflict"
    ]
}}

Severity Guide:
- high: Direct reversal of a recent decision (<30 days)
- medium: Conflicts with older decision or partial contradiction
- low: Potentially conflicting but requires clarification

If NO conflict exists, respond:
{{"is_conflict": false, "confidence": 0.0}}
"""

        response = await self.llm_client.create_message(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=400,
            temperature=0.3
        )

        # Parse JSON response
        import json
        try:
            analysis = json.loads(response.content[0].text)
            return analysis
        except json.JSONDecodeError:
            logger.error(
                f"Failed to parse conflict analysis JSON: {response.content[0].text}"
            )
            return None
