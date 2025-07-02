#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Elasticsearch + E5 Setup Verification ===${NC}"
echo -e "${YELLOW}Note: If services are starting up, wait 5-10 minutes for complete initialization${NC}"
echo -e "${YELLOW}      - Elasticsearch: ~2-3 minutes${NC}"
echo -e "${YELLOW}      - E5 Model Setup: ~3-5 minutes (downloads model)${NC}"
echo -e "${YELLOW}      - Kibana: ~2-3 minutes${NC}"
echo -e "${YELLOW}      - FSCrawler: ~1-2 minutes${NC}"
echo

# Function to check if service is responding
check_service() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "Checking $name... "
    response=$(curl -s -k -u elastic:changeme "$url" 2>/dev/null)
    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Function to run semantic search test
test_semantic_search() {
    echo -n "Testing semantic search... "
    response=$(curl -s -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search" \
        -H "Content-Type: application/json" \
        -d '{
            "query": {
                "semantic": {
                    "field": "content_semantic",
                    "query": "medical diagnosis and treatment"
                }
            },
            "size": 1
        }' 2>/dev/null)
    
    if echo "$response" | grep -q '"hits"' && echo "$response" | grep -q '"total"'; then
        echo -e "${GREEN}✓ OK${NC}"
        hits=$(echo "$response" | grep -o '"value":[0-9]*' | head -1 | cut -d':' -f2)
        echo -e "  Found $hits documents"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Check Elasticsearch (usually ready first)
check_service "Elasticsearch" "https://localhost:9200" "You Know, for Search"

# Check Kibana (takes 2-3 minutes to start)
echo -n "Checking Kibana... "
kibana_response=$(curl -s -I http://localhost:5601 2>/dev/null)
if echo "$kibana_response" | grep -q "HTTP/1.1 302"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC} (may need more time to start)"
fi

# Check FSCrawler (takes 1-2 minutes to start)
echo -n "Checking FSCrawler... "
fscrawler_response=$(curl -s -I http://localhost:8080 2>/dev/null)
if echo "$fscrawler_response" | grep -q "HTTP/1.1 200"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC} (may need more time to start)"
fi

# Check ML Info
echo -n "Checking ML capabilities... "
ml_response=$(curl -s -k -u elastic:changeme "https://localhost:9200/_ml/info" 2>/dev/null)
if echo "$ml_response" | grep -q "total_ml_memory"; then
    echo -e "${GREEN}✓ OK${NC}"
    memory=$(echo "$ml_response" | grep -o '"total_ml_memory":"[^"]*"' | cut -d'"' -f4)
    echo -e "  ML Memory: $memory"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Check E5 Inference Endpoint (created by e5-setup service, takes 3-5 minutes)
echo -n "Checking E5 inference endpoint... "
e5_response=$(curl -s -k -u elastic:changeme "https://localhost:9200/_inference/my-e5-model" 2>/dev/null)
if echo "$e5_response" | grep -q "my-e5-model"; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC} (E5 setup may still be running - check: docker logs fscrawler-e5-setup-1)"
fi

# Check Semantic Documents Index
echo -n "Checking semantic documents index... "
index_response=$(curl -s -k -u elastic:changeme "https://localhost:9200/semantic_documents" 2>/dev/null)
if echo "$index_response" | grep -q "semantic_documents"; then
    echo -e "${GREEN}✓ OK${NC}"
    
    # Count documents
    count_response=$(curl -s -k -u elastic:changeme "https://localhost:9200/semantic_documents/_count" 2>/dev/null)
    count=$(echo "$count_response" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo -e "  Documents indexed: $count"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

echo
echo -e "${YELLOW}=== Testing Search Functionality ===${NC}"

# Test traditional search
echo -n "Testing keyword search... "
keyword_response=$(curl -s -k -u elastic:changeme "https://localhost:9200/semantic_documents/_search?q=machine+learning" 2>/dev/null)
if echo "$keyword_response" | grep -q '"hits"'; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

# Test semantic search (requires embeddings to be processed - may take 1-2 minutes after indexing)
test_semantic_search

echo
echo -e "${YELLOW}=== Example Search Queries ===${NC}"
echo
echo -e "${BLUE}Semantic Search Examples:${NC}"
echo "curl -k -u elastic:changeme -X POST \"https://localhost:9200/semantic_documents/_search?pretty\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{"
echo "    \"query\": {"
echo "      \"semantic\": {"
echo "        \"field\": \"content_semantic\","
echo "        \"query\": \"medical diagnosis and treatment\""
echo "      }"
echo "    }"
echo "  }'"
echo
echo -e "${BLUE}Keyword Search Examples:${NC}"
echo "curl -k -u elastic:changeme \"https://localhost:9200/semantic_documents/_search?q=machine+learning&pretty\""
echo
echo -e "${BLUE}Access URLs:${NC}"
echo "• Elasticsearch: https://localhost:9200 (elastic:changeme)"
echo "• Kibana: http://localhost:5601 (elastic:changeme)"
echo "• FSCrawler: http://localhost:8080"
echo
echo -e "${GREEN}Setup verification completed!${NC}"