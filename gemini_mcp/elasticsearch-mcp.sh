#!/bin/bash

# Elasticsearch MCP Server using curl commands
# This script provides MCP tools for Elasticsearch search

# Default configuration
ES_HOST="${ES_HOST:-https://localhost:9200}"
ES_USER="${ES_USER:-elastic}"
ES_PASS="${ES_PASS:-changeme}"

case "$1" in
  "search")
    # Traditional search
    QUERY="$2"
    INDEX="${3:-idx}"
    SIZE="${4:-10}"
    
    curl -k -u "$ES_USER:$ES_PASS" \
      "$ES_HOST/$INDEX/_search?q=$QUERY&size=$SIZE&pretty"
    ;;
    
  "semantic_search")
    # Semantic search
    QUERY="$2"
    INDEX="${3:-semantic_documents}"
    SIZE="${4:-10}"
    
    curl -k -u "$ES_USER:$ES_PASS" \
      -X POST "$ES_HOST/$INDEX/_search?pretty" \
      -H "Content-Type: application/json" \
      -d "{
        \"query\": {
          \"semantic\": {
            \"field\": \"content_semantic\",
            \"query\": \"$QUERY\"
          }
        },
        \"size\": $SIZE
      }"
    ;;
    
  "count")
    # Document count
    INDEX="${2:-idx}"
    
    curl -k -u "$ES_USER:$ES_PASS" \
      "$ES_HOST/$INDEX/_count?pretty"
    ;;
    
  "indices")
    # List indices
    curl -k -u "$ES_USER:$ES_PASS" \
      "$ES_HOST/_cat/indices?v"
    ;;
    
  *)
    echo "Usage: $0 {search|semantic_search|count|indices} <query> [index] [size]"
    echo "Examples:"
    echo "  $0 search 'contract agreement'"
    echo "  $0 semantic_search 'legal documents'"
    echo "  $0 count idx"
    echo "  $0 indices"
    exit 1
    ;;
esac