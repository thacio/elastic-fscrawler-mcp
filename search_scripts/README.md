
This folder contains scripts to use Elasticsearch search.

## Files Overview

### Linux/WSL Files:
- `elasticsearch.sh` - Elasticsearch search tools for Linux

### Windows Files:
- `elasticsearch.bat` - Elasticsearch search tools for Windows

## Available Tools

### Elasticsearch Tools:
- **search** - Traditional keyword search on `semantic_documents` index with highlighted fragments
- **semantic_search** - AI-powered semantic search using E5 model on `semantic_documents` index with fragments
- **hybrid_search** - RRF (Reciprocal Rank Fusion) combining both lexical and semantic search
- **count** - Get document count for an index (defaults to `semantic_documents`)
- **indices** - List all available indices

### Unified Index Architecture:
- All three search types use the same `semantic_documents` index
- Normal search queries the `content` field for keyword matching
- Semantic search queries the `content_semantic` field for AI-powered contextual search
- Hybrid search combines both approaches using RRF for optimal results
- Single FSCrawler processes documents for all search types automatically

### Search Parameters:
All `.sh` and `.bat` scripts now support:
```
search "query" [index] [size] [highlight] [fragment_size] [num_fragments]
semantic_search "query" [index] [size] [highlight] [fragment_size] [num_fragments]
hybrid_search "query" [index] [size] [highlight] [fragment_size] [num_fragments] [rank_window_size] [rank_constant]
```

## Testing

### Test Elasticsearch (Linux):
```bash
# Basic search with default fragments
./elasticsearch.sh search "contract agreement"

# Custom fragment settings (query, index, size, highlight, fragment_size, num_fragments)
./elasticsearch.sh search "elementos" semantic_documents 5 true 200 2

# Normal search with highlighting
./elasticsearch.sh search "auditoria" semantic_documents 10 true

# Semantic search for concepts
./elasticsearch.sh semantic_search "documentos sobre auditoria e evidências"

# Semantic search with highlighting
./elasticsearch.sh semantic_search "relatórios de compliance" semantic_documents 10 true

# Hybrid search combining both approaches
./elasticsearch.sh hybrid_search "contract agreement"

# Hybrid search with custom parameters
./elasticsearch.sh hybrid_search "elementos evidências" semantic_documents 10 true 300 3 50 20

# Other operations
./elasticsearch.sh count
./elasticsearch.sh indices
```

### Test Elasticsearch (Windows):
```cmd
REM Basic search with default fragments
elasticsearch.bat search "contract agreement"

REM Custom fragment settings (query, index, size, highlight, fragment_size, num_fragments)
elasticsearch.bat search "elementos" semantic_documents 5 true 200 2

REM Normal search with highlighting
elasticsearch.bat search "auditoria" semantic_documents 10 true

REM Semantic search for concepts
elasticsearch.bat semantic_search "documentos sobre auditoria e evidências"

REM Semantic search with highlighting
elasticsearch.bat semantic_search "relatórios de compliance" semantic_documents 10 true

REM Hybrid search combining both approaches
elasticsearch.bat hybrid_search "contract agreement"

REM Hybrid search with custom parameters
elasticsearch.bat hybrid_search "elementos evidências" semantic_documents 10 true 300 3 50 20

REM Other operations
elasticsearch.bat count
elasticsearch.bat indices
```
## Environment Variables

You can customize Elasticsearch connection by setting:
- `ES_HOST` - Elasticsearch host (default: https://localhost:9200)
- `ES_USER` - Username (default: elastic)
- `ES_PASS` - Password (default: changeme)

## Quick Reference - Default Parameters

### Minimal Usage (using all defaults):
```bash
./elasticsearch.sh search "your query"                    # Returns 5 results with 600-char fragments
./elasticsearch.sh semantic_search "your query"           # AI-powered search with same defaults  
./elasticsearch.sh hybrid_search "your query"             # Combined search with RRF defaults (50/20)
```

### Custom Usage Examples:
```bash
# Custom result count and fragment size
./elasticsearch.sh search "query" semantic_documents 10 true 300 3

# Disable highlighting (returns full content)
./elasticsearch.sh semantic_search "query" semantic_documents 5 false

# Custom RRF parameters for hybrid search
./elasticsearch.sh hybrid_search "query" semantic_documents 10 true 400 4 100 30
```

### Default Settings by Search Type:

| Parameter | Normal Search | Semantic Search | Hybrid Search |
|-----------|---------------|-----------------|---------------|
| **index** | `semantic_documents` | `semantic_documents` | `semantic_documents` |
| **size** | `5` | `5` | `5` |
| **highlight** | `true` | `true` | `true` |
| **fragment_size** | `600` | `600` | `600` |
| **num_fragments** | `5` | `5` | `5` |
| **rank_window_size** | N/A | N/A | `50` |
| **rank_constant** | N/A | N/A | `20` |

**Notes:**
- **fragment_size**: Characters per highlighted text excerpt
- **num_fragments**: Maximum number of text excerpts returned per document
- **rank_window_size**: RRF algorithm window size for combining results
- **rank_constant**: RRF algorithm constant for score normalization

### Performance Optimizations:
- Automatic recursive document processing from `elastic_documents/` folder
- OCR support for image-based PDFs and scanned documents
- Real-time indexing with subdirectory support
- README files automatically excluded from indexing
- Single index architecture supports both search types efficiently

### Current Configuration:
- **Index**: `semantic_documents` (unified for both search types)
- **Document Location**: `../elastic_documents/` (auto-monitored by FSCrawler)
- **Search Types**: Normal keyword search + AI semantic search
- **File Support**: PDF, TXT, DOC, DOCX with OCR capabilities
- **Subdirectories**: Fully supported with recursive crawling
- **Exclusions**: README files automatically excluded

### Example Usage:
```bash
# Normal search for exact keywords
./elasticsearch.sh search "elementos comprobatórios" semantic_documents 5 true

# Semantic search for concepts and meaning
./elasticsearch.sh semantic_search "documentos de auditoria e evidências" semantic_documents 5 true

# Hybrid search for best of both approaches
./elasticsearch.sh hybrid_search "elementos comprobatórios" semantic_documents 5 true

# Check total document count
./elasticsearch.sh count semantic_documents
```