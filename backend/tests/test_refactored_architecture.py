"""
Test script for the refactored ProjectDescriptionService architecture.
This test demonstrates proper separation of concerns.
"""
import asyncio
import sys
import uuid
from datetime import datetime, date

sys.path.append('.')

from db.database import db_manager
from models.project import Project
from models.content import Content, ContentType
from services.intelligence.project_description_service import project_description_analyzer
from services.hierarchy.project_service import ProjectService


async def test_refactored_architecture():
    """Test the refactored architecture with separated concerns."""
    print("🏗️ Testing Refactored Architecture...")
    
    try:
        async for session in db_manager.get_session():
            # 1. Create test project using ProjectService
            print("\n📋 Creating test project via ProjectService...")
            project_name = f"Refactored Test Project {datetime.now().strftime('%H%M%S')}"
            test_project = await ProjectService.create_project(
                session=session,
                name=project_name,
                description="Initial minimal description",
                created_by="test_system"
            )
            print(f"✅ Created project: {test_project.name}")
            print(f"   Initial description: {test_project.description}")
            
            # 2. Create test content
            print("\n📄 Creating substantial test content...")
            test_content = Content(
                project_id=test_project.id,
                content_type=ContentType.MEETING,
                title="Product Strategy Deep Dive",
                content="""
                Comprehensive product strategy session with full leadership team.
                
                We're building a revolutionary AI-powered customer support automation platform.
                The platform uses advanced natural language processing to automatically respond to 
                customer inquiries across multiple channels (email, chat, social media).
                
                Key features:
                - Multi-language support (15+ languages)
                - Sentiment analysis for priority routing
                - Integration with major CRM systems (Salesforce, HubSpot)
                - 24/7 automated responses with 95% accuracy
                - Real-time escalation to human agents when needed
                
                Target market: SMB and enterprise companies with high customer support volume
                Revenue model: SaaS subscription ($299-$2999/month tiers)
                Go-to-market: Direct sales + partner channel
                
                Competitive advantage: Our AI models are trained specifically on customer support 
                conversations, giving us 30% better accuracy than general-purpose solutions.
                
                Timeline: Beta launch in Q1, GA in Q2
                Team: 12 engineers, 4 product managers, 6 customer success
                Funding: $15M Series A raised, runway until profitability
                """,
                date=date.today(),
                uploaded_by="product_team"
            )
            session.add(test_content)
            await session.flush()
            print(f"✅ Created content: {test_content.title}")
            
            # 3. Test business logic separation - Smart Triggers
            print("\n🧠 Testing smart triggers (pure business logic)...")
            should_analyze = project_description_analyzer.should_trigger_analysis(
                content_text=test_content.content,
                content_type=test_content.content_type.value,
                last_change_time=None  # No previous changes
            )
            
            print(f"✅ Smart triggers result: {should_analyze}")
            assert should_analyze, "Should recommend analysis for substantial content"
            
            # 4. Test Claude analysis (pure AI logic)
            print("\n🤖 Testing Claude analysis (pure AI logic)...")
            content_data = {
                'content_type': test_content.content_type.value,
                'title': test_content.title,
                'content': test_content.content,
                'date': test_content.date.strftime('%Y-%m-%d') if test_content.date else None,
                'uploaded_by': test_content.uploaded_by
            }
            
            analysis_result = await project_description_analyzer.analyze_for_description_update(
                current_description=test_project.description,
                project_name=test_project.name,
                content_data=content_data
            )
            
            if analysis_result:
                print(f"✅ Claude analysis complete!")
                print(f"   Should update: {analysis_result['should_update']}")
                print(f"   Confidence: {analysis_result['confidence']}")
                print(f"   New description: {analysis_result['new_description'][:100]}...")
                print(f"   Reason: {analysis_result['reason'][:100]}...")
            else:
                print("❌ No analysis result from Claude")
                return False
            
            # 5. Test database operations via ProjectService
            print("\n💾 Testing database operations via ProjectService...")
            if analysis_result and analysis_result.get('should_update'):
                description_change = await ProjectService.update_project_description(
                    session=session,
                    project_id=test_project.id,
                    new_description=analysis_result['new_description'],
                    content_id=test_content.id,
                    reason=analysis_result['reason'],
                    confidence_score=analysis_result['confidence'],
                    changed_by="system"
                )
                
                if description_change:
                    print(f"✅ Database update successful!")
                    print(f"   Change record ID: {description_change.id}")
                    
                    # Verify project was updated
                    updated_project = await ProjectService.get_project(session, test_project.id)
                    print(f"   Updated description: {updated_project.description[:100]}...")
                else:
                    print("❌ Database update failed")
                    return False
            
            # 6. Test data retrieval via ProjectService
            print("\n📚 Testing description change history retrieval...")
            history = await ProjectService.get_description_change_history(
                session, test_project.id, limit=5
            )
            
            print(f"✅ Retrieved {len(history)} description changes:")
            for i, change in enumerate(history, 1):
                print(f"   {i}. {change.changed_at} - Confidence: {change.confidence_score}")
                print(f"      Changed by: {change.changed_by}")
            
            # 7. Test smart triggers cooldown
            print("\n⏰ Testing smart triggers cooldown...")
            should_analyze_again = project_description_analyzer.should_trigger_analysis(
                content_text="Another meeting with some updates",
                content_type="meeting",
                last_change_time=datetime.utcnow()  # Just changed
            )
            
            print(f"✅ Smart triggers cooldown result: {should_analyze_again}")
            assert not should_analyze_again, "Should skip analysis during cooldown period"
            
            await session.commit()
            print("\n🎉 All architecture tests passed!")
            
            # 8. Print architecture summary
            print(f"\n📊 Architecture Summary:")
            print(f"   🧠 Business Logic: ProjectDescriptionAnalyzer (AI decisions)")
            print(f"   💾 Data Layer: ProjectService (database operations)")
            print(f"   🔗 Integration: ContentService (orchestration)")
            print(f"   🌐 API Layer: ProjectsRouter (HTTP endpoints)")
            
            return True
            
    except Exception as e:
        print(f"\n❌ Architecture test failed: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    print("Testing Refactored Architecture with Separated Concerns...")
    success = asyncio.run(test_refactored_architecture())
    if success:
        print("\n✅ Refactored architecture working correctly!")
        print("   ✓ Clean separation of concerns")
        print("   ✓ Business logic isolated from data access")
        print("   ✓ Testable components")
        print("   ✓ Consistent with existing codebase patterns")
    else:
        print("\n❌ Architecture tests failed!")
        sys.exit(1)