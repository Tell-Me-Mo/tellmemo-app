from pydantic_settings import BaseSettings
from pydantic import Field
import logging
from typing import List
from functools import lru_cache


class Settings(BaseSettings):
    # API Configuration
    api_host: str = Field(default="0.0.0.0", env="API_HOST")
    api_port: int = Field(default=8000, env="API_PORT")
    api_reload: bool = Field(default=True, env="API_RELOAD")
    api_log_level: str = Field(default="debug", env="API_LOG_LEVEL")
    api_env: str = Field(default="development", env="API_ENV")
    
    # PostgreSQL Configuration
    postgres_user: str = Field(default="pm_master", env="POSTGRES_USER")
    postgres_password: str = Field(default="pm_master_pass", env="POSTGRES_PASSWORD")
    postgres_db: str = Field(default="pm_master_db", env="POSTGRES_DB")
    postgres_host: str = Field(default="localhost", env="POSTGRES_HOST")
    postgres_port: int = Field(default=5432, env="POSTGRES_PORT")

    # Redis Configuration
    redis_host: str = Field(default="localhost", env="REDIS_HOST")
    redis_port: int = Field(default=6379, env="REDIS_PORT")
    redis_password: str = Field(default="", env="REDIS_PASSWORD")
    redis_db: int = Field(default=0, env="REDIS_DB")
    session_cache_ttl_minutes: int = Field(default=30, env="SESSION_CACHE_TTL_MINUTES")
    
    # Qdrant Configuration
    qdrant_host: str = Field(default="localhost", env="QDRANT_HOST")
    qdrant_port: int = Field(default=6333, env="QDRANT_PORT")
    qdrant_collection: str = Field(default="pm_master_vectors", env="QDRANT_COLLECTION")
    
    # Claude API Configuration
    anthropic_api_key: str = Field(default="", env="ANTHROPIC_API_KEY")
    llm_model: str = Field(default="claude-3-5-haiku-latest", env="LLM_MODEL")
    max_tokens: int = Field(default=4096, env="MAX_TOKENS")
    temperature: float = Field(default=0.7, env="TEMPERATURE")
    
    # Langfuse Configuration
    LANGFUSE_ENABLED: bool = Field(default=False, env="LANGFUSE_ENABLED")
    LANGFUSE_URL: str = Field(default="http://localhost:3000", env="LANGFUSE_URL")
    LANGFUSE_SECRET_KEY: str = Field(default="", env="LANGFUSE_SECRET_KEY")
    LANGFUSE_PUBLIC_KEY: str = Field(default="", env="LANGFUSE_PUBLIC_KEY")
    LANGFUSE_HOST: str = Field(default="http://localhost:3000", env="LANGFUSE_HOST")
    
    # Authentication Configuration
    auth_provider: str = Field(default="backend", env="AUTH_PROVIDER")  # 'backend' or 'supabase'

    # Supabase Configuration (only needed if AUTH_PROVIDER=supabase)
    supabase_url: str = Field(default="", env="SUPABASE_URL")
    supabase_anon_key: str = Field(default="", env="SUPABASE_ANON_KEY")
    supabase_service_role_key: str = Field(default="", env="SUPABASE_SERVICE_ROLE_KEY")
    supabase_jwt_secret: str = Field(default="", env="SUPABASE_JWT_SECRET")

    # Native Auth Configuration (only needed if AUTH_PROVIDER=backend)
    jwt_secret: str = Field(default="", env="JWT_SECRET")  # Generate with: openssl rand -hex 32
    access_token_expire_minutes: int = Field(default=60, env="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_days: int = Field(default=7, env="REFRESH_TOKEN_EXPIRE_DAYS")

    # Application Configuration
    frontend_url: str = Field(default="http://localhost:8100", env="FRONTEND_URL")

    # Security
    api_key: str = Field(default="development_api_key_change_in_production", env="API_KEY")
    cors_origins: str = Field(default="http://localhost:3001,http://localhost:8080", env="CORS_ORIGINS")
    
    # Database Reset Endpoint (development only)
    enable_reset_endpoint: bool = Field(default=True, env="ENABLE_RESET_ENDPOINT")
    reset_api_key: str = Field(default="development_reset_key", env="RESET_API_KEY")
    
    # Application Settings
    max_file_size_mb: int = Field(default=10, env="MAX_FILE_SIZE_MB")
    max_audio_file_size_mb: int = Field(default=500, env="MAX_AUDIO_FILE_SIZE_MB")  # Audio files can be larger
    chunk_size_words: int = Field(default=1500, env="CHUNK_SIZE_WORDS")  # Optimized for 2048 token context
    chunk_overlap_words: int = Field(default=200, env="CHUNK_OVERLAP_WORDS")  # Better coherence
    embedding_model: str = Field(default="google/embeddinggemma-300m", env="EMBEDDING_MODEL")
    embedding_dimension: int = Field(default=768, env="EMBEDDING_DIMENSION")
    top_k_chunks: int = Field(default=5, env="TOP_K_CHUNKS")

    # EmbeddingGemma MRL (Matryoshka) Configuration
    enable_mrl: bool = Field(default=True, env="ENABLE_MRL")
    mrl_dimensions: str = Field(default="128,256,512,768", env="MRL_DIMENSIONS")
    mrl_search_dimension: int = Field(default=128, env="MRL_SEARCH_DIMENSION")  # Fast search
    mrl_rerank_dimension: int = Field(default=768, env="MRL_RERANK_DIMENSION")  # Precise rerank
    rag_use_two_stage_search: bool = Field(default=True, env="RAG_USE_TWO_STAGE_SEARCH")  # Use two-stage MRL search for better quality

    # Multilingual Support
    enable_multilingual: bool = Field(default=True, env="ENABLE_MULTILINGUAL")
    supported_languages: str = Field(default="en,es,fr,de,zh,ja,ar,hi,pt,ru", env="SUPPORTED_LANGUAGES")
    detect_language: bool = Field(default=True, env="DETECT_LANGUAGE")
    cross_lingual_search: bool = Field(default=True, env="CROSS_LINGUAL_SEARCH")
    
    # Enhanced RAG Settings
    # Intelligent Chunking (Optimized for EmbeddingGemma 2048 context)
    intelligent_chunk_size_words: int = Field(default=1500, env="INTELLIGENT_CHUNK_SIZE_WORDS")
    intelligent_chunk_max_size: int = Field(default=1800, env="INTELLIGENT_CHUNK_MAX_SIZE")
    intelligent_chunk_min_size: int = Field(default=300, env="INTELLIGENT_CHUNK_MIN_SIZE")
    intelligent_chunk_overlap: int = Field(default=200, env="INTELLIGENT_CHUNK_OVERLAP")
    semantic_threshold: float = Field(default=0.7, env="SEMANTIC_THRESHOLD")
    topic_boundary_bonus: float = Field(default=0.3, env="TOPIC_BOUNDARY_BONUS")
    speaker_change_bonus: float = Field(default=0.2, env="SPEAKER_CHANGE_BONUS")
    
    # Multi-Query Retrieval
    max_query_variations: int = Field(default=5, env="MAX_QUERY_VARIATIONS")
    multi_query_max_results: int = Field(default=15, env="MULTI_QUERY_MAX_RESULTS")
    query_similarity_threshold: float = Field(default=0.35, env="QUERY_SIMILARITY_THRESHOLD")  # Increased from 0.1 for higher quality results
    query_deduplication_threshold: float = Field(default=0.9, env="QUERY_DEDUPLICATION_THRESHOLD")
    
    # Hybrid Search - Optimized for meeting transcripts (high keyword importance)
    semantic_search_weight: float = Field(default=0.45, env="SEMANTIC_SEARCH_WEIGHT")  # Reduced from 0.6
    keyword_search_weight: float = Field(default=0.55, env="KEYWORD_SEARCH_WEIGHT")  # Increased from 0.4
    cross_encoder_weight: float = Field(default=0.5, env="CROSS_ENCODER_WEIGHT")  # Increased from 0.3
    bm25_k1: float = Field(default=1.2, env="BM25_K1")  # Reduced from 1.5 for less term saturation
    bm25_b: float = Field(default=0.5, env="BM25_B")  # Reduced from 0.75 for consistent-length transcripts
    hybrid_max_results_per_method: int = Field(default=30, env="HYBRID_MAX_RESULTS_PER_METHOD")  # Increased from 20
    hybrid_final_result_count: int = Field(default=15, env="HYBRID_FINAL_RESULT_COUNT")
    diversity_boost: float = Field(default=0.1, env="DIVERSITY_BOOST")
    
    # Meeting Intelligence
    engagement_threshold_very_high: float = Field(default=0.8, env="ENGAGEMENT_THRESHOLD_VERY_HIGH")
    engagement_threshold_high: float = Field(default=0.65, env="ENGAGEMENT_THRESHOLD_HIGH")
    engagement_threshold_medium: float = Field(default=0.45, env="ENGAGEMENT_THRESHOLD_MEDIUM")
    engagement_threshold_low: float = Field(default=0.25, env="ENGAGEMENT_THRESHOLD_LOW")
    min_confidence_for_decisions: float = Field(default=0.7, env="MIN_CONFIDENCE_FOR_DECISIONS")
    min_confidence_for_actions: float = Field(default=0.6, env="MIN_CONFIDENCE_FOR_ACTIONS")
    
    # Enhanced RAG Strategy
    rag_auto_strategy_selection: bool = Field(default=True, env="RAG_AUTO_STRATEGY_SELECTION")
    rag_default_strategy: str = Field(default="intelligent", env="RAG_DEFAULT_STRATEGY")
    rag_max_context_length: int = Field(default=8000, env="RAG_MAX_CONTEXT_LENGTH")
    rag_similarity_threshold: float = Field(default=0.3, env="RAG_SIMILARITY_THRESHOLD")  # Increased from 0.05 for better relevance filtering
    
    # Quality Thresholds
    min_coherence_score: float = Field(default=0.6, env="MIN_COHERENCE_SCORE")
    min_completeness_score: float = Field(default=0.5, env="MIN_COMPLETENESS_SCORE")
    min_confidence_score: float = Field(default=0.3, env="MIN_CONFIDENCE_SCORE")
    filter_low_quality_chunks: bool = Field(default=True, env="FILTER_LOW_QUALITY_CHUNKS")
    
    # NLP Model Settings
    spacy_model: str = Field(default="en_core_web_sm", env="SPACY_MODEL")
    sentence_transformer_model: str = Field(default="google/embeddinggemma-300m", env="SENTENCE_TRANSFORMER_MODEL")
    cross_encoder_model: str = Field(default="cross-encoder/ms-marco-MiniLM-L-2-v2", env="CROSS_ENCODER_MODEL")
    enable_advanced_nlp: bool = Field(default=True, env="ENABLE_ADVANCED_NLP")
    
    # Performance Settings
    max_concurrent_queries: int = Field(default=10, env="MAX_CONCURRENT_QUERIES")
    query_timeout_seconds: int = Field(default=60, env="QUERY_TIMEOUT_SECONDS")
    enable_result_caching: bool = Field(default=True, env="ENABLE_RESULT_CACHING")
    cache_ttl_seconds: int = Field(default=3600, env="CACHE_TTL_SECONDS")

    # Hugging Face Configuration
    hf_token: str = Field(default="", env="HF_TOKEN")

    # Sentry Configuration
    sentry_enabled: bool = Field(default=False, env="SENTRY_ENABLED")
    sentry_dsn: str = Field(default="", env="SENTRY_DSN")
    sentry_environment: str = Field(default="development", env="SENTRY_ENVIRONMENT")
    sentry_traces_sample_rate: float = Field(default=1.0, env="SENTRY_TRACES_SAMPLE_RATE")
    sentry_profile_sample_rate: float = Field(default=1.0, env="SENTRY_PROFILE_SAMPLE_RATE")

    # Logging Configuration
    enable_logstash: bool = Field(default=False, env="ENABLE_LOGSTASH")
    logstash_host: str = Field(default="localhost", env="LOGSTASH_HOST")
    logstash_port: int = Field(default=8080, env="LOGSTASH_PORT")  # HTTP input port

    # Transcription Service Configuration (Defaults - can be overridden by UI integration settings)
    # Options: "whisper" (local), "salad" (Salad API), or "replicate" (Replicate API)
    default_transcription_service: str = Field(default="whisper", env="DEFAULT_TRANSCRIPTION_SERVICE")
    # Salad API credentials (only needed if using Salad as default)
    salad_api_key: str = Field(default="", env="SALAD_API_KEY")
    salad_organization_name: str = Field(default="", env="SALAD_ORGANIZATION_NAME")
    # Replicate API credentials (only needed if using Replicate as default)
    replicate_api_key: str = Field(default="", env="REPLICATE_API_KEY")
    
    class Config:
        # Look for .env in parent directory (root of project)
        import os
        env_file = os.path.join(os.path.dirname(__file__), "..", ".env")
        env_file_encoding = "utf-8"
        case_sensitive = False
        extra = "ignore"  # Ignore extra fields not defined in Settings
    
    @property
    def database_url(self) -> str:
        return f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
    
    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.cors_origins.split(",")]
    
    @property
    def is_development(self) -> bool:
        return self.api_env == "development"
    
    @property
    def is_production(self) -> bool:
        return self.api_env == "production"
    
    # Backward compatibility aliases for Langfuse
    @property
    def langfuse_url(self) -> str:
        return self.LANGFUSE_URL
    
    @property
    def langfuse_host(self) -> str:
        return self.LANGFUSE_HOST
    
    @property  
    def langfuse_public_key(self) -> str:
        return self.LANGFUSE_PUBLIC_KEY
    
    @property
    def langfuse_secret(self) -> str:
        return self.LANGFUSE_SECRET_KEY

    @property
    def mrl_dimensions_list(self) -> List[int]:
        """Parse MRL dimensions from comma-separated string."""
        return [int(d.strip()) for d in self.mrl_dimensions.split(",") if d.strip()]

    @property
    def supported_languages_list(self) -> List[str]:
        """Parse supported languages from comma-separated string."""
        return [lang.strip() for lang in self.supported_languages.split(",") if lang.strip()]


@lru_cache()
def get_settings() -> Settings:
    return Settings()


def configure_logging(settings: Settings) -> None:
    log_level = getattr(logging, settings.api_log_level.upper(), logging.INFO)

    # Clear any existing handlers to avoid duplicates
    logging.getLogger().handlers = []

    # Configure the root logger with a single handler
    logging.basicConfig(
        level=log_level,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        force=True  # Force reconfiguration to avoid duplicates
    )

    # Add Logstash handler for ELK stack integration (optional)
    if settings.enable_logstash:
        try:
            from utils.logstash_handler import AsyncLogstashHandler
            logstash_handler = AsyncLogstashHandler(
                host=settings.logstash_host,
                port=settings.logstash_port,
                app_name='pm_master',
                environment=settings.api_env
            )
            logstash_handler.setLevel(logging.INFO)  # Send INFO and above to Logstash
            logging.getLogger().addHandler(logstash_handler)
            logging.info("Logstash handler configured successfully")
        except Exception as e:
            # Don't fail if Logstash is unavailable - log to console only
            logging.warning(f"Failed to configure Logstash handler: {e}")
    else:
        logging.info("Logstash logging disabled - using local file/console logging only")

    # Disable verbose HTTP logging
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("urllib3.connectionpool").setLevel(logging.WARNING)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("anthropic._base_client").setLevel(logging.WARNING)

    # Disable SQLAlchemy INFO logging - set all SQLAlchemy loggers to WARNING
    logging.getLogger("sqlalchemy").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine.Engine").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.pool.impl").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.orm").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.dialects").setLevel(logging.WARNING)