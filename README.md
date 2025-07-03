# Elasticsearch + FSCrawler + E5 Semantic Search

A complete document search solution with automatic document crawling, OCR processing, and AI-powered semantic search capabilities.

## Features

🔍 **Dual Search Capabilities**
- **Normal Search**: Traditional keyword-based search with highlighting
- **Semantic Search**: AI-powered contextual search using E5 multilingual model
- **Single Index**: Both search types work on the same `semantic_documents` index
- **Real-time Results**: Instant search across all document content

📄 **Automatic Document Processing**
- **Single FSCrawler**: One instance handles all document processing
- **Auto-Detection**: Monitors `elastic_documents/` folder for new files
- **OCR Enabled**: Processes image-based PDFs and scanned documents
- **Dual Indexing**: Creates both normal and semantic search fields automatically
- **File Formats**: PDF, DOC, DOCX, TXT, HTML, RTF, ODT and more

🚀 **Fully Automated Setup**
- Zero-configuration deployment
- Automatic E5 model download and configuration
- Pre-configured security with SSL
- Sample data for immediate testing

🔧 **Production Ready**
- 20GB memory allocation for ML workloads
- Health monitoring and verification scripts
- Docker-based deployment
- Kibana dashboard for data visualization

## Quick Start

### Prerequisites
- Docker and Docker Compose
- At least 25GB of available RAM
- WSL2 or Linux environment

### 1. Clone and Start

```bash
git clone <your-repo>
cd elasticsearch
docker-compose up -d
```

**Note**: First startup takes 5-10 minutes to download and configure the E5 model.

### 2. Verify Setup

```bash
./verify-setup.sh
```

### 3. Add Documents

Simply add any documents to the `elastic_documents/` folder:

```bash
cp your-document.pdf elastic_documents/
# FSCrawler automatically detects and indexes for BOTH search types
# Available for normal AND semantic search within minutes
```

### 4. Search Your Documents

**Normal Search (Keyword-based):**
```bash
# Search with keywords and highlighting
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {"match": {"content": "your search terms"}},
    "highlight": {"fields": {"content": {}}}
  }'
```

**Semantic Search (AI-powered):**
```bash
# Search with natural language concepts
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "semantic": {
        "field": "content_semantic",
        "query": "artificial intelligence in healthcare"
      }
    }
  }'
```

## Architecture

### Services

| Service | Port | Purpose |
|---------|------|---------|
| **Elasticsearch** | 9200 | Search engine + ML inference |
| **Kibana** | 5601 | Web interface and visualization |
| **FSCrawler** | 8080 | Document monitoring and indexing |

### Memory Allocation

| Component | Memory | Purpose |
|-----------|---------|---------|
| Elasticsearch | 20GB | Search + ML models (10GB ML) |
| Kibana | 8GB | Web interface |
| E5 Model | ~500MB | Semantic embeddings |

### Document Flow

```
Documents → elastic_documents/ → FSCrawler → semantic_documents index
                                     ↓              ↓
                                OCR Processing    Dual Fields:
                                     ↓              ├── content (normal search)
                               Text Extraction     └── content_semantic (AI search)
                                     ↓
                              E5 Pipeline Processing
                                     ↓
                            Both Search Types Available
```

## Access Information

### Default Credentials
- **Username**: `elastic`
- **Password**: `changeme`

### Service URLs
- **Elasticsearch**: https://localhost:9200
- **Kibana**: http://localhost:5601
- **FSCrawler**: http://localhost:8080

## Usage Examples

### Document Management

**Add documents for automatic indexing:**
```bash
# Copy files to monitored folder
cp *.pdf elastic_documents/
# Files are automatically indexed within 15 minutes
```

**Force immediate scan:**
```bash
curl -X POST "http://localhost:8080/fscrawler/_start"
```

### Search Examples

**Normal keyword search:**
```bash
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{"query": {"match": {"content": "contract"}}}'
```

**Search with filters:**
```bash
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "bool": {
        "must": [{"match": {"content": "agreement"}}],
        "filter": [{"term": {"file.content_type": "application/pdf"}}]
      }
    }
  }'
```

**Semantic search for concepts:**
```bash
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "semantic": {
        "field": "content_semantic",
        "query": "legal contracts and agreements"
      }
    }
  }'
```

### Data Management

**Delete all documents:**
```bash
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_delete_by_query" \
  -H "Content-Type: application/json" \
  -d '{"query": {"match_all": {}}}'
```

**Count indexed documents:**
```bash
curl -k -u elastic:changeme "https://localhost:9200/semantic_documents/_count?pretty"
```

## Configuration

### FSCrawler Settings

Edit `config/idx/_settings.yaml`:

```yaml
name: "idx"
fs:
  indexed_chars: 100%
  lang_detect: true
  continue_on_error: true
  ocr:
    language: "por"  # Change language for OCR
    enabled: true
    pdf_strategy: "ocr_and_text"
elasticsearch:
  nodes:
    - url: "https://elasticsearch:9200"
  username: "elastic"
  password: "changeme"
  ssl_verification: false
  index: "semantic_documents"  # Single index for both search types
  type: "_doc"
  pipeline: "semantic_documents_pipeline"  # Auto-creates semantic field
```

### Environment Variables

Edit `.env` file:

```env
# Memory allocation (adjust based on your system)
MEM_LIMIT=21474836480  # 20GB

# Credentials
ELASTIC_PASSWORD=changeme
KIBANA_PASSWORD=changeme

# Ports
ES_PORT=9200
KIBANA_PORT=5601
FSCRAWLER_PORT=8080
```

## Monitoring

### Health Checks

```bash
# Overall system verification
./verify-setup.sh

# Individual service checks
curl -k -u elastic:changeme "https://localhost:9200/_cluster/health?pretty"
curl -I http://localhost:5601
curl -I http://localhost:8080
```

### Logs

```bash
# View service logs
docker-compose logs -f elasticsearch
docker-compose logs -f fscrawler
docker-compose logs -f kibana

# Check E5 setup logs
docker logs fscrawler-e5-setup-1
```

## Troubleshooting

### Common Issues

**Services not starting:**
```bash
# Check available memory
free -h
# Ensure at least 25GB available

# Check Docker resources
docker system df
```

**Documents not being indexed:**
```bash
# Check FSCrawler can see files
docker exec fscrawler ls -la /tmp/es/

# Force FSCrawler scan
curl -X POST "http://localhost:8080/fscrawler/_start"

# Check FSCrawler logs
docker logs fscrawler --tail 50
```

**Semantic search not working:**
```bash
# Verify E5 endpoint
curl -k -u elastic:changeme "https://localhost:9200/_inference/my-e5-model?pretty"

# Check ML memory
curl -k -u elastic:changeme "https://localhost:9200/_ml/info?pretty"
```

### Performance Tuning

**For production environments:**

1. **Increase memory allocation** in `.env`
2. **Add more Elasticsearch nodes** for scaling
3. **Configure index templates** for consistent mappings
4. **Set up index lifecycle management** for data retention
5. **Enable monitoring** with Elastic APM

## Development

### File Structure

```
elasticsearch/
├── docker-compose.yml          # Service definitions
├── .env                       # Environment configuration
├── verify-setup.sh           # System verification script
├── SETUP_GUIDE.md            # Detailed setup instructions
├── README.md                 # This file
├── config/
│   └── idx/
│       └── _settings.yaml    # FSCrawler configuration
├── elastic_documents/        # Document folder (gitignored)
│   └── README.txt           # Folder usage instructions
└── .gitignore               # Git ignore rules
```

### Adding New Features

**To add new document types:**
1. Update FSCrawler configuration in `config/idx/_settings.yaml`
2. Restart FSCrawler: `docker-compose restart fscrawler`

**To customize semantic search:**
1. Modify E5 setup in `docker-compose.yml` (e5-setup service)
2. Update index mappings for new semantic fields

**To add new languages:**
1. Update OCR language in `config/idx/_settings.yaml`
2. E5 model supports multilingual out of the box

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]

---

**Need help?** Check the [detailed setup guide](SETUP_GUIDE.md) or run `./verify-setup.sh` for system diagnostics.