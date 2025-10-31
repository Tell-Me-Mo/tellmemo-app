#!/usr/bin/env python3
"""
Export Grafana dashboard JSON files for manual import.
These can be imported via Grafana UI: Dashboards → Import
"""
import json
import os
from create_grafana_dashboards import (
    create_dashboard_1_business_overview,
    create_dashboard_2_llm_costs,
    create_dashboard_3_organization_health,
    create_dashboard_4_churn_risk,
    create_dashboard_5_sla_performance,
    create_dashboard_6_content_quality,
    create_dashboard_7_time_to_value,
)

OUTPUT_DIR = "grafana_dashboards"

def export_dashboards():
    """Export all dashboards as JSON files."""
    dashboards = [
        ("1_business_overview.json", create_dashboard_1_business_overview),
        ("2_llm_cost_optimization.json", create_dashboard_2_llm_costs),
        ("3_organization_health.json", create_dashboard_3_organization_health),
        ("4_churn_risk_detection.json", create_dashboard_4_churn_risk),
        ("5_sla_performance.json", create_dashboard_5_sla_performance),
        ("6_content_quality.json", create_dashboard_6_content_quality),
        ("7_time_to_value.json", create_dashboard_7_time_to_value),
    ]

    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print(f"📊 Exporting {len(dashboards)} Grafana Dashboards to JSON...\n")

    for filename, dashboard_func in dashboards:
        try:
            dashboard_data = dashboard_func()
            filepath = os.path.join(OUTPUT_DIR, filename)

            with open(filepath, 'w') as f:
                json.dump(dashboard_data['dashboard'], f, indent=2)

            print(f"   ✅ {filename}")
            print(f"      Title: {dashboard_data['dashboard']['title']}")
            print(f"      Panels: {len(dashboard_data['dashboard']['panels'])}")
            print()

        except Exception as e:
            print(f"   ❌ {filename}: {e}\n")

    print(f"{'='*60}")
    print(f"✅ Dashboards exported to: {OUTPUT_DIR}/")
    print(f"{'='*60}\n")

    print(f"📖 HOW TO IMPORT:")
    print(f"   1. Go to https://tellmemo.grafana.net/")
    print(f"   2. Click 'Dashboards' → '+ Create' → 'Import'")
    print(f"   3. Upload each JSON file from {OUTPUT_DIR}/")
    print(f"   4. Select your Prometheus data source")
    print(f"   5. Click 'Import'")
    print(f"\n💡 Tip: Import all 7 dashboards for complete observability!")


if __name__ == "__main__":
    export_dashboards()
