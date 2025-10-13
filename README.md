# TellMeMo

Turn project chaos into clarity. AI-powered platform that transforms meetings into searchable knowledge—upload content, ask questions, get instant answers.

## ✨ Features

- 🔍 **Ask questions** - Search in plain English, get answers with sources
- ✅ **Track actions** - AI extracts tasks automatically
- ⚠️ **Detect risks** - Spot problems before they become critical
- 📝 **Generate summaries** - Executive, technical, or stakeholder formats
- 📊 **Portfolio view** - Organize by Portfolio → Program → Project
- 🔓 **100% Open Source** - Self-host or use our cloud

## 🏗️ Tech Stack

- **Frontend**: Flutter Web
- **Backend**: FastAPI + PostgreSQL + Qdrant
- **AI**: Claude 3.5 (primary LLM) + OpenAI GPT (fallback), EmbeddingGemma (local embeddings)
- **Deploy**: Docker Compose (everything containerized)

## 🚀 Quick Start

### Prerequisites

- Docker ≥20.10
- Docker Compose ≥2.0

Everything else runs in containers.

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Tell-Me-Mo/tellmemo-app.git
cd tellmemo-app

# 2. Create .env file with your API keys
cat > .env << EOF
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
HF_TOKEN=your-huggingface-token-here
EOF

# 3. Start all services
docker compose up -d

# 4. Access the application
# Open http://localhost:8100 in your browser
```

### Getting API Keys

**ANTHROPIC_API_KEY** (Required): Get from [console.anthropic.com](https://console.anthropic.com/) → API Keys

**HF_TOKEN** (Required): Get from [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens) → Create token (Read permission)

**OPENAI_API_KEY** (Optional): Get from [platform.openai.com](https://platform.openai.com/api-keys) → For automatic fallback when Claude is overloaded

### Useful Commands

```bash
# View running containers
docker compose ps

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Restart services
docker compose restart

# Update to latest version
git pull
docker compose pull
docker compose up -d
```

## 📖 Documentation

- **Online**: [tellmemo.io/documentation](https://tellmemo.io/documentation)
- **Local**: Open `docs/documentation.html` in browser
- **API**: Full REST API reference included

## 🛠️ Development

For development and customization:

```bash
# Clone repository
git clone https://github.com/Tell-Me-Mo/tellmemo-app.git
cd tellmemo-app

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Start services
docker compose up -d

# For frontend development (Flutter)
cd frontend
flutter pub get
flutter run -d chrome --web-port 8100

# For backend development (Python)
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Project Structure

```
tellmemo-app/
├── frontend/          # Flutter web application
├── backend/           # FastAPI backend
├── docs/              # Documentation website
├── docker-compose.yml # Docker services configuration
├── .env.example       # Environment variables template
└── README.md          # This file
```

## 🔧 Configuration

Key environment variables:

```bash
# Required
ANTHROPIC_API_KEY=sk-ant-api03-xxx
HF_TOKEN=hf_xxx

# Optional (High Availability)
OPENAI_API_KEY=sk-proj-xxx           # Automatic fallback on Claude overload
ENABLE_LLM_FALLBACK=true             # Enable provider fallback (default: true)

# Optional (Other)
JWT_SECRET=your-secret-here
SENTRY_ENABLED=false
```

See `.env.example` for all options.

## 📚 More Info

- **[CLAUDE.md](CLAUDE.md)** - Claude Code instructions
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guide
- **[SECURITY.md](SECURITY.md)** - Security policy
- **[LICENSE](LICENSE)** - MIT License

## 🤝 Contributing

We follow the **Feature Branch Model**:

1. Fork the repo
2. Start from main: `git checkout main && git pull origin main`
3. Create feature branch: `git checkout -b feature/amazing-feature`
4. Make changes and run tests
5. Commit: `git commit -m 'feat: add amazing feature'`
6. Push and open a Pull Request to `main`

See [CONTRIBUTING.md](CONTRIBUTING.md) for full workflow and guidelines.

## 🐛 Troubleshooting

**Services won't start?**
```bash
docker compose down
docker compose up -d
```

**Check logs:**
```bash
docker compose logs -f
```

See [full troubleshooting guide](https://tellmemo.io/documentation#troubleshooting).

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🔒 Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) for reporting.

## 🌐 Links

- **Website**: [tellmemo.io](https://tellmemo.io)
- **Documentation**: [tellmemo.io/documentation](https://tellmemo.io/documentation)
- **Repository**: [github.com/Tell-Me-Mo/tellmemo-app](https://github.com/Tell-Me-Mo/tellmemo-app)
- **Issues**: [github.com/Tell-Me-Mo/tellmemo-app/issues](https://github.com/Tell-Me-Mo/tellmemo-app/issues)

---

Built with ❤️ using Flutter, FastAPI, and AI
