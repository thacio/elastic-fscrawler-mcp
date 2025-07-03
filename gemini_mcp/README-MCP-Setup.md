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
- **search** - Traditional keyword search
- **semantic_search** - AI-powered semantic search using E5 model
- **count** - Get document count for an index
- **indices** - List all available indices

### Python Tools:
- Direct Python code execution
- File execution
- Version checking

## Testing

### Test Elasticsearch (Linux):
```bash
./elasticsearch-mcp.sh search "contract agreement"
./elasticsearch-mcp.sh semantic_search "legal documents"
./elasticsearch-mcp.sh count
./elasticsearch-mcp.sh indices
```

### Test Elasticsearch (Windows):
```cmd
elasticsearch-mcp.bat search "contract agreement"
elasticsearch-mcp.bat semantic_search "legal documents"
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
- "Search my documents for contracts about legal agreements"
- "Find documents semantically related to artificial intelligence"
- "Count how many documents are in my index"
- "Write and run a Python script to calculate the average of these numbers: [1,2,3,4,5]"
- "Execute this Python code: print('Hello World')"

The Gemini CLI will automatically use these MCP tools to fulfill your requests.