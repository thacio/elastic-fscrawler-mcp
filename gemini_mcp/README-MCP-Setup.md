# MCP Server Setup for Gemini CLI

This folder contains MCP server configurations to use Elasticsearch search and Python execution with Gemini CLI.

## Files Overview

### Linux/WSL Files:
- `elasticsearch-mcp.sh` - Elasticsearch search tools for Linux
- `python-executor.sh` - Python execution wrapper for Linux
- `gemini-settings-complete.json` - Complete configuration for Linux

### Windows Files:
- `elasticsearch-mcp.bat` - Elasticsearch search tools for Windows
- `python-executor.bat` - Python execution wrapper for Windows  
- `gemini-settings-windows.json` - Complete configuration for Windows

## Setup Instructions

### For Linux/WSL:

1. **Copy configuration to Gemini CLI:**
   ```bash
   # For global configuration
   cp gemini-settings-complete.json ~/.gemini/settings.json
   
   # OR for project-specific configuration
   mkdir -p .gemini
   cp gemini-settings-complete.json .gemini/settings.json
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x elasticsearch-mcp.sh
   chmod +x python-executor.sh
   ```

3. **Update paths in settings if needed:**
   Edit the `command` paths in the JSON to match your actual file locations.

### For Windows:

1. **Copy configuration to Gemini CLI:**
   ```cmd
   # For global configuration
   copy gemini-settings-windows.json %USERPROFILE%\.gemini\settings.json
   
   # OR for project-specific configuration
   mkdir .gemini
   copy gemini-settings-windows.json .gemini\settings.json
   ```

2. **Update paths in settings:**
   Edit `gemini-settings-windows.json` and replace:
   ```json
   "command": "C:\\path\\to\\your\\elasticsearch\\elasticsearch-mcp.bat"
   ```
   With your actual path to the batch file.

## Available Tools

### Elasticsearch Tools:
- **search** - Traditional keyword search with highlighted fragments
- **semantic_search** - AI-powered semantic search using E5 model with fragments
- **count** - Get document count for an index
- **indices** - List all available indices

### New Fragment-Based Search Features:
- Returns relevant text fragments instead of entire documents
- Configurable fragment size (default: 300 characters)
- Configurable number of fragments per document (default: 3)
- Highlighted matching terms with `<mark>` tags
- Optimized for better search result granularity

### Python Tools:
- Direct Python code execution
- File execution
- Version checking

## Testing

### Test Elasticsearch (Linux):
```bash
# Basic search with default fragments
./elasticsearch-mcp.sh search "contract agreement"

# Custom fragment settings (query, index, size, fragment_size, num_fragments)
./elasticsearch-mcp.sh search "legal documents" idx 5 200 2

# Semantic search
./elasticsearch-mcp.sh semantic_search "legal documents"

# Other operations
./elasticsearch-mcp.sh count
./elasticsearch-mcp.sh indices
```

### Test Elasticsearch (Windows):
```cmd
REM Basic search with default fragments
elasticsearch-mcp.bat search "contract agreement"

REM Custom fragment settings (query, index, size, fragment_size, num_fragments)
elasticsearch-mcp.bat search "legal documents" idx 5 200 2

REM Semantic search
elasticsearch-mcp.bat semantic_search "legal documents"

REM Other operations
elasticsearch-mcp.bat count
elasticsearch-mcp.bat indices
```

### Test Python (Linux):
```bash
./python-executor.sh run "print('Hello from Python!')"
./python-executor.sh version
```

### Test Python (Windows):
```cmd
python-executor.bat run "print('Hello from Python!')"
python-executor.bat version
```

## Environment Variables

You can customize Elasticsearch connection by setting:
- `ES_HOST` - Elasticsearch host (default: https://localhost:9200)
- `ES_USER` - Username (default: elastic)
- `ES_PASS` - Password (default: changeme)

## Usage with Gemini CLI

Once configured, you can ask Gemini CLI to:
- "Search my documents for contracts about legal agreements" (returns relevant fragments)
- "Find documents semantically related to artificial intelligence" (fragment-based results)
- "Search for 'project management' but show me only short excerpts"
- "Count how many documents are in my index"
- "Write and run a Python script to calculate the average of these numbers: [1,2,3,4,5]"
- "Execute this Python code: print('Hello World')"

The Gemini CLI will automatically use these MCP tools to fulfill your requests.

## Key Improvements

### Fragment-Based Search Results:
- **Before**: Searches returned entire document content, making results hard to scan
- **After**: Returns 3 highlighted fragments of 300 characters each by default
- **Benefits**: Better result relevancy, faster scanning, reduced token usage

### Enhanced Search Parameters:
Both `.sh` and `.bat` scripts now support:
```
search "query" [index] [size] [fragment_size] [num_fragments]
semantic_search "query" [index] [size] [fragment_size] [num_fragments]
```

### Performance Optimizations:
- Limited document indexing to 500KB per file (configurable)
- Added term vectors and offsets for faster highlighting
- Only essential metadata returned in search results