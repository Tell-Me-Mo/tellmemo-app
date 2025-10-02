#!/usr/bin/env python3
"""Test script for content upload functionality."""

import asyncio
import httpx
import json
from datetime import date

# API base URL
BASE_URL = "http://localhost:8000/api"

# Sample meeting transcript
SAMPLE_MEETING = """
Meeting: Weekly Product Standup
Date: January 15, 2024
Attendees: John Doe (PM), Jane Smith (Dev Lead), Bob Johnson (Designer)

Agenda:
1. Sprint Progress Review
2. API Authentication Discussion
3. UI/UX Updates
4. Blockers and Next Steps

Discussion:

Sprint Progress:
John opened the meeting by reviewing the current sprint progress. The team has completed 60% of the planned stories, with the core features on track for the deadline. Jane mentioned that the backend infrastructure is stable and ready for integration testing.

API Authentication:
The team had an extensive discussion about API authentication methods. After evaluating several options including OAuth2, API keys, and JWT tokens, the team decided to implement JWT tokens for API authentication. This decision was based on better security, scalability, and the ability to include user claims in the token. Jane will lead the implementation, with a target completion date of January 22.

UI/UX Updates:
Bob presented the latest mockups for the dashboard redesign. The new design features improved data visualization, better mobile responsiveness, and adheres to the Material Design 3 guidelines. The team agreed that the new design significantly improves user experience.

Blockers:
- Waiting for design assets from the marketing team (expected by Jan 17)
- Need clarification on payment integration requirements from the product team
- Database migration scripts need review before deployment

Action Items:
1. Jane: Implement JWT authentication by Jan 22
2. Bob: Finalize dashboard designs and create design specs by Jan 18
3. John: Schedule meeting with payment team for requirements clarification
4. Team: Review database migration scripts by Jan 19

Next Steps:
- Continue with sprint development
- Daily standups at 9 AM
- Code review session on Thursday
- Sprint demo on Friday at 2 PM

Meeting adjourned at 10:45 AM.
"""

async def create_project():
    """Create a test project."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{BASE_URL}/projects",
            json={
                "name": "Q1 Product Launch",
                "description": "Mobile app v2.0 release planning and development",
                "members": [
                    {"name": "John Doe", "email": "john@example.com", "role": "PM"},
                    {"name": "Jane Smith", "email": "jane@example.com", "role": "Dev Lead"}
                ]
            }
        )
        if response.status_code == 200:
            project = response.json()
            print(f"✅ Created project: {project['name']} (ID: {project['id']})")
            return project['id']
        else:
            print(f"❌ Failed to create project: {response.text}")
            return None

async def upload_text_content(project_id: str):
    """Upload text content directly."""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{BASE_URL}/projects/{project_id}/upload/text",
            json={
                "content_type": "meeting",
                "title": "Weekly Product Standup - Jan 15",
                "content": SAMPLE_MEETING,
                "date": "2024-01-15"
            }
        )
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Uploaded content: {result['title']} (ID: {result['id']})")
            print(f"   Status: {result['status']}")
            print(f"   Message: {result['message']}")
            return result['id']
        else:
            print(f"❌ Failed to upload content: {response.text}")
            return None

async def upload_file(project_id: str):
    """Upload a file."""
    # Create a temporary file
    import tempfile
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        f.write(SAMPLE_MEETING)
        temp_file = f.name
    
    async with httpx.AsyncClient() as client:
        with open(temp_file, 'rb') as f:
            files = {'file': ('meeting_notes.txt', f, 'text/plain')}
            data = {
                'content_type': 'meeting',
                'title': 'Weekly Standup File Upload',
                'content_date': '2024-01-15'
            }
            
            response = await client.post(
                f"{BASE_URL}/projects/{project_id}/upload",
                files=files,
                data=data
            )
        
        # Clean up temp file
        import os
        os.unlink(temp_file)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Uploaded file: {result['title']} (ID: {result['id']})")
            print(f"   Status: {result['status']}")
            print(f"   Message: {result['message']}")
            return result['id']
        else:
            print(f"❌ Failed to upload file: {response.text}")
            return None

async def get_project_content(project_id: str):
    """Get all content for a project."""
    async with httpx.AsyncClient() as client:
        response = await client.get(f"{BASE_URL}/projects/{project_id}/content")
        if response.status_code == 200:
            content_list = response.json()
            print(f"\n📄 Project content ({len(content_list)} items):")
            for content in content_list:
                print(f"   - {content['title']}")
                print(f"     Type: {content['content_type']}, Chunks: {content['chunk_count']}")
                print(f"     Uploaded: {content['uploaded_at']}")
                if content['processed_at']:
                    print(f"     Processed: {content['processed_at']}")
                if content['processing_error']:
                    print(f"     ⚠️ Error: {content['processing_error']}")
        else:
            print(f"❌ Failed to get content: {response.text}")

async def main():
    """Run the test."""
    print("🚀 Testing Content Upload System\n")
    
    # Create a project
    project_id = await create_project()
    if not project_id:
        return
    
    print("\n📤 Testing text upload...")
    content_id = await upload_text_content(project_id)
    
    print("\n📤 Testing file upload...")
    file_id = await upload_file(project_id)
    
    # Wait a bit for processing
    print("\n⏳ Waiting for processing...")
    await asyncio.sleep(2)
    
    # Get all content
    await get_project_content(project_id)
    
    print("\n✅ Test completed!")

if __name__ == "__main__":
    asyncio.run(main())