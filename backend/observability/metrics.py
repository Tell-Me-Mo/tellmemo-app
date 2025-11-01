"""
Application-Specific Metrics Registry

Provides structured metrics for key TellMeMo operations:
- LLM calls (by provider, model, status)
- RAG queries (latency, chunk count, success rate)
- Embeddings generation (model, dimension, batch size)
- Meeting processing (transcription, summarization)
- Database operations
"""

from typing import Optional
from opentelemetry import metrics
from opentelemetry.metrics import Counter, Histogram, UpDownCounter

# Singleton metrics instance
_metrics_instance: Optional["TellMeMoMetrics"] = None


class TellMeMoMetrics:
    """
    Centralized metrics registry for TellMeMo application.

    Provides counters, histograms, and gauges for all critical operations.
    """

    def __init__(self, meter_name: str = "tellmemo"):
        """Initialize metrics with a meter instance."""
        self.meter = metrics.get_meter(meter_name)

        # === LLM Metrics ===
        self.llm_requests_total = self.meter.create_counter(
            name="llm.requests.total",
            description="Total number of LLM API requests",
            unit="requests",
        )

        self.llm_requests_duration = self.meter.create_histogram(
            name="llm.requests.duration",
            description="Duration of LLM API requests in seconds",
            unit="s",
        )

        self.llm_tokens_total = self.meter.create_counter(
            name="llm.tokens.total",
            description="Total number of tokens processed (prompt + completion)",
            unit="tokens",
        )

        self.llm_errors_total = self.meter.create_counter(
            name="llm.errors.total",
            description="Total number of LLM API errors",
            unit="errors",
        )

        self.llm_cost_total = self.meter.create_counter(
            name="llm.cost.total",
            description="Total estimated cost of LLM calls in USD cents",
            unit="cents",
        )

        # === RAG Metrics ===
        self.rag_queries_total = self.meter.create_counter(
            name="rag.queries.total",
            description="Total number of RAG queries",
            unit="queries",
        )

        self.rag_query_duration = self.meter.create_histogram(
            name="rag.query.duration",
            description="Duration of RAG query processing in seconds",
            unit="s",
        )

        self.rag_chunks_retrieved = self.meter.create_histogram(
            name="rag.chunks.retrieved",
            description="Number of chunks retrieved per query",
            unit="chunks",
        )

        self.rag_context_size = self.meter.create_histogram(
            name="rag.context.size",
            description="Size of context sent to LLM in characters",
            unit="characters",
        )

        self.rag_errors_total = self.meter.create_counter(
            name="rag.errors.total",
            description="Total number of RAG query errors",
            unit="errors",
        )

        # === Embedding Metrics ===
        self.embedding_requests_total = self.meter.create_counter(
            name="embedding.requests.total",
            description="Total number of embedding generation requests",
            unit="requests",
        )

        self.embedding_duration = self.meter.create_histogram(
            name="embedding.duration",
            description="Duration of embedding generation in seconds",
            unit="s",
        )

        self.embedding_texts_processed = self.meter.create_counter(
            name="embedding.texts.processed",
            description="Total number of texts embedded",
            unit="texts",
        )

        # === Meeting Intelligence Metrics ===
        self.meetings_transcribed_total = self.meter.create_counter(
            name="meetings.transcribed.total",
            description="Total number of meetings transcribed",
            unit="meetings",
        )

        self.meetings_summarized_total = self.meter.create_counter(
            name="meetings.summarized.total",
            description="Total number of meetings summarized",
            unit="meetings",
        )

        self.transcription_duration = self.meter.create_histogram(
            name="transcription.duration",
            description="Duration of transcription processing in seconds",
            unit="s",
        )

        self.summarization_duration = self.meter.create_histogram(
            name="summarization.duration",
            description="Duration of summary generation in seconds",
            unit="s",
        )

        # === Database Metrics ===
        self.db_queries_total = self.meter.create_counter(
            name="db.queries.total",
            description="Total number of database queries",
            unit="queries",
        )

        self.db_query_duration = self.meter.create_histogram(
            name="db.query.duration",
            description="Duration of database queries in seconds",
            unit="s",
        )

        self.db_connection_pool_size = self.meter.create_up_down_counter(
            name="db.connection_pool.size",
            description="Current database connection pool size",
            unit="connections",
        )

        # === Vector Store Metrics ===
        self.vector_store_searches_total = self.meter.create_counter(
            name="vector_store.searches.total",
            description="Total number of vector similarity searches",
            unit="searches",
        )

        self.vector_store_search_duration = self.meter.create_histogram(
            name="vector_store.search.duration",
            description="Duration of vector similarity searches in seconds",
            unit="s",
        )

        self.vector_store_inserts_total = self.meter.create_counter(
            name="vector_store.inserts.total",
            description="Total number of vectors inserted",
            unit="vectors",
        )

        # === HTTP Metrics (custom beyond auto-instrumentation) ===
        self.websocket_connections_active = self.meter.create_up_down_counter(
            name="websocket.connections.active",
            description="Current number of active WebSocket connections",
            unit="connections",
        )

        self.file_uploads_total = self.meter.create_counter(
            name="file.uploads.total",
            description="Total number of file uploads",
            unit="files",
        )

        self.file_upload_size = self.meter.create_histogram(
            name="file.upload.size",
            description="Size of uploaded files in bytes",
            unit="bytes",
        )

    # === Helper Methods for Common Operations ===

    def record_llm_request(
        self,
        provider: str,
        model: str,
        duration: float,
        prompt_tokens: int = 0,
        completion_tokens: int = 0,
        success: bool = True,
        error_type: Optional[str] = None,
    ):
        """Record metrics for an LLM request."""
        attributes = {
            "llm.provider": provider,
            "llm.model": model,
            "llm.status": "success" if success else "error",
        }

        self.llm_requests_total.add(1, attributes)
        self.llm_requests_duration.record(duration, attributes)

        if success:
            total_tokens = prompt_tokens + completion_tokens
            self.llm_tokens_total.add(
                total_tokens,
                {
                    **attributes,
                    "token.type": "total",
                },
            )
            self.llm_tokens_total.add(
                prompt_tokens,
                {
                    **attributes,
                    "token.type": "prompt",
                },
            )
            self.llm_tokens_total.add(
                completion_tokens,
                {
                    **attributes,
                    "token.type": "completion",
                },
            )
        else:
            self.llm_errors_total.add(
                1,
                {
                    **attributes,
                    "error.type": error_type or "unknown",
                },
            )

    def record_rag_query(
        self,
        duration: float,
        chunks_retrieved: int,
        context_size: int,
        success: bool = True,
        error_type: Optional[str] = None,
    ):
        """Record metrics for a RAG query."""
        attributes = {
            "rag.status": "success" if success else "error",
        }

        self.rag_queries_total.add(1, attributes)
        self.rag_query_duration.record(duration, attributes)

        if success:
            self.rag_chunks_retrieved.record(chunks_retrieved, attributes)
            self.rag_context_size.record(context_size, attributes)
        else:
            self.rag_errors_total.add(
                1,
                {
                    "error.type": error_type or "unknown",
                },
            )

    def record_embedding_generation(
        self,
        model: str,
        duration: float,
        text_count: int,
        success: bool = True,
    ):
        """Record metrics for embedding generation."""
        attributes = {
            "embedding.model": model,
            "embedding.status": "success" if success else "error",
        }

        self.embedding_requests_total.add(1, attributes)
        self.embedding_duration.record(duration, attributes)

        if success:
            self.embedding_texts_processed.add(text_count, attributes)

    def record_transcription(self, service: str, duration: float, success: bool = True):
        """Record metrics for transcription."""
        attributes = {
            "transcription.service": service,
            "transcription.status": "success" if success else "error",
        }

        self.meetings_transcribed_total.add(1, attributes)
        self.transcription_duration.record(duration, attributes)

    def record_summarization(self, summary_type: str, duration: float, success: bool = True):
        """Record metrics for summary generation."""
        attributes = {
            "summary.type": summary_type,
            "summary.status": "success" if success else "error",
        }

        self.meetings_summarized_total.add(1, attributes)
        self.summarization_duration.record(duration, attributes)

    def record_vector_search(self, duration: float, results_count: int):
        """Record metrics for vector similarity search."""
        attributes = {
            "vector_store.operation": "search",
        }

        self.vector_store_searches_total.add(1, attributes)
        self.vector_store_search_duration.record(duration, attributes)

    def record_file_upload(self, file_type: str, file_size: int, success: bool = True):
        """Record metrics for file uploads."""
        attributes = {
            "file.type": file_type,
            "file.status": "success" if success else "error",
        }

        self.file_uploads_total.add(1, attributes)
        if success:
            self.file_upload_size.record(file_size, attributes)


def get_metrics() -> TellMeMoMetrics:
    """
    Get the singleton TellMeMo metrics instance.

    Returns:
        TellMeMoMetrics: Global metrics registry

    Example:
        ```python
        from observability import get_metrics

        metrics = get_metrics()
        metrics.record_llm_request(
            provider="claude",
            model="haiku",
            duration=1.5,
            prompt_tokens=100,
            completion_tokens=50,
            success=True
        )
        ```
    """
    global _metrics_instance

    if _metrics_instance is None:
        _metrics_instance = TellMeMoMetrics()

    return _metrics_instance
