#!/usr/bin/env python3
"""
Test script to verify Grafana Cloud OpenTelemetry integration.
Sends test metrics to confirm connectivity and configuration.
"""
import sys
import time
from config import get_settings
from observability.telemetry import init_telemetry, shutdown_telemetry
from observability.business_metrics import get_business_metrics
from observability.metrics import TellMeMoMetrics

def main():
    print("🧪 Testing Grafana Cloud OpenTelemetry Integration\n")

    # Load settings
    settings = get_settings()
    print(f"Service Name: {settings.otel_service_name}")
    print(f"OTLP Endpoint: {settings.otel_exporter_otlp_endpoint}")
    print(f"Region: EU West 2")
    print(f"Protocol: {settings.otel_exporter_otlp_protocol}\n")

    # Initialize OpenTelemetry
    print("📡 Initializing OpenTelemetry...")
    if not init_telemetry(settings):
        print("❌ Failed to initialize OpenTelemetry")
        return 1

    print("✅ OpenTelemetry initialized successfully\n")

    # Get metrics instances
    print("📊 Creating test metrics...")
    business_metrics = get_business_metrics()
    tech_metrics = TellMeMoMetrics()

    # Send test business metrics
    print("\n1️⃣ Sending business metrics...")

    # User engagement test
    business_metrics.record_user_question(
        user_id="test_user_123",
        project_id="test_project_456",
        has_results=True
    )
    print("   ✓ User question recorded")

    # LLM cost test
    business_metrics.record_llm_cost(
        provider="claude",
        cost_cents=0.28,  # ~$0.0028
        operation_type="query",
        user_id="test_user_123"
    )
    print("   ✓ LLM cost recorded (Claude: $0.0028)")

    # Organization-level test
    business_metrics.record_org_query(
        organization_id="test_org_789",
        user_id="test_user_123",
        cost_cents=0.28
    )
    print("   ✓ Organization query recorded")

    # Content coverage gap test
    business_metrics.record_content_coverage_gap(
        query="What is the project status?",
        project_id="test_project_456",
        user_id="test_user_123",
        reason="no_results"
    )
    print("   ✓ Content coverage gap recorded")

    # SLA compliance test
    business_metrics.record_sla_compliance(
        operation="rag_query",
        response_time_ms=1500,  # 1.5 seconds (within 2s SLA)
        sla_threshold_ms=2000,
        success=True
    )
    print("   ✓ SLA compliance recorded (1.5s < 2.0s)")

    # Time-to-value test
    business_metrics.record_time_to_first_query(
        user_id="test_user_123",
        seconds_since_signup=240,  # 4 minutes
        success=True
    )
    print("   ✓ Time-to-value recorded (4 min)")

    # Send test technical metrics
    print("\n2️⃣ Sending technical metrics...")

    # LLM request test
    tech_metrics.llm_requests_total.add(
        1,
        attributes={
            "provider": "claude",
            "model": "claude-3-5-haiku-latest",
            "success": "true"
        }
    )
    print("   ✓ LLM request recorded")

    # RAG query test
    tech_metrics.rag_queries_total.add(
        1,
        attributes={
            "strategy": "intelligent",
            "success": "true"
        }
    )
    print("   ✓ RAG query recorded")

    # Embedding request test
    tech_metrics.embedding_requests_total.add(
        1,
        attributes={
            "model": "google/embeddinggemma-300m",
            "success": "true"
        }
    )
    print("   ✓ Embedding request recorded")

    print("\n⏳ Waiting 5 seconds for metrics to be exported...")
    time.sleep(5)

    # Shutdown telemetry (flush remaining metrics)
    print("📤 Flushing metrics to Grafana Cloud...")
    shutdown_telemetry()

    print("\n✅ Test Complete!")
    print("\n📊 Next Steps:")
    print("1. Go to your Grafana Cloud dashboard: https://grafana.com/")
    print("2. Navigate to Explore → Metrics")
    print("3. Search for metrics starting with:")
    print("   - business.users.questions")
    print("   - business.llm.cost")
    print("   - business.organization.queries")
    print("   - business.content.coverage_gaps")
    print("   - business.sla.compliance")
    print("   - technical.llm.requests")
    print("   - technical.rag.queries")
    print("4. Filter by service.name = 'tellmemo-app'")
    print("\n💡 Metrics are exported every 60 seconds by default")
    print("   You should see the test data within 1-2 minutes!\n")

    return 0

if __name__ == "__main__":
    sys.exit(main())
