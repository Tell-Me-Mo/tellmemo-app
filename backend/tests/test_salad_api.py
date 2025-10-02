#!/usr/bin/env python3
"""
Test script for Salad API connection validation.
Usage: python test_salad_api.py <api_key> <organization_name>
"""

import asyncio
import sys
from services.transcription.salad_transcription_service import SaladTranscriptionService


async def test_salad_connection(api_key: str, org_name: str):
    """Test Salad API connection"""
    print(f"Testing Salad API connection...")
    print(f"Organization: {org_name}")
    print("-" * 50)

    service = SaladTranscriptionService(
        api_key=api_key,
        organization_name=org_name
    )

    result = await service.test_connection()

    if result["success"]:
        print(f"✅ SUCCESS: {result['message']}")
    else:
        print(f"❌ FAILED: {result['error']}")

    return result


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python test_salad_api.py <api_key> <organization_name>")
        print("Example: python test_salad_api.py 'your-api-key' 'your-org-name'")
        sys.exit(1)

    api_key = sys.argv[1]
    org_name = sys.argv[2]

    # Run the test
    result = asyncio.run(test_salad_connection(api_key, org_name))

    # Exit with appropriate code
    sys.exit(0 if result["success"] else 1)