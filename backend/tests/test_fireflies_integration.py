#!/usr/bin/env python3
"""
Test script for Fireflies webhook integration with smart project matching
"""
import asyncio
import httpx
import json
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8001"  # Update with your backend URL
INTEGRATION_ID = "fireflies"  # The integration ID to use


async def connect_fireflies_integration(api_key: str, webhook_secret: str = None):
    """Connect the Fireflies integration."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{BASE_URL}/api/integrations/{INTEGRATION_ID}/connect",
            json={
                "api_key": api_key,
                "webhook_secret": webhook_secret,
                "auto_sync": True,
                "selected_project": None  # This will trigger smart matching
            }
        )
        response.raise_for_status()
        print(f"✅ Connected Fireflies integration: {response.json()}")
        return response.json()


async def test_webhook_with_smart_matching(meeting_id: str = "TEST_MEETING_001"):
    """Test the webhook endpoint with a sample payload."""
    async with httpx.AsyncClient() as client:
        # Sample webhook payload from Fireflies
        payload = {
            "meetingId": meeting_id,
            "eventType": "Transcription completed"
        }
        
        print(f"\n📤 Sending webhook payload: {json.dumps(payload, indent=2)}")
        
        response = await client.post(
            f"{BASE_URL}/api/integrations/webhooks/fireflies/{INTEGRATION_ID}",
            json=payload,
            headers={
                "Content-Type": "application/json",
                # Add signature header if webhook secret is configured
            }
        )
        
        if response.status_code == 200:
            print(f"✅ Webhook accepted: {response.json()}")
        else:
            print(f"❌ Webhook failed: {response.status_code} - {response.text}")
        
        return response


async def check_integration_status():
    """Check the status of all integrations."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/integrations/")
        response.raise_for_status()
        
        print("\n📋 Integration Status:")
        for integration in response.json():
            print(f"  - {integration['name']}: {integration['status']}")
            if integration.get('last_sync_at'):
                print(f"    Last sync: {integration['last_sync_at']}")
        
        return response.json()


async def get_projects():
    """Get all projects to see if new ones were created."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/api/projects")
        response.raise_for_status()
        
        print("\n📁 Current Projects:")
        for project in response.json():
            print(f"  - {project['name']}")
            if project.get('description'):
                print(f"    Description: {project['description']}")
        
        return response.json()


async def test_mock_transcript():
    """Test with a mock transcript to simulate real meeting content."""
    mock_transcript = {
        "meetingId": "MOCK_PRODUCT_MEETING_001",
        "eventType": "Transcription completed"
    }
    
    print("\n🧪 Testing with mock product meeting transcript...")
    print("This will trigger the Fireflies API to fetch transcript data")
    print("The AI will analyze it and assign to the most relevant project")
    
    return await test_webhook_with_smart_matching(mock_transcript["meetingId"])


async def main():
    """Run the integration tests."""
    print("🚀 Fireflies Integration Test Suite")
    print("=" * 50)
    
    # Check if you want to connect the integration first
    connect = input("\nDo you want to connect/configure the Fireflies integration? (y/n): ")
    if connect.lower() == 'y':
        api_key = input("Enter your Fireflies API key: ")
        webhook_secret = input("Enter webhook secret (optional, press Enter to skip): ")
        await connect_fireflies_integration(
            api_key, 
            webhook_secret if webhook_secret else None
        )
    
    # Check integration status
    await check_integration_status()
    
    # Get current projects
    await get_projects()
    
    # Test webhook
    test = input("\nDo you want to test the webhook endpoint? (y/n): ")
    if test.lower() == 'y':
        meeting_id = input("Enter a Fireflies meeting ID (or press Enter for test ID): ")
        if not meeting_id:
            meeting_id = f"TEST_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        await test_webhook_with_smart_matching(meeting_id)
        
        # Wait a bit for processing
        print("\n⏳ Waiting for processing to complete...")
        await asyncio.sleep(5)
        
        # Check projects again to see if new one was created
        await get_projects()
    
    # Test with mock transcript
    mock_test = input("\nDo you want to test with a mock transcript? (y/n): ")
    if mock_test.lower() == 'y':
        await test_mock_transcript()
        
        # Wait and check results
        print("\n⏳ Waiting for processing to complete...")
        await asyncio.sleep(5)
        await get_projects()
    
    print("\n✅ Test suite completed!")


if __name__ == "__main__":
    asyncio.run(main())