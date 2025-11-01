"""
TellMeMo Observability Module

Provides OpenTelemetry instrumentation for traces, metrics, and logs.
Supports Grafana Cloud and other OTLP-compatible backends.
"""

from .telemetry import (
    init_telemetry,
    shutdown_telemetry,
    get_tracer,
    get_meter,
)

from .decorators import (
    trace_async,
    trace_sync,
    track_llm_call,
    track_rag_query,
    track_embedding_generation,
)

from .metrics import (
    TellMeMoMetrics,
    get_metrics,
)

from .business_metrics import (
    BusinessMetrics,
    get_business_metrics,
)

__all__ = [
    # Core telemetry
    "init_telemetry",
    "shutdown_telemetry",
    "get_tracer",
    "get_meter",
    # Decorators
    "trace_async",
    "trace_sync",
    "track_llm_call",
    "track_rag_query",
    "track_embedding_generation",
    # Metrics
    "TellMeMoMetrics",
    "get_metrics",
    # Business Metrics
    "BusinessMetrics",
    "get_business_metrics",
]
