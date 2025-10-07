"""Multi-tenant vector store management with per-organization collections."""

import asyncio
import uuid
from typing import Dict, List, Optional, Any
from contextlib import asynccontextmanager

from qdrant_client import QdrantClient
from qdrant_client.models import (
    VectorParams,
    Distance,
    PointStruct,
    Filter,
    OptimizersConfigDiff,
    ScalarQuantization,
    ScalarQuantizationConfig,
    ScalarType,
    HnswConfigDiff,
    SearchRequest,
    SearchParams,
    QuantizationSearchParams,
    PayloadFieldSchema,
    PayloadSchemaType,
    FieldCondition,
    MatchValue,
    HasIdCondition
)
from qdrant_client.http.exceptions import ResponseHandlingException, UnexpectedResponse

from config import get_settings
from utils.logger import get_logger, sanitize_for_log
from utils.monitoring import monitor_operation, MonitoringContext

settings = get_settings()
logger = get_logger(__name__)


class MultiTenantVectorStore:
    """Manages per-organization Qdrant collections for multi-tenant vector storage."""

    # Collection naming prefix
    COLLECTION_PREFIX = "org"

    # Collection types
    CONTENT_COLLECTION = "content"
    SUMMARIES_COLLECTION = "summaries"

    def __init__(self):
        self._client: Optional[QdrantClient] = None
        self._collection_cache: Dict[str, bool] = {}  # Cache for existing collections

    @property
    def client(self) -> QdrantClient:
        """Get or create the Qdrant client."""
        if self._client is None:
            self._client = QdrantClient(
                host=settings.qdrant_host,
                port=settings.qdrant_port,
                timeout=30,
                prefer_grpc=True  # Use gRPC for better performance
            )
        return self._client

    def _get_collection_name(self, organization_id: str, collection_type: str = CONTENT_COLLECTION) -> str:
        """Generate collection name for an organization."""
        # Format: org_{organization_id}_{collection_type}
        # Replace hyphens in UUID with underscores for compatibility
        org_id_safe = str(organization_id).replace('-', '_')
        return f"{self.COLLECTION_PREFIX}_{org_id_safe}_{collection_type}"

    def _parse_collection_name(self, collection_name: str) -> Optional[Dict[str, str]]:
        """Parse collection name to extract organization ID and type."""
        parts = collection_name.split('_')
        if len(parts) >= 7 and parts[0] == self.COLLECTION_PREFIX:
            # Reconstruct UUID from parts (org_UUID_type format)
            try:
                # Join UUID parts back with hyphens
                uuid_parts = parts[1:6]  # 5 parts of UUID
                org_id = '-'.join(uuid_parts)
                collection_type = '_'.join(parts[6:]) if len(parts) > 6 else self.CONTENT_COLLECTION

                # Validate UUID format
                uuid.UUID(org_id)

                return {
                    "organization_id": org_id,
                    "collection_type": collection_type
                }
            except (ValueError, IndexError):
                return None
        return None

    async def init_client(self) -> None:
        """Initialize the Qdrant client with retry logic."""
        max_retries = 5
        retry_delay = 2

        for attempt in range(max_retries):
            try:
                # Test connection
                client = self.client
                collections_response = await asyncio.get_event_loop().run_in_executor(
                    None, client.get_collections
                )

                logger.info(f"Connected to Qdrant successfully. Found {len(collections_response.collections)} collections")

                # Refresh collection cache
                self._collection_cache = {
                    col.name: True
                    for col in collections_response.collections
                }

                break

            except (ResponseHandlingException, Exception) as e:
                if attempt < max_retries - 1:
                    logger.warning(
                        f"Failed to connect to Qdrant (attempt {attempt + 1}/{max_retries}): {e}"
                    )
                    await asyncio.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    logger.error(f"Failed to connect to Qdrant after {max_retries} attempts")
                    raise

    async def ensure_organization_collections(self, organization_id: str) -> None:
        """Ensure all required collections exist for an organization."""
        collection_types = [self.CONTENT_COLLECTION, self.SUMMARIES_COLLECTION]

        for collection_type in collection_types:
            collection_name = self._get_collection_name(organization_id, collection_type)

            # Check cache first
            if collection_name in self._collection_cache:
                logger.debug(f"Collection '{collection_name}' exists (cached)")
                continue

            try:
                # Check if collection exists
                collection_exists = await self._collection_exists(collection_name)

                if not collection_exists:
                    logger.info(f"Creating collection: {collection_name}")

                    # Create collection with optimized configuration
                    await asyncio.get_event_loop().run_in_executor(
                        None,
                        self._create_collection,
                        collection_name
                    )

                    # Update cache
                    self._collection_cache[collection_name] = True

                    logger.info(f"Collection '{collection_name}' created successfully")
                else:
                    # Update cache
                    self._collection_cache[collection_name] = True
                    logger.info(f"Collection '{collection_name}' already exists")

            except Exception as e:
                logger.error(f"Failed to ensure collection '{collection_name}' exists: {e}")
                raise

    async def _collection_exists(self, collection_name: str) -> bool:
        """Check if a collection exists."""
        try:
            collections = await asyncio.get_event_loop().run_in_executor(
                None, self.client.get_collections
            )
            return any(col.name == collection_name for col in collections.collections)
        except Exception as e:
            logger.error(f"Failed to check collection existence: {e}")
            return False

    def _create_collection(self, collection_name: str) -> None:
        """Create a collection with MRL support for multiple embedding dimensions."""
        # Create collection with multiple vector configurations for MRL
        if settings.enable_mrl:
            # Support multiple dimensions for MRL
            vectors_config = {}
            for dim in settings.mrl_dimensions_list:
                vectors_config[f"vector_{dim}"] = VectorParams(
                    size=dim,
                    distance=Distance.COSINE,
                    on_disk=(dim == 768),  # Store only full vectors on disk
                    hnsw_config=HnswConfigDiff(
                        m=16 if dim <= 256 else 32,  # Smaller m for smaller dimensions
                        ef_construct=100 if dim <= 256 else 200,
                        full_scan_threshold=20000,
                        max_indexing_threads=4,
                        on_disk=False  # Keep HNSW in memory for all dimensions
                    )
                )
        else:
            # Single vector configuration
            vectors_config = VectorParams(
                size=settings.embedding_dimension,  # 768 for EmbeddingGemma
                distance=Distance.COSINE,
                on_disk=True,  # Store vectors on disk for memory efficiency
                hnsw_config=HnswConfigDiff(
                    m=32,  # Increase from default 16 for better recall
                    ef_construct=200,  # Increase for better index quality
                    full_scan_threshold=20000,  # Use exact search for small collections
                    max_indexing_threads=4,  # Parallel indexing
                    on_disk=False  # Keep HNSW in memory for speed
                )
            )

        self.client.create_collection(
            collection_name=collection_name,
            vectors_config=vectors_config,
            optimizers_config=OptimizersConfigDiff(
                default_segment_number=4,  # Increase for better parallelism
                max_segment_size=200000,  # Increase from 100k for larger segments
                memmap_threshold=100000,  # Increase threshold for better performance
                indexing_threshold=50000,  # Increase for better index performance
                flush_interval_sec=60,  # Increase for less frequent writes
                max_optimization_threads=4,  # Match CPU cores
                deleted_threshold=0.2,
                vacuum_min_vector_number=1000
            ),
            quantization_config=ScalarQuantization(
                scalar=ScalarQuantizationConfig(
                    type=ScalarType.INT8,
                    quantile=0.99,
                    always_ram=True  # Keep quantized vectors in RAM for speed
                )
            )
        )

        # Create payload indexes for common filter fields
        self._create_payload_indexes(collection_name)

    def _create_payload_indexes(self, collection_name: str) -> None:
        """Create indexes for common filter fields to improve search performance."""
        indexes = [
            ("project_id", PayloadSchemaType.INTEGER),
            ("content_type", PayloadSchemaType.KEYWORD),
            ("date", PayloadSchemaType.DATETIME),
            ("content_id", PayloadSchemaType.INTEGER),
            ("title", PayloadSchemaType.TEXT),
            ("chunk_index", PayloadSchemaType.INTEGER),
            ("organization_id", PayloadSchemaType.KEYWORD),  # Add organization_id index
        ]

        for field_name, field_type in indexes:
            try:
                self.client.create_payload_index(
                    collection_name=collection_name,
                    field_name=field_name,
                    field_schema=PayloadFieldSchema(data_type=field_type)
                )
                logger.debug(f"Created payload index for field '{field_name}' with type {field_type}")
            except Exception as e:
                # Index might already exist, which is fine
                logger.debug(f"Payload index for '{field_name}' already exists or failed to create: {e}")

    async def delete_organization_collections(self, organization_id: str) -> None:
        """Delete all collections for an organization."""
        collection_types = [self.CONTENT_COLLECTION, self.SUMMARIES_COLLECTION]

        for collection_type in collection_types:
            collection_name = self._get_collection_name(organization_id, collection_type)

            try:
                # Check if collection exists
                if await self._collection_exists(collection_name):
                    logger.info(f"Deleting collection: {sanitize_for_log(collection_name)}")

                    # Delete collection
                    await asyncio.get_event_loop().run_in_executor(
                        None,
                        self.client.delete_collection,
                        collection_name
                    )

                    # Remove from cache
                    self._collection_cache.pop(collection_name, None)

                    logger.info(f"Collection '{sanitize_for_log(collection_name)}' deleted successfully")
                else:
                    logger.debug(f"Collection '{sanitize_for_log(collection_name)}' does not exist, skipping deletion")

            except Exception as e:
                logger.error(f"Failed to delete collection '{sanitize_for_log(collection_name)}': {e}")
                # Continue with other collections even if one fails

    async def list_organization_collections(self, organization_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """List all collections, optionally filtered by organization."""
        try:
            collections = await asyncio.get_event_loop().run_in_executor(
                None, self.client.get_collections
            )

            result = []
            for col in collections.collections:
                # Parse collection name
                parsed = self._parse_collection_name(col.name)

                if parsed:
                    # If organization_id provided, filter by it
                    if organization_id and parsed["organization_id"] != str(organization_id):
                        continue

                    # Get collection info
                    try:
                        info = await asyncio.get_event_loop().run_in_executor(
                            None, self.client.get_collection, col.name
                        )

                        result.append({
                            "name": col.name,
                            "organization_id": parsed["organization_id"],
                            "collection_type": parsed["collection_type"],
                            "vectors_count": info.vectors_count,
                            "points_count": info.points_count,
                            "status": info.status.value,
                        })
                    except Exception as e:
                        logger.error(f"Failed to get info for collection '{col.name}': {e}")

            return result

        except Exception as e:
            logger.error(f"Failed to list organization collections: {e}")
            return []

    @monitor_operation("insert_vectors", "vector", capture_args=True)
    async def insert_vectors(
        self,
        organization_id: str,
        points: List[PointStruct],
        collection_type: str = CONTENT_COLLECTION
    ) -> bool:
        """Insert vector points into an organization's collection."""
        collection_name = self._get_collection_name(organization_id, collection_type)

        # Ensure collection exists
        await self.ensure_organization_collections(organization_id)

        # Handle MRL named vectors - convert single vector to named vectors
        if settings.enable_mrl:
            for point in points:
                # If point has a single vector list, convert to named vectors dict
                if isinstance(point.vector, list):
                    full_vector = point.vector
                    named_vectors = {}
                    for dim in settings.mrl_dimensions_list:
                        named_vectors[f"vector_{dim}"] = full_vector[:dim]
                    point.vector = named_vectors

        # Add organization_id to each point's payload
        for point in points:
            if point.payload:
                point.payload["organization_id"] = str(organization_id)
            else:
                point.payload = {"organization_id": str(organization_id)}

        try:
            await asyncio.get_event_loop().run_in_executor(
                None,
                self.client.upsert,
                collection_name,
                points
            )

            logger.info(f"Inserted {len(points)} vectors into collection '{collection_name}'")
            return True

        except Exception as e:
            logger.error(f"Failed to insert vectors: {e}")
            raise

    @monitor_operation("search_vectors", "vector", capture_args=True)
    async def search_vectors(
        self,
        organization_id: str,
        query_vector: List[float],
        collection_type: str = CONTENT_COLLECTION,
        limit: int = 5,
        score_threshold: Optional[float] = None,
        filter_dict: Optional[Dict] = None,
        search_params: Optional[SearchParams] = None,
        with_payload: bool = True,
        with_vectors: bool = False,
        vector_dimension: Optional[int] = None  # For MRL support
    ) -> List[Dict[str, Any]]:
        """Search for similar vectors in an organization's collection."""
        collection_name = self._get_collection_name(organization_id, collection_type)

        # Ensure collection exists
        await self.ensure_organization_collections(organization_id)

        # Build filter with organization_id
        must_conditions = [
            FieldCondition(
                key="organization_id",
                match=MatchValue(value=str(organization_id))
            )
        ]

        # Add additional filters if provided
        if filter_dict:
            for key, value in filter_dict.items():
                if key != "organization_id":  # Skip if already added
                    must_conditions.append(
                        FieldCondition(key=key, match=MatchValue(value=value))
                    )

        filter_obj = Filter(must=must_conditions) if must_conditions else None

        # Set search params with quantization
        if not search_params:
            search_params = SearchParams(
                hnsw_ef=256,  # Increase for better recall
                exact=False,  # Use approximate search
                quantization=QuantizationSearchParams(
                    ignore=False,
                    rescore=True,  # Rescore with full precision
                    oversampling=2.0  # Oversample for better quality
                )
            )

        try:
            # Handle MRL named vectors vs single vector
            if settings.enable_mrl:
                # Use provided dimension or default to search dimension
                search_dim = vector_dimension if vector_dimension else settings.mrl_search_dimension
                vector_name = f"vector_{search_dim}"

                # Use query_points for named vectors (recommended by Qdrant docs)
                response = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: self.client.query_points(
                        collection_name=collection_name,
                        query=query_vector[:search_dim],  # Truncate to search dimension
                        using=vector_name,  # Specify which named vector to use
                        limit=limit,
                        query_filter=filter_obj,
                        search_params=search_params,
                        score_threshold=score_threshold,
                        with_payload=with_payload,
                        with_vectors=with_vectors
                    )
                )
                # Extract points from QueryResponse
                results = response.points if hasattr(response, 'points') else response
            else:
                # For single vector, use the search method
                results = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: self.client.search(
                        collection_name=collection_name,
                        query_vector=query_vector,
                        limit=limit,
                        query_filter=filter_obj,
                        search_params=search_params,
                        score_threshold=score_threshold,
                        with_payload=with_payload,
                        with_vectors=with_vectors
                    )
                )

            # Convert results to list of dicts
            return [
                {
                    "id": str(result.id),
                    "score": result.score,
                    "payload": result.payload if with_payload else None,
                    "vector": result.vector if with_vectors else None
                }
                for result in results
            ]

        except UnexpectedResponse as e:
            if "Not found" in str(e):
                logger.warning(f"Collection '{collection_name}' not found, returning empty results")
                return []
            raise
        except Exception as e:
            logger.error(f"Failed to search vectors: {e}")
            raise

    @monitor_operation("search_vectors_two_stage", "vector", capture_args=True)
    async def search_vectors_two_stage(
        self,
        organization_id: str,
        query_vector: List[float],
        collection_type: str = CONTENT_COLLECTION,
        initial_limit: int = 50,  # Get more candidates in stage 1
        final_limit: int = 10,    # Return fewer high-quality results
        score_threshold: Optional[float] = None,
        filter_dict: Optional[Dict] = None,
        with_payload: bool = True,
        with_vectors: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Two-stage MRL search for better quality results.

        Stage 1: Fast search with 128d vectors to get candidates
        Stage 2: Rerank candidates with 768d vectors for precision

        Args:
            organization_id: Organization ID
            query_vector: Full query embedding (768d)
            collection_type: Type of collection to search
            initial_limit: Number of candidates to retrieve in stage 1
            final_limit: Number of final results to return
            score_threshold: Minimum score threshold
            filter_dict: Additional filters
            with_payload: Include payload in results
            with_vectors: Include vectors in results

        Returns:
            List of search results with high precision
        """
        if not settings.enable_mrl:
            # Fall back to regular search if MRL is not enabled
            return await self.search_vectors(
                organization_id=organization_id,
                query_vector=query_vector,
                collection_type=collection_type,
                limit=final_limit,
                score_threshold=score_threshold,
                filter_dict=filter_dict,
                with_payload=with_payload,
                with_vectors=with_vectors
            )

        logger.info(f"🔍 Starting two-stage MRL search: {initial_limit} candidates -> {final_limit} results")

        # Stage 1: Fast search with 128d vectors
        fast_results = await self.search_vectors(
            organization_id=organization_id,
            query_vector=query_vector,
            collection_type=collection_type,
            limit=initial_limit,
            score_threshold=0.2,  # Lower threshold for initial candidates
            filter_dict=filter_dict,
            vector_dimension=128,  # Use fast 128d vectors
            with_payload=True,  # Need payload for stage 2
            with_vectors=False
        )

        if not fast_results:
            logger.debug("No candidates found in stage 1")
            return []

        logger.info(f"📊 Stage 1: Found {len(fast_results)} candidates with 128d search")

        # Stage 2: Rerank with 768d vectors for precision
        # Get the IDs of candidates
        candidate_ids = [result['id'] for result in fast_results]

        logger.info(f"🔍 Stage 2 starting with {len(candidate_ids)} candidate IDs")
        logger.debug(f"First 5 candidate IDs: {candidate_ids[:5]}")

        # Search again with full 768d vectors, but only among candidates
        collection_name = self._get_collection_name(organization_id, collection_type)

        # For reranking, we only want to search among the candidates from stage 1
        try:
            # Use full 768d vectors for precise reranking
            search_dim = 768
            vector_name = f"vector_{search_dim}"

            # Proper implementation using HasIdCondition filter
            from qdrant_client.models import Filter, HasIdCondition

            # Ensure IDs are properly formatted as strings (UUIDs)
            formatted_ids = [str(cid) for cid in candidate_ids]

            logger.info(f"🔄 Performing 768d search with HasIdCondition filter")
            logger.debug(f"Filtering to {len(formatted_ids)} specific IDs: {formatted_ids[:3]}...")

            # Create HasIdCondition filter to search only among candidates
            id_filter = Filter(
                must=[
                    HasIdCondition(has_id=formatted_ids)
                ]
            )

            # Since HasIdCondition with query_points doesn't work with named vectors,
            # use the working approach: broader search + manual filtering
            logger.info(f"🔄 Performing 768d search and filtering to candidate IDs")

            # Do a broader search with 768d vectors to get more results than needed
            response = await asyncio.get_event_loop().run_in_executor(
                None,
                lambda: self.client.query_points(
                    collection_name=collection_name,
                    query=query_vector[:search_dim],
                    using=vector_name,  # Use 768d vectors
                    limit=initial_limit * 2,  # Get more results to filter from
                    with_payload=with_payload,
                    with_vectors=with_vectors,
                    score_threshold=0.1,  # Lower threshold to ensure we get candidates
                    search_params=SearchParams(
                        hnsw_ef=256,
                        exact=False  # Use HNSW for efficiency
                    )
                )
            )

            # Extract points from response
            all_768_results = response.points if hasattr(response, 'points') else response

            logger.info(f"📊 768d search returned {len(all_768_results) if all_768_results else 0} total results")

            # Filter to only include our candidate IDs (this is the effective "HasIdCondition")
            candidate_id_set = set(formatted_ids)

            # Filter and keep only candidates from stage 1
            reranked_points = []
            for point in all_768_results:
                point_id = str(point.id)
                if point_id in candidate_id_set:
                    reranked_points.append(point)
                    logger.debug(f"✓ Found candidate {point_id} with score {point.score:.3f}")

            logger.info(f"📈 Filtered to {len(reranked_points)} candidates from Stage 1")

            # Sort by score and take top results
            reranked_points.sort(key=lambda x: x.score, reverse=True)
            final_points = reranked_points[:final_limit]

            logger.info(f"🎯 Final selection: {len(final_points)} results")

            # Format results
            final_results = [
                {
                    "id": str(result.id),
                    "score": result.score,
                    "payload": result.payload if with_payload else None,
                    "vector": result.vector if with_vectors else None
                }
                for result in final_points
            ]

            # Log score improvements
            if final_results and fast_results:
                stage1_scores = [r['score'] for r in fast_results[:final_limit]]
                stage2_scores = [r['score'] for r in final_results]

                avg_stage1 = sum(stage1_scores) / len(stage1_scores) if stage1_scores else 0
                avg_stage2 = sum(stage2_scores) / len(stage2_scores) if stage2_scores else 0

                logger.info(f"📊 Score improvement: Stage 1 avg={avg_stage1:.3f} → Stage 2 avg={avg_stage2:.3f} (Δ={avg_stage2-avg_stage1:+.3f})")

            # Log individual candidate matches for debugging
            for result in final_results[:5]:  # Log first 5
                logger.debug(f"✓ Reranked candidate {result['id']} with score {result['score']:.3f}")

            logger.info(f"🎯 Stage 2 completed: {len(final_results)} results with HasIdCondition")

            # If we got no results from reranking, fall back to stage 1
            if not final_results:
                logger.warning("⚠️ Stage 2 produced no results, falling back to Stage 1 results")
                final_results = fast_results[:final_limit]

            logger.info(
                f"✅ Stage 2: Reranked to {len(final_results)} results with 768d vectors. "
                f"Score improvement: {sum(r['score'] for r in final_results[:5]) / min(5, len(final_results)) if final_results else 0:.3f}"
            )

            return final_results

        except Exception as e:
            logger.error(f"❌ Failed in stage 2 reranking: {e}", exc_info=True)
            logger.warning("⚠️ Falling back to Stage 1 results due to error")
            # Fall back to stage 1 results
            final_results = fast_results[:final_limit]
            logger.info(f"📌 Returning {len(final_results)} results from Stage 1 fallback")
            return final_results

    @monitor_operation("delete_vectors", "vector", capture_args=True)
    async def delete_vectors(
        self,
        organization_id: str,
        points_selector: Optional[List[str]] = None,
        filter_dict: Optional[Dict] = None,
        collection_type: str = CONTENT_COLLECTION
    ) -> bool:
        """Delete vectors from an organization's collection."""
        collection_name = self._get_collection_name(organization_id, collection_type)

        if not await self._collection_exists(collection_name):
            logger.warning(f"Collection '{collection_name}' does not exist, nothing to delete")
            return True

        try:
            if points_selector:
                # Delete specific points by ID
                await asyncio.get_event_loop().run_in_executor(
                    None,
                    self.client.delete,
                    collection_name,
                    HasIdCondition(has_id=points_selector)
                )
                logger.info(f"Deleted {len(points_selector)} vectors from '{collection_name}'")
            elif filter_dict:
                # Delete by filter
                must_conditions = [
                    FieldCondition(
                        key="organization_id",
                        match=MatchValue(value=str(organization_id))
                    )
                ]

                for key, value in filter_dict.items():
                    if key != "organization_id":
                        must_conditions.append(
                            FieldCondition(key=key, match=MatchValue(value=value))
                        )

                filter_obj = Filter(must=must_conditions)

                await asyncio.get_event_loop().run_in_executor(
                    None,
                    self.client.delete,
                    collection_name,
                    filter_obj
                )
                logger.info(f"Deleted vectors matching filter from '{collection_name}'")
            else:
                logger.warning("No selector or filter provided for deletion")
                return False

            return True

        except Exception as e:
            logger.error(f"Failed to delete vectors: {e}")
            raise

    async def get_collection_info(self, organization_id: str, collection_type: str = CONTENT_COLLECTION) -> Dict[str, Any]:
        """Get information about an organization's collection."""
        collection_name = self._get_collection_name(organization_id, collection_type)

        try:
            if not await self._collection_exists(collection_name):
                return {
                    "name": collection_name,
                    "exists": False,
                    "organization_id": str(organization_id),
                    "collection_type": collection_type
                }

            info = await asyncio.get_event_loop().run_in_executor(
                None, self.client.get_collection, collection_name
            )

            # Handle both single vector and named vectors (MRL)
            vectors_config = info.config.params.vectors
            if isinstance(vectors_config, dict):
                # MRL enabled - multiple named vectors
                # Use the largest dimension for reporting
                largest_dim = max(settings.mrl_dimensions_list)
                vector_info = vectors_config.get(f"vector_{largest_dim}")
                config_dict = {
                    "vector_type": "named_vectors",
                    "dimensions": list(vectors_config.keys()),
                    "largest_vector_size": vector_info.size if vector_info else largest_dim,
                    "distance": vector_info.distance.value if vector_info else "COSINE",
                    "on_disk": vector_info.on_disk if vector_info else True
                }
            else:
                # Single vector
                config_dict = {
                    "vector_type": "single_vector",
                    "vector_size": vectors_config.size,
                    "distance": vectors_config.distance.value,
                    "on_disk": vectors_config.on_disk
                }

            return {
                "name": collection_name,
                "exists": True,
                "organization_id": str(organization_id),
                "collection_type": collection_type,
                "status": info.status.value,
                "vectors_count": info.vectors_count,
                "indexed_vectors_count": info.indexed_vectors_count,
                "points_count": info.points_count,
                "segments_count": getattr(info, 'segments_count', 0),
                "config": config_dict
            }
        except Exception as e:
            logger.error(f"Failed to get collection info: {e}")
            return {"error": str(e)}

    async def migrate_from_single_collection(
        self,
        organization_id: str,
        source_collection: str = None,
        batch_size: int = 100
    ) -> int:
        """Migrate vectors from single collection to per-organization collection."""
        if not source_collection:
            source_collection = settings.qdrant_collection

        target_collection = self._get_collection_name(organization_id, self.CONTENT_COLLECTION)

        # Ensure target collection exists
        await self.ensure_organization_collections(organization_id)

        try:
            # Count total points to migrate
            count_result = await asyncio.get_event_loop().run_in_executor(
                None,
                self.client.count,
                source_collection
            )
            total_points = count_result.count

            if total_points == 0:
                logger.info(f"No points to migrate from '{source_collection}'")
                return 0

            logger.info(f"Starting migration of {total_points} points from '{source_collection}' to '{target_collection}'")

            migrated = 0
            offset = None

            while migrated < total_points:
                # Scroll through points in batches
                results, next_offset = await asyncio.get_event_loop().run_in_executor(
                    None,
                    self.client.scroll,
                    source_collection,
                    limit=batch_size,
                    offset=offset,
                    with_payload=True,
                    with_vectors=True
                )

                if not results:
                    break

                # Convert to PointStruct and add organization_id
                points = []
                for record in results:
                    payload = record.payload or {}
                    payload["organization_id"] = str(organization_id)

                    points.append(
                        PointStruct(
                            id=record.id,
                            vector=record.vector,
                            payload=payload
                        )
                    )

                # Insert into target collection
                if points:
                    await asyncio.get_event_loop().run_in_executor(
                        None,
                        self.client.upsert,
                        target_collection,
                        points
                    )
                    migrated += len(points)
                    logger.info(f"Migrated {migrated}/{total_points} points")

                offset = next_offset
                if not offset:
                    break

            logger.info(f"Migration completed: {migrated} points migrated to '{target_collection}'")
            return migrated

        except Exception as e:
            logger.error(f"Failed to migrate vectors: {e}")
            raise

    async def scroll_documents(
        self,
        organization_id: str,
        collection_type: str = "content",
        filter_dict: Optional[Dict[str, Any]] = None,
        limit: Optional[int] = None,
        with_payload: bool = True,
        with_vectors: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Scroll through documents in a collection without vector similarity search.
        This is useful for keyword search and bulk document retrieval.

        Args:
            organization_id: Organization ID
            collection_type: Type of collection ('content' or 'summaries')
            filter_dict: Optional filters to apply
            limit: Maximum number of documents to return
            with_payload: Include document payload in results
            with_vectors: Include vectors in results (default False for performance)

        Returns:
            List of documents with their metadata
        """
        try:
            collection_name = self._get_collection_name(organization_id, collection_type)

            # Ensure collections exist
            await self.ensure_organization_collections(organization_id)

            # Build filter
            from qdrant_client.models import Filter, FieldCondition, MatchValue

            conditions = []
            if filter_dict:
                for field, value in filter_dict.items():
                    if value is not None:
                        conditions.append(
                            FieldCondition(
                                key=field,
                                match=MatchValue(value=value)
                            )
                        )

            qdrant_filter = Filter(must=conditions) if conditions else None

            # Use scroll to fetch documents
            all_documents = []
            offset = None
            batch_size = min(limit or 100, 100)  # Qdrant recommends batch size of 100

            while True:
                # Scroll through documents
                scroll_result = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: self.client.scroll(
                        collection_name=collection_name,
                        scroll_filter=qdrant_filter,
                        limit=batch_size,
                        offset=offset,
                        with_payload=with_payload,
                        with_vectors=with_vectors
                    )
                )

                points, next_offset = scroll_result

                # Convert points to dict format
                for point in points:
                    doc = {
                        'id': str(point.id),
                        'payload': point.payload if with_payload else {}
                    }
                    if with_vectors and point.vector:
                        doc['vector'] = point.vector
                    all_documents.append(doc)

                # Check if we've reached the limit or end of results
                if limit and len(all_documents) >= limit:
                    all_documents = all_documents[:limit]
                    break

                if next_offset is None or len(points) < batch_size:
                    break

                offset = next_offset

            logger.debug(f"Scrolled {len(all_documents)} documents from {collection_name}")
            return all_documents

        except Exception as e:
            logger.error(f"Failed to scroll documents: {e}")
            return []

    async def check_connection(self) -> bool:
        """Check if Qdrant connection is healthy."""
        try:
            client = self.client
            collections = await asyncio.get_event_loop().run_in_executor(
                None, client.get_collections
            )
            return True
        except Exception as e:
            logger.error(f"Qdrant health check failed: {e}")
            return False

    async def close(self) -> None:
        """Close the Qdrant client connection."""
        if self._client:
            self._client.close()
            self._client = None
            self._collection_cache.clear()
            logger.info("Qdrant client connection closed")


# Create a singleton instance
multi_tenant_vector_store = MultiTenantVectorStore()


# Backwards compatibility wrapper for existing code
async def get_vector_store(organization_id: Optional[str] = None):
    """Get vector store instance for an organization."""
    if not organization_id:
        # Use default organization if not specified
        organization_id = "00000000-0000-0000-0000-000000000001"

    # Ensure collections exist for organization
    await multi_tenant_vector_store.ensure_organization_collections(organization_id)

    return multi_tenant_vector_store