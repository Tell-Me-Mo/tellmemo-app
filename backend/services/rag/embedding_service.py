"""Embedding generation service using SentenceTransformers."""

import os
import ssl
import asyncio
from typing import List, Dict, Any, Optional
from pathlib import Path
import numpy as np

# CRITICAL: Apply SSL bypass BEFORE importing sentence_transformers
# This fixes SSL certificate errors when downloading models from HuggingFace
os.environ['PYTHONHTTPSVERIFY'] = '0'
os.environ['CURL_CA_BUNDLE'] = ''
os.environ['REQUESTS_CA_BUNDLE'] = ''
ssl._create_default_https_context = ssl._create_unverified_context

# Monkey-patch requests for HuggingFace Hub downloads
try:
    import requests
    from requests.adapters import HTTPAdapter
    import urllib3

    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    class NoSSLAdapter(HTTPAdapter):
        def init_poolmanager(self, *args, **kwargs):
            kwargs['ssl_context'] = ssl._create_unverified_context()
            return super().init_poolmanager(*args, **kwargs)

    _original_session_init = requests.Session.__init__

    def patched_session_init(self, *args, **kwargs):
        _original_session_init(self, *args, **kwargs)
        adapter = NoSSLAdapter()
        self.mount('https://', adapter)
        self.mount('http://', adapter)
        self.verify = False

    requests.Session.__init__ = patched_session_init
except ImportError:
    pass

from sentence_transformers import SentenceTransformer
import torch

from config import get_settings
from utils.logger import get_logger
from utils.monitoring import monitor_operation, MonitoringContext

settings = get_settings()
logger = get_logger(__name__)


class EmbeddingService:
    """Service for generating embeddings from text using SentenceTransformers."""
    
    _instance: Optional['EmbeddingService'] = None
    _model: Optional[SentenceTransformer] = None
    _model_lock = asyncio.Lock()
    
    def __new__(cls):
        """Singleton pattern to ensure single model instance."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        """Initialize embedding service with MRL and multilingual support."""
        if not hasattr(self, '_initialized'):
            self._initialized = True
            self.model_name = settings.embedding_model
            self.embedding_dimension = settings.embedding_dimension
            self.max_sequence_length = 2048  # EmbeddingGemma max tokens
            self.cache_dir = Path.home() / ".cache" / "sentence_transformers"

            # MRL configuration
            self.enable_mrl = settings.enable_mrl
            self.mrl_dimensions = settings.mrl_dimensions_list if settings.enable_mrl else [768]
            self.search_dimension = settings.mrl_search_dimension
            self.rerank_dimension = settings.mrl_rerank_dimension

            # Multilingual configuration
            self.enable_multilingual = settings.enable_multilingual
            self.supported_languages = settings.supported_languages_list

            # Cache for different dimension embeddings
            self._embedding_cache = {}

            logger.info(f"Embedding service initialized with model: {self.model_name}")
            logger.info(f"MRL enabled: {self.enable_mrl}, dimensions: {self.mrl_dimensions}")
            logger.info(f"Multilingual enabled: {self.enable_multilingual}")
    
    @monitor_operation("get_embedding_model", "embedding")
    async def get_model(self) -> SentenceTransformer:
        """
        Get or download the embedding model.
        Uses async lock to prevent multiple downloads.
        
        Returns:
            SentenceTransformer model instance
        """
        async with self._model_lock:
            if self._model is None:
                logger.info(f"Loading embedding model: {self.model_name}")
                
                # Run model loading in executor to avoid blocking
                loop = asyncio.get_event_loop()
                self._model = await loop.run_in_executor(
                    None,
                    self._load_model
                )
                
                # Verify model dimensions
                test_embedding = await loop.run_in_executor(
                    None,
                    lambda: self._model.encode("test"),
                )
                
                actual_dim = len(test_embedding)
                if actual_dim != self.embedding_dimension:
                    logger.warning(
                        f"Model dimension mismatch. Expected: {self.embedding_dimension}, "
                        f"Got: {actual_dim}. Updating configuration."
                    )
                    self.embedding_dimension = actual_dim
                
                logger.info(
                    f"Model loaded successfully. Dimension: {self.embedding_dimension}, "
                    f"Max sequence length: {self.max_sequence_length}"
                )
            
            return self._model
    
    def _load_model(self) -> SentenceTransformer:
        """
        Load the model synchronously.

        Returns:
            Loaded SentenceTransformer model
        """
        # Set device to CPU if CUDA not available
        device = 'cuda' if torch.cuda.is_available() else 'cpu'

        # Create cache directory if it doesn't exist
        self.cache_dir.mkdir(parents=True, exist_ok=True)

        # Get HF token from settings
        from config import get_settings
        settings = get_settings()
        hf_token = settings.hf_token if hasattr(settings, 'hf_token') and settings.hf_token else None

        # Check multiple possible cache locations
        possible_paths = [
            self.cache_dir / "sentence-transformers_google_embeddinggemma-300m",
            self.cache_dir / "models--google--embeddinggemma-300m" / "snapshots",
        ]

        local_model_path = None
        for path in possible_paths:
            if path.exists():
                # For HF cache format, get the latest snapshot
                if "snapshots" in str(path):
                    snapshots = list(path.iterdir())
                    if snapshots:
                        local_model_path = snapshots[0]  # Use first (usually only) snapshot
                        break
                else:
                    local_model_path = path
                    break

        if local_model_path and local_model_path.exists():
            # Load from local cache with local_files_only to avoid online checks
            logger.info(f"Loading model from cache: {local_model_path}")
            try:
                model = SentenceTransformer(
                    str(local_model_path),
                    device=device,
                    cache_folder=str(self.cache_dir),
                    local_files_only=True  # Don't check online
                )
                logger.info("✅ Successfully loaded EmbeddingGemma from local cache")
            except Exception as local_error:
                # Try loading with model name but still enforce local_files_only
                # This handles cases where the cache path format changed
                logger.warning(f"Failed to load from cache path, trying model name with local files only: {local_error}")
                try:
                    model = SentenceTransformer(
                        self.model_name,
                        device=device,
                        cache_folder=str(self.cache_dir),
                        local_files_only=True,  # Still don't go online
                        trust_remote_code=True
                    )
                    logger.info("✅ Successfully loaded EmbeddingGemma from local cache using model name")
                except Exception as retry_error:
                    # Only now try online download if local loading completely failed
                    logger.warning(f"Local cache loading failed completely: {retry_error}")
                    logger.info("Attempting online download as last resort...")
                    model = SentenceTransformer(
                        self.model_name,
                        device=device,
                        cache_folder=str(self.cache_dir),
                        token=hf_token,
                        trust_remote_code=True
                    )
        else:
            # Try to download with authentication token
            logger.info(f"Attempting to download model: {self.model_name}")
            if hf_token:
                logger.info("Using HF authentication token for model download")
            else:
                logger.warning("No HF token available - may fail for gated models")
                logger.warning("If download fails, run: ./download_model_curl.sh")

            try:
                model = SentenceTransformer(
                    self.model_name,
                    cache_folder=str(self.cache_dir),
                    device=device,
                    token=hf_token,
                    trust_remote_code=True
                )
                logger.info(f"✅ Successfully downloaded EmbeddingGemma model")
            except Exception as download_error:
                # Provide specific error guidance
                error_msg = str(download_error).lower()

                if "403" in error_msg or "access" in error_msg or "gated" in error_msg:
                    logger.error("❌ ACCESS DENIED: You don't have access to EmbeddingGemma model")
                    logger.error("   Solution: Request access at https://huggingface.co/google/embeddinggemma-300m")
                    logger.error("   Then wait for approval before restarting the application")
                elif "401" in error_msg or "token" in error_msg:
                    logger.error("❌ AUTHENTICATION FAILED: Invalid or missing HF_TOKEN")
                    logger.error("   Solution: Check HF_TOKEN in .env file")
                    logger.error("   Get token from: https://huggingface.co/settings/tokens")
                elif "ssl" in error_msg or "certificate" in error_msg:
                    logger.error("❌ SSL/NETWORK ERROR: Cannot connect to Hugging Face")
                    logger.error("   Solution: Check network connectivity and SSL certificates")
                elif "space" in error_msg or "disk" in error_msg:
                    logger.error("❌ DISK SPACE ERROR: Insufficient space for model download")
                    logger.error("   Solution: Free up ~500MB disk space")
                else:
                    logger.error(f"❌ DOWNLOAD FAILED: {download_error}")
                    logger.error("   Check network connectivity and try again")

                raise RuntimeError(f"Failed to download EmbeddingGemma: {download_error}")
        
        # Set max sequence length
        model.max_seq_length = self.max_sequence_length
        
        # Enable eval mode for inference
        model.eval()
        
        return model
    
    @monitor_operation("generate_single_embedding", "embedding", capture_result=False)
    async def generate_embedding(
        self,
        text: str,
        normalize: bool = True
    ) -> List[float]:
        """
        Generate embedding for a single text.

        Args:
            text: Input text to embed
            normalize: Whether to normalize the embedding vector

        Returns:
            Embedding vector as list of floats
        """
        try:
            if not text or not text.strip():
                raise ValueError("Empty text cannot be embedded")

            # Validate text length and truncate if necessary
            if len(text) > self.max_sequence_length * 4:  # Rough token estimation (4 chars per token)
                logger.warning(f"Text too long ({len(text)} chars), truncating for embedding")
                text = text[:self.max_sequence_length * 4]

            model = await self.get_model()

            # Generate embedding in executor
            loop = asyncio.get_event_loop()
            embedding = await loop.run_in_executor(
                None,
                lambda t: model.encode(t, normalize_embeddings=normalize),
                text
            )

            # Convert to list for JSON serialization
            return embedding.tolist()

        except Exception as e:
            logger.error(f"Failed to generate embedding for text (length: {len(text) if text else 0}): {e}")
            raise

    @monitor_operation("generate_embedding_mrl", "embedding", capture_result=False)
    async def generate_embedding_mrl(
        self,
        text: str,
        dimension: int = None,
        normalize: bool = True
    ) -> List[float]:
        """
        Generate MRL embedding at specific dimension for speed/quality tradeoff.

        Args:
            text: Input text to embed
            dimension: Target dimension (128, 256, 512, or 768)
            normalize: Whether to normalize the embedding

        Returns:
            Truncated embedding at specified dimension
        """
        if dimension is None:
            dimension = self.search_dimension

        if dimension not in self.mrl_dimensions:
            logger.warning(f"Requested dimension {dimension} not in MRL dimensions, using full 768")
            dimension = 768

        # Generate full embedding
        full_embedding = await self.generate_embedding(text, normalize)

        # MRL truncation - EmbeddingGemma supports this natively
        return full_embedding[:dimension]

    async def generate_search_embeddings(
        self,
        text: str,
        normalize: bool = True
    ) -> Dict[str, List[float]]:
        """
        Generate both search (fast) and rerank (accurate) embeddings.

        Returns:
            Dict with 'search' and 'rerank' embeddings
        """
        full_embedding = await self.generate_embedding(text, normalize)

        return {
            'search': full_embedding[:self.search_dimension],    # Fast 128d
            'rerank': full_embedding[:self.rerank_dimension],    # Accurate 768d
            'full': full_embedding                               # Complete 768d
        }

    async def detect_language(self, text: str) -> str:
        """
        Detect language of text using simple heuristics.
        For production, integrate with langdetect or similar.
        """
        # Simple heuristic based on character ranges
        # This is a placeholder - for production use langdetect library
        if any('\u4e00' <= char <= '\u9fff' for char in text):
            return 'zh'  # Chinese
        elif any('\u0600' <= char <= '\u06ff' for char in text):
            return 'ar'  # Arabic
        elif any('\u3040' <= char <= '\u309f' for char in text):
            return 'ja'  # Japanese
        elif any('\u0400' <= char <= '\u04ff' for char in text):
            return 'ru'  # Russian
        else:
            return 'en'  # Default to English

    @monitor_operation("generate_embeddings_batch", "embedding", capture_args=True)
    async def generate_embeddings_batch(
        self,
        texts: List[str],
        batch_size: int = 32,
        normalize: bool = True,
        show_progress: bool = False
    ) -> List[List[float]]:
        """
        Generate embeddings for multiple texts in batches.
        
        Args:
            texts: List of input texts
            batch_size: Number of texts to process at once
            normalize: Whether to normalize embedding vectors
            show_progress: Whether to show progress bar
            
        Returns:
            List of embedding vectors
        """
        try:
            if not texts:
                return []
            
            # Filter out empty texts
            valid_texts = [t for t in texts if t and t.strip()]
            if not valid_texts:
                raise ValueError("No valid texts to embed")
            
            if len(valid_texts) != len(texts):
                logger.warning(
                    f"Filtered out {len(texts) - len(valid_texts)} empty texts"
                )
            
            model = await self.get_model()
            
            # Process in batches for memory efficiency
            all_embeddings = []
            
            for i in range(0, len(valid_texts), batch_size):
                batch = valid_texts[i:i + batch_size]
                
                # Generate embeddings for batch
                loop = asyncio.get_event_loop()
                batch_embeddings = await loop.run_in_executor(
                    None,
                    lambda b: model.encode(
                        b, 
                        batch_size=batch_size,
                        show_progress_bar=show_progress,
                        normalize_embeddings=normalize
                    ),
                    batch
                )
                
                # Convert to list and extend results
                all_embeddings.extend(batch_embeddings.tolist())
                
                if show_progress and i > 0:
                    logger.info(
                        f"Processed {min(i + batch_size, len(valid_texts))}/{len(valid_texts)} texts"
                    )
            
            logger.info(f"Generated {len(all_embeddings)} embeddings")
            return all_embeddings
            
        except Exception as e:
            logger.error(f"Failed to generate batch embeddings: {e}")
            raise
    
    @monitor_operation("generate_chunk_embeddings", "embedding", capture_args=True)
    async def generate_embeddings_for_chunks(
        self,
        chunks: List[Dict[str, Any]],
        batch_size: int = 32
    ) -> List[Dict[str, Any]]:
        """
        Generate embeddings for text chunks with metadata preservation.
        
        Args:
            chunks: List of chunk dictionaries with 'text' and metadata
            batch_size: Number of chunks to process at once
            
        Returns:
            List of chunks with added 'embedding' field
        """
        try:
            if not chunks:
                return []
            
            # Extract texts
            texts = [chunk.get('text', '') for chunk in chunks]
            
            # Generate embeddings
            embeddings = await self.generate_embeddings_batch(
                texts,
                batch_size=batch_size,
                normalize=True,
                show_progress=len(chunks) > 100
            )
            
            # Add embeddings to chunks
            for chunk, embedding in zip(chunks, embeddings):
                chunk['embedding'] = embedding
            
            return chunks
            
        except Exception as e:
            logger.error(f"Failed to generate chunk embeddings: {e}")
            raise
    
    def calculate_similarity(
        self,
        embedding1: List[float],
        embedding2: List[float]
    ) -> float:
        """
        Calculate cosine similarity between two embeddings.
        
        Args:
            embedding1: First embedding vector
            embedding2: Second embedding vector
            
        Returns:
            Cosine similarity score between -1 and 1
        """
        try:
            # Convert to numpy arrays
            vec1 = np.array(embedding1)
            vec2 = np.array(embedding2)
            
            # Calculate cosine similarity
            dot_product = np.dot(vec1, vec2)
            norm1 = np.linalg.norm(vec1)
            norm2 = np.linalg.norm(vec2)
            
            if norm1 == 0 or norm2 == 0:
                return 0.0
            
            similarity = dot_product / (norm1 * norm2)
            return float(similarity)
            
        except Exception as e:
            logger.error(f"Failed to calculate similarity: {e}")
            raise
    
    async def find_similar_texts(
        self,
        query_text: str,
        candidate_texts: List[str],
        top_k: int = 5,
        min_similarity: float = 0.5
    ) -> List[Dict[str, Any]]:
        """
        Find most similar texts to a query from candidates.
        
        Args:
            query_text: Query text to compare against
            candidate_texts: List of candidate texts
            top_k: Number of top results to return
            min_similarity: Minimum similarity threshold
            
        Returns:
            List of similar texts with scores
        """
        try:
            if not query_text or not candidate_texts:
                return []
            
            # Generate embeddings for all texts
            all_texts = [query_text] + candidate_texts
            embeddings = await self.generate_embeddings_batch(all_texts)
            
            query_embedding = embeddings[0]
            candidate_embeddings = embeddings[1:]
            
            # Calculate similarities
            results = []
            for i, (text, embedding) in enumerate(zip(candidate_texts, candidate_embeddings)):
                similarity = self.calculate_similarity(query_embedding, embedding)
                
                if similarity >= min_similarity:
                    results.append({
                        'text': text,
                        'index': i,
                        'similarity': similarity
                    })
            
            # Sort by similarity and return top k
            results.sort(key=lambda x: x['similarity'], reverse=True)
            return results[:top_k]
            
        except Exception as e:
            logger.error(f"Failed to find similar texts: {e}")
            raise
    
    def get_model_info(self) -> Dict[str, Any]:
        """
        Get information about the current model including MRL and multilingual capabilities.

        Returns:
            Dictionary with model information
        """
        return {
            'model_name': self.model_name,
            'embedding_dimension': self.embedding_dimension,
            'max_sequence_length': self.max_sequence_length,
            'model_loaded': self._model is not None,
            'cache_directory': str(self.cache_dir),
            'device': 'cuda' if torch.cuda.is_available() else 'cpu',
            'mrl_enabled': self.enable_mrl,
            'mrl_dimensions': self.mrl_dimensions,
            'search_dimension': self.search_dimension,
            'rerank_dimension': self.rerank_dimension,
            'multilingual_enabled': self.enable_multilingual,
            'supported_languages': self.supported_languages
        }
    
    async def warm_up(self) -> None:
        """
        Warm up the model by loading it and generating a test embedding.
        Useful for reducing latency on first real request.
        """
        try:
            logger.info("Warming up embedding model...")
            
            # Load model
            await self.get_model()
            
            # Generate test embedding
            test_text = "This is a warm-up test for the embedding model."
            await self.generate_embedding(test_text)
            
            logger.info("Embedding model warmed up successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to warm up embedding model: {e}")
            logger.error("This is a CRITICAL error - application cannot continue without EmbeddingGemma")
            raise


# Global embedding service instance
embedding_service = EmbeddingService()


async def init_embedding_service():
    """Initialize and warm up the embedding service (MANDATORY)."""
    try:
        logger.info("🚀 Initializing EmbeddingGemma model...")
        await embedding_service.warm_up()
        info = embedding_service.get_model_info()
        logger.info(f"✅ Embedding service ready: {info}")

        # Verify the model is actually EmbeddingGemma
        if 'embeddinggemma' not in info['model_name'].lower():
            raise RuntimeError(f"Expected EmbeddingGemma model, got: {info['model_name']}")

        if info['embedding_dimension'] != 768:
            raise RuntimeError(f"Expected 768 dimensions, got: {info['embedding_dimension']}")

        logger.info("🎉 EmbeddingGemma model validation successful")

    except Exception as e:
        logger.error(f"❌ CRITICAL: Failed to initialize embedding service: {e}")
        logger.error("EmbeddingGemma model is REQUIRED for the application")
        logger.error("Possible solutions:")
        logger.error("  1. Check HF_TOKEN in .env file")
        logger.error("  2. Ensure network connectivity to huggingface.co")
        logger.error("  3. Verify access to google/embeddinggemma-300m model")
        logger.error("  4. Check available disk space (~500MB needed)")
        raise