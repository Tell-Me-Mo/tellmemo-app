#!/usr/bin/env python3
"""
Find Grafana Cloud instance URL from the API token.
"""
import base64
import json
import requests

# Decode the OTLP header
OTLP_HEADER = "Authorization=Basic MTQyMzQ3NTpnbGNfZXlKdklqb2lNVFUzTmpZME5DSXNJbTRpT2lKaGNIQWlMQ0pySWpvaVZYTk1lSFpNZDBwaGNFOUxObEEyY3pRME1EYzNOelF3SWl3aWJTSTZleUp5SWpvaWNISnZaQzFsZFMxM1pYTjBMVElpZlgwPQ=="
encoded_creds = OTLP_HEADER.split("Basic ")[1]
decoded = base64.b64decode(encoded_creds).decode('utf-8')
instance_id, api_token = decoded.split(":", 1)

print(f"🔐 Grafana Cloud Credentials:")
print(f"   Instance ID: {instance_id}")
print(f"   API Token: {api_token[:30]}...")
print()

# Decode the JWT-like token to get organization info
token_payload = api_token.replace("glc_", "")
try:
    # Add padding if needed
    padding = len(token_payload) % 4
    if padding:
        token_payload += '=' * (4 - padding)

    token_data = json.loads(base64.b64decode(token_payload))
    print(f"📋 Token Information:")
    print(f"   Org ID: {token_data.get('o', 'unknown')}")
    print(f"   Name: {token_data.get('n', 'unknown')}")
    print(f"   Key: {token_data.get('k', 'unknown')[:20]}...")
    print(f"   Region: {token_data.get('m', {}).get('r', 'unknown')}")
    print()

    # For Grafana Cloud, the URL structure is typically:
    # https://<org-slug>.grafana.net
    # Or for OTLP metrics: https://prometheus-prod-<region>.grafana.net

    region = token_data.get('m', {}).get('r', 'prod-eu-west-2')

    # Try to construct possible URLs
    possible_urls = [
        f"https://tellmemoapp.grafana.net",  # Custom slug
        f"https://tellmemo.grafana.net",
        f"https://app.grafana.net",
        f"https://prometheus-{region}.grafana.net",
    ]

    print(f"🔍 Testing possible Grafana Cloud URLs...")
    print()

    for url in possible_urls:
        try:
            # Test API endpoint
            response = requests.get(
                f"{url}/api/health",
                headers={"Authorization": f"Bearer {api_token}"},
                timeout=5
            )

            if response.status_code in [200, 401, 403]:
                # 200 = Success, 401/403 = Wrong auth but endpoint exists
                print(f"   ✅ Found: {url}")
                print(f"      Status: {response.status_code}")

                if response.status_code == 200:
                    print(f"      ✨ This is your Grafana instance!")
                    print(f"\n🎯 Use this URL in create_grafana_dashboards.py:")
                    print(f"   GRAFANA_URL = \"{url}\"")
                    break
                elif response.status_code == 401:
                    print(f"      ⚠️  Endpoint exists but authentication may need adjustment")
            else:
                print(f"   ❌ Not found: {url} ({response.status_code})")
        except Exception as e:
            print(f"   ❌ Error testing {url}: {str(e)[:50]}...")

    print(f"\n📝 Note: You may need to check your Grafana Cloud account to find the exact URL")
    print(f"   1. Go to https://grafana.com/")
    print(f"   2. Login to your account")
    print(f"   3. The URL in your browser will be your Grafana instance URL")
    print(f"   4. It typically looks like: https://yourorg.grafana.net")

except Exception as e:
    print(f"❌ Error decoding token: {e}")
    print(f"\n💡 Please provide your Grafana Cloud instance URL manually")
    print(f"   You can find it by logging into https://grafana.com/")
