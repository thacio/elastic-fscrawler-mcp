#!/usr/bin/env python3
"""
Elasticsearch MCP Server

This server provides AI agents with access to Elasticsearch search capabilities
including normal search, semantic search, and hybrid search using the E5 model.
"""

import asyncio
import json
import logging
import os
import re
from typing import Dict, Any, List, Optional, Union
from urllib.parse import quote_plus

import httpx
from fastmcp import FastMCP, Context

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Elasticsearch configuration from environment variables
ES_HOST = os.getenv("ES_HOST", "https://elasticsearch:9200")
ES_USER = os.getenv("ES_USER", "elastic")
ES_PASS = os.getenv("ES_PASS", "changeme")
ES_DEFAULT_INDEX = os.getenv("ES_DEFAULT_INDEX", "documents")

# Create MCP server
mcp = FastMCP(name="Elasticsearch Search Server")

# Global HTTP client for Elasticsearch
es_client = None

async def get_elasticsearch_client():
    """Get or create Elasticsearch HTTP client"""
    global es_client
    if es_client is None:
        es_client = httpx.AsyncClient(
            auth=(ES_USER, ES_PASS),
            verify=False,  # Disable SSL verification for self-signed certs
            timeout=30.0,
            headers={"Content-Type": "application/json"}
        )
    return es_client

async def elasticsearch_request(method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
    """Make a request to Elasticsearch"""
    client = await get_elasticsearch_client()
    url = f"{ES_HOST}/{endpoint}"
    
    try:
        if method.upper() == "GET":
            response = await client.get(url)
        elif method.upper() == "POST":
            response = await client.post(url, json=data)
        elif method.upper() == "PUT":
            response = await client.put(url, json=data)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")
        
        response.raise_for_status()
        return response.json()
    except httpx.HTTPError as e:
        logger.error(f"Elasticsearch request failed: {e}")
        raise Exception(f"Elasticsearch request failed: {str(e)}")

def remove_html_tags(text: str) -> str:
    """Remove HTML tags from text for comparison purposes"""
    if not text:
        return ""
    # Remove <mark> and </mark> tags specifically
    clean_text = re.sub(r'</?mark>', '', text)
    return clean_text

def deduplicate_highlights(highlight_fragments: List[str]) -> List[str]:
    """
    Remove duplicate highlight fragments by comparing stripped text.
    Keep the version with the most highlighting coverage.
    
    Args:
        highlight_fragments: List of highlight fragments with <mark> tags
    
    Returns:
        List of unique highlight fragments, preserving the best highlighted version
    """
    if not highlight_fragments:
        return []
    
    seen_texts = {}  # plain_text -> (highlighted_version, mark_count, original_index)
    result_order = []  # Track order of unique texts
    
    for i, fragment in enumerate(highlight_fragments):
        if not fragment:
            continue
            
        # Strip HTML tags for comparison
        plain_text = remove_html_tags(fragment).strip()
        
        # Skip empty fragments
        if not plain_text:
            continue
            
        # Count highlighting coverage
        mark_count = fragment.count('<mark>')
        
        # Check if we've seen this text before
        if plain_text in seen_texts:
            # Keep the version with more highlighting
            if mark_count > seen_texts[plain_text][1]:
                # Update with better highlighted version, preserve original position
                seen_texts[plain_text] = (fragment, mark_count, seen_texts[plain_text][2])
        else:
            # First time seeing this text
            seen_texts[plain_text] = (fragment, mark_count, i)
            result_order.append(plain_text)
    
    # Return results in original order, using the best highlighted version
    return [seen_texts[plain_text][0] for plain_text in result_order if plain_text in seen_texts]

def format_search_results(results: Dict[str, Any]) -> Dict[str, Any]:
    """Format search results for better readability"""
    if "hits" not in results:
        return results
    
    formatted_hits = []
    for hit in results["hits"]["hits"]:
        formatted_hit = {
            "document_id": hit.get("_id"),
            "score": hit.get("_score", 0),
            "source": hit.get("_source", {}),
        }
        
        # Add highlighted content if available
        if "highlight" in hit:
            # Apply deduplication to highlight fragments
            deduplicated_highlight = {}
            for field, fragments in hit["highlight"].items():
                if isinstance(fragments, list):
                    deduplicated_highlight[field] = deduplicate_highlights(fragments)
                else:
                    deduplicated_highlight[field] = fragments
            formatted_hit["highlighted_content"] = deduplicated_highlight
        
        formatted_hits.append(formatted_hit)
    
    return {
        "total_hits": results["hits"]["total"]["value"],
        "max_score": results["hits"]["max_score"],
        # "took_ms": results.get("took", 0),
        "documents": formatted_hits
    }

@mcp.tool
async def search(
    query: str,
    index: str = ES_DEFAULT_INDEX,
    size: int = 5,
    highlight: bool = True,
    fragment_size: int = 600,
    num_fragments: int = 5,
    ctx: Context = None
) -> Dict[str, Any]:
    """
    Perform a traditional keyword search on Elasticsearch.
    
    Args:
        query: Search query string
        index: Elasticsearch index to search (default: documents)
        size: Number of results to return (default: 5)
        highlight: Whether to include highlighted text fragments (default: True)
        fragment_size: Size of highlighted fragments in characters (default: 600)
        num_fragments: Number of fragments to return per document (default: 5)
    
    Returns:
        Search results with document content and metadata
    """
    if ctx:
        await ctx.info(f"Performing keyword search for: '{query}' on index '{index}'")
    
    search_body = {
        "query": {
            "multi_match": {
                "query": query,
                "fields": ["content", "file.filename"]
            }
        },
        "size": size
    }
    
    if highlight:
        search_body["highlight"] = {
            "fields": {
                "content": {
                    "fragment_size": fragment_size,
                    "number_of_fragments": num_fragments,
                    "pre_tags": ["<mark>"],
                    "post_tags": ["</mark>"]
                }
            }
        }
        search_body["_source"] = ["file.filename", "path.virtual"]
    else:
        search_body["_source"] = ["content", "file.filename", "path.virtual"]
    
    try:
        results = await elasticsearch_request("POST", f"{index}/_search", search_body)
        formatted_results = format_search_results(results)
        
        # if ctx:
        #     await ctx.info(f"Found {formatted_results['total_hits']} documents in {formatted_results['took_ms']}ms")
        
        return formatted_results
    except Exception as e:
        if ctx:
            await ctx.error(f"Search failed: {str(e)}")
        raise

@mcp.tool
async def semantic_search(
    query: str,
    index: str = ES_DEFAULT_INDEX,
    size: int = 5,
    highlight: bool = True,
    fragment_size: int = 600,
    num_fragments: int = 5,
    ctx: Context = None
) -> Dict[str, Any]:
    """
    Perform AI-powered semantic search using the E5 model.
    
    Args:
        query: Search query string (can be natural language)
        index: Elasticsearch index to search (default: documents)
        size: Number of results to return (default: 5)
        highlight: Whether to include highlighted text fragments (default: True)
        fragment_size: Size of highlighted fragments in characters (default: 600)
        num_fragments: Number of fragments to return per document (default: 5)
    
    Returns:
        Semantic search results with document content and relevance scores
    """
    if ctx:
        await ctx.info(f"Performing semantic search for: '{query}' on index '{index}'")
    
    if highlight:
        # For semantic search with highlighting, use a hybrid approach
        search_body = {
            "query": {
                "bool": {
                    "should": [
                        {
                            "semantic": {
                                "field": "content_semantic",
                                "query": query,
                                "boost": 2.0
                            }
                        },
                        {
                            "multi_match": {
                                "query": query,
                                "fields": ["content"],
                                "boost": 0.5
                            }
                        }
                    ]
                }
            },
            "highlight": {
                "fields": {
                    "content": {
                        "fragment_size": fragment_size,
                        "number_of_fragments": num_fragments,
                        "pre_tags": ["<mark>"],
                        "post_tags": ["</mark>"]
                    }
                }
            },
            "_source": ["file.filename", "path.virtual"],
            "size": size
        }
    else:
        # Pure semantic search
        search_body = {
            "query": {
                "semantic": {
                    "field": "content_semantic",
                    "query": query
                }
            },
            "_source": ["content", "content_semantic", "file.filename", "path.virtual"],
            "size": size
        }
    
    try:
        results = await elasticsearch_request("POST", f"{index}/_search", search_body)
        formatted_results = format_search_results(results)
        
        # if ctx:
        #     await ctx.info(f"Found {formatted_results['total_hits']} documents in {formatted_results['took_ms']}ms using semantic search")
        
        return formatted_results
    except Exception as e:
        if ctx:
            await ctx.error(f"Semantic search failed: {str(e)}")
        raise

@mcp.tool
async def hybrid_search(
    query: str,
    index: str = ES_DEFAULT_INDEX,
    size: int = 5,
    highlight: bool = True,
    fragment_size: int = 600,
    num_fragments: int = 5,
    rank_window_size: int = 50,
    rank_constant: int = 20,
    ctx: Context = None
) -> Dict[str, Any]:
    """
    Perform hybrid search combining keyword and semantic search using RRF (Reciprocal Rank Fusion).
    
    Args:
        query: Search query string
        index: Elasticsearch index to search (default: documents)
        size: Number of results to return (default: 5)
        highlight: Whether to include highlighted text fragments (default: True)
        fragment_size: Size of highlighted fragments in characters (default: 600)
        num_fragments: Number of fragments to return per document (default: 5)
        rank_window_size: RRF rank window size (default: 50)
        rank_constant: RRF rank constant (default: 20)
    
    Returns:
        Hybrid search results combining keyword and semantic search
    """
    if ctx:
        await ctx.info(f"Performing hybrid search for: '{query}' on index '{index}'")
    
    search_body = {
        "retriever": {
            "rrf": {
                "retrievers": [
                    {
                        "standard": {
                            "query": {
                                "multi_match": {
                                    "query": query,
                                    "fields": ["content"]
                                }
                            }
                        }
                    },
                    {
                        "standard": {
                            "query": {
                                "semantic": {
                                    "field": "content_semantic",
                                    "query": query
                                }
                            }
                        }
                    }
                ],
                "rank_window_size": rank_window_size,
                "rank_constant": rank_constant
            }
        },
        "size": size
    }
    
    if highlight:
        search_body["highlight"] = {
            "fields": {
                "content": {
                    "fragment_size": fragment_size,
                    "number_of_fragments": num_fragments,
                    "pre_tags": ["<mark>"],
                    "post_tags": ["</mark>"]
                }
            }
        }
        search_body["_source"] = ["file.filename", "path.virtual"]
    else:
        search_body["_source"] = ["content", "file.filename", "path.virtual"]
    
    try:
        results = await elasticsearch_request("POST", f"{index}/_search", search_body)
        formatted_results = format_search_results(results)
        
        # if ctx:
        #     await ctx.info(f"Found {formatted_results['total_hits']} documents in {formatted_results['took_ms']}ms using hybrid search")
        
        return formatted_results
    except Exception as e:
        if ctx:
            await ctx.error(f"Hybrid search failed: {str(e)}")
        raise

@mcp.tool
async def count_documents(
    index: str = ES_DEFAULT_INDEX,
    query: Optional[str] = None,
    ctx: Context = None
) -> Dict[str, Any]:
    """
    Count documents in an Elasticsearch index.
    
    Args:
        index: Elasticsearch index to count documents in (default: documents)
        query: Optional query to count specific documents (default: None - count all)
    
    Returns:
        Document count and index information
    """
    if ctx:
        await ctx.info(f"Counting documents in index '{index}'")
    
    count_body = {}
    if query:
        count_body = {
            "query": {
                "multi_match": {
                    "query": query,
                    "fields": ["content", "file.filename"]
                }
            }
        }
    
    try:
        results = await elasticsearch_request("POST", f"{index}/_count", count_body)
        
        if ctx:
            await ctx.info(f"Found {results['count']} documents in index '{index}'")
        
        return {
            "index": index,
            "count": results["count"],
            "query": query
        }
    except Exception as e:
        if ctx:
            await ctx.error(f"Count failed: {str(e)}")
        raise

@mcp.tool
async def list_indices(ctx: Context = None) -> Dict[str, Any]:
    """
    List all available Elasticsearch indices.
    
    Returns:
        List of available indices with their document counts and sizes
    """
    if ctx:
        await ctx.info("Listing all Elasticsearch indices")
    
    try:
        results = await elasticsearch_request("GET", "_cat/indices?format=json&h=index,docs.count,store.size")
        
        indices = []
        for index_info in results:
            indices.append({
                "index": index_info["index"],
                "document_count": int(index_info["docs.count"]) if index_info["docs.count"] != "0" else 0,
                "size": index_info["store.size"]
            })
        
        if ctx:
            await ctx.info(f"Found {len(indices)} indices")
        
        return {
            "indices": indices,
            "total_indices": len(indices)
        }
    except Exception as e:
        if ctx:
            await ctx.error(f"List indices failed: {str(e)}")
        raise

@mcp.tool
async def health_check(ctx: Context = None) -> Dict[str, Any]:
    """
    Check Elasticsearch cluster health and connectivity.
    
    Returns:
        Cluster health status and basic information
    """
    if ctx:
        await ctx.info("Checking Elasticsearch cluster health")
    
    try:
        health_results = await elasticsearch_request("GET", "_cluster/health")
        info_results = await elasticsearch_request("GET", "")
        
        health_info = {
            "status": health_results["status"],
            "cluster_name": health_results["cluster_name"],
            "number_of_nodes": health_results["number_of_nodes"],
            "active_primary_shards": health_results["active_primary_shards"],
            "active_shards": health_results["active_shards"],
            "elasticsearch_version": info_results["version"]["number"],
            "connection_url": ES_HOST
        }
        
        if ctx:
            await ctx.info(f"Cluster status: {health_info['status']}")
        
        return health_info
    except Exception as e:
        if ctx:
            await ctx.error(f"Health check failed: {str(e)}")
        raise

@mcp.tool
async def get_document(
    document_id: str,
    index: str = ES_DEFAULT_INDEX,
    ctx: Context = None
) -> Dict[str, Any]:
    """
    Get a specific document by ID from Elasticsearch.
    
    Args:
        document_id: The document ID to retrieve (use document_id from search results)
        index: Elasticsearch index to search in (default: documents)
    
    Returns:
        The document content and metadata
    """
    if ctx:
        await ctx.info(f"Getting document '{document_id}' from index '{index}'")
    
    try:
        results = await elasticsearch_request("GET", f"{index}/_doc/{quote_plus(document_id)}")
        
        if ctx:
            await ctx.info(f"Retrieved document '{document_id}'")
        
        return {
            "document_id": results["_id"],
            "index": results["_index"],
            "found": results["found"],
            "source": results.get("_source", {}),
            "version": results.get("_version", 0)
        }
    except Exception as e:
        if ctx:
            await ctx.error(f"Get document failed: {str(e)}")
        # Provide helpful error message about using document_id from search results
        error_msg = str(e)
        if "404 Not Found" in error_msg:
            raise Exception(f"Document '{document_id}' not found in index '{index}'. Make sure to use the 'document_id' field from search results.")
        raise

# Resource for getting search statistics
@mcp.resource("elasticsearch://stats")
async def get_search_stats(ctx: Context = None) -> Dict[str, Any]:
    """Get Elasticsearch search statistics and performance metrics"""
    if ctx:
        await ctx.info("Getting Elasticsearch search statistics")
    
    try:
        stats_results = await elasticsearch_request("GET", "_stats/search")
        
        total_stats = stats_results["_all"]["total"]
        
        return {
            "total_searches": total_stats["search"]["query_total"],
            "search_time_ms": total_stats["search"]["query_time_in_millis"],
            "avg_search_time_ms": round(total_stats["search"]["query_time_in_millis"] / max(total_stats["search"]["query_total"], 1), 2),
            "current_searches": total_stats["search"]["query_current"],
            "indices": list(stats_results["indices"].keys())
        }
    except Exception as e:
        if ctx:
            await ctx.error(f"Get search stats failed: {str(e)}")
        raise Exception(f"Failed to get search stats: {str(e)}")

# Resource template for getting index information
@mcp.resource("elasticsearch://index/{index_name}")
async def get_index_info(index_name: str, ctx: Context = None) -> Dict[str, Any]:
    """Get information about a specific Elasticsearch index"""
    if ctx:
        await ctx.info(f"Getting information for index '{index_name}'")
    
    try:
        # Get index settings and mappings
        settings_results = await elasticsearch_request("GET", f"{index_name}/_settings")
        mappings_results = await elasticsearch_request("GET", f"{index_name}/_mapping")
        stats_results = await elasticsearch_request("GET", f"{index_name}/_stats")
        
        index_info = {
            "index_name": index_name,
            "settings": settings_results[index_name]["settings"],
            "mappings": mappings_results[index_name]["mappings"],
            "stats": {
                "document_count": stats_results["indices"][index_name]["total"]["docs"]["count"],
                "store_size": stats_results["indices"][index_name]["total"]["store"]["size_in_bytes"],
                "search_total": stats_results["indices"][index_name]["total"]["search"]["query_total"]
            }
        }
        
        return index_info
    except Exception as e:
        if ctx:
            await ctx.error(f"Get index info failed: {str(e)}")
        raise Exception(f"Failed to get index info: {str(e)}")

# Cleanup function
async def cleanup():
    """Cleanup resources"""
    global es_client
    if es_client:
        await es_client.aclose()

@mcp.tool
async def server_health() -> Dict[str, Any]:
    """
    Simple health check endpoint for Docker health monitoring.
    
    Returns:
        Server health status
    """
    return {
        "status": "healthy",
        "service": "elasticsearch-mcp-server",
        "timestamp": asyncio.get_event_loop().time()
    }

if __name__ == "__main__":
    try:
        # Run the MCP server
        mcp.run(transport="http", host="0.0.0.0", port=8080)
    except KeyboardInterrupt:
        print("\nShutting down MCP server...")
    finally:
        # Cleanup
        asyncio.run(cleanup())