"""
Repetition Detector Service for Phase 6: Meeting Efficiency Features

Detects when the same topic is being discussed repeatedly without progress,
helping teams recognize when they're going in circles.
"""

from dataclasses import dataclass
from typing import List, Optional, Dict
from datetime import datetime, timezone
import logging
from collections import defaultdict

logger = logging.getLogger(__name__)


@dataclass
class RepetitionAlert:
    """Alert for detected repetition in discussion"""
    topic: str
    first_mention_index: int
    current_mention_index: int
    occurrences: int
    time_span_minutes: float
    confidence: float
    reasoning: str
    suggestions: List[str]
    timestamp: datetime


class RepetitionDetectorService:
    """
    Service for detecting repetitive discussion topics that aren't making progress.

    Helps teams recognize when they're discussing the same thing multiple times
    without reaching a decision or making progress.
    """

    # Configuration
    MIN_OCCURRENCES = 3  # Topic must appear at least 3 times
    MIN_SIMILARITY = 0.75  # Semantic similarity threshold
    TIME_WINDOW_MINUTES = 15  # Look back window
    MIN_CONFIDENCE = 0.65  # Minimum confidence to alert (Lowered from 0.7 - Oct 2025)

    def __init__(self, llm_client, embedding_service):
        self.llm_client = llm_client
        self.embedding_service = embedding_service
        # Session-specific topic tracking
        self.session_topics: Dict[str, List[Dict]] = defaultdict(list)

    async def detect_repetition(
        self,
        session_id: str,
        current_text: str,
        chunk_index: int,
        chunk_timestamp: datetime
    ) -> Optional[RepetitionAlert]:
        """
        Detect if current text represents a repetitive topic.

        Args:
            session_id: Meeting session identifier
            current_text: Current discussion text
            chunk_index: Current chunk number
            chunk_timestamp: When this chunk was captured

        Returns:
            RepetitionAlert if repetition detected, None otherwise
        """

        # Skip very short texts
        if len(current_text) < 50:
            return None

        # Generate embedding for current text
        current_embedding = await self.embedding_service.generate_embedding(current_text)

        # Get previous topics for this session
        previous_topics = self.session_topics[session_id]

        # Find similar previous topics
        similar_topics = self._find_similar_topics(
            current_embedding,
            previous_topics,
            chunk_timestamp
        )

        # Add current topic to history
        self.session_topics[session_id].append({
            'text': current_text,
            'embedding': current_embedding,
            'chunk_index': chunk_index,
            'timestamp': chunk_timestamp
        })

        # Check if we have enough repetitions
        if len(similar_topics) < self.MIN_OCCURRENCES - 1:  # -1 because we're adding current
            return None

        # Analyze if this is true repetition (not progress)
        repetition_analysis = await self._analyze_repetition(
            current_text=current_text,
            similar_texts=[t['text'] for t in similar_topics]
        )

        if not repetition_analysis or repetition_analysis['confidence'] < self.MIN_CONFIDENCE:
            if repetition_analysis:
                logger.info(
                    f"🚫 Repetition FILTERED (low confidence): "
                    f"Topic: '{repetition_analysis.get('topic', 'unknown')[:60]}...', "
                    f"Confidence: {repetition_analysis.get('confidence', 0):.2f} < threshold {self.MIN_CONFIDENCE}"
                )
            return None

        # Calculate time span
        first_topic = similar_topics[0]
        time_span = (chunk_timestamp - first_topic['timestamp']).total_seconds() / 60

        # Generate suggestions
        suggestions = self._generate_suggestions(repetition_analysis['reasoning'])

        return RepetitionAlert(
            topic=repetition_analysis['topic'],
            first_mention_index=first_topic['chunk_index'],
            current_mention_index=chunk_index,
            occurrences=len(similar_topics) + 1,  # +1 for current
            time_span_minutes=time_span,
            confidence=repetition_analysis['confidence'],
            reasoning=repetition_analysis['reasoning'],
            suggestions=suggestions,
            timestamp=datetime.now(timezone.utc)
        )

    def _find_similar_topics(
        self,
        current_embedding: List[float],
        previous_topics: List[Dict],
        current_timestamp: datetime
    ) -> List[Dict]:
        """
        Find previous topics similar to current embedding within time window.
        """
        similar_topics = []

        for topic in previous_topics:
            # Check time window
            time_diff = (current_timestamp - topic['timestamp']).total_seconds() / 60
            if time_diff > self.TIME_WINDOW_MINUTES:
                continue

            # Calculate cosine similarity
            similarity = self._cosine_similarity(current_embedding, topic['embedding'])

            if similarity >= self.MIN_SIMILARITY:
                similar_topics.append(topic)

        return similar_topics

    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors"""
        import math

        dot_product = sum(a * b for a, b in zip(vec1, vec2))
        magnitude1 = math.sqrt(sum(a * a for a in vec1))
        magnitude2 = math.sqrt(sum(b * b for b in vec2))

        if magnitude1 == 0 or magnitude2 == 0:
            return 0.0

        return dot_product / (magnitude1 * magnitude2)

    async def _analyze_repetition(
        self,
        current_text: str,
        similar_texts: List[str]
    ) -> Optional[Dict]:
        """
        Use LLM to determine if this is true repetition without progress.
        """

        # Build context from similar texts
        previous_mentions = "\n\n".join([
            f"[Mention {i+1}] {text[:300]}..."
            for i, text in enumerate(similar_texts)
        ])

        prompt = f"""
Analyze if this meeting discussion shows repetitive conversation without progress.

Current Discussion:
"{current_text}"

Previous Similar Mentions:
{previous_mentions}

Task: Determine if the team is discussing the same topic repeatedly without making progress.

Signs of TRUE repetition:
- Same questions being asked multiple times
- Same concerns raised without resolution
- Same options discussed without decision
- Circular reasoning

Signs of PROGRESS (not repetition):
- Building on previous points
- Reaching conclusions
- Making decisions
- Moving through phases of discussion

Response Format (JSON):
{{
    "is_repetition": true/false,
    "topic": "brief topic name (3-5 words)",
    "confidence": 0.0-1.0,
    "reasoning": "Brief explanation of why this is (or isn't) repetition"
}}

Be conservative - only flag clear repetition where no progress is being made.
"""

        response = await self.llm_client.create_message(
            messages=[{"role": "user", "content": prompt}],
            max_tokens=200,
            temperature=0.3
        )

        import json
        try:
            result = json.loads(response.content[0].text)

            if result.get('is_repetition'):
                return {
                    'topic': result['topic'],
                    'confidence': result['confidence'],
                    'reasoning': result['reasoning']
                }
        except Exception as e:
            logger.error(f"Failed to parse repetition analysis: {e}")

        return None

    def _generate_suggestions(self, reasoning: str) -> List[str]:
        """
        Generate actionable suggestions for breaking the repetition.
        """
        suggestions = [
            "Consider tabling this discussion and moving forward",
            "Assign someone to research and report back",
            "Set a timer for 2 minutes to reach a decision"
        ]

        # Customize based on reasoning
        if "question" in reasoning.lower():
            suggestions.append("Document open questions for follow-up")

        if "concern" in reasoning.lower():
            suggestions.append("List concerns and address them one by one")

        if "decision" in reasoning.lower():
            suggestions.append("Take a vote or assign decision owner")

        return suggestions[:4]  # Max 4 suggestions

    def clear_session(self, session_id: str):
        """Clear topic history for a session when meeting ends"""
        if session_id in self.session_topics:
            del self.session_topics[session_id]
            logger.info(f"Cleared repetition history for session {session_id}")
