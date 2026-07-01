#!/bin/bash
###############################################################################
# 🚀 Phi-3.5-Financial Infrastructure Deployment Script (Linux/macOS)
# Purpose: Deploy Ollama + Phi-3.5-Financial using Docker
# Requirements: Docker, Docker Compose, Bash 4+
###############################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
MODELFILE="${SCRIPT_DIR}/Modelfile"
INIT_SCRIPT="${SCRIPT_DIR}/init-model.sh"

API_URL="http://localhost:11434"
CONTAINER_NAME="phi-financial-ollama"
MODEL_NAME="phi-financial"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

###############################################################################
# Logging Functions
###############################################################################

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

###############################################################################
# Prerequisites Check
###############################################################################

check_prerequisites() {
    log_header "Checking Prerequisites"

    # Check Docker
    log_step "Checking Docker..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found. Install Docker first"
        log_info "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    DOCKER_VERSION=$(docker --version)
    log_info "Docker installed: $DOCKER_VERSION"

    # Check Docker Compose
    log_step "Checking Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose not found"
        log_info "Visit: https://docs.docker.com/compose/install/"
        exit 1
    fi
    COMPOSE_VERSION=$(docker-compose --version)
    log_info "Docker Compose installed: $COMPOSE_VERSION"

    # Check Docker daemon
    log_step "Checking Docker daemon..."
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker daemon not running"
        log_info "Start Docker and try again"
        exit 1
    fi
    log_info "Docker daemon is running"

    # Check required files
    log_step "Checking required files..."
    for file in "$COMPOSE_FILE" "$DOCKERFILE" "$MODELFILE" "$INIT_SCRIPT"; do
        if [ ! -f "$file" ]; then
            log_error "Required file not found: $file"
            exit 1
        fi
    done
    log_info "All required files present"

    log_info "All prerequisites met"
}

###############################################################################
# Helper Functions
###############################################################################

wait_for_api() {
    local max_retries=60
    local retry_delay=2
    local retries=0

    log_step "Waiting for API to be ready..."

    while [ $retries -lt $max_retries ]; do
        if curl -s "${API_URL}/api/tags" > /dev/null 2>&1; then
            log_info "API is ready"
            return 0
        fi

        if [ $((retries % 10)) -eq 0 ]; then
            echo -ne "${YELLOW}.(${retries}/${max_retries})${NC}"
        fi

        retries=$((retries + 1))
        sleep $retry_delay
    done

    log_error "API failed to start after $((max_retries * retry_delay)) seconds"
    return 1
}

###############################################################################
# Actions
###############################################################################

action_install() {
    log_header "Installing Phi-3.5-Financial Infrastructure"

    # Build image
    log_step "Building Docker image..."
    if ! docker-compose build --no-cache; then
        log_error "Docker build failed"
        exit 1
    fi
    log_info "Image built successfully"

    # Start container
    log_step "Starting containers..."
    if ! docker-compose up -d; then
        log_error "Failed to start containers"
        exit 1
    fi
    log_info "Containers started"

    # Wait for API
    if ! wait_for_api; then
        log_error "API startup failed"
        docker-compose logs ollama
        exit 1
    fi

    # Initialize model
    log_step "Initializing Phi-3.5-Financial model..."
    if docker-compose exec -T ollama /usr/local/bin/init-model.sh; then
        log_info "Model initialized successfully"
    else
        log_warn "Model initialization may have issues"
    fi

    display_summary
}

action_start() {
    log_header "Starting Containers"

    if docker-compose up -d; then
        log_info "Containers started"
        if wait_for_api; then
            log_info "API is ready"
        else
            exit 1
        fi
    else
        log_error "Failed to start containers"
        exit 1
    fi
}

action_stop() {
    log_header "Stopping Containers"

    if docker-compose stop; then
        log_info "Containers stopped"
    else
        log_error "Failed to stop containers"
        exit 1
    fi
}

action_restart() {
    log_header "Restarting Containers"
    action_stop
    sleep 2
    action_start
}

action_status() {
    log_header "Service Status"

    log_step "Container Status:"
    docker-compose ps

    echo ""
    log_step "API Health:"
    if curl -s "${API_URL}/api/tags" > /dev/null 2>&1; then
        log_info "API is responding"
        curl -s "${API_URL}/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read model; do
            log_info "Model available: $model"
        done
    else
        log_error "API is not responding"
    fi
}

action_health_check() {
    log_header "Health Check"

    log_step "Checking server connectivity..."
    if curl -s "${API_URL}/api/tags" > /dev/null 2>&1; then
        log_info "Server is responding"
    else
        log_error "Server is not responding at ${API_URL}"
        exit 1
    fi

    log_step "Checking model availability..."
    if curl -s "${API_URL}/api/tags" | grep -q "${MODEL_NAME}"; then
        log_info "Model '${MODEL_NAME}' is available"
    else
        log_warn "Model '${MODEL_NAME}' not found"
    fi

    echo ""
    log_info "✓ Health check complete"
}

action_test() {
    log_header "Testing API"

    log_step "Sending test prompt..."

    RESPONSE=$(curl -s -X POST "${API_URL}/api/generate" \
        -H "Content-Type: application/json" \
        --max-time 60 \
        -d '{
            "model": "'${MODEL_NAME}'",
            "prompt": "What is finance?",
            "stream": false
        }' 2>/dev/null)

    if echo "$RESPONSE" | grep -q '"response"'; then
        log_info "API test successful"
        echo ""
        echo -e "${GREEN}Response:${NC}"
        echo "$RESPONSE" | grep -o '"response":"[^"]*' | cut -d'"' -f4 | head -c 200
        echo "..."
    else
        log_error "API test failed or timed out"
        exit 1
    fi
}

action_logs() {
    log_header "Container Logs"
    docker-compose logs -f ollama
}

action_clean() {
    log_header "Cleanup"

    log_warn "This will remove containers and data"
    read -p "Continue? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Removing containers and volumes..."
        docker-compose down -v
        log_info "Cleanup complete"
    else
        log_info "Cleanup cancelled"
    fi
}

display_summary() {
    log_header "✅ INSTALLATION COMPLETE"

    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════════╗${NC}
${GREEN}║         Phi-3.5-Financial Infrastructure Ready            ║${NC}
${GREEN}╚════════════════════════════════════════════════════════════╝${NC}

${BLUE}📊 Service Information:${NC}
  • Server:        Ollama (Docker)
  • Model:         ${MODEL_NAME}
  • API URL:       ${API_URL}
  • Health Check:  ${API_URL}/api/tags

${BLUE}📡 API Endpoints:${NC}
  • Generate:      POST ${API_URL}/api/generate
  • List Models:   GET  ${API_URL}/api/tags
  • Model Info:    POST ${API_URL}/api/show

${BLUE}🧪 Test Commands:${NC}
  # Health check
  curl ${API_URL}/api/tags

  # Generate response
  curl -X POST ${API_URL}/api/generate \\
    -H "Content-Type: application/json" \\
    -d '{
      "model": "${MODEL_NAME}",
      "prompt": "What is investment?",
      "stream": false
    }'

${BLUE}📝 Important Notes:${NC}
  ✓ Server runs on ${API_URL}
  ✓ Model: ${MODEL_NAME}
  ✓ Data persists in Docker volume
  ✓ Check logs: docker-compose logs -f

${BLUE}🚀 Next Steps:${NC}
  1. Keep container running
  2. DEV WEB team: Connect to ${API_URL}
  3. Share API endpoint with other teams
  4. Monitor with: docker-compose logs -f

${BLUE}📚 Documentation:${NC}
  See: README.md

EOF
}

###############################################################################
# Main Entry Point
###############################################################################

show_help() {
    cat << EOF

${BLUE}╔════════════════════════════════════════════════════════════╗${NC}
${BLUE}║  Phi-3.5-Financial Infrastructure - Docker Deployment     ║${NC}
${BLUE}╚════════════════════════════════════════════════════════════╝${NC}

Usage: $0 [COMMAND]

Commands:
  install        Install and start (default)
  start          Start containers
  stop           Stop containers
  restart        Restart containers
  status         Show service status
  health-check   Run health check
  test           Test API
  logs           Show container logs
  clean          Remove containers and data
  help           Show this help message

Examples:
  $0 install           # Full installation
  $0 health-check      # Verify service
  $0 test              # Test API
  $0 logs              # Show logs

EOF
}

main() {
    clear

    cat << 'EOF'

 ____  _     _     _ ___   __   ____  _   _   _   _   _   _   _   _
|  _ \| |   (_)   | |___) (  ) (  ___)|  | | | | | |_| | | | | |_| |
| |_)| |    | | | | |__     ||  |__  |  |_| |  \ /  | | | |_| | |   |
|  __/| |   | | | | |  ___) ||  __) |  \_/    \_/   |_| |__   | |   |
| |   | |___| |  \| | |____) (( (___  |          Financial| |_| |   |
|_|   |_____|_|_/\_| |_____ / \ ____|

═══════════════════════════════════════════════════════════════════════════
  🚀 Phi-3.5-Financial Infrastructure Deployment (Docker)
  TechCorp Industries Hackathon - Linux/macOS Edition
═══════════════════════════════════════════════════════════════════════════

EOF

    local action="${1:-install}"

    case $action in
        install) check_prerequisites; action_install ;;
        start) action_start ;;
        stop) action_stop ;;
        restart) action_restart ;;
        status) action_status ;;
        health-check) action_health_check ;;
        test) action_test ;;
        logs) action_logs ;;
        clean) action_clean ;;
        help|--help|-h) show_help ;;
        *)
            log_error "Unknown command: $action"
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"
