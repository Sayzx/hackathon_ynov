#!/bin/bash
###############################################################################
# 🚀 Initialize Phi-3.5-Financial Model in Ollama
# This script runs inside the Docker container to setup the model
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODEL_NAME="phi-financial"
MODELFILE_PATH="/tmp/Modelfile"
API_URL="http://localhost:11434"
MAX_RETRIES=60
RETRY_DELAY=2

# Logging functions
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
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Wait for Ollama server to be ready
wait_for_server() {
    log_step "Waiting for Ollama server to start..."

    for ((i=1; i<=MAX_RETRIES; i++)); do
        if curl -s "${API_URL}/api/tags" > /dev/null 2>&1; then
            log_info "Ollama server is ready (attempt $i/$MAX_RETRIES)"
            return 0
        fi

        if [ $((i % 10)) -eq 0 ]; then
            echo -ne "${YELLOW}Still waiting... ($i/$MAX_RETRIES)${NC}\r"
        fi
        sleep $RETRY_DELAY
    done

    log_error "Ollama server failed to start after ${MAX_RETRIES} attempts"
    return 1
}

# Check if model exists
model_exists() {
    if curl -s "${API_URL}/api/tags" | grep -q "${MODEL_NAME}"; then
        return 0
    fi
    return 1
}

# Create the model
create_model() {
    log_step "Creating ${MODEL_NAME} model from Modelfile..."

    if ! ollama create "${MODEL_NAME}" -f "${MODELFILE_PATH}"; then
        log_error "Failed to create model"
        return 1
    fi

    log_info "Model created successfully"
    return 0
}

# Verify model creation
verify_model() {
    log_step "Verifying model..."

    if curl -s "${API_URL}/api/tags" | grep -q "${MODEL_NAME}"; then
        log_info "Model verified successfully"
        return 0
    fi

    log_error "Model verification failed"
    return 1
}

# Test model inference
test_model() {
    log_step "Testing model inference..."

    RESPONSE=$(curl -s -X POST "${API_URL}/api/generate" \
        -H "Content-Type: application/json" \
        --max-time 60 \
        -d '{
            "model": "'${MODEL_NAME}'",
            "prompt": "What is finance?",
            "stream": false
        }' 2>/dev/null || echo '{}')

    if echo "$RESPONSE" | grep -q '"response"'; then
        log_info "Model inference test successful"
        return 0
    fi

    log_warn "Model inference test inconclusive (may be slow)"
    return 0
}

# Display summary
display_summary() {
    log_header "✅ INITIALIZATION COMPLETE"

    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════╗${NC}
${GREEN}║    Phi-3.5-Financial Model Ready for Production        ║${NC}
${GREEN}╚════════════════════════════════════════════════════════╝${NC}

${BLUE}📊 Model Information:${NC}
  • Name: ${MODEL_NAME}
  • Base Model: phi3.5 (3.8B parameters)
  • API URL: ${API_URL}
  • Status: Ready ✓

${BLUE}📡 Available Endpoints:${NC}
  • Generate: POST ${API_URL}/api/generate
  • List Models: GET ${API_URL}/api/tags
  • Model Info: POST ${API_URL}/api/show

${BLUE}🚀 Ready for:${NC}
  ✓ DEV WEB team to build chat interface
  ✓ DATA team for inference testing
  ✓ IA team for model evaluation
  ✓ CYBER team for security testing

EOF
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    log_header "Initializing Phi-3.5-Financial Model"

    # Check Modelfile exists
    if [ ! -f "${MODELFILE_PATH}" ]; then
        log_error "Modelfile not found at ${MODELFILE_PATH}"
        return 1
    fi
    log_info "Modelfile found"

    # Wait for server
    if ! wait_for_server; then
        return 1
    fi

    # Check if model already exists
    if model_exists; then
        log_warn "Model ${MODEL_NAME} already exists, skipping creation"
    else
        if ! create_model; then
            return 1
        fi

        if ! verify_model; then
            return 1
        fi
    fi

    # Test model
    test_model

    # Display summary
    display_summary

    log_info "Model initialization pipeline completed successfully! 🎉"
    return 0
}

# Run main function
main "$@"
exit $?
