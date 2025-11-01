"""
OpenTelemetry Telemetry Setup (2025 Best Practices)

Configures traces, metrics, and logs for Grafana Cloud (OTLP endpoint).

Uses OpenTelemetry Distro approach:
- Common frameworks (FastAPI, SQLAlchemy, Redis, httpx, aiohttp) are auto-instrumented
  via `opentelemetry-bootstrap -a install` and distro
- Specialized libraries (asyncpg, Qdrant) are manually instrumented below

Setup:
1. pip install opentelemetry-distro opentelemetry-exporter-otlp
2. opentelemetry-bootstrap -a install  # Auto-detects and installs instrumentations
3. pip install opentelemetry-instrumentation-asyncpg opentelemetry-instrumentation-qdrant
"""

import logging
from typing import Optional
import urllib3
import requests
import ssl
import os
from opentelemetry import trace, metrics
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider, Counter, UpDownCounter, Histogram
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader, AggregationTemporality
from opentelemetry.sdk.metrics.view import View
from opentelemetry.sdk.resources import Resource, SERVICE_NAME, SERVICE_VERSION, DEPLOYMENT_ENVIRONMENT
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter

from config import Settings

logger = logging.getLogger(__name__)

# Global telemetry state
_tracer_provider: Optional[TracerProvider] = None
_meter_provider: Optional[MeterProvider] = None
_is_initialized = False


def init_telemetry(settings: Settings) -> bool:
    """
    Initialize OpenTelemetry with Grafana Cloud OTLP endpoint.

    Returns:
        bool: True if telemetry was successfully initialized, False otherwise
    """
    global _tracer_provider, _meter_provider, _is_initialized

    if _is_initialized:
        logger.warning("Telemetry already initialized, skipping")
        return True

    if not settings.otel_enabled:
        logger.info("OpenTelemetry is disabled (OTEL_ENABLED=false)")
        return False

    if not settings.otel_exporter_otlp_headers.strip():
        logger.warning("OpenTelemetry headers not configured (OTEL_EXPORTER_OTLP_HEADERS is empty)")
        logger.warning("Telemetry will not be sent to Grafana Cloud until credentials are configured")
        return False

    try:
        # Create resource with service information
        resource = Resource.create({
            SERVICE_NAME: settings.otel_service_name,
            SERVICE_VERSION: settings.otel_service_version,
            DEPLOYMENT_ENVIRONMENT: settings.otel_deployment_environment,
            "service.instance.id": f"{settings.otel_service_name}-{settings.api_env}",
        })

        # Parse OTLP headers (format: "key1=value1,key2=value2")
        headers_dict = {}
        if settings.otel_exporter_otlp_headers:
            for header in settings.otel_exporter_otlp_headers.split(","):
                if "=" in header:
                    key, value = header.split("=", 1)
                    headers_dict[key.strip()] = value.strip()

        # Disable SSL verification globally for development
        # This is the most reliable way to disable SSL for OTLP exporters
        if settings.api_env == "development":
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            # Monkey-patch requests to disable SSL verification globally
            original_request = requests.Session.request

            def patched_request(self, *args, **kwargs):
                kwargs['verify'] = False
                return original_request(self, *args, **kwargs)

            requests.Session.request = patched_request
            logger.info("🔓 SSL verification disabled globally for development environment")

        # Initialize Traces
        _tracer_provider = TracerProvider(resource=resource)
        trace_exporter = OTLPSpanExporter(
            endpoint=f"{settings.otel_exporter_otlp_endpoint}/v1/traces",
            headers=headers_dict,
            timeout=10,  # 10 second timeout
        )
        _tracer_provider.add_span_processor(BatchSpanProcessor(trace_exporter))
        trace.set_tracer_provider(_tracer_provider)

        # Initialize Metrics with Cumulative temporality (required by Grafana Cloud/Prometheus)
        # Grafana Cloud uses Prometheus/Mimir which expects cumulative metrics
        # Cumulative = total accumulated value since start (resilient to data loss)
        metric_exporter = OTLPMetricExporter(
            endpoint=f"{settings.otel_exporter_otlp_endpoint}/v1/metrics",
            headers=headers_dict,
            timeout=10,  # 10 second timeout
            preferred_temporality={
                # All metric types use Cumulative for Grafana Cloud/Prometheus
                Counter: AggregationTemporality.CUMULATIVE,
                UpDownCounter: AggregationTemporality.CUMULATIVE,
                Histogram: AggregationTemporality.CUMULATIVE,
            }
        )

        metric_reader = PeriodicExportingMetricReader(
            metric_exporter,
            export_interval_millis=settings.otel_metrics_export_interval_millis,
        )
        _meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
        metrics.set_meter_provider(_meter_provider)

        logger.info(f"✅ OpenTelemetry initialized successfully")
        logger.info(f"   Service: {settings.otel_service_name}")
        logger.info(f"   Environment: {settings.otel_deployment_environment}")
        logger.info(f"   Endpoint: {settings.otel_exporter_otlp_endpoint}")

        _is_initialized = True
        return True

    except Exception as e:
        logger.error(f"❌ Failed to initialize OpenTelemetry: {e}")
        logger.error("   Application will continue without telemetry")
        return False


def instrument_specialized_libraries():
    """
    Manually instrument specialized libraries that are not auto-detected by distro.

    Libraries instrumented:
    - asyncpg: PostgreSQL async driver
    - Qdrant: Vector database for embeddings

    Note: Common frameworks (FastAPI, SQLAlchemy, Redis, httpx, aiohttp) are
    auto-instrumented by the distro via opentelemetry-bootstrap -a install.
    """
    instrumented = []

    # Instrument asyncpg (PostgreSQL async driver)
    try:
        from opentelemetry.instrumentation.asyncpg import AsyncPGInstrumentor
        AsyncPGInstrumentor().instrument()
        instrumented.append("asyncpg")
        logger.info("✅ asyncpg (PostgreSQL) auto-instrumented")
    except ImportError:
        logger.warning("⚠️ opentelemetry-instrumentation-asyncpg not installed")
        logger.warning("   Install with: pip install opentelemetry-instrumentation-asyncpg")
    except Exception as e:
        logger.error(f"❌ Failed to instrument asyncpg: {e}")

    # Instrument Qdrant (vector database)
    try:
        from opentelemetry.instrumentation.qdrant import QdrantInstrumentor
        QdrantInstrumentor().instrument()
        instrumented.append("Qdrant")
        logger.info("✅ Qdrant (vector DB) auto-instrumented")
    except ImportError:
        logger.warning("⚠️ opentelemetry-instrumentation-qdrant not installed")
        logger.warning("   Install with: pip install opentelemetry-instrumentation-qdrant")
    except Exception as e:
        logger.error(f"❌ Failed to instrument Qdrant: {e}")

    if instrumented:
        logger.info(f"🎯 Specialized instrumentation complete: {', '.join(instrumented)}")
    else:
        logger.warning("⚠️ No specialized libraries were instrumented")

    # Log auto-instrumented libraries (from distro bootstrap)
    logger.info("📦 Auto-instrumented by distro: FastAPI, SQLAlchemy, Redis, httpx, aiohttp")
    logger.info("   (Run 'opentelemetry-bootstrap -a install' to enable)")


def shutdown_telemetry():
    """
    Shutdown telemetry providers and flush remaining data.
    """
    global _tracer_provider, _meter_provider, _is_initialized

    if not _is_initialized:
        return

    try:
        if _tracer_provider:
            _tracer_provider.shutdown()
        if _meter_provider:
            _meter_provider.shutdown()
        logger.info("OpenTelemetry shutdown complete")
        _is_initialized = False
    except Exception as e:
        logger.error(f"Error during telemetry shutdown: {e}")


def get_tracer(name: str = __name__):
    """
    Get a tracer instance for creating custom spans.

    Args:
        name: Name of the tracer (typically __name__ of the module)

    Returns:
        Tracer instance for creating spans
    """
    return trace.get_tracer(name)


def get_meter(name: str = __name__):
    """
    Get a meter instance for creating custom metrics.

    Args:
        name: Name of the meter (typically __name__ of the module)

    Returns:
        Meter instance for creating metrics
    """
    return metrics.get_meter(name)


def is_telemetry_enabled() -> bool:
    """Check if telemetry is initialized and enabled."""
    return _is_initialized
