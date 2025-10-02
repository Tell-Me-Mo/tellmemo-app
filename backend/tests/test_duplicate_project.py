#!/usr/bin/env python3
"""Test script to verify duplicate project name validation."""

import asyncio
import aiohttp
import json

BASE_URL = "http://localhost:8000/api/v1"

async def test_duplicate_project_validation():
    """Test that duplicate project names are properly rejected."""
    
    async with aiohttp.ClientSession() as session:
        # Test 1: Create a project
        print("Test 1: Creating initial project...")
        project_data = {
            "name": "Test Project Alpha",
            "description": "First test project",
            "members": [
                {
                    "name": "John Doe",
                    "email": "john@example.com",
                    "role": "admin"
                }
            ]
        }
        
        async with session.post(f"{BASE_URL}/projects", json=project_data) as resp:
            if resp.status == 200:
                project = await resp.json()
                project_id = project["id"]
                print(f"✓ Created project: {project['name']} (ID: {project_id})")
            else:
                error = await resp.text()
                print(f"✗ Failed to create initial project: {error}")
                return
        
        # Test 2: Try to create another project with the same name
        print("\nTest 2: Attempting to create duplicate project...")
        duplicate_data = {
            "name": "Test Project Alpha",  # Same name
            "description": "Duplicate test project"
        }
        
        async with session.post(f"{BASE_URL}/projects", json=duplicate_data) as resp:
            if resp.status == 409:
                error = await resp.json()
                print(f"✓ Duplicate creation properly rejected: {error['detail']}")
            else:
                print(f"✗ Unexpected status code: {resp.status}")
                if resp.status == 200:
                    print("  ERROR: Duplicate project was created!")
        
        # Test 3: Create a project with different name (should succeed)
        print("\nTest 3: Creating project with different name...")
        different_data = {
            "name": "Test Project Beta",
            "description": "Second test project"
        }
        
        async with session.post(f"{BASE_URL}/projects", json=different_data) as resp:
            if resp.status == 200:
                project2 = await resp.json()
                project2_id = project2["id"]
                print(f"✓ Created project: {project2['name']} (ID: {project2_id})")
            else:
                error = await resp.text()
                print(f"✗ Failed to create second project: {error}")
                return
        
        # Test 4: Try to rename project to existing name
        print("\nTest 4: Attempting to rename project to existing name...")
        update_data = {
            "name": "Test Project Alpha"  # Try to rename Beta to Alpha
        }
        
        async with session.put(f"{BASE_URL}/projects/{project2_id}", json=update_data) as resp:
            if resp.status == 409:
                error = await resp.json()
                print(f"✓ Rename to duplicate properly rejected: {error['detail']}")
            else:
                print(f"✗ Unexpected status code: {resp.status}")
                if resp.status == 200:
                    print("  ERROR: Project was renamed to duplicate name!")
        
        # Test 5: Rename to unique name (should succeed)
        print("\nTest 5: Renaming project to unique name...")
        update_data = {
            "name": "Test Project Gamma"
        }
        
        async with session.put(f"{BASE_URL}/projects/{project2_id}", json=update_data) as resp:
            if resp.status == 200:
                updated = await resp.json()
                print(f"✓ Successfully renamed project to: {updated['name']}")
            else:
                error = await resp.text()
                print(f"✗ Failed to rename project: {error}")
        
        # Test 6: Archive first project and try to create with same name
        print("\nTest 6: Archiving project and creating new one with same name...")
        
        # Archive the first project
        async with session.delete(f"{BASE_URL}/projects/{project_id}") as resp:
            if resp.status == 200:
                print(f"✓ Archived project: {project_id}")
            else:
                print(f"✗ Failed to archive project")
                return
        
        # Now try to create a new project with the archived project's name
        archived_name_data = {
            "name": "Test Project Alpha",  # Same as archived project
            "description": "New project with archived project's name"
        }
        
        async with session.post(f"{BASE_URL}/projects", json=archived_name_data) as resp:
            if resp.status == 200:
                new_project = await resp.json()
                print(f"✓ Successfully created project with archived project's name: {new_project['name']}")
            else:
                error = await resp.text()
                print(f"✗ Failed to create project with archived name: {error}")
        
        print("\n" + "="*50)
        print("All tests completed!")

if __name__ == "__main__":
    asyncio.run(test_duplicate_project_validation())