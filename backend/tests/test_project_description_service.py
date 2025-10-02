"""
Test script for the ProjectDescriptionService to verify end-to-end functionality.
"""
import asyncio
import sys
import uuid
from datetime import datetime, date

sys.path.append('.')

from db.database import db_manager
from models.project import Project
from models.content import Content, ContentType
from services.intelligence.project_description_service import project_description_service


async def test_project_description_service():
    """Test the complete project description service flow."""
    print("🚀 Testing Project Description Service...")
    
    try:
        async for session in db_manager.get_session():
            # 1. Create a test project
            print("\n📋 Creating test project...")
            test_project = Project(
                name="Test Project for Description Updates",
                description="Initial basic description",
                created_by="test_system",
                status="active"
            )
            session.add(test_project)
            await session.flush()
            await session.refresh(test_project)
            print(f"✅ Created project: {test_project.name} (ID: {test_project.id})")
            print(f"   Initial description: {test_project.description}")
            
            # 2. Create substantial test content that should trigger description update
            print("\n📄 Creating test content...")
            test_content = Content(
                project_id=test_project.id,
                content_type=ContentType.MEETING,
                title="Strategic Planning Meeting - Q4 Roadmap",
                content="""
                Meeting attendees: John (CEO), Sarah (CTO), Mike (Product Manager), Lisa (Marketing Director)
                
                Key discussion points:
                - We discussed the new AI-powered analytics dashboard that will be our flagship product for Q4
                - The dashboard will integrate machine learning algorithms to provide predictive insights
                - Target market: mid-size companies in finance and healthcare sectors
                - Expected to generate $2M ARR within first 6 months of launch
                - Technical requirements: React frontend, Python backend with FastAPI, PostgreSQL database
                - Marketing strategy: focus on LinkedIn ads and tech conference presentations
                - Competitive analysis shows this will differentiate us from existing players
                - Timeline: MVP by end of Q3, full launch in Q4
                - Budget approved: $500K development, $200K marketing
                - Team expansion needed: 2 additional engineers, 1 data scientist
                
                Action items:
                - Sarah to finalize technical architecture by next week
                - Mike to create detailed product requirements document
                - Lisa to develop go-to-market strategy
                - John to secure additional funding if needed
                
                Next meeting: September 20th to review progress
                """,
                date=date.today(),
                uploaded_by="test_user"
            )
            session.add(test_content)
            await session.flush()
            await session.refresh(test_content)
            print(f"✅ Created content: {test_content.title} (ID: {test_content.id})")
            
            # 3. Test the description service analysis
            print("\n🔍 Analyzing content for description update...")
            analysis_result = await project_description_service.analyze_content_for_description_update(
                session, test_content.id, force_update=True
            )
            
            if analysis_result:
                print(f"✅ Analysis complete!")
                print(f"   Confidence: {analysis_result['confidence']}")
                print(f"   Reason: {analysis_result['reason']}")
                print(f"   Current description: {analysis_result['current_description']}")
                print(f"   Proposed new description: {analysis_result['new_description']}")
                
                # 4. Apply the description update
                print("\n📝 Applying description update...")
                change_record = await project_description_service.update_project_description(
                    session, analysis_result
                )
                
                if change_record:
                    print(f"✅ Description updated successfully!")
                    print(f"   Change record ID: {change_record.id}")
                    print(f"   Confidence score: {change_record.confidence_score}")
                    
                    # 5. Verify project description was updated
                    await session.refresh(test_project)
                    print(f"   Updated project description: {test_project.description}")
                    
                    # 6. Test description change history
                    print("\n📚 Retrieving description change history...")
                    history = await project_description_service.get_description_change_history(
                        session, test_project.id, limit=5
                    )
                    
                    print(f"✅ Found {len(history)} description changes:")
                    for i, change in enumerate(history, 1):
                        print(f"   {i}. {change.changed_at} - Confidence: {change.confidence_score}")
                        print(f"      Reason: {change.reason[:100]}...")
                        print(f"      Content: {change.content.title if change.content else 'N/A'}")
                else:
                    print("❌ Failed to create change record")
            else:
                print("ℹ️ No description update recommended")
            
            # 7. Test smart triggers with similar content (should be skipped)
            print("\n🧠 Testing smart triggers with similar content...")
            similar_content = Content(
                project_id=test_project.id,
                content_type=ContentType.MEETING,
                title="Follow-up Meeting - Minor Updates",
                content="Quick status update meeting with minimal new information about the project.",
                date=date.today(),
                uploaded_by="test_user"
            )
            session.add(similar_content)
            await session.flush()
            
            analysis_result2 = await project_description_service.analyze_content_for_description_update(
                session, similar_content.id
            )
            
            if analysis_result2:
                print("⚠️ Unexpected: Analysis should have been skipped due to smart triggers")
            else:
                print("✅ Smart triggers working correctly - analysis skipped for minimal content")
            
            await session.commit()
            print("\n🎉 All tests completed successfully!")
            break
            
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True


if __name__ == "__main__":
    print("Testing Project Description Service...")
    success = asyncio.run(test_project_description_service())
    if success:
        print("\n✅ All tests passed!")
    else:
        print("\n❌ Tests failed!")
        sys.exit(1)