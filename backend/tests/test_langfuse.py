#!/usr/bin/env python3
"""Test script to verify Langfuse v3 integration."""

import asyncio
import os
import sys
from datetime import datetime
import logging

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

async def test_langfuse_integration():
    """Test Langfuse service with real API calls."""
    
    # Import after path setup
    from services.observability.langfuse_service import langfuse_service
    from config import get_settings
    
    settings = get_settings()
    
    print("=" * 60)
    print("Testing Langfuse v3 Integration")
    print("=" * 60)
    
    # Check configuration
    print(f"\n1. Configuration Check:")
    print(f"   - Langfuse Enabled: {langfuse_service.is_enabled}")
    print(f"   - Host: {settings.LANGFUSE_HOST}")
    print(f"   - Public Key Set: {'Yes' if settings.LANGFUSE_PUBLIC_KEY else 'No'}")
    print(f"   - Secret Key Set: {'Yes' if settings.LANGFUSE_SECRET_KEY else 'No'}")
    
    if not langfuse_service.is_enabled:
        print("\n❌ Langfuse is not enabled. Please set LANGFUSE_PUBLIC_KEY and LANGFUSE_SECRET_KEY")
        return
    
    # Test 1: Create a trace
    print(f"\n2. Creating Trace:")
    trace = langfuse_service.create_trace(
        name="test_rag_query",
        user_id="test_user_123",
        session_id="test_session_456",
        metadata={"test": True, "environment": "testing"},
        tags=["test", "integration"],
        version="1.0.0"
    )
    
    if trace:
        print(f"   ✅ Trace created: {trace.get('id')}")
        trace_id = trace.get('id')
    else:
        print(f"   ❌ Failed to create trace")
        return
    
    # Test 2: Create a span
    print(f"\n3. Creating Span:")
    span = langfuse_service.create_span(
        trace_id=trace_id,
        name="embedding_generation",
        input={"query": "What were the key decisions?"},
        metadata={"step": "embedding", "model": "google/embeddinggemma-300m"},
        level="DEFAULT"
    )
    
    if span:
        print(f"   ✅ Span created")
        # Update span with output
        if hasattr(span, 'update'):
            span.update(output={"embedding_size": 768})
            print(f"   ✅ Span updated with output")
    else:
        print(f"   ❌ Failed to create span")
    
    # Test 3: Create a generation
    print(f"\n4. Creating Generation:")
    generation = langfuse_service.create_generation(
        trace_id=trace_id,
        name="claude_rag_response",
        model="claude-3-5-haiku-latest",
        model_parameters={"temperature": 0.7, "max_tokens": 4096},
        input="Based on the meeting transcript, what were the key decisions?",
        output="The key decisions from the meeting were...",
        usage={"input_tokens": 1500, "output_tokens": 250, "total_tokens": 1750},
        metadata={"rag_strategy": "hybrid", "chunks_retrieved": 5}
    )
    
    if generation:
        print(f"   ✅ Generation created")
        if hasattr(generation, 'end'):
            generation.end()
            print(f"   ✅ Generation ended")
    else:
        print(f"   ❌ Failed to create generation")
    
    # Test 4: Create an event
    print(f"\n5. Creating Event:")
    event = langfuse_service.create_event(
        trace_id=trace_id,
        name="chunk_retrieved",
        input={"chunk_id": "test_chunk_001"},
        output={"relevance_score": 0.92},
        metadata={"source": "vector_db"},
        level="DEFAULT"
    )
    
    if event:
        print(f"   ✅ Event created")
    else:
        print(f"   ❌ Failed to create event")
    
    # Test 5: Add a score
    print(f"\n6. Adding Score:")
    score = langfuse_service.score(
        trace_id=trace_id,
        name="quality",
        value=0.85,
        comment="Good response quality with relevant information"
    )
    
    if score:
        print(f"   ✅ Score added")
    else:
        print(f"   ❌ Failed to add score")
    
    # Test 6: End the root span if it exists
    if trace and 'span' in trace and hasattr(trace['span'], 'end'):
        trace['span'].end()
        print(f"\n7. Ending Root Span:")
        print(f"   ✅ Root span ended")
    
    # Test 7: Flush events
    print(f"\n8. Flushing Events:")
    langfuse_service.flush()
    print(f"   ✅ Events flushed to Langfuse")
    
    # Test 8: Check health
    print(f"\n9. Health Check:")
    health = await langfuse_service.check_health()
    print(f"   - Status: {health.get('status')}")
    if health.get('message'):
        print(f"   - Message: {health.get('message')}")
    
    print("\n" + "=" * 60)
    print("Test Complete!")
    print("=" * 60)
    
    if trace_id:
        print(f"\n📊 View your trace in Langfuse:")
        print(f"   {settings.LANGFUSE_HOST}/trace/{trace_id}")

if __name__ == "__main__":
    asyncio.run(test_langfuse_integration())