#!/bin/bash
# OpenTelemetry Installation Script (2025 Best Practices)
# Follows official distro approach for TellMeMo backend

set -e  # Exit on error

echo "🚀 Installing OpenTelemetry for TellMeMo Backend (2025 Distro Approach)"
echo "============================================================================"

# Activate virtual environment
if [ -d "venv" ]; then
    echo "✅ Activating virtual environment..."
    source venv/bin/activate
else
    echo "❌ Error: Virtual environment not found at ./venv"
    echo "   Please create venv first: python -m venv venv"
    exit 1
fi

# Step 1: Uninstall old OpenTelemetry packages (clean slate)
echo ""
echo "🧹 Step 1: Cleaning up old OpenTelemetry packages..."
pip uninstall -y \
    opentelemetry-api \
    opentelemetry-sdk \
    opentelemetry-exporter-otlp-proto-http \
    opentelemetry-instrumentation-fastapi \
    opentelemetry-instrumentation-sqlalchemy \
    opentelemetry-instrumentation-redis \
    opentelemetry-instrumentation-httpx \
    opentelemetry-instrumentation-aiohttp-client \
    opentelemetry-instrumentation \
    opentelemetry-instrumentation-asgi \
    opentelemetry-util-http \
    opentelemetry-semantic-conventions \
    opentelemetry-proto \
    opentelemetry-exporter-otlp-proto-common \
    2>/dev/null || true  # Ignore errors if packages don't exist

echo "✅ Old packages removed"

# Step 2: Install core distro and exporter
echo ""
echo "📦 Step 2: Installing OpenTelemetry distro (includes API, SDK, bootstrap tool)..."
pip install --upgrade 'opentelemetry-distro>=0.59b0' 'opentelemetry-exporter-otlp>=1.38.0'

echo "✅ Distro installed successfully"

# Step 3: Run bootstrap to auto-detect and install instrumentations
echo ""
echo "🔍 Step 3: Auto-detecting installed packages and installing instrumentations..."
echo "   This will install instrumentations for: FastAPI, SQLAlchemy, Redis, httpx, aiohttp"
opentelemetry-bootstrap -a install

echo "✅ Auto-instrumentation packages installed"

# Step 4: Install specialized instrumentations
echo ""
echo "🎯 Step 4: Installing specialized instrumentations (asyncpg, Qdrant)..."
pip install --upgrade \
    'opentelemetry-instrumentation-asyncpg>=0.59b0' \
    'opentelemetry-instrumentation-qdrant>=0.17.0'

echo "✅ Specialized instrumentations installed"

# Step 5: Verify installation
echo ""
echo "✅ Step 5: Verifying installation..."
echo ""
pip list | grep opentelemetry | sort

echo ""
echo "============================================================================"
echo "🎉 OpenTelemetry installation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Configure Grafana Cloud credentials in .env:"
echo "   OTEL_ENABLED=true"
echo "   OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp-gateway-prod-us-central-0.grafana.net/otlp"
echo "   OTEL_EXPORTER_OTLP_HEADERS=Authorization=Basic YOUR_BASE64_TOKEN"
echo ""
echo "2. Start your backend:"
echo "   python main.py"
echo ""
echo "3. Check Grafana Cloud for traces and metrics"
echo "============================================================================"
