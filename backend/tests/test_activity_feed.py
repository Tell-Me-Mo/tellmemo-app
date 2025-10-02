"""Test script for activity feed functionality."""

import asyncio
import httpx
from uuid import uuid4
from datetime import datetime

BASE_URL = "http://localhost:8000"

async def test_activity_feed():
    """Test the complete activity feed functionality."""
    
    async with httpx.AsyncClient() as client:
        print("\n🧪 Testing Activity Feed Functionality\n")
        
        # 1. Create a test project
        print("1. Creating test project...")
        project_data = {
            "name": f"Activity Test Project {datetime.now().strftime('%H:%M:%S')}",
            "description": "Project for testing activity feed",
            "members": [
                {"name": "Test User", "email": "test@example.com", "role": "owner"}
            ]
        }
        
        response = await client.post(f"{BASE_URL}/api/projects", json=project_data)
        if response.status_code != 200:
            print(f"❌ Failed to create project: {response.status_code}")
            print(response.text)
            return
        
        project = response.json()
        project_id = project["id"]
        print(f"✅ Project created: {project_id}")
        
        # 2. Fetch activities for the project
        print("\n2. Fetching project activities...")
        response = await client.get(f"{BASE_URL}/api/projects/{project_id}/activities")
        
        if response.status_code != 200:
            print(f"❌ Failed to fetch activities: {response.status_code}")
            print(response.text)
            return
        
        activities = response.json()
        print(f"✅ Found {len(activities)} activities")
        
        # 3. Check if project creation activity was logged
        print("\n3. Checking for project creation activity...")
        creation_activity = None
        for activity in activities:
            if activity["type"] == "project_created":
                creation_activity = activity
                break
        
        if creation_activity:
            print(f"✅ Project creation activity found:")
            print(f"   - Title: {creation_activity['title']}")
            print(f"   - Description: {creation_activity['description']}")
            print(f"   - Timestamp: {creation_activity['timestamp']}")
        else:
            print("⚠️  No project creation activity found (might not be implemented yet)")
        
        # 4. Upload content to trigger more activities
        print("\n4. Uploading test content...")
        upload_data = {
            "content_type": "meeting",
            "title": "Test Meeting Transcript",
            "content": "This is a test meeting transcript for activity testing.",
            "date": datetime.now().isoformat()
        }
        
        response = await client.post(
            f"{BASE_URL}/api/projects/{project_id}/upload/text",
            json=upload_data
        )
        
        if response.status_code == 200:
            print("✅ Content uploaded successfully")
        else:
            print(f"⚠️  Content upload failed: {response.status_code}")
        
        # 5. Submit a query to generate more activity
        print("\n5. Submitting test query...")
        query_data = {
            "question": "What is this project about?"
        }
        
        response = await client.post(
            f"{BASE_URL}/api/projects/{project_id}/query",
            json=query_data
        )
        
        if response.status_code == 200:
            print("✅ Query submitted successfully")
        else:
            print(f"⚠️  Query submission failed: {response.status_code}")
        
        # 6. Fetch activities again to see updates
        print("\n6. Fetching updated activities...")
        await asyncio.sleep(1)  # Small delay to ensure activities are logged
        
        response = await client.get(f"{BASE_URL}/api/projects/{project_id}/activities")
        
        if response.status_code == 200:
            activities = response.json()
            print(f"✅ Found {len(activities)} total activities")
            
            # Display all activities
            print("\n📋 Activity Timeline:")
            for i, activity in enumerate(activities[:5], 1):  # Show first 5
                print(f"\n   {i}. {activity['title']}")
                print(f"      Type: {activity['type']}")
                print(f"      Description: {activity['description']}")
                print(f"      Time: {activity['timestamp']}")
        
        # 7. Test activity filtering
        print("\n7. Testing activity filtering...")
        response = await client.get(
            f"{BASE_URL}/api/projects/{project_id}/activities",
            params={"activity_type": "project_created"}
        )
        
        if response.status_code == 200:
            filtered = response.json()
            print(f"✅ Filtered activities (project_created): {len(filtered)} found")
        else:
            print(f"❌ Activity filtering failed: {response.status_code}")
        
        # 8. Test recent activities across projects
        print("\n8. Testing recent activities endpoint...")
        response = await client.get(
            f"{BASE_URL}/api/activities/recent",
            params={"project_ids": project_id, "hours": 24}
        )
        
        if response.status_code == 200:
            recent = response.json()
            print(f"✅ Recent activities (last 24h): {len(recent)} found")
        else:
            print(f"❌ Recent activities failed: {response.status_code}")
        
        # 9. Clean up - delete project
        print("\n9. Cleaning up test project...")
        response = await client.delete(f"{BASE_URL}/api/projects/{project_id}")
        
        if response.status_code in [200, 204]:
            print("✅ Test project deleted")
        else:
            print(f"⚠️  Failed to delete project: {response.status_code}")
        
        print("\n✅ Activity Feed Test Complete!")

if __name__ == "__main__":
    print("=" * 50)
    print("Activity Feed Integration Test")
    print("=" * 50)
    print("\nNote: Make sure the backend is running on http://localhost:8000")
    print("You can start it with: make backend")
    print()
    
    try:
        asyncio.run(test_activity_feed())
    except httpx.ConnectError:
        print("❌ Cannot connect to backend. Please start it with: make backend")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")