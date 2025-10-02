"""Portfolio-specific prompts for RAG queries and summary generation."""

from typing import List, Dict, Any


def get_portfolio_query_prompt(
    query: str,
    portfolio_name: str,
    portfolio_context: Dict[str, Any],
    aggregated_chunks: List[Dict[str, Any]]
) -> str:
    """
    Generate a prompt for portfolio-level RAG queries.

    Args:
        query: The user's question
        portfolio_name: Name of the portfolio
        portfolio_context: Context about the portfolio (programs, projects, health status)
        aggregated_chunks: Retrieved chunks from all projects

    Returns:
        Formatted prompt for Claude
    """
    # Format the context chunks
    chunks_text = ""
    projects_covered = set()

    for chunk in aggregated_chunks:
        project_name = chunk.get("project_name", "Unknown Project")
        projects_covered.add(project_name)
        chunks_text += f"\n[Project: {project_name}]\n{chunk.get('content', '')}\n"

    prompt = f"""You are analyzing information from a portfolio called "{portfolio_name}" which contains multiple projects and programs.

## Portfolio Context:
- Total Programs: {portfolio_context.get('program_count', 0)}
- Total Projects: {portfolio_context.get('project_count', 0)}
- Portfolio Health: {portfolio_context.get('health_status', 'Not Set')}
- Portfolio Owner: {portfolio_context.get('owner', 'Not Assigned')}

## Projects Analyzed:
{', '.join(sorted(projects_covered))}

## Retrieved Information from Portfolio Projects:
{chunks_text}

## User Question:
{query}

## Instructions:
1. Answer the question using information from ALL relevant projects in the portfolio
2. When information comes from specific projects, mention which project it's from
3. Identify patterns, trends, or commonalities across multiple projects
4. Highlight any contradictions or differences between projects
5. If the question asks about the portfolio as a whole, synthesize information across all projects
6. Be specific and cite project sources when making claims
7. If information is incomplete, mention which projects might have missing data

Provide a comprehensive answer that addresses the portfolio-level perspective:"""

    return prompt


def get_portfolio_summary_prompt(
    portfolio_name: str,
    portfolio_info: Dict[str, Any],
    programs: List[Dict[str, Any]],
    project_summaries: List[Dict[str, Any]],
    recent_activities: List[Dict[str, Any]],
    period: str
) -> str:
    """
    Generate a prompt for portfolio-level summary generation.

    Args:
        portfolio_name: Name of the portfolio
        portfolio_info: Portfolio metadata (owner, health, risks)
        programs: List of programs in the portfolio
        project_summaries: Recent summaries from all projects
        recent_activities: Recent activities across projects
        period: Time period for summary (weekly, monthly, quarterly)

    Returns:
        Formatted prompt for Claude
    """
    # Format program information
    programs_text = ""
    if programs:
        programs_text = "\n## Programs in Portfolio:\n"
        for prog in programs:
            programs_text += f"- {prog['name']}: {prog.get('project_count', 0)} projects\n"

    # Format project summaries
    summaries_text = ""
    if project_summaries:
        summaries_text = "\n## Recent Project Summaries:\n"
        by_project = {}
        for summary in project_summaries:
            proj = summary.get('project_name', 'Unknown')
            if proj not in by_project:
                by_project[proj] = []
            by_project[proj].append(summary)

        for proj, sums in by_project.items():
            summaries_text += f"\n### {proj}:\n"
            for s in sums[:2]:  # Limit to 2 summaries per project
                if s.get('key_points'):
                    summaries_text += "Key Points:\n"
                    for point in s['key_points'][:3]:
                        summaries_text += f"- {point}\n"

    # Format recent activities
    activities_text = ""
    if recent_activities:
        activities_text = "\n## Recent Portfolio Activity:\n"
        for activity in recent_activities[:10]:
            activities_text += f"- [{activity.get('project_name')}] {activity.get('description', '')}\n"

    prompt = f"""You are generating an executive {period} summary for the portfolio "{portfolio_name}".

## Portfolio Overview:
- Owner: {portfolio_info.get('owner', 'Not Assigned')}
- Health Status: {portfolio_info.get('health_status', 'Not Set')}
- Risk Summary: {portfolio_info.get('risk_summary', 'No risks identified')}
- Total Programs: {len(programs)}
- Total Projects: {portfolio_info.get('project_count', 0)}

{programs_text}
{summaries_text}
{activities_text}

## Task:
Generate a comprehensive {period} portfolio summary that:

1. **Executive Summary** (2-3 sentences)
   - Overall portfolio health and progress
   - Most critical items requiring attention

2. **Key Achievements**
   - Major milestones completed across all projects
   - Successful deliverables or outcomes
   - Progress on strategic objectives

3. **Cross-Project Insights**
   - Common themes or patterns across projects
   - Synergies or dependencies identified
   - Resource optimization opportunities

4. **Risk Assessment**
   - Critical risks affecting multiple projects
   - Emerging risks to monitor
   - Mitigation strategies in progress

5. **Recommendations**
   - Priority actions for portfolio owner
   - Resource reallocation suggestions
   - Strategic adjustments needed

6. **Upcoming Milestones**
   - Key deliverables in the next period
   - Critical dependencies to watch

Format the summary in clear sections with bullet points. Focus on actionable insights that help portfolio-level decision making. Highlight any issues that require escalation.

Generate the portfolio summary:"""

    return prompt


def get_portfolio_risk_analysis_prompt(
    portfolio_name: str,
    risk_data: List[Dict[str, Any]],
    project_risks: Dict[str, List[str]]
) -> str:
    """
    Generate a prompt for portfolio-level risk analysis.

    Args:
        portfolio_name: Name of the portfolio
        risk_data: Aggregated risk information
        project_risks: Risks by project

    Returns:
        Formatted prompt for Claude
    """
    risks_text = ""
    for project, risks in project_risks.items():
        if risks:
            risks_text += f"\n{project}:\n"
            for risk in risks:
                risks_text += f"- {risk}\n"

    prompt = f"""Analyze risks across the portfolio "{portfolio_name}" and provide strategic risk management recommendations.

## Identified Risks by Project:
{risks_text}

## Task:
Provide a portfolio-level risk analysis that includes:

1. **Risk Categorization**
   - Group similar risks across projects
   - Identify systemic vs. project-specific risks
   - Assess risk interconnections

2. **Impact Assessment**
   - Portfolio-level impact if risks materialize
   - Projects most at risk
   - Potential cascade effects

3. **Mitigation Strategies**
   - Portfolio-wide mitigation approaches
   - Resource allocation for risk management
   - Preventive measures to implement

4. **Risk Prioritization**
   - Critical risks requiring immediate attention
   - Medium-term risks to monitor
   - Low-priority risks to track

Provide actionable recommendations for the portfolio owner:"""

    return prompt


def get_portfolio_resource_optimization_prompt(
    portfolio_name: str,
    resource_data: Dict[str, Any],
    project_statuses: List[Dict[str, Any]]
) -> str:
    """
    Generate a prompt for portfolio resource optimization analysis.

    Args:
        portfolio_name: Name of the portfolio
        resource_data: Resource allocation information
        project_statuses: Status of all projects

    Returns:
        Formatted prompt for Claude
    """
    status_text = ""
    for proj in project_statuses:
        status_text += f"- {proj['name']}: {proj['status']} (Team size: {proj.get('team_size', 'Unknown')})\n"

    prompt = f"""Analyze resource allocation across the portfolio "{portfolio_name}" and provide optimization recommendations.

## Current Project Status:
{status_text}

## Resource Allocation Context:
- Total team members: {resource_data.get('total_members', 'Unknown')}
- Projects with resource constraints: {resource_data.get('constrained_projects', [])}
- Underutilized resources: {resource_data.get('underutilized', [])}

## Task:
Provide resource optimization recommendations:

1. **Current State Analysis**
   - Resource distribution effectiveness
   - Bottlenecks and constraints
   - Underutilized capacity

2. **Optimization Opportunities**
   - Resource reallocation suggestions
   - Skill sharing between projects
   - Efficiency improvements

3. **Recommendations**
   - Immediate actions to improve allocation
   - Long-term capacity planning
   - Cross-project collaboration opportunities

Focus on practical, implementable suggestions:"""

    return prompt