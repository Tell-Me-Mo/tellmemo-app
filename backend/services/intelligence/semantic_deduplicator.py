"""
Semantic deduplication service using embeddings + AI.
Combines fast embedding similarity with intelligent merge strategies.
"""

import logging
from typing import Dict, Any, List, Optional, Tuple
import numpy as np
from services.rag.embedding_service import embedding_service
from services.llm.multi_llm_client import get_multi_llm_client
from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class SemanticDeduplicator:
    """
    Hybrid deduplication system:
    1. Fast embedding-based similarity (deterministic, 85%+ threshold)
    2. AI-powered merge decision (extract updates from duplicates)
    """

    def __init__(self):
        self.embedding_service = embedding_service
        self.llm_client = get_multi_llm_client()

        # Similarity thresholds (configurable via settings)
        # NOTE: We compare title + description for better context
        # With combined text, standard thresholds work well
        self.HIGH_SIMILARITY_THRESHOLD = getattr(settings, 'semantic_similarity_high_threshold', 0.85)
        self.MEDIUM_SIMILARITY_THRESHOLD = getattr(settings, 'semantic_similarity_medium_threshold', 0.75)
        self.LOW_SIMILARITY_THRESHOLD = 0.65  # Minimum to even consider as potential match

        # Feature flags
        self.enable_semantic_dedup = getattr(settings, 'enable_semantic_deduplication', True)
        self.use_ai_fallback = getattr(settings, 'semantic_dedup_use_ai_fallback', True)

    async def deduplicate_items(
        self,
        item_type: str,  # 'risk', 'task', 'blocker', 'lesson'
        new_items: List[Dict[str, Any]],
        existing_items: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Deduplicate new items against existing ones with intelligent merging.

        Args:
            item_type: Type of items ('risk', 'task', 'blocker', 'lesson')
            new_items: List of newly extracted items
            existing_items: List of existing items in database

        Returns:
            {
                'unique_items': [...],  # Truly new items to insert
                'updates': [...],       # Items that are duplicates but have new info
                'exact_duplicates': [...],  # Items to skip entirely
                'duplicate_analysis': {...}  # Detailed matching info
            }
        """
        if not new_items:
            return {
                'unique_items': [],
                'updates': [],
                'exact_duplicates': [],
                'duplicate_analysis': {}
            }

        if not self.enable_semantic_dedup:
            # Semantic deduplication disabled - return all as unique
            logger.info(f"Semantic deduplication disabled, treating all {len(new_items)} items as unique")
            return {
                'unique_items': new_items,
                'updates': [],
                'exact_duplicates': [],
                'duplicate_analysis': {}
            }

        # Step 1: Generate embeddings for new items
        # Combine title + description for better semantic matching
        new_texts = [self._combine_text_for_embedding(item) for item in new_items]
        new_embeddings = await self.embedding_service.generate_embeddings_batch(new_texts)

        # Step 2: Get or generate embeddings for existing items
        existing_embeddings = await self._get_existing_embeddings(existing_items)

        # Step 3: Fast embedding-based similarity matching
        matches = self._find_similar_items(
            new_items, new_embeddings,
            existing_items, existing_embeddings
        )

        # Step 4: Classify items based on similarity
        unique_items = []
        potential_updates = []
        exact_duplicates = []
        duplicate_analysis = {}

        for idx, item in enumerate(new_items):
            match_info = matches.get(idx)

            if not match_info:
                # No similar existing item found
                unique_items.append({
                    **item,
                    'title_embedding': new_embeddings[idx]
                })
                duplicate_analysis[idx] = {
                    'status': 'unique',
                    'similarity': 0.0,
                    'matched_to': None
                }

            elif match_info['similarity'] >= self.HIGH_SIMILARITY_THRESHOLD:
                # High similarity - likely duplicate, check for updates
                potential_updates.append({
                    'new_item': item,
                    'new_embedding': new_embeddings[idx],
                    'existing_item': match_info['existing_item'],
                    'similarity': match_info['similarity'],
                    'item_index': idx
                })
                duplicate_analysis[idx] = {
                    'status': 'high_similarity',
                    'similarity': match_info['similarity'],
                    'matched_to': match_info['existing_item'].get('title')
                }

            elif match_info['similarity'] >= self.MEDIUM_SIMILARITY_THRESHOLD and self.use_ai_fallback:
                # Medium similarity - use AI to decide
                potential_updates.append({
                    'new_item': item,
                    'new_embedding': new_embeddings[idx],
                    'existing_item': match_info['existing_item'],
                    'similarity': match_info['similarity'],
                    'item_index': idx,
                    'needs_ai_review': True
                })
                duplicate_analysis[idx] = {
                    'status': 'medium_similarity_ai_review',
                    'similarity': match_info['similarity'],
                    'matched_to': match_info['existing_item'].get('title')
                }

            else:
                # Low similarity - treat as unique
                unique_items.append({
                    **item,
                    'title_embedding': new_embeddings[idx]
                })
                duplicate_analysis[idx] = {
                    'status': 'unique_below_threshold',
                    'similarity': match_info['similarity'] if match_info else 0.0,
                    'matched_to': None
                }

        # Step 5: Use AI to extract meaningful updates from potential duplicates
        updates = await self._extract_updates_from_duplicates(
            item_type, potential_updates
        )

        # Separate true updates from exact duplicates
        actual_updates = [u for u in updates if u.get('has_new_info')]
        exact_duplicates = [u for u in updates if not u.get('has_new_info')]

        logger.info(
            f"Deduplication results for {item_type}: "
            f"{len(unique_items)} unique, {len(actual_updates)} updates, "
            f"{len(exact_duplicates)} exact duplicates"
        )

        return {
            'unique_items': unique_items,
            'updates': actual_updates,
            'exact_duplicates': exact_duplicates,
            'duplicate_analysis': duplicate_analysis
        }

    def _find_similar_items(
        self,
        new_items: List[Dict],
        new_embeddings: List[List[float]],
        existing_items: List[Dict],
        existing_embeddings: List[List[float]]
    ) -> Dict[int, Dict]:
        """
        Find most similar existing item for each new item using cosine similarity.

        Returns:
            Dict mapping new_item_index -> {existing_item, similarity}
        """
        if not existing_items or not existing_embeddings:
            return {}

        matches = {}

        for new_idx, new_emb in enumerate(new_embeddings):
            best_similarity = 0.0
            best_match = None

            for existing_idx, existing_emb in enumerate(existing_embeddings):
                similarity = self._cosine_similarity(new_emb, existing_emb)

                if similarity > best_similarity and similarity >= self.LOW_SIMILARITY_THRESHOLD:
                    best_similarity = similarity
                    best_match = existing_items[existing_idx]
                    logger.debug(f"Match found: '{new_items[new_idx].get('title')}' vs '{existing_items[existing_idx].get('title')}' - similarity: {similarity:.3f}")

            if best_match:
                matches[new_idx] = {
                    'existing_item': best_match,
                    'similarity': best_similarity
                }

        return matches

    def _combine_text_for_embedding(self, item: Dict[str, Any]) -> str:
        """
        Combine title and description for better semantic matching.

        STRATEGY: Always use title + description for embedding generation.

        Why this matters:
        - Title-only embeddings miss crucial context (e.g., "Budget Risk" is too generic)
        - Title + description provides semantic richness for accurate matching
        - This strategy MUST be used consistently for both new and existing items

        Example:
          Title: "Budget Risk"
          Description: "Potential cost overrun in Q3 due to vendor delays"
          Combined: "Budget Risk. Potential cost overrun in Q3 due to vendor delays"

        This combined text creates a much more distinctive embedding vector,
        reducing false positives when comparing similar items.
        """
        title = item.get('title', '').strip()
        description = item.get('description', '').strip()

        # Combine with a separator for better sentence boundary detection
        if title and description:
            return f"{title}. {description}"
        elif title:
            return title
        elif description:
            return description
        else:
            return "untitled"

    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors."""
        try:
            v1 = np.array(vec1)
            v2 = np.array(vec2)

            dot_product = np.dot(v1, v2)
            norm1 = np.linalg.norm(v1)
            norm2 = np.linalg.norm(v2)

            if norm1 == 0 or norm2 == 0:
                return 0.0

            return float(dot_product / (norm1 * norm2))
        except Exception as e:
            logger.error(f"Error calculating cosine similarity: {e}")
            return 0.0

    async def _get_existing_embeddings(
        self,
        existing_items: List[Dict[str, Any]]
    ) -> List[List[float]]:
        """
        Get embeddings for existing items.

        IMPORTANT: Always regenerates embeddings to ensure consistency.

        We cannot trust cached embeddings because:
        1. Old embeddings might be title-only (before combined text strategy)
        2. Comparing title+description vs title-only creates dimension mismatches
        3. This causes incorrect similarity scores and false positives/negatives

        Solution: Always embed title + description for ALL items (new and existing).
        This ensures apples-to-apples comparison.

        Performance note: This is acceptable because:
        - Embedding generation is fast (~50ms for batch of 10)
        - Deduplication only runs on new items (small batches)
        - Correctness > slight performance gain from caching
        """
        embeddings = []
        items_to_embed = []

        # Always regenerate embeddings with title + description
        for item in existing_items:
            items_to_embed.append(self._combine_text_for_embedding(item))

        # Generate all embeddings
        if items_to_embed:
            logger.debug(f"Generating {len(items_to_embed)} embeddings for existing items (always regenerating for consistency)")
            embeddings = await self.embedding_service.generate_embeddings_batch(
                items_to_embed
            )

        return embeddings

    async def _extract_updates_from_duplicates(
        self,
        item_type: str,
        potential_duplicates: List[Dict]
    ) -> List[Dict]:
        """
        Use AI to determine if duplicates contain meaningful updates.

        For each duplicate pair, extract:
        - Status changes
        - New information (description updates, mitigation updates, etc.)
        - Progress updates
        """
        if not potential_duplicates:
            return []

        updates = []

        # Build prompt for AI to analyze duplicates
        prompt = self._build_update_extraction_prompt(item_type, potential_duplicates)

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                model="claude-3-5-haiku-latest",
                max_tokens=4096,
                temperature=0.1
            )

            # Parse response
            if not response:
                logger.error("LLM returned None response")
                raise Exception("LLM returned None response")

            if not hasattr(response, 'content') or len(response.content) == 0:
                logger.error(f"LLM response has no content. Response type: {type(response)}, Response: {response}")
                raise Exception("LLM response has no content")

            import json
            response_text = response.content[0].text

            if not response_text or not response_text.strip():
                logger.error("LLM returned empty response text")
                raise Exception("LLM returned empty response text")

            logger.debug(f"LLM response text (first 500 chars): {response_text[:500]}")

            # Parse JSON directly (we asked for pure JSON in the prompt)
            parsed = json.loads(response_text.strip())
            ai_analysis = parsed.get('analysis', [])

            # Process AI analysis
            for analysis in ai_analysis:
                try:
                    dup_idx = analysis.get('index', -1)
                    if dup_idx < 0 or dup_idx >= len(potential_duplicates):
                        continue

                    duplicate_info = potential_duplicates[dup_idx]

                    if analysis.get('has_new_info'):
                        updates.append({
                            'existing_item_id': duplicate_info['existing_item']['id'],
                            'existing_item_title': duplicate_info['existing_item']['title'],
                            'new_item': duplicate_info['new_item'],
                            'update_type': analysis.get('update_type'),  # 'status', 'content', 'progress'
                            'new_info': analysis.get('new_info', {}),
                            'confidence': analysis.get('confidence', 0.8),
                            'has_new_info': True,
                            'similarity': duplicate_info['similarity'],
                            'reasoning': analysis.get('reasoning', '')
                        })
                    else:
                        updates.append({
                            'existing_item_id': duplicate_info['existing_item']['id'],
                            'existing_item_title': duplicate_info['existing_item']['title'],
                            'new_item': duplicate_info['new_item'],
                            'has_new_info': False,
                            'similarity': duplicate_info['similarity'],
                            'reasoning': analysis.get('reasoning', 'Exact duplicate with no new information')
                        })
                except Exception as e:
                    logger.error(f"Error processing analysis item: {e}")
                    continue

        except Exception as e:
            logger.error(f"Failed to extract updates from duplicates: {e}")
            # Fallback: treat all high-similarity items as exact duplicates
            for dup in potential_duplicates:
                updates.append({
                    'existing_item_id': dup['existing_item']['id'],
                    'existing_item_title': dup['existing_item']['title'],
                    'new_item': dup['new_item'],
                    'has_new_info': False,
                    'similarity': dup['similarity'],
                    'reasoning': 'AI analysis failed, defaulting to exact duplicate'
                })

        return updates

    def _build_update_extraction_prompt(
        self,
        item_type: str,
        duplicates: List[Dict]
    ) -> str:
        """Build prompt for AI to extract meaningful updates from duplicates."""

        duplicates_text = ""
        for idx, dup in enumerate(duplicates):
            existing = dup['existing_item']
            new = dup['new_item']

            duplicates_text += f"""
Pair {idx}:
Existing {item_type}:
  Title: {existing.get('title')}
  Description: {existing.get('description', 'N/A')[:200]}
  Status: {existing.get('status', 'N/A')}
  {self._get_item_specific_fields(item_type, existing)}

New {item_type}:
  Title: {new.get('title')}
  Description: {new.get('description', 'N/A')[:200]}
  Status: {new.get('status', 'N/A')}
  {self._get_item_specific_fields(item_type, new)}

Similarity: {dup['similarity']:.2f}
---
"""

        return f"""You are a duplicate detection and update extraction system.

Analyze these {item_type} pairs that are semantically similar.

For each pair, determine:
1. Are they truly the same {item_type}? (even if worded differently)
2. If yes, does the new item contain meaningful updates?
3. What type of update? (status, content, progress, metadata)

{duplicates_text}

IMPORTANT INSTRUCTIONS:
- If similarity > 0.90, they're almost certainly duplicates
- Status changes ARE meaningful updates (has_new_info=true)
- Slight rewording without new info = exact duplicate (has_new_info=false)
- New mitigation/resolution info = meaningful update (has_new_info=true)
- Only include fields in new_info that actually changed

Return ONLY valid JSON (no markdown, no code blocks, no explanations - just pure JSON):
{{
  "analysis": [
    {{
      "index": 0,
      "is_duplicate": true,
      "has_new_info": false,
      "update_type": null,
      "new_info": {{}},
      "confidence": 0.95,
      "reasoning": "brief explanation"
    }}
  ]
}}"""

    def _get_item_specific_fields(self, item_type: str, item: Dict) -> str:
        """Get type-specific fields for comparison."""
        if item_type == 'risk':
            return f"Severity: {item.get('severity')}\n  Mitigation: {str(item.get('mitigation', 'N/A'))[:100]}"
        elif item_type == 'task':
            return f"Assignee: {item.get('assignee', 'N/A')}\n  Due: {item.get('due_date', 'N/A')}"
        elif item_type == 'blocker':
            return f"Impact: {item.get('impact')}\n  Resolution: {str(item.get('resolution', 'N/A'))[:100]}"
        elif item_type == 'lesson':
            return f"Category: {item.get('category')}\n  Type: {item.get('lesson_type', 'N/A')}"
        return ""


# Singleton instance
semantic_deduplicator = SemanticDeduplicator()
