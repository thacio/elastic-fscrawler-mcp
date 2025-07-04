# Elasticsearch MCP Server

This is a Model Context Protocol (MCP) server that provides AI agents with access to Elasticsearch search capabilities, including traditional keyword search, AI-powered semantic search, and hybrid search using the E5 model.

## Features

### Search Tools
- **Traditional Search** (`search`): Keyword-based search with highlighting
- **Semantic Search** (`semantic_search`): AI-powered contextual search using E5 model
- **Hybrid Search** (`hybrid_search`): Combines keyword and semantic search using RRF (Reciprocal Rank Fusion)
- **Document Count** (`count_documents`): Count documents in an index with optional query filtering
- **Get Document** (`get_document`): Retrieve a specific document by ID

### Management Tools
- **List Indices** (`list_indices`): Get all available Elasticsearch indices with stats
- **Health Check** (`health_check`): Check Elasticsearch cluster health and connectivity
- **Server Health** (`server_health`): Simple health check for the MCP server itself

### Resources
- **Search Statistics** (`elasticsearch://stats`): Get search performance metrics
- **Index Information** (`elasticsearch://index/{index_name}`): Get detailed information about a specific index

## Configuration

The server uses the following environment variables:

- `ES_HOST`: Elasticsearch host URL (default: `https://elasticsearch:9200`)
- `ES_USER`: Elasticsearch username (default: `elastic`)
- `ES_PASS`: Elasticsearch password (default: `changeme`)
- `ES_DEFAULT_INDEX`: Default index to search (default: `documents`)

## Docker Usage

The MCP server runs as a Docker container and is included in the main docker-compose.yml file:

```bash
# Start the entire stack (includes Elasticsearch, Kibana, FSCrawler, and MCP server)
docker compose up -d

# Check container status
docker compose ps

# View MCP server logs
docker logs mcp-server

# Test MCP server (should return JSON-RPC error about content-type - this is normal)
curl http://localhost:8081/mcp/
```

## Standalone Usage

You can also run the MCP server standalone:

```bash
# Install dependencies
pip install -r requirements.txt

# Run the server
python server.py
```

The server will start on `http://0.0.0.0:8080/mcp/` by default.

## Client Integration

To use this server with an AI agent or MCP client, connect to:
- **URL**: `http://localhost:8081/mcp/` (when using Docker)
- **Transport**: HTTP with Server-Sent Events (SSE)

### Example Client Code

```python
from fastmcp import Client

async def main():
    async with Client("http://localhost:8081/mcp/") as client:
        # List available tools
        tools = await client.list_tools()
        print("Available tools:", [tool.name for tool in tools])
        
        # Perform a search
        results = await client.call_tool("search", {
            "query": "document analysis",
            "size": 5,
            "highlight": True
        })
        print("Search results:", results.data)
        
        # Check cluster health
        health = await client.call_tool("health_check", {})
        print("Cluster health:", health.data)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

## Tool Details

### Search Tools

#### `search(query, index, size, highlight, fragment_size, num_fragments)`
Performs traditional keyword search.
- **query**: Search query string
- **index**: Index to search (default: documents)
- **size**: Number of results (default: 5)
- **highlight**: Include highlighted fragments (default: true)
- **fragment_size**: Size of fragments in characters (default: 600)
- **num_fragments**: Number of fragments per document (default: 5)

#### `semantic_search(query, index, size, highlight, fragment_size, num_fragments)`
Performs AI-powered semantic search using the E5 model.
- Parameters same as `search`
- Uses natural language understanding for better contextual results

#### `hybrid_search(query, index, size, highlight, fragment_size, num_fragments, rank_window_size, rank_constant)`
Combines keyword and semantic search using RRF.
- Parameters same as `search` plus:
- **rank_window_size**: RRF window size (default: 50)
- **rank_constant**: RRF constant (default: 20)

### Management Tools

#### `count_documents(index, query)`
Counts documents in an index.
- **index**: Index to count (default: documents)
- **query**: Optional filter query

#### `get_document(document_id, index)`
Retrieves a specific document.
- **document_id**: Document ID to retrieve
- **index**: Index to search (default: documents)

#### `list_indices()`
Lists all available indices with document counts and sizes.

#### `health_check()`
Checks Elasticsearch cluster health and returns status information.

## Integration with Existing Setup

This MCP server is designed to work seamlessly with the existing Elasticsearch + FSCrawler setup:

1. **Elasticsearch**: Provides the search engine with E5 model for semantic search
2. **FSCrawler**: Indexes documents from `./elastic_documents/` folder
3. **MCP Server**: Exposes search capabilities to AI agents via MCP protocol

The server automatically uses the same index (`documents`) that FSCrawler populates, ensuring all indexed documents are immediately searchable through the MCP interface.

## Troubleshooting

### Common Issues

1. **Connection Refused**: Make sure Elasticsearch is running and healthy
2. **SSL Errors**: The server disables SSL verification for self-signed certificates
3. **Empty Results**: Check if FSCrawler has indexed documents in the `documents` index
4. **404 Errors**: Use the correct endpoint `/mcp/` not just `/`

### Debug Commands

```bash
# Check if Elasticsearch is accessible
curl -k -u elastic:changeme https://localhost:9200/_cluster/health

# Check if documents index exists
curl -k -u elastic:changeme https://localhost:9200/documents/_count

# Check MCP server logs
docker logs mcp-server

# Test MCP server connectivity
curl -H "Accept: text/event-stream" http://localhost:8081/mcp/
```

## Security Notes

- The server disables SSL verification for development use with self-signed certificates
- Authentication is handled through environment variables
- The server runs as a non-root user in the Docker container
- All requests to Elasticsearch are authenticated using the configured credentials

## Version Information

- **FastMCP**: 2.0+
- **Python**: 3.11
- **Elasticsearch**: 9.0.3
- **E5 Model**: .multilingual-e5-small