.PHONY: dev stop backend frontend db test clean help

# Default target
help:
	@echo "ryanriegel.com Development Commands"
	@echo ""
	@echo "  make dev        - Start all services (DB + Rails + Astro)"
	@echo "  make stop       - Stop all running services"
	@echo "  make backend    - Start Rails server only (port 3000)"
	@echo "  make frontend   - Start Astro dev server only (port 4321)"
	@echo "  make db         - Start database only (port 5434)"
	@echo "  make test       - Run test suite"
	@echo "  make clean      - Stop services and remove containers"
	@echo ""

# Start all services
dev: db backend frontend
	@echo "All services started:"
	@echo "  Frontend: http://localhost:4321"
	@echo "  Backend:  http://localhost:3000"

# Stop all services
stop:
	@echo "Stopping ryanriegel.com services..."
	@-pkill -9 -f "rails server" 2>/dev/null || true
	@-pkill -9 -f "rails s" 2>/dev/null || true
	@-pkill -9 -f "puma" 2>/dev/null || true
	@-pkill -9 -f "astro dev" 2>/dev/null || true
	@-docker stop ryanriegel-com-db 2>/dev/null || true
	@echo "All services stopped"

# Start database
db:
	@echo "Starting database..."
	@docker start ryanriegel-com-db 2>/dev/null || echo "Container not found. Run setup first."
	@echo "Database ready on port 5434"

# Start Rails backend
backend:
	@echo "Starting Rails server..."
	@RAILS_ENV=development bundle exec rails server &
	@echo "Rails starting on port 3000..."
	@sleep 2

# Start Astro frontend
frontend:
	@echo "Starting Astro dev server..."
	@cd frontend && npm run dev &
	@echo "Astro starting on port 4321..."
	@sleep 2

# Run tests
test: db
	@echo "Running backend tests..."
	@bundle exec rspec
	@echo ""
	@echo "Running frontend tests..."
	@cd frontend && npm test

# Clean up everything
clean: stop
	@echo "Cleaning up containers..."
	@docker stop ryanriegel-com-db 2>/dev/null || true
	@docker rm ryanriegel-com-db 2>/dev/null || true

# Status check
status:
	@echo "Checking service status..."
	@echo ""
	@echo "Database:"
	@docker ps --filter name=ryanriegel-com-db --format "  {{.Status}}" 2>/dev/null || echo "  Not running (or Docker unavailable)"
	@echo ""
	@echo "Rails backend (port 3000):"
	@ss -tlnp 2>/dev/null | grep ':3000 ' || lsof -i :3000 2>/dev/null | grep LISTEN || echo "  Not running"
	@echo ""
	@echo "Astro frontend (port 4321):"
	@ss -tlnp 2>/dev/null | grep ':4321 ' || lsof -i :4321 2>/dev/null | grep LISTEN || echo "  Not running"
