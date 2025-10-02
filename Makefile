# PM Master V2 - Development Commands
.PHONY: help up down restart logs clean setup dev backend frontend test docker-status init-db

# Default target
help:
	@echo "PM Master V2 - Development Commands"
	@echo "===================================="
	@echo ""
	@echo "Infrastructure Commands:"
	@echo "  make up              - Start all Docker services"
	@echo "  make down            - Stop all Docker services"
	@echo "  make restart         - Restart all Docker services"
	@echo "  make logs            - Show logs from all services"
	@echo "  make clean           - Stop services and remove volumes (CAUTION: deletes data)"
	@echo "  make docker-status   - Check status of Docker services"
	@echo ""
	@echo "Development Commands:"
	@echo "  make setup           - Initial setup (copy .env, start services)"
	@echo "  make dev             - Start development environment"
	@echo "  make backend         - Run FastAPI backend (requires services)"
	@echo "  make frontend        - Run Flutter web frontend"
	@echo "  make test            - Run all tests"
	@echo ""
	@echo "Database Commands:"
	@echo "  make init-db         - Initialize databases with schemas"
	@echo "  make psql            - Connect to PostgreSQL"
	@echo ""
	@echo "Service URLs (when running):"
	@echo "  FastAPI:     http://localhost:8000/docs"
	@echo "  Qdrant UI:   http://localhost:6333/dashboard"
	@echo "  Langfuse:    http://localhost:3000"
	@echo "  Flutter Web: http://localhost:8080"

# Setup environment
setup:
	@echo "Setting up PM Master V2 development environment..."
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "✅ .env file created. Please update with your API keys."; \
	else \
		echo "✅ .env file already exists"; \
	fi
	@echo "Starting Docker services..."
	@$(MAKE) up
	@echo ""
	@echo "✅ Setup complete!"
	@echo ""
	@echo "Service URLs:"
	@echo "  Qdrant Dashboard: http://localhost:6333/dashboard"
	@echo "  Langfuse:         http://localhost:3000"
	@echo ""
	@echo "Next steps:"
	@echo "1. Update .env with your Anthropic API key"
	@echo "2. Run 'make backend' to start the FastAPI server"
	@echo "3. Run 'make frontend' to start the Flutter web app"

# Docker compose commands
up:
	@echo "Starting Docker services..."
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@$(MAKE) docker-status

down:
	@echo "Stopping Docker services..."
	docker-compose down

restart:
	@echo "Restarting Docker services..."
	docker-compose restart

logs:
	docker-compose logs -f

clean:
	@echo "⚠️  WARNING: This will delete all data!"
	@echo "Press Ctrl+C within 5 seconds to cancel..."
	@sleep 5
	docker-compose down -v
	@echo "✅ All services stopped and volumes removed"

docker-status:
	@echo "Docker Services Status:"
	@echo "======================="
	@docker-compose ps
	@echo ""
	@echo "Health Check:"
	@docker ps --filter "name=pm_master" --format "table {{.Names}}\t{{.Status}}"

# Development commands
dev: up
	@echo "Development environment is ready!"
	@echo "Run 'make backend' in one terminal and 'make frontend' in another"

backend:
	@echo "Starting FastAPI backend..."
	@echo "API will be available at http://localhost:8000"
	@echo "API docs at http://localhost:8000/docs"
	cd backend && python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

frontend:
	@echo "Starting Flutter web frontend..."
	@echo "Web app will be available at http://localhost:8080"
	flutter run -d chrome --web-port 8080

test:
	@echo "Running backend tests..."
	cd backend && python -m pytest tests/ -v
	@echo ""
	@echo "Running Flutter tests..."
	flutter test

# Database utilities
psql:
	@echo "Connecting to PostgreSQL..."
	docker exec -it pm_master_postgres psql -U pm_master -d pm_master_db

init-db:
	@echo "Initializing database schemas..."
	@echo "Creating Langfuse database..."
	docker exec pm_master_postgres psql -U pm_master -c "CREATE DATABASE langfuse_db;" 2>/dev/null || true
	@echo "✅ Databases initialized"

# Quick access to services
qdrant-ui:
	@echo "Opening Qdrant Dashboard..."
	open http://localhost:6333/dashboard

langfuse-ui:
	@echo "Opening Langfuse..."
	open http://localhost:3000

api-docs:
	@echo "Opening FastAPI docs..."
	open http://localhost:8000/docs