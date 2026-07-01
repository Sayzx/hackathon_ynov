#!/bin/bash

###############################################################################
# 🧪 Test Script - Phi-3.5-Financial API
###############################################################################

API_URL="${1:-http://localhost:11434}"
MODEL="${2:-phi-financial}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing Phi-3.5-Financial API${NC}"
echo "URL: $API_URL"
echo "Model: $MODEL"
echo ""

# Test 1: Simple prompt
echo -e "${YELLOW}Test 1: Simple prompt${NC}"
echo "Prompt: 'What is finance?'"
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/generate" \
    -H "Content-Type: application/json" \
    --max-time 120 \
    -d '{
        "model": "'$MODEL'",
        "prompt": "What is finance?",
        "stream": false,
        "temperature": 0.7,
        "top_p": 0.9,
        "top_k": 40
    }')

if echo "$RESPONSE" | grep -q '"response"'; then
    echo -e "${GREEN}✓ Response received:${NC}"
    echo "$RESPONSE" | grep -o '"response":"[^"]*' | cut -d'"' -f4
    echo ""
else
    echo -e "${YELLOW}⚠ No response or timeout${NC}"
fi

# Test 2: Business prompt
echo ""
echo -e "${YELLOW}Test 2: Business prompt${NC}"
echo "Prompt: 'Explain portfolio diversification'"
echo ""

RESPONSE=$(curl -s -X POST "$API_URL/api/generate" \
    -H "Content-Type: application/json" \
    --max-time 120 \
    -d '{
        "model": "'$MODEL'",
        "prompt": "Explain portfolio diversification",
        "stream": false,
        "temperature": 0.7,
        "max_tokens": 256
    }')

if echo "$RESPONSE" | grep -q '"response"'; then
    echo -e "${GREEN}✓ Response received:${NC}"
    echo "$RESPONSE" | grep -o '"response":"[^"]*' | cut -d'"' -f4 | head -c 200
    echo "..."
    echo ""
else
    echo -e "${YELLOW}⚠ No response or timeout${NC}"
fi

# Test 3: Model info
echo ""
echo -e "${YELLOW}Test 3: Model information${NC}"

curl -s -X POST "$API_URL/api/show" \
    -H "Content-Type: application/json" \
    -d '{"name": "'$MODEL'"}' | grep -E '"name"|"model"|"format"' | head -10

echo ""
echo -e "${GREEN}✓ Tests complete!${NC}"
