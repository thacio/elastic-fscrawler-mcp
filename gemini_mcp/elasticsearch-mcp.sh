#!/bin/bash

# Elasticsearch MCP Server using curl commands
# This script provides MCP tools for Elasticsearch search

# Default configuration
ES_HOST="${ES_HOST:-https://localhost:9200}"
ES_USER="${ES_USER:-elastic}"
ES_PASS="${ES_PASS:-changeme}"

case "$1" in
  "search")
    # Traditional search with optional highlighting
    QUERY="$2"
    INDEX="${3:-semantic_documents}"
    SIZE="${4:-10}"
    HIGHLIGHT="${5:-false}"
    FRAGMENT_SIZE="${6:-300}"
    NUM_FRAGMENTS="${7:-3}"
    
    if [ "$HIGHLIGHT" = "true" ]; then
      HIGHLIGHT_JSON=", \"highlight\": {
          \"fields\": {
            \"content\": {
              \"fragment_size\": $FRAGMENT_SIZE,
              \"number_of_fragments\": $NUM_FRAGMENTS,
              \"pre_tags\": [\"<mark>\"],
              \"post_tags\": [\"</mark>\"]
            }
          }
        }"
    else
      HIGHLIGHT_JSON=""
    fi
    
    curl -k -u "$ES_USER:$ES_PASS" \
      -X POST "$ES_HOST/$INDEX/_search?pretty" \
      -H "Content-Type: application/json" \
      -d "{
        \"query\": {
          \"multi_match\": {
            \"query\": \"$QUERY\",
            \"fields\": [\"content\", \"title\", \"file.filename\"]
          }
        }$HIGHLIGHT_JSON,
        \"_source\": [\"title\", \"content\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"],
        \"size\": $SIZE
      }"
    ;;
    
  "semantic_search")
    # Semantic search with optional highlighting
    QUERY="$2"
    INDEX="${3:-semantic_documents}"
    SIZE="${4:-10}"
    HIGHLIGHT="${5:-false}"
    FRAGMENT_SIZE="${6:-300}"
    NUM_FRAGMENTS="${7:-3}"
    
    if [ "$HIGHLIGHT" = "true" ]; then
      HIGHLIGHT_JSON=", \"highlight\": {
          \"fields\": {
            \"content\": {
              \"fragment_size\": $FRAGMENT_SIZE,
              \"number_of_fragments\": $NUM_FRAGMENTS,
              \"pre_tags\": [\"<mark>\"],
              \"post_tags\": [\"</mark>\"]
            }
          }
        }"
    else
      HIGHLIGHT_JSON=""
    fi
    
    curl -k -u "$ES_USER:$ES_PASS" \
      -X POST "$ES_HOST/$INDEX/_search?pretty" \
      -H "Content-Type: application/json" \
      -d "{
        \"query\": {
          \"semantic\": {
            \"field\": \"content_semantic\",
            \"query\": \"$QUERY\"
          }
        }$HIGHLIGHT_JSON,
        \"_source\": [\"title\", \"content\", \"content_semantic\", \"author\", \"created_date\", \"tags\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"],
        \"size\": $SIZE
      }"
    ;;
    
  "count")
    # Document count
    INDEX="${2:-semantic_documents}"
    
    curl -k -u "$ES_USER:$ES_PASS" \
      "$ES_HOST/$INDEX/_count?pretty"
    ;;
    
  "indices")
    # List indices
    curl -k -u "$ES_USER:$ES_PASS" \
      "$ES_HOST/_cat/indices?v"
    ;;
    
  *)
    echo "Usage: $0 {search|semantic_search|count|indices} <query> [index] [size] [highlight] [fragment_size] [num_fragments]"
    echo "Examples:"
    echo "  $0 search 'contract agreement'"
  echo "  $0 search 'elementos' semantic_documents 5 true 200 2"
    echo "  $0 search 'legal documents' semantic_documents 5 true 200 2"
    echo "  $0 semantic_search 'legal documents'"
    echo "  $0 semantic_search 'auditoria dados' semantic_documents 10 true"
    echo "  $0 count semantic_documents"
    echo "  $0 indices"
    echo ""
    echo "Search Parameters:"
    echo "  highlight: Enable highlighting with <mark> tags (true/false, default: false)"
    echo "  fragment_size: Characters per highlighted fragment (default: 300)"
    echo "  num_fragments: Number of fragments to return (default: 3)"
    exit 1
    ;;
esac