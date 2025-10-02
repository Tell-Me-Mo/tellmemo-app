#!/usr/bin/env python3
"""Test script to generate activity data for testing the Recent Activity feature."""

import asyncio
import aiohttp
import json
from datetime import datetime
from uuid import uuid4

BASE_URL = "http://localhost:8000/api"

async def test_activities():
    """Generate test activities by performing various actions."""
    async with aiohttp.ClientSession() as session:
        print("Testing Activity Tracking...")
        
        # 1. Get existing projects
        async with session.get(f"{BASE_URL}/projects") as resp:
            projects = await resp.json()
            
            if not projects:
                print("No projects found. Create a project first.")
                return
            
            project = projects[0]
            project_id = project["id"]
            print(f"Using project: {project['name']} (ID: {project_id})")
        
        # 2. Update the project to generate an update activity
        print("\n2. Updating project...")
        update_data = {
            "description": f"Updated description at {datetime.now()}"
        }
        async with session.put(
            f"{BASE_URL}/projects/{project_id}",
            json=update_data
        ) as resp:
            if resp.status == 200:
                print("✓ Project updated successfully")
            else:
                print(f"✗ Failed to update project: {resp.status}")
        
        # 3. Upload content to generate upload activity
        print("\n3. Simulating content upload activity...")
        content_data = {
            "title": f"Test Meeting Notes {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            "content": "This is test content for demonstrating activity tracking.",
            "content_type": "meeting",
            "file_path": f"test_meeting_{uuid4().hex[:8]}.txt"
        }
        async with session.post(
            f"{BASE_URL}/projects/{project_id}/content",
            json=content_data
        ) as resp:
            if resp.status == 200:
                print("✓ Content uploaded successfully")
                content = await resp.json()
            else:
                print(f"✗ Failed to upload content: {resp.status}")
        
        # 4. Submit a query to generate query activity
        print("\n4. Submitting a test query...")
        query_data = {
            "query": "What were the key decisions made in recent meetings?",
            "use_rag": False
        }
        async with session.post(
            f"{BASE_URL}/projects/{project_id}/query",
            json=query_data
        ) as resp:
            if resp.status == 200:
                print("✓ Query submitted successfully")
            else:
                print(f"✗ Failed to submit query: {resp.status}")
        
        # 5. Fetch activities to verify they were logged
        print("\n5. Fetching project activities...")
        async with session.get(f"{BASE_URL}/projects/{project_id}/activities") as resp:
            if resp.status == 200:
                activities = await resp.json()
                print(f"✓ Found {len(activities)} activities:")
                for activity in activities[:5]:  # Show first 5
                    print(f"  - [{activity['type']}] {activity['title']}: {activity['description']}")
            else:
                print(f"✗ Failed to fetch activities: {resp.status}")

if __name__ == "__main__":
    asyncio.run(test_activities())