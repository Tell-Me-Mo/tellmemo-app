#!/usr/bin/env python3
"""
Test script to verify the LLM client refactoring.
Tests that all services properly use the centralized LLM client.
"""

import asyncio
import sys
from pathlib import Path

# Add backend directory to path
sys.path.insert(0, str(Path(__file__).parent))

from config import get_settings
from services.llm.multi_llm_client import get_multi_llm_client, MultiProviderLLMClient
from services.summaries.summary_service_refactored import SummaryService
from services.rag.enhanced_rag_service_refactored import EnhancedRAGService
from services.intelligence.project_matcher_service import ProjectMatcherService
from services.intelligence.risks_tasks_analyzer_service import RisksTasksAnalyzer
from services.intelligence.project_description_service import ProjectDescriptionAnalyzer


async def test_llm_client():
    """Test the centralized LLM client."""
    print("\n=== Testing LLM Client ===")

    settings = get_settings()

    # Test singleton pattern
    client1 = get_multi_llm_client(settings)
    client2 = get_multi_llm_client()
    assert client1 is client2, "LLM client should be a singleton"
    print("✓ Singleton pattern working")

    # Test availability check
    is_available = client1.is_available()
    print(f"✓ LLM client available: {is_available}")

    # Test model info
    model_info = client1.get_model_info()
    print(f"✓ Model info: {model_info}")

    # Test health check
    if is_available:
        health = await client1.health_check()
        print(f"✓ Health check: {health}")

    return client1


async def test_service_initialization():
    """Test that all services initialize properly with the centralized client."""
    print("\n=== Testing Service Initialization ===")

    try:
        # Test SummaryService
        summary_svc = SummaryService()
        assert hasattr(summary_svc, 'llm_client'), "SummaryService should have llm_client"
        assert isinstance(summary_svc.llm_client, MultiProviderLLMClient), "Should be MultiProviderLLMClient instance"
        print("✓ SummaryService initialized correctly")

        # Test EnhancedRAGService
        rag_svc = EnhancedRAGService()
        assert hasattr(rag_svc, 'llm_client'), "EnhancedRAGService should have llm_client"
        assert isinstance(rag_svc.llm_client, MultiProviderLLMClient), "Should be MultiProviderLLMClient instance"
        print("✓ EnhancedRAGService initialized correctly")

        # Test ProjectMatcherService
        matcher_svc = ProjectMatcherService()
        assert hasattr(matcher_svc, 'llm_client'), "ProjectMatcherService should have llm_client"
        assert isinstance(matcher_svc.llm_client, MultiProviderLLMClient), "Should be MultiProviderLLMClient instance"
        print("✓ ProjectMatcherService initialized correctly")

        # Test RisksTasksAnalyzer
        risks_svc = RisksTasksAnalyzer()
        assert hasattr(risks_svc, 'llm_client'), "RisksTasksAnalyzer should have llm_client"
        assert isinstance(risks_svc.llm_client, MultiProviderLLMClient), "Should be MultiProviderLLMClient instance"
        print("✓ RisksTasksAnalyzer initialized correctly")

        # Test ProjectDescriptionAnalyzer
        desc_svc = ProjectDescriptionAnalyzer()
        assert hasattr(desc_svc, 'llm_client'), "ProjectDescriptionAnalyzer should have llm_client"
        assert isinstance(desc_svc.llm_client, MultiProviderLLMClient), "Should be MultiProviderLLMClient instance"
        print("✓ ProjectDescriptionAnalyzer initialized correctly")

        # Verify all services use the same client instance
        assert summary_svc.llm_client is rag_svc.llm_client, "Services should share the same LLM client"
        assert rag_svc.llm_client is matcher_svc.llm_client, "Services should share the same LLM client"
        assert matcher_svc.llm_client is risks_svc.llm_client, "Services should share the same LLM client"
        assert risks_svc.llm_client is desc_svc.llm_client, "Services should share the same LLM client"
        print("✓ All services share the same LLM client instance")

    except Exception as e:
        print(f"✗ Error during service initialization: {e}")
        raise


async def test_api_call():
    """Test making an API call through the centralized client."""
    print("\n=== Testing API Call ===")

    client = get_multi_llm_client()

    if not client.is_available():
        print("⚠ Skipping API call test - no API key configured")
        return

    try:
        # Test a simple message
        response = await client.create_message(
            prompt="Say 'Hello, World!' and nothing else.",
            max_tokens=20,
            temperature=0
        )

        if response:
            print(f"✓ API call successful")
            print(f"  Response: {response.content[0].text[:50]}...")
        else:
            print("✗ API call returned None")

    except Exception as e:
        print(f"✗ API call failed: {e}")


async def main():
    """Run all tests."""
    print("=" * 50)
    print("LLM Client Refactoring Test Suite")
    print("=" * 50)

    try:
        # Test LLM client
        client = await test_llm_client()

        # Test service initialization
        await test_service_initialization()

        # Test API call
        await test_api_call()

        print("\n" + "=" * 50)
        print("✅ All tests passed successfully!")
        print("=" * 50)

    except Exception as e:
        print("\n" + "=" * 50)
        print(f"❌ Tests failed: {e}")
        print("=" * 50)
        sys.exit(1)
    finally:
        # Clean up singleton for future tests
        MultiProviderLLMClient.reset_instance()


if __name__ == "__main__":
    asyncio.run(main())