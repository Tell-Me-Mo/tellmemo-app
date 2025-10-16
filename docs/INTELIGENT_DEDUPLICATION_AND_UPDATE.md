Elegant Solution for Semantic Duplication & Intelligent Updates

  Based on my analysis of your codebase, I've designed a comprehensive solution that addresses both semantic duplication (Issue #2) and intelligent updates to existing items. Here's the elegant approach:

  ---
  Solution Overview

  The current system uses AI-only deduplication which has inconsistent results (allowing 37 duplicate risk pairs). The elegant solution is a hybrid approach:

  1. Embedding-based semantic similarity (fast, deterministic, reliable)
  2. AI-powered nuance detection (for edge cases and update extraction)
  3. Intelligent merge strategy (instead of just skipping duplicates)

  ---
  Architecture

  Phase 1: Add Embedding Storage to Models

  Add embedding columns to store title embeddings for fast similarity matching:

  # backend/alembic/versions/XXXX_add_embeddings_to_items.py
  """Add embedding columns for semantic deduplication

  Revision ID: XXXX
  """
  from alembic import op
  import sqlalchemy as sa
  from pgvector.sqlalchemy import Vector

  def upgrade():
      # Add embedding columns (768 dimensions for EmbeddingGemma)
      op.add_column('risks', sa.Column('title_embedding', Vector(768), nullable=True))
      op.add_column('tasks', sa.Column('title_embedding', Vector(768), nullable=True))
      op.add_column('lessons_learned', sa.Column('title_embedding', Vector(768), nullable=True))
      op.add_column('blockers', sa.Column('title_embedding', Vector(768), nullable=True))

      # Create indexes for fast similarity search
      op.create_index('idx_risks_embedding', 'risks', ['title_embedding'],
                      postgresql_using='ivfflat',
                      postgresql_with={'lists': 100})
      # Repeat for other tables...

  def downgrade():
      op.drop_index('idx_risks_embedding', 'risks')
      op.drop_column('risks', 'title_embedding')
      # Repeat for other tables...

  Note: This requires pgvector extension. If not available, embeddings can be stored as JSON arrays.

  ---
  Phase 2: Create Semantic Deduplication Service

  # backend/services/intelligence/semantic_deduplicator.py
  """
  Semantic deduplication service using embeddings + AI.
  Combines fast embedding similarity with intelligent merge strategies.
  """

  import logging
  from typing import Dict, Any, List, Optional, Tuple
  import numpy as np
  from services.rag.embedding_service import embedding_service
  from services.llm.multi_llm_client import multi_llm_client

  logger = logging.getLogger(__name__)


  class SemanticDeduplicator:
      """
      Hybrid deduplication system:
      1. Fast embedding-based similarity (deterministic, 85%+ threshold)
      2. AI-powered merge decision (extract updates from duplicates)
      """

      def __init__(self):
          self.embedding_service = embedding_service
          self.llm_client = multi_llm_client

          # Similarity thresholds
          self.HIGH_SIMILARITY_THRESHOLD = 0.85  # Definitely duplicate
          self.MEDIUM_SIMILARITY_THRESHOLD = 0.75  # Needs AI review
          self.LOW_SIMILARITY_THRESHOLD = 0.60  # Different items

      async def deduplicate_items(
          self,
          item_type: str,  # 'risk', 'task', 'blocker', 'lesson'
          new_items: List[Dict[str, Any]],
          existing_items: List[Dict[str, Any]]
      ) -> Dict[str, Any]:
          """
          Deduplicate new items against existing ones with intelligent merging.
          
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

          # Step 1: Generate embeddings for new items
          new_titles = [item.get('title', '') for item in new_items]
          new_embeddings = await self.embedding_service.generate_embeddings_batch(new_titles)

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

              elif match_info['similarity'] >= self.MEDIUM_SIMILARITY_THRESHOLD:
                  # Medium similarity - use AI to decide
                  potential_updates.append({
                      'new_item': item,
                      'new_embedding': new_embeddings[idx],
                      'existing_item': match_info['existing_item'],
                      'similarity': match_info['similarity'],
                      'item_index': idx,
                      'needs_ai_review': True
                  })

              else:
                  # Low similarity - treat as unique
                  unique_items.append({
                      **item,
                      'title_embedding': new_embeddings[idx]
                  })

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

              if best_match:
                  matches[new_idx] = {
                      'existing_item': best_match,
                      'similarity': best_similarity
                  }

          return matches

      def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
          """Calculate cosine similarity between two vectors."""
          v1 = np.array(vec1)
          v2 = np.array(vec2)

          dot_product = np.dot(v1, v2)
          norm1 = np.linalg.norm(v1)
          norm2 = np.linalg.norm(v2)

          if norm1 == 0 or norm2 == 0:
              return 0.0

          return float(dot_product / (norm1 * norm2))

      async def _get_existing_embeddings(
          self,
          existing_items: List[Dict[str, Any]]
      ) -> List[List[float]]:
          """
          Get embeddings for existing items.
          Uses cached embeddings if available, otherwise generates new ones.
          """
          embeddings = []
          items_to_embed = []
          items_to_embed_indices = []

          for idx, item in enumerate(existing_items):
              # Check if item has cached embedding
              cached_embedding = item.get('title_embedding')

              if cached_embedding and isinstance(cached_embedding, list):
                  embeddings.append(cached_embedding)
              else:
                  # Need to generate embedding
                  embeddings.append(None)
                  items_to_embed.append(item.get('title', ''))
                  items_to_embed_indices.append(idx)

          # Generate missing embeddings
          if items_to_embed:
              new_embeddings = await self.embedding_service.generate_embeddings_batch(
                  items_to_embed
              )

              # Fill in the missing embeddings
              for i, embedding_idx in enumerate(items_to_embed_indices):
                  embeddings[embedding_idx] = new_embeddings[i]

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
              response = await self.llm_client.call(
                  messages=[{"role": "user", "content": prompt}],
                  model="claude-3-5-haiku-latest",
                  temperature=0.1,
                  response_format="json"
              )

              ai_analysis = response.get('analysis', [])

              # Process AI analysis
              for analysis in ai_analysis:
                  duplicate_info = potential_duplicates[analysis['index']]

                  if analysis.get('has_new_info'):
                      updates.append({
                          'existing_item_id': duplicate_info['existing_item']['id'],
                          'existing_item_title': duplicate_info['existing_item']['title'],
                          'new_item': duplicate_info['new_item'],
                          'update_type': analysis.get('update_type'),  # 'status', 'content', 'progress'
                          'new_info': analysis.get('new_info'),
                          'confidence': analysis.get('confidence', 0.8),
                          'has_new_info': True,
                          'similarity': duplicate_info['similarity']
                      })
                  else:
                      updates.append({
                          'existing_item_id': duplicate_info['existing_item']['id'],
                          'existing_item_title': duplicate_info['existing_item']['title'],
                          'new_item': duplicate_info['new_item'],
                          'has_new_info': False,
                          'similarity': duplicate_info['similarity']
                      })

          except Exception as e:
              logger.error(f"Failed to extract updates from duplicates: {e}")
              # Fallback: treat all high-similarity items as exact duplicates
              for dup in potential_duplicates:
                  updates.append({
                      'existing_item_id': dup['existing_item']['id'],
                      'has_new_info': False,
                      'similarity': dup['similarity']
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
    Description: {existing.get('description', 'N/A')}
    Status: {existing.get('status', 'N/A')}
    {self._get_item_specific_fields(item_type, existing)}

  New {item_type}:
    Title: {new.get('title')}
    Description: {new.get('description', 'N/A')}
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

  Return JSON:
  {{
    "analysis": [
      {{
        "index": 0,
        "is_duplicate": true/false,
        "has_new_info": true/false,
        "update_type": "status" | "content" | "progress" | "metadata" | null,
        "new_info": {{
          "field": "value",  // Only changed fields
          "description": "Updated description if different",
          "status": "new_status if changed"
        }},
        "confidence": 0.0-1.0,
        "reasoning": "brief explanation"
      }}
    ]
  }}

  IMPORTANT:
  - If similarity > 0.90, they're almost certainly duplicates
  - Status changes ARE meaningful updates (keep them)
  - Slight rewording without new info = exact duplicate (skip)
  - New mitigation/resolution info = meaningful update (keep)
  """

      def _get_item_specific_fields(self, item_type: str, item: Dict) -> str:
          """Get type-specific fields for comparison."""
          if item_type == 'risk':
              return f"Severity: {item.get('severity')}\nMitigation: {item.get('mitigation', 'N/A')}"
          elif item_type == 'task':
              return f"Assignee: {item.get('assignee', 'N/A')}\nDue: {item.get('due_date', 'N/A')}"
          elif item_type == 'blocker':
              return f"Impact: {item.get('impact')}\nResolution: {item.get('resolution', 'N/A')}"
          elif item_type == 'lesson':
              return f"Category: {item.get('category')}\nRecommendation: {item.get('recommendation', 'N/A')}"
          return ""


  # Singleton instance
  semantic_deduplicator = SemanticDeduplicator()

  ---
  Phase 3: Update Project Items Sync Service

  Modify project_items_sync_service.py to use the new semantic deduplicator:

  # backend/services/sync/project_items_sync_service.py

  from services.intelligence.semantic_deduplicator import semantic_deduplicator

  class ProjectItemsSyncService:

      async def sync_items_from_summary(
          self,
          session: AsyncSession,
          project_id: uuid.UUID,
          content_id: uuid.UUID,
          summary_data: Dict[str, Any]
      ) -> Dict[str, Any]:
          """Synchronize project items with semantic deduplication."""

          result = {
              "risks_synced": 0,
              "risks_updated": 0,
              "risks_skipped": 0,
              # ... similar for tasks, blockers, lessons
              "errors": []
          }

          try:
              # Extract items from summary
              extracted_items = self._extract_items_from_summary(summary_data)

              # Get existing items
              existing_items = await self._get_existing_project_items(session, project_id)

              # Process each item type with semantic deduplication
              for item_type in ['risks', 'tasks', 'blockers', 'lessons']:
                  dedup_result = await semantic_deduplicator.deduplicate_items(
                      item_type=item_type.rstrip('s'),  # Remove plural
                      new_items=extracted_items.get(item_type, []),
                      existing_items=existing_items.get(item_type, [])
                  )

                  # Insert unique items
                  for item in dedup_result['unique_items']:
                      await self._insert_new_item(
                          session, project_id, content_id,
                          item_type, item
                      )
                      result[f'{item_type}_synced'] += 1

                  # Update duplicates that have new info
                  for update_info in dedup_result['updates']:
                      await self._apply_item_update(
                          session, project_id, content_id,
                          item_type, update_info
                      )
                      result[f'{item_type}_updated'] += 1

                  # Log skipped exact duplicates
                  result[f'{item_type}_skipped'] = len(dedup_result['exact_duplicates'])

              await session.commit()

              logger.info(
                  f"Sync complete: {result['risks_synced']} risks added, "
                  f"{result['risks_updated']} updated, {result['risks_skipped']} skipped"
              )

          except Exception as e:
              logger.error(f"Sync failed: {e}")
              result['errors'].append(str(e))
              await session.rollback()

          return result

      async def _apply_item_update(
          self,
          session: AsyncSession,
          project_id: uuid.UUID,
          content_id: uuid.UUID,
          item_type: str,
          update_info: Dict[str, Any]
      ) -> None:
          """Apply intelligent update to existing item."""

          existing_id = update_info['existing_item_id']
          new_info = update_info.get('new_info', {})
          update_type = update_info.get('update_type')

          # Get the model class
          if item_type == 'risks':
              from models.risk import Risk
              model_class = Risk
          elif item_type == 'tasks':
              from models.task import Task
              model_class = Task
          elif item_type == 'blockers':
              from models.blocker import Blocker
              model_class = Blocker
          elif item_type == 'lessons':
              from models.lesson_learned import LessonLearned
              model_class = LessonLearned

          # Fetch existing item
          existing_obj = await session.get(model_class, existing_id)

          if not existing_obj:
              logger.warning(f"Could not find {item_type} with ID {existing_id}")
              return

          # Apply updates based on type
          if update_type == 'status' and 'status' in new_info:
              existing_obj.status = new_info['status']

          if update_type == 'content':
              if 'description' in new_info:
                  # Append new info instead of replacing
                  existing_desc = existing_obj.description or ""
                  existing_obj.description = f"{existing_desc}\n\nUpdate: {new_info['description']}"

              # Type-specific updates
              if item_type == 'risks' and 'mitigation' in new_info:
                  existing_obj.mitigation = new_info['mitigation']
              elif item_type == 'blockers' and 'resolution' in new_info:
                  existing_obj.resolution = new_info['resolution']
              elif item_type == 'lessons' and 'recommendation' in new_info:
                  existing_obj.recommendation = new_info['recommendation']

          # Update metadata
          existing_obj.source_content_id = str(content_id)
          existing_obj.last_updated = datetime.utcnow()
          existing_obj.updated_by = "ai"

          logger.info(
              f"Updated {item_type} '{existing_obj.title}' with {update_type}: "
              f"confidence={update_info.get('confidence', 0.8):.2f}"
          )

  ---
  Benefits of This Solution

  1. Addresses Semantic Duplication (Issue #2)

  - Embedding similarity catches duplicates that AI prompts miss (e.g., "AI Tool Adoption" vs "AI Tool Proliferation")
  - 85% similarity threshold is much stricter than current AI-only approach
  - Deterministic - same items always get same similarity score

  2. Intelligent Updates Instead of Just Skipping

  - Extracts meaningful updates from duplicates (status changes, new mitigation, progress)
  - Preserves history by appending updates instead of replacing
  - Reduces manual work - no need to manually update items mentioned in new meetings

  3. Performance

  - Fast embedding generation - batched, uses existing EmbeddingGemma service
  - Cached embeddings - stored in database, only computed once
  - Fallback to AI only for medium-similarity cases (75-85%)

  4. Observability

  - Detailed logging of skipped vs updated vs new items
  - Confidence scores for all deduplication decisions
  - Similarity metrics help tune thresholds

  ---
  Implementation Plan

⏺ | Step | Task                                                                                 | Effort  | Impact |
  |------|--------------------------------------------------------------------------------------|---------|--------|
  | 1    | Add title_embedding columns to Risk, Task, Blocker, LessonLearned models (migration) | 1 hour  | HIGH   |
  | 2    | Create semantic_deduplicator.py service                                              | 4 hours | HIGH   |
  | 3    | Update project_items_sync_service.py to use semantic deduplicator                    | 2 hours | HIGH   |
  | 4    | Backfill embeddings for existing items (one-time script)                             | 1 hour  | MEDIUM |
  | 5    | Add unit tests for semantic deduplication                                            | 2 hours | MEDIUM |
  | 6    | Monitor and tune similarity thresholds based on production data                      | Ongoing | MEDIUM |

  Total Effort: ~10 hours (1.5 days)

  ---
  Configuration Options

  Add to backend/config.py:

  class Settings(BaseSettings):
      # Semantic deduplication settings
      enable_semantic_deduplication: bool = True
      semantic_similarity_high_threshold: float = 0.85
      semantic_similarity_medium_threshold: float = 0.75
      semantic_dedup_use_ai_fallback: bool = True

      # Update extraction settings
      enable_intelligent_updates: bool = True
      append_updates_to_description: bool = True  # vs replacing

  ---
  Alternative: Simpler Approach (If No Migration)

  If you don't want to add database columns, embeddings can be computed on-the-fly:

  # Compute embeddings for existing items each time (slower but no migration)
  async def _get_existing_embeddings_on_the_fly(self, existing_items):
      titles = [item.get('title', '') for item in existing_items]
      return await self.embedding_service.generate_embeddings_batch(titles)

  Trade-off: 2-3x slower for projects with 100+ items, but no schema changes needed.

  ---
  Monitoring

  Track these metrics in Langfuse/logs:

  # Log deduplication metrics
  logger.info(
      f"Deduplication stats: "
      f"high_similarity={count_high}, "
      f"medium_similarity={count_medium}, "
      f"unique={count_unique}, "
      f"avg_similarity={avg_similarity:.3f}"
  )

  ---
  Summary

  This solution provides:

  ✅ Elegant deduplication using proven embedding similarity✅ Intelligent updates instead of just skipping duplicates✅ Better data quality - fewer semantic duplicates (37 pairs → <10 expected)✅ Preserved information - updates append to existing items✅ Performance -
  cached embeddings, batched operations✅ Configurability - tunable thresholds, AI fallback toggle✅ Observability - detailed metrics and confidence scores

  The hybrid approach (embeddings + AI) is much more reliable than AI-only deduplication while still handling edge cases intelligently. The intelligent update mechanism ensures no information is lost when duplicates are detected.

  Would you like me to implement this solution? I can start with creating the migration, the semantic deduplicator service, and updating the sync service.