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
    SIZE="${4:-5}"
    HIGHLIGHT="${5:-true}"
    FRAGMENT_SIZE="${6:-600}"
    NUM_FRAGMENTS="${7:-5}"
    
    if [ "$HIGHLIGHT" = "true" ]; then
      HIGHLIGHT_JSON=", \"highlight\": {
          \"fields\": {
            \"content\": {
              \"fragment_size\": $FRAGMENT_SIZE,
              \"number_of_fragments\": $NUM_FRAGMENTS,
              \"pre_tags\": [\"\"],
              \"post_tags\": [\"\"]
            }
          }
        }"
      SOURCE_FIELDS="[\"title\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]"
    else
      HIGHLIGHT_JSON=""
      SOURCE_FIELDS="[\"title\", \"content\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]"
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
        \"_source\": $SOURCE_FIELDS,
        \"size\": $SIZE
      }"
    ;;
    
  "semantic_search")
    # Semantic search with optional highlighting
    QUERY="$2"
    INDEX="${3:-semantic_documents}"
    SIZE="${4:-5}"
    HIGHLIGHT="${5:-true}"
    FRAGMENT_SIZE="${6:-600}"
    NUM_FRAGMENTS="${7:-5}"
    
    if [ "$HIGHLIGHT" = "true" ]; then
      HIGHLIGHT_JSON=", \"highlight\": {
          \"fields\": {
            \"content\": {
              \"fragment_size\": $FRAGMENT_SIZE,
              \"number_of_fragments\": $NUM_FRAGMENTS,
              \"pre_tags\": [\"\"],
              \"post_tags\": [\"\"]
            }
          }
        }"
      SOURCE_FIELDS="[\"title\", \"author\", \"created_date\", \"tags\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]"
    else
      HIGHLIGHT_JSON=""
      SOURCE_FIELDS="[\"title\", \"content\", \"content_semantic\", \"author\", \"created_date\", \"tags\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]"
    fi
    
    if [ "$HIGHLIGHT" = "true" ]; then
      # For semantic search with highlighting, we need a hybrid approach
      curl -k -u "$ES_USER:$ES_PASS" \
        -X POST "$ES_HOST/$INDEX/_search?pretty" \
        -H "Content-Type: application/json" \
        -d "{
          \"query\": {
            \"bool\": {
              \"should\": [
                {
                  \"semantic\": {
                    \"field\": \"content_semantic\",
                    \"query\": \"$QUERY\",
                    \"boost\": 2.0
                  }
                },
                {
                  \"multi_match\": {
                    \"query\": \"$QUERY\",
                    \"fields\": [\"content\", \"title\"],
                    \"boost\": 0.5
                  }
                }
              ]
            }
          }$HIGHLIGHT_JSON,
          \"_source\": $SOURCE_FIELDS,
          \"size\": $SIZE
        }"
    else
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
          \"_source\": $SOURCE_FIELDS,
          \"size\": $SIZE
        }"
    fi
    ;;
    
  "hybrid_search")
    # Hybrid search using RRF (Reciprocal Rank Fusion)
    QUERY="$2"
    INDEX="${3:-semantic_documents}"
    SIZE="${4:-5}"
    HIGHLIGHT="${5:-true}"
    FRAGMENT_SIZE="${6:-600}"
    NUM_FRAGMENTS="${7:-5}"
    RANK_WINDOW_SIZE="${8:-50}"
    RANK_CONSTANT="${9:-20}"
    
    if [ "$HIGHLIGHT" = "true" ]; then
      HIGHLIGHT_JSON=", \"highlight\": {
          \"fields\": {
            \"content\": {
              \"fragment_size\": $FRAGMENT_SIZE,
              \"number_of_fragments\": $NUM_FRAGMENTS,
              \"pre_tags\": [\"\"],
              \"post_tags\": [\"\"]
            }
          }
        }"
      SOURCE_FIELDS="[\"title\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]"
    else
      HIGHLIGHT_JSON=""
      SOURCE_FIELDS="[\"title\", \"content\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]"
    fi
    
    curl -k -u "$ES_USER:$ES_PASS" \
      -X POST "$ES_HOST/$INDEX/_search?pretty" \
      -H "Content-Type: application/json" \
      -d "{
        \"retriever\": {
          \"rrf\": {
            \"retrievers\": [
              {
                \"standard\": {
                  \"query\": {
                    \"multi_match\": {
                      \"query\": \"$QUERY\",
                      \"fields\": [\"content\", \"title\", \"file.filename\"]
                    }
                  }
                }
              },
              {
                \"standard\": {
                  \"query\": {
                    \"semantic\": {
                      \"field\": \"content_semantic\",
                      \"query\": \"$QUERY\"
                    }
                  }
                }
              }
            ],
            \"rank_window_size\": $RANK_WINDOW_SIZE,
            \"rank_constant\": $RANK_CONSTANT
          }
        }$HIGHLIGHT_JSON,
        \"_source\": $SOURCE_FIELDS,
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
    echo "Usage: $0 {search|semantic_search|hybrid_search|count|indices} <query> [index] [size] [highlight] [fragment_size] [num_fragments] [rank_window_size] [rank_constant]"
    echo "Examples:"
    echo "  $0 search 'contract agreement'"
    echo "  $0 search 'elementos' semantic_documents 5 true 200 2"
    echo "  $0 search 'legal documents' semantic_documents 5 true 200 2"
    echo "  $0 semantic_search 'legal documents'"
    echo "  $0 semantic_search 'auditoria dados' semantic_documents 10 true"
    echo "  $0 hybrid_search 'contract agreement'"
    echo "  $0 hybrid_search 'elementos evidências' semantic_documents 10 true 300 3 50 20"
    echo "  $0 count semantic_documents"
    echo "  $0 indices"
    echo ""
    echo "Search Types:"
    echo "  search: Traditional keyword-based search"
    echo "  semantic_search: AI-powered semantic search using E5 model"
    echo "  hybrid_search: RRF combination of both lexical and semantic search"
    echo ""
    echo "Search Parameters:"
    echo "  highlight: Enable highlighting with <mark> tags (true/false, default: true)"
    echo "  fragment_size: Characters per highlighted fragment (default: 600)"
    echo "  num_fragments: Number of fragments to return (default: 5)"
    echo "  rank_window_size: RRF rank window size (default: 50)"
    echo "  rank_constant: RRF rank constant (default: 20)"
    exit 1
    ;;
esac