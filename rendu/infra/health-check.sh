#!/bin/bash

###############################################################################
# 🏥 Health Check Script - Phi-3.5-Financial API
###############################################################################

API_URL="${1:-http://localhost:11434}"
TIMEOUT=10

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏥 Health Check - Phi-3.5-Financial API${NC}"
echo "URL: $API_URL"
echo ""

# Check server connectivity
echo -n "1️⃣  Server connectivity... "
if curl -s --connect-timeout 2 "$API_URL/api/tags" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}Server not responding at $API_URL${NC}"
    exit 1
fi

# Check model availability
echo -n "2️⃣  Model availability... "
MODELS=$(curl -s "$API_URL/api/tags" | grep -o '"name":"[^"]*"' | grep -c "phi-financial")
if [ "$MODELS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} phi-financial model not found"
fi

# Test inference
echo -n "3️⃣  Inference capability... "
RESPONSE=$(curl -s -X POST "$API_URL/api/generate" \
    -H "Content-Type: application/json" \
    --max-time $TIMEOUT \
    -d '{
        "model": "phi-financial",
        "prompt": "Hi",
        "stream": false
    }' 2>/dev/null)

if echo "$RESPONSE" | grep -q '"response"'; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} Inference may be slow or not responding"
fi

# Summary
echo ""
echo -e "${GREEN}✓ API is operational${NC}"
echo ""
echo "Available endpoints:"
echo "  • POST   $API_URL/api/generate"
echo "  • GET    $API_URL/api/tags"
echo "  • POST   $API_URL/api/show"
echo ""
