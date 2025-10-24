"""
Follow-up Suggestions Service - Phase 5 of Active Meeting Intelligence

This service suggests related topics to discuss based on current conversation by:
1. Finding related content with open items from past meetings
2. Finding related decisions with downstream implications
3. Analyzing relevance and urgency using LLM
4. Providing context for each suggestion

Author: Claude Code AI Assistant
Date: October 20, 2025
"""

from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime, timezone
import logging
import json

logger = logging.getLogger(__name__)


@dataclass
class FollowUpSuggestion:
    """Suggestion for a follow-up topic to discuss"""
    topic: str
    reason: str
    related_content_id: str
    related_title: str
    related_date: datetime
    urgency: str  # 'high', 'medium', 'low'
    context_snippet: str
    confidence: float


class FollowUpSuggestionsService:
    """
    Service for suggesting follow-up topics based on current conversation.

    Triggers:
    - When a topic is mentioned that has open items from past meetings
    - When a decision is made that has downstream implications
    - When a project milestone is discussed
    """

    # Similarity threshold for related content
    SIMILARITY_THRESHOLD = 0.70

    # Minimum confidence to suggest a follow-up (Lowered from 0.65 to 0.55 - Oct 2025)
    MIN_CONFIDENCE_THRESHOLD = 0.55

    # Maximum days back to search for related content
    MAX_DAYS_LOOKBACK = 30

    def __init__(self, vector_store, llm_client, embedding_service, search_cache=None):
        """
        Initialize follow-up suggestions service.

        Args:
            vector_store: Qdrant vector store for semantic search
            llm_client: Claude LLM client for analysis
            embedding_service: Service for generating embeddings
            search_cache: Optional shared search cache for optimization
        """
        self.vector_store = vector_store
        self.llm_client = llm_client
        self.embedding_service = embedding_service
        self.search_cache = search_cache  # Shared search cache for optimization

    async def suggest_follow_ups(
        self,
        current_topic: str,
        insight_type: str,
        project_id: str,
        organization_id: str,
        context: str = "",
        session_id: Optional[str] = None
    ) -> List[FollowUpSuggestion]:
        """
        Based on current topic, suggest related follow-ups.

        Args:
            current_topic: The current topic being discussed
            insight_type: Type of insight (decision, action_item, etc.)
            project_id: Current project ID
            organization_id: Current organization ID
            context: Current meeting context
            session_id: Optional session ID for cache optimization

        Returns:
            List of follow-up suggestions, sorted by urgency
        """

        try:
            # 1. Search for related content with open items (using shared cache)
            related_open_items = await self._search_open_items(
                topic=current_topic,
                project_id=project_id,
                organization_id=organization_id,
                session_id=session_id
            )

            # 2. Search for related decisions with implications (using shared cache)
            related_decisions = await self._search_related_decisions(
                topic=current_topic,
                project_id=project_id,
                organization_id=organization_id,
                session_id=session_id
            )

            # Combine results
            related_content = related_open_items + related_decisions

            if not related_content:
                logger.debug(f"No related content found for topic: {current_topic}")
                return []

            # 3. Use LLM to determine relevance and urgency
            suggestions = await self._analyze_follow_ups(
                current_topic=current_topic,
                insight_type=insight_type,
                related_content=related_content,
                context=context
            )

            # 4. Filter by confidence and sort by urgency
            low_confidence_count = len([s for s in suggestions if s.confidence < self.MIN_CONFIDENCE_THRESHOLD])
            if low_confidence_count > 0:
                logger.warning(
                    f"🚫 Follow-up suggestions FILTERED (low confidence): "
                    f"{low_confidence_count} suggestions below threshold {self.MIN_CONFIDENCE_THRESHOLD}"
                )

            high_confidence_suggestions = [
                s for s in suggestions
                if s.confidence >= self.MIN_CONFIDENCE_THRESHOLD
            ]

            # Sort by urgency (high → medium → low) then by confidence
            urgency_order = {'high': 0, 'medium': 1, 'low': 2}
            sorted_suggestions = sorted(
                high_confidence_suggestions,
                key=lambda x: (urgency_order.get(x.urgency, 3), -x.confidence)
            )

            logger.info(
                f"Generated {len(sorted_suggestions)} follow-up suggestions "
                f"for topic: {current_topic[:50]}..."
            )

            return sorted_suggestions[:3]  # Return top 3

        except Exception as e:
            logger.error(f"Error generating follow-up suggestions: {e}", exc_info=True)
            return []

    async def _search_open_items(
        self,
        topic: str,
        project_id: str,
        organization_id: str,
        session_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[dict]:
        """
        Search for related content with open items (action items, questions).

        Uses shared search cache if available and session_id is provided.

        Args:
            topic: Topic to search for
            project_id: Project ID
            organization_id: Organization ID
            session_id: Optional session ID for cache optimization
            top_k: Number of results to return

        Returns:
            List of related content dictionaries
        """

        try:
            # Use shared cache if available
            if self.search_cache and session_id:
                logger.debug(f"[Phase 5] Attempting to use shared search cache for session {session_id[:8]}...")
                results = await self.search_cache.get_or_search(
                    session_id=session_id,
                    query=topic,
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
                logger.debug("[Phase 5] No cache available, performing direct search")
                topic_embedding = await self.embedding_service.generate_embedding(topic)
                results = await self.vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=topic_embedding,
                    collection_type="content",
                    limit=top_k,
                    filter_dict={
                        "project_id": project_id
                    },
                    score_threshold=self.SIMILARITY_THRESHOLD
                )

            # Format results
            related_items = []
            for r in results:
                if r['score'] >= self.SIMILARITY_THRESHOLD:
                    related_items.append({
                        'id': r['id'],
                        'title': r.get('payload', {}).get('title', 'Untitled'),
                        'text': r.get('payload', {}).get('text', ''),
                        'date': r.get('payload', {}).get('created_at', datetime.now(timezone.utc).isoformat()),
                        'content_type': r.get('payload', {}).get('content_type', 'unknown'),
                        'score': r['score']
                    })

            return related_items

        except Exception as e:
            logger.error(f"Error searching open items: {e}")
            return []

    async def _search_related_decisions(
        self,
        topic: str,
        project_id: str,
        organization_id: str,
        session_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[dict]:
        """
        Search for related past decisions with potential implications.

        Uses shared search cache if available and session_id is provided.
        Note: This will reuse the cache from _search_open_items if the query is similar enough.

        Args:
            topic: Topic to search for
            project_id: Project ID
            organization_id: Organization ID
            session_id: Optional session ID for cache optimization
            top_k: Number of results to return

        Returns:
            List of related decision dictionaries
        """

        try:
            # Use shared cache if available (may reuse results from _search_open_items!)
            if self.search_cache and session_id:
                logger.debug(f"[Phase 5] Attempting to use shared search cache for session {session_id[:8]}...")
                results = await self.search_cache.get_or_search(
                    session_id=session_id,
                    query=topic,
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
                logger.debug("[Phase 5] No cache available, performing direct search")
                topic_embedding = await self.embedding_service.generate_embedding(topic)
                results = await self.vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=topic_embedding,
                    collection_type="content",
                    limit=top_k,
                    filter_dict={
                        "project_id": project_id
                    },
                    score_threshold=self.SIMILARITY_THRESHOLD
                )

            # Format results
            related_decisions = []
            for r in results:
                if r['score'] >= self.SIMILARITY_THRESHOLD:
                    related_decisions.append({
                        'id': r['id'],
                        'title': r.get('payload', {}).get('title', 'Untitled'),
                        'text': r.get('payload', {}).get('text', ''),
                        'date': r.get('payload', {}).get('created_at', datetime.now(timezone.utc).isoformat()),
                        'content_type': 'decision',
                        'score': r['score']
                    })

            return related_decisions

        except Exception as e:
            logger.error(f"Error searching related decisions: {e}")
            return []

    async def _analyze_follow_ups(
        self,
        current_topic: str,
        insight_type: str,
        related_content: List[dict],
        context: str
    ) -> List[FollowUpSuggestion]:
        """
        Use LLM to analyze which related content should be suggested as follow-ups.

        Args:
            current_topic: Current discussion topic
            insight_type: Type of current insight
            related_content: List of related content from search
            context: Current meeting context

        Returns:
            List of FollowUpSuggestion objects
        """

        # Build context from related content
        related_text = "\n\n".join([
            f"[{i+1}] {item['title']} ({item['date']})\n"
            f"Type: {item['content_type']}\n"
            f"{item['text'][:300]}..."
            for i, item in enumerate(related_content[:5])
        ])

        prompt = f"""
You are an AI meeting assistant helping identify relevant follow-up topics.

Current Discussion:
Type: {insight_type}
Topic: "{current_topic}"

Meeting Context:
{context[:500]}

Related Past Content:
{related_text}

Task: Identify which past items (if any) should be brought up as follow-up suggestions.

Consider:
- Are there open action items related to current topic?
- Are there past decisions with downstream implications?
- Has enough time passed that an update is warranted?
- Would discussing this add value to the meeting?

For each relevant item, assess urgency:
- "high": Blocking current discussion or overdue
- "medium": Important but not urgent
- "low": Nice to have, contextual information

Response Format (JSON array):
[
  {{
    "item_index": 0-4,
    "topic": "Brief topic name (3-5 words)",
    "reason": "Why bring this up now (1 sentence)",
    "urgency": "high/medium/low",
    "confidence": 0.0-1.0
  }}
]

If no relevant follow-ups, respond: []

Be selective - only suggest truly relevant follow-ups (confidence >= 0.65).
Maximum 3 suggestions.
"""

        try:
            response = await self.llm_client.create_message(
                messages=[{"role": "user", "content": prompt}],
                max_tokens=500,
                temperature=0.4
            )

            # Parse JSON response
            suggestions_data = json.loads(response.content[0].text)

            if not suggestions_data:
                return []

            # Build FollowUpSuggestion objects
            suggestions = []
            for suggestion in suggestions_data:
                try:
                    item_index = suggestion['item_index']
                    if item_index < len(related_content):
                        related_item = related_content[item_index]

                        suggestions.append(FollowUpSuggestion(
                            topic=suggestion['topic'],
                            reason=suggestion['reason'],
                            related_content_id=related_item['id'],
                            related_title=related_item['title'],
                            related_date=datetime.fromisoformat(
                                related_item['date'].replace('Z', '+00:00')
                            ),
                            urgency=suggestion['urgency'],
                            context_snippet=related_item['text'][:200],
                            confidence=suggestion['confidence']
                        ))
                except (KeyError, IndexError) as e:
                    logger.warning(f"Skipping malformed suggestion: {e}")
                    continue

            return suggestions

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse LLM response as JSON: {e}")
            return []
        except Exception as e:
            logger.error(f"Error analyzing follow-ups: {e}")
            return []
