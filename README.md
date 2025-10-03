# TellMeMo

**TellMeMo** is an AI-powered Meeting Intelligence platform that uses RAG (Retrieval Augmented Generation) to help teams extract insights from meeting transcripts, generate summaries, track action items, and detect risks automatically.

## ✨ Features

- 🎙️ **Meeting Intelligence** - Transform meeting transcripts into actionable insights
- 📝 **Auto Summaries** - Generate executive, technical, and stakeholder summaries
- ✅ **Action Item Tracking** - Automatically extract and track tasks from meetings
- ⚠️ **Risk Detection** - AI identifies risks and concerns mentioned in discussions
- 💬 **Context-Aware Chat** - Ask questions about your meetings with full context
- 🔍 **Semantic Search** - Find information across all your meeting content
- 📊 **Project Hierarchy** - Organize by Portfolio → Programs → Projects

## 🏗️ Architecture

- **Frontend**: Flutter Web (port 8100)
- **Backend**: FastAPI with built-in authentication (port 8000)
- **Databases**: PostgreSQL (metadata), Qdrant (vector search)
- **AI/LLM**: Claude 3.5 Haiku via Anthropic API
- **Embeddings**: Google EmbeddingGemma-300m (local)

## 🚀 Quick Start

### Prerequisites

- **Docker** ≥20.10
- **Docker Compose** ≥2.0

That's it! Everything else runs in containers.

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

**ANTHROPIC_API_KEY** (Required):
1. Visit [console.anthropic.com](https://console.anthropic.com/)
2. Sign up or log in
3. Go to API Keys section
4. Create a new key (starts with `sk-ant-api03-`)

**HF_TOKEN** (Required):
1. Visit [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
2. Sign up or log in
3. Create a new token with "Read" permission
4. Used for downloading embedding models

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

Full documentation is available at:
- **Online**: [tellmemo.io/documentation](https://tellmemo.io/documentation)
- **Local**: Open `docs/documentation.html` in a browser

### Key Documentation Sections

- **Installation** - Detailed setup instructions
- **Configuration** - All environment variables and options
- **User Guide** - How to use TellMeMo's features
- **Troubleshooting** - Common issues and solutions
- **API Reference** - Backend API documentation

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

TellMeMo is highly configurable via environment variables. The most common options:

```bash
# Required
ANTHROPIC_API_KEY=sk-ant-api03-xxx
HF_TOKEN=hf_xxx

# Authentication (optional, has defaults)
JWT_SECRET=your-secret-here

# Optional features
SENTRY_ENABLED=false
FLUTTER_FIREBASE_ANALYTICS_ENABLED=false
```

See `.env.example` for all available configuration options.

## 📚 Key Documents

- **[CLAUDE.md](CLAUDE.md)** - Instructions for Claude Code (AI assistant)
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[SECURITY.md](SECURITY.md)** - Security policy and reporting
- **[LICENSE](LICENSE)** - MIT License

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `flutter test` and `pytest`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check ports are not in use
lsof -i :5432  # PostgreSQL
lsof -i :6333  # Qdrant
lsof -i :8000  # Backend
lsof -i :8100  # Frontend

# Restart Docker
docker compose down
docker compose up -d
```

**Database connection errors:**
```bash
# Check PostgreSQL logs
docker compose logs postgres

# Restart database
docker compose restart postgres
```

For more help, see the [Troubleshooting section](docs/documentation.html#troubleshooting) in the documentation.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔒 Security

If you discover a security vulnerability, please see [SECURITY.md](SECURITY.md) for reporting instructions.

## 🌐 Links

- **Website**: [tellmemo.io](https://tellmemo.io)
- **Documentation**: [tellmemo.io/documentation](https://tellmemo.io/documentation)
- **Repository**: [github.com/Tell-Me-Mo/tellmemo-app](https://github.com/Tell-Me-Mo/tellmemo-app)
- **Issues**: [github.com/Tell-Me-Mo/tellmemo-app/issues](https://github.com/Tell-Me-Mo/tellmemo-app/issues)

---

Built with ❤️ using Flutter, FastAPI, and AI
