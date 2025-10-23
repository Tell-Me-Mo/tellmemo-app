"""
Question Answering Service

Uses RAG (Retrieval-Augmented Generation) to automatically answer questions
detected during live meetings by searching past meeting content.
"""

from dataclasses import dataclass, field
from typing import List, Optional
from datetime import datetime
import logging
import json

logger = logging.getLogger(__name__)


@dataclass
class AnswerSource:
    """Source document used for answer"""
    content_id: str
    title: str
    snippet: str
    date: datetime
    relevance_score: float
    meeting_type: str = "unknown"  # e.g., "standup", "planning", etc.


@dataclass
class Answer:
    """Synthesized answer to a question"""
    question: str
    answer_text: str
    confidence: float  # 0.0 to 1.0
    sources: List[AnswerSource] = field(default_factory=list)
    reasoning: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


class QuestionAnsweringService:
    """
    Service for automatically answering questions using RAG.
    """

    def __init__(
        self,
        vector_store,
        llm_client,
        embedding_service,
        search_cache=None,
        min_confidence_threshold: float = 0.7
    ):
        self.vector_store = vector_store
        self.llm_client = llm_client
        self.embedding_service = embedding_service
        self.search_cache = search_cache  # Shared search cache for optimization
        self.min_confidence_threshold = min_confidence_threshold

    async def answer_question(
        self,
        question: str,
        question_type: str,
        project_id: str,
        organization_id: str,
        context: str = "",
        session_id: Optional[str] = None
    ) -> Optional[Answer]:
        """
        Attempt to answer a question using RAG.
        Returns None if no confident answer can be provided.
        """

        logger.info(f"Attempting to answer question: {question}")

        # 1. Search knowledge base for relevant content
        search_results = await self._search_knowledge_base(
            question=question,
            project_id=project_id,
            organization_id=organization_id,
            session_id=session_id,
            top_k=10
        )

        if not search_results:
            logger.info(f"No relevant content found for question: {question}")
            return None

        # 2. Filter results by relevance threshold
        relevant_results = [
            r for r in search_results
            if r.get('score', 0) >= 0.7  # High relevance threshold
        ]

        if not relevant_results:
            logger.info(f"No highly relevant results for: {question}")
            return None

        # 3. Synthesize answer using LLM
        answer = await self._synthesize_answer(
            question=question,
            question_type=question_type,
            search_results=relevant_results,
            context=context
        )

        # 4. Check confidence threshold
        if answer and answer.confidence < self.min_confidence_threshold:
            logger.info(
                f"Answer confidence {answer.confidence} below threshold "
                f"{self.min_confidence_threshold}"
            )
            return None

        return answer

    async def _search_knowledge_base(
        self,
        question: str,
        project_id: str,
        organization_id: str,
        session_id: Optional[str] = None,
        top_k: int = 10
    ) -> List[dict]:
        """
        Search vector database for relevant content.

        Uses shared search cache if available and session_id is provided.
        """

        try:
            # Use shared cache if available
            if self.search_cache and session_id:
                logger.debug(f"[Phase 1] Attempting to use shared search cache for session {session_id[:8]}...")
                search_results = await self.search_cache.get_or_search(
                    session_id=session_id,
                    query=question,
                    project_id=project_id,
                    organization_id=organization_id,
                    embedding_service=self.embedding_service,
                    vector_store=self.vector_store,
                    search_params={
                        'limit': top_k,
                        'filter_dict': {
                            "project_id": project_id,
                            "content_type": "transcript"
                        },
                        'score_threshold': 0.5
                    }
                )
            else:
                # Fallback to direct search if no cache
                logger.debug("[Phase 1] No cache available, performing direct search")
                question_embedding = await self.embedding_service.generate_embedding(question)
                search_results = await self.vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=question_embedding,
                    collection_type="content",
                    limit=top_k,
                    filter_dict={
                        "project_id": project_id,
                        "content_type": "transcript"
                    },
                    score_threshold=0.5
                )

            return search_results
        except Exception as e:
            logger.error(f"Failed to search knowledge base: {e}")
            return []

    async def _synthesize_answer(
        self,
        question: str,
        question_type: str,
        search_results: List[dict],
        context: str
    ) -> Optional[Answer]:
        """Use LLM to synthesize answer from search results"""

        # Build prompt with search results
        sources_text = "\n\n".join([
            f"[Source {i+1}] {result.get('payload', {}).get('title', 'Untitled')} "
            f"({result.get('payload', {}).get('created_at', 'Unknown date')})\n"
            f"{result.get('payload', {}).get('text', '')[:500]}..."
            for i, result in enumerate(search_results[:5])
        ])

        prompt = f"""You are an AI assistant helping answer questions during a meeting.

Question Type: {question_type}
Question: {question}

Current Meeting Context:
{context[:500] if context else 'None'}

Relevant Information from Past Meetings:
{sources_text}

Instructions:
1. Provide a direct, concise answer to the question based on the sources
2. If the sources contain the answer, state it clearly and cite which source(s)
3. If the sources don't fully answer the question, say so explicitly
4. Keep the answer under 3 sentences for brevity
5. Include your confidence level (0.0 to 1.0)

Response Format (JSON):
{{
    "answer": "Your answer here",
    "confidence": 0.0-1.0,
    "sources_used": [1, 2],
    "reasoning": "Brief explanation of how you derived the answer"
}}"""

        try:
            response = await self.llm_client.create_message(
                messages=[{"role": "user", "content": prompt}],
                max_tokens=300,
                temperature=0.3
            )

            # Parse JSON response
            response_text = response.content[0].text.strip()

            # Extract JSON if wrapped in markdown code blocks
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0].strip()
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0].strip()

            response_data = json.loads(response_text)

            # Build Answer object
            sources = []
            for i in response_data.get('sources_used', []):
                if 0 <= i < len(search_results):
                    result = search_results[i]
                    payload = result.get('payload', {})
                    sources.append(AnswerSource(
                        content_id=str(result.get('id', '')),
                        title=payload.get('title', 'Untitled'),
                        snippet=payload.get('text', '')[:200],
                        date=datetime.fromisoformat(payload.get('created_at', datetime.now().isoformat())),
                        relevance_score=result.get('score', 0.0),
                        meeting_type=payload.get('meeting_type', 'unknown')
                    ))

            return Answer(
                question=question,
                answer_text=response_data.get('answer', 'Unable to determine answer'),
                confidence=float(response_data.get('confidence', 0.0)),
                sources=sources,
                reasoning=response_data.get('reasoning', ''),
                timestamp=datetime.now()
            )

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse LLM response as JSON: {e}")
            logger.error(f"Response was: {response.content[0].text if response else 'None'}")
            return Answer(
                question=question,
                answer_text="Could not generate answer",
                confidence=0.0,
                sources=[],
                reasoning="Failed to parse response",
                timestamp=datetime.now()
            )
        except Exception as e:
            logger.error(f"Failed to synthesize answer: {e}")
            return None
