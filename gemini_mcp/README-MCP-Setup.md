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
- **search** - Traditional keyword search on `semantic_documents` index with highlighted fragments
- **semantic_search** - AI-powered semantic search using E5 model on `semantic_documents` index with fragments
- **count** - Get document count for an index (defaults to `semantic_documents`)
- **indices** - List all available indices

### Unified Index Architecture:
- Both search types use the same `semantic_documents` index
- Normal search queries the `content` field for keyword matching
- Semantic search queries the `content_semantic` field for AI-powered contextual search
- Single FSCrawler processes documents for both search types automatically

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

# Custom fragment settings (query, index, size, highlight, fragment_size, num_fragments)
./elasticsearch-mcp.sh search "elementos" semantic_documents 5 true 200 2

# Normal search with highlighting
./elasticsearch-mcp.sh search "auditoria" semantic_documents 10 true

# Semantic search for concepts
./elasticsearch-mcp.sh semantic_search "documentos sobre auditoria e evidências"

# Semantic search with highlighting
./elasticsearch-mcp.sh semantic_search "relatórios de compliance" semantic_documents 10 true

# Other operations
./elasticsearch-mcp.sh count
./elasticsearch-mcp.sh indices
```

### Test Elasticsearch (Windows):
```cmd
REM Basic search with default fragments
elasticsearch-mcp.bat search "contract agreement"

REM Custom fragment settings (query, index, size, highlight, fragment_size, num_fragments)
elasticsearch-mcp.bat search "elementos" semantic_documents 5 true 200 2

REM Normal search with highlighting
elasticsearch-mcp.bat search "auditoria" semantic_documents 10 true

REM Semantic search for concepts
elasticsearch-mcp.bat semantic_search "documentos sobre auditoria e evidências"

REM Semantic search with highlighting
elasticsearch-mcp.bat semantic_search "relatórios de compliance" semantic_documents 10 true

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
- "Search my documents for elementos comprobatórios" (normal keyword search with fragments)
- "Find documents semantically related to auditoria e evidências" (AI-powered semantic search)
- "Search for 'relatórios' but show me only highlighted excerpts" (fragment-based results)
- "Count how many documents are in the semantic_documents index"
- "Search both ways - normal and semantic - for compliance documents" (dual search approach)
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
- Automatic recursive document processing from `elastic_documents/` folder
- OCR support for image-based PDFs and scanned documents
- Real-time indexing with subdirectory support
- README files automatically excluded from indexing
- Single index architecture supports both search types efficiently

## ✅ Verified Setup

### Current Configuration:
- **Index**: `semantic_documents` (unified for both search types)
- **Document Location**: `../elastic_documents/` (auto-monitored by FSCrawler)
- **Search Types**: Normal keyword search + AI semantic search
- **File Support**: PDF, TXT, DOC, DOCX with OCR capabilities
- **Subdirectories**: Fully supported with recursive crawling
- **Exclusions**: README files automatically excluded

### Working Features:
✅ **Normal Search**: Traditional keyword matching with highlighting  
✅ **Semantic Search**: AI-powered contextual search using E5 model  
✅ **Automatic Indexing**: Files added to folder are auto-processed  
✅ **Subdirectory Support**: Files in folders like `racom_cpf_pecas/` are indexed  
✅ **Dual Fields**: Same documents available for both search approaches  
✅ **Real-time Processing**: New documents available within minutes  

### Example Usage:
```bash
# Normal search for exact keywords
./elasticsearch-mcp.sh search "elementos comprobatórios" semantic_documents 5 true

# Semantic search for concepts and meaning
./elasticsearch-mcp.sh semantic_search "documentos de auditoria e evidências" semantic_documents 5 true

# Check total document count
./elasticsearch-mcp.sh count semantic_documents
```