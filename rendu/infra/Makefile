.PHONY: help build up down logs ps shell test health-check clean restart stop init

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Show this help message
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  Phi-3.5-Financial Infrastructure - Docker Commands       ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

##@ Docker Operations

build: ## Build Docker image for phi-financial
	@echo "$(BLUE)[→] Building Docker image...$(NC)"
	docker-compose build --no-cache
	@echo "$(GREEN)[✓] Build complete$(NC)"

up: ## Start containers (includes model initialization)
	@echo "$(BLUE)[→] Starting Ollama container...$(NC)"
	docker-compose up -d
	@echo "$(BLUE)[→] Initializing model (this may take a few minutes)...$(NC)"
	@sleep 5
	docker-compose exec -T ollama /usr/local/bin/init-model.sh
	@echo "$(GREEN)[✓] Container started successfully$(NC)"

down: ## Stop and remove containers
	@echo "$(BLUE)[→] Stopping containers...$(NC)"
	docker-compose down
	@echo "$(GREEN)[✓] Containers stopped$(NC)"

stop: ## Stop containers without removing
	@echo "$(BLUE)[→] Stopping containers...$(NC)"
	docker-compose stop
	@echo "$(GREEN)[✓] Containers stopped$(NC)"

restart: stop up ## Restart containers

logs: ## View container logs (follow)
	docker-compose logs -f ollama

ps: ## Show running containers
	docker-compose ps

shell: ## Open shell in container
	docker-compose exec ollama /bin/bash

##@ Testing & Verification

health-check: ## Run health check on API
	@echo "$(BLUE)🏥 Health Check - Phi-3.5-Financial API$(NC)"
	@./health-check.sh

test: ## Test API with sample prompts
	@echo "$(BLUE)🧪 Testing Phi-3.5-Financial API$(NC)"
	@./test-api.sh

init: ## Initialize model in running container
	@echo "$(BLUE)[→] Initializing model...$(NC)"
	docker-compose exec -T ollama /usr/local/bin/init-model.sh
	@echo "$(GREEN)[✓] Model initialization complete$(NC)"

status: ## Show service status
	@echo "$(BLUE)📊 Service Status$(NC)"
	@echo ""
	@docker-compose ps
	@echo ""
	@echo "$(BLUE)API Health:$(NC)"
	@curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' || echo "$(RED)API not responding$(NC)"

##@ Maintenance

clean: ## Remove containers and volumes
	@echo "$(RED)[!] WARNING: This will remove containers and volumes$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "$(GREEN)[✓] Cleanup complete$(NC)"; \
	else \
		echo "$(BLUE)[→] Cleanup cancelled$(NC)"; \
	fi

prune-images: ## Remove unused Docker images
	@echo "$(BLUE)[→] Pruning images...$(NC)"
	docker image prune -f
	@echo "$(GREEN)[✓] Prune complete$(NC)"

##@ Development

logs-build: ## Show build logs
	docker-compose logs --tail=100 ollama

shell-root: ## Open shell as root in container
	docker-compose exec -u root ollama /bin/bash

inspect-volume: ## Inspect ollama data volume
	@echo "$(BLUE)📁 Volume Information:$(NC)"
	docker volume inspect infra_ollama_data

##@ Full Workflow

setup: clean build up health-check ## Complete setup: build + start + health check

reset: down clean build ## Complete reset: stop + clean + rebuild

all: setup status ## Setup and show status
