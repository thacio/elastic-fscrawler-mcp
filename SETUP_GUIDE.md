# Elasticsearch + FSCrawler + E5 Semantic Search Setup Guide

This guide provides step-by-step instructions to set up a complete Elasticsearch environment with FSCrawler for document indexing and E5 for semantic search capabilities.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration Files](#configuration-files)
4. [Starting the Services](#starting-the-services)
5. [Setting up E5 Semantic Search](#setting-up-e5-semantic-search)
6. [Document Indexing](#document-indexing)
7. [Testing Search Functionality](#testing-search-functionality)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker and Docker Compose installed
- At least 25GB of available RAM (20GB for Elasticsearch, 8GB for Kibana)
- WSL2 or Linux environment (for the provided configuration)

## Initial Setup

### 1. Directory Structure
Create the following directory structure:
```
elasticsearch/
├── docker-compose.yml
├── .env
├── config/
│   └── idx/
│       └── _settings.yaml
└── logs/
```

### 2. Environment Configuration

Create `.env` file:
```env
# FSCrawler Settings
FSCRAWLER_VERSION=2.10-SNAPSHOT
FSCRAWLER_PORT=8080
FS_JAVA_OPTS="-DLOG_LEVEL=debug -DDOC_LEVEL=debug"

# Authentication
ELASTIC_PASSWORD=changeme
KIBANA_PASSWORD=changeme

# Elastic Stack Configuration
STACK_VERSION=9.0.3
CLUSTER_NAME=docker-cluster
LICENSE=trial

# Ports
ES_PORT=9200
KIBANA_PORT=5601

# Memory Configuration (20GB for ML models like E5)
MEM_LIMIT=21474836480

# Project Settings
COMPOSE_PROJECT_NAME=fscrawler
```

## Configuration Files

### 3. Docker Compose Configuration

Create `docker-compose.yml`:
```yaml
---
services:
  setup:
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    user: "0"
    command: >
      bash -c '
        if [ x${ELASTIC_PASSWORD} == x ]; then
          echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
          exit 1;
        elif [ x${KIBANA_PASSWORD} == x ]; then
          echo "Set the KIBANA_PASSWORD environment variable in the .env file";
          exit 1;
        fi;
        if [ ! -f certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f certs/certs.zip ]; then
          echo "Creating certs";
          echo -ne \
          "instances:\n"\
          "  - name: elasticsearch\n"\
          "    dns:\n"\
          "      - elasticsearch\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          > config/certs/instances.yml;
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions"
        chown -R root:root config/certs;
        find . -type d -exec chmod 750 \{\} \;;
        find . -type f -exec chmod 640 \{\} \;;
        echo "Waiting for Elasticsearch availability";
        until curl -s --cacert config/certs/ca/ca.crt https://elasticsearch:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
        echo "Setting kibana_system password";
        until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://elasticsearch:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
        echo "All done!";
      '
    healthcheck:
      test: ["CMD-SHELL", "[ -f config/certs/elasticsearch/elasticsearch.crt ]"]
      interval: 1s
      timeout: 5s
      retries: 120

  elasticsearch:
    depends_on:
      setup:
        condition: service_healthy
    image: docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - esdata:/usr/share/elasticsearch/data
    ports:
      - ${ES_PORT}:9200
    environment:
      - node.name=elasticsearch
      - cluster.name=${CLUSTER_NAME}
      - cluster.initial_master_nodes=elasticsearch
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/elasticsearch/elasticsearch.key
      - xpack.security.http.ssl.certificate=certs/elasticsearch/elasticsearch.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/elasticsearch/elasticsearch.key
      - xpack.security.transport.ssl.certificate=certs/elasticsearch/elasticsearch.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=${LICENSE}
      # ML Configuration for E5 and other models
      - xpack.ml.enabled=true
      - xpack.ml.max_machine_memory_percent=50
      - xpack.ml.max_model_memory_limit=10gb
      - xpack.ml.use_auto_machine_memory_percent=false
      # JVM heap size (should be ~50% of container memory)
      - "ES_JAVA_OPTS=-Xms10g -Xmx10g"
    mem_limit: ${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  kibana:
    depends_on:
      elasticsearch:
        condition: service_healthy
    image: docker.elastic.co/kibana/kibana:${STACK_VERSION}
    volumes:
      - certs:/usr/share/kibana/config/certs
      - kibanadata:/usr/share/kibana/data
    ports:
      - ${KIBANA_PORT}:5601
    environment:
      - SERVERNAME=kibana
      - ELASTICSEARCH_HOSTS=https://elasticsearch:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=${KIBANA_PASSWORD}
      - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
      # Kibana optimization for ML interface
      - "NODE_OPTIONS=--max-old-space-size=4096"
    mem_limit: 8gb
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  # FSCrawler
  fscrawler:
    image: dadoonet/fscrawler:${FSCRAWLER_VERSION}
    container_name: fscrawler
    restart: always
    environment:
      - FS_JAVA_OPTS=${FS_JAVA_OPTS}
    volumes:
      - ../../test-documents/src/main/resources/documents/:/tmp/es:ro
      - ${PWD}/config:/root/.fscrawler
      - ${PWD}/logs:/usr/share/fscrawler/logs
      - ${PWD}/external:/usr/share/fscrawler/external
    depends_on:
      elasticsearch:
        condition: service_healthy
    ports:
      - ${FSCRAWLER_PORT}:8080
    command: idx --restart --rest

volumes:
  certs:
    driver: local
  esdata:
    driver: local
  kibanadata:
    driver: local
```

### 4. FSCrawler Configuration

Create `config/idx/_settings.yaml`:
```yaml
---
name: "idx"
fs:
  indexed_chars: 100%
  lang_detect: true
  continue_on_error: true
  ocr:
    language: "por"
    enabled: true
    pdf_strategy: "ocr_and_text"
elasticsearch:
  nodes:
    - url: "https://elasticsearch:9200"
  username: "elastic"
  password: "changeme"
  ssl_verification: false
rest:
  url: "http://fscrawler:8080"
```

## Starting the Services

### 5. Launch the Stack

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs if needed
docker-compose logs -f elasticsearch
docker-compose logs -f fscrawler
```

### 6. Verify Services

Wait for all services to be healthy, then test connectivity:

```bash
# Test Elasticsearch (use -k for self-signed certificates)
curl -k -u elastic:changeme https://localhost:9200

# Test Kibana
curl -I http://localhost:5601

# Test FSCrawler
curl -I http://localhost:8080
```

**Access URLs:**
- Elasticsearch: https://localhost:9200 (user: elastic, pass: changeme)
- Kibana: http://localhost:5601 (user: elastic, pass: changeme)
- FSCrawler: http://localhost:8080

## Setting up E5 Semantic Search

### 7. Create E5 Inference Endpoint

```bash
curl -k -u elastic:changeme -X PUT "https://localhost:9200/_inference/text_embedding/my-e5-model" -H "Content-Type: application/json" -d '{
  "service": "elasticsearch",
  "service_settings": {
    "num_allocations": 1,
    "num_threads": 1,
    "model_id": ".multilingual-e5-small"
  }
}'
```

### 8. Verify ML Capacity

```bash
# Check ML node info
curl -k -u elastic:changeme "https://localhost:9200/_ml/info?pretty"

# Should show: "total_ml_memory": "10240mb"
```

### 9. Create Semantic Index

```bash
curl -k -u elastic:changeme -X PUT "https://localhost:9200/semantic_documents" -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "title": {
        "type": "text"
      },
      "content": {
        "type": "text"
      },
      "content_semantic": {
        "type": "semantic_text",
        "inference_id": "my-e5-model"
      },
      "author": {
        "type": "keyword"
      },
      "created_date": {
        "type": "date"
      },
      "tags": {
        "type": "keyword"
      }
    }
  }
}'
```

## Document Indexing

### 10. Index Sample Documents

**Method 1: Direct Elasticsearch API**

```bash
# Index document with semantic field
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_doc/1" -H "Content-Type: application/json" -d '{
  "title": "Machine Learning in Healthcare",
  "content": "Artificial intelligence and machine learning are revolutionizing healthcare by enabling predictive diagnostics, personalized treatment plans, and automated medical image analysis.",
  "content_semantic": "Artificial intelligence and machine learning are revolutionizing healthcare by enabling predictive diagnostics, personalized treatment plans, and automated medical image analysis.",
  "author": "Dr. Smith",
  "created_date": "2025-07-02",
  "tags": ["healthcare", "AI", "machine learning", "diagnostics"]
}'
```

**Method 2: FSCrawler (File-based)**

1. Create documents in the monitored directory:
```bash
mkdir -p ../test-documents/src/main/resources/documents/
```

2. Add files to be crawled:
```bash
echo "Your document content here" > ../test-documents/src/main/resources/documents/sample.txt
```

3. FSCrawler will automatically detect and index files

### 11. Verify Indexing

```bash
# Check indices
curl -k -u elastic:changeme "https://localhost:9200/_cat/indices"

# Search documents
curl -k -u elastic:changeme "https://localhost:9200/semantic_documents/_search?pretty"
```

## Testing Search Functionality

### 12. Traditional Keyword Search

```bash
curl -k -u elastic:changeme "https://localhost:9200/semantic_documents/_search?q=machine+learning&pretty"
```

### 13. Semantic Search

```bash
# Search for medical concepts
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" -H "Content-Type: application/json" -d '{
  "query": {
    "semantic": {
      "field": "content_semantic",
      "query": "medical diagnosis and treatment"
    }
  }
}'
```

```bash
# Search with different terminology
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" -H "Content-Type: application/json" -d '{
  "query": {
    "semantic": {
      "field": "content_semantic",
      "query": "working from home during COVID"
    }
  }
}'
```

### 14. Complex Queries

```bash
# Boolean query combining semantic and traditional search
curl -k -u elastic:changeme -X POST "https://localhost:9200/semantic_documents/_search?pretty" -H "Content-Type: application/json" -d '{
  "query": {
    "bool": {
      "should": [
        {
          "semantic": {
            "field": "content_semantic",
            "query": "artificial intelligence"
          }
        },
        {
          "match": {
            "tags": "AI"
          }
        }
      ]
    }
  }
}'
```

### 15. Direct Embedding Generation

```bash
# Test the inference endpoint directly
curl -k -u elastic:changeme -X POST "https://localhost:9200/_inference/text_embedding/my-e5-model" -H "Content-Type: application/json" -d '{
  "input": ["artificial intelligence in healthcare", "blockchain financial technology"]
}'
```

## Troubleshooting

### Common Issues

1. **Insufficient Memory Error**
   - Ensure MEM_LIMIT is set to at least 20GB
   - Check available system RAM

2. **ML Node Not Found**
   - Verify ML settings in docker-compose.yml
   - Check that the elasticsearch node has 'm' role

3. **SSL Certificate Issues**
   - Use `-k` flag with curl for self-signed certificates
   - Wait for setup container to complete

4. **FSCrawler Not Indexing**
   - Check volume mounts in docker-compose.yml
   - Verify file permissions
   - Review FSCrawler logs: `docker logs fscrawler`

5. **E5 Model Download Issues**
   - Ensure trial license is activated
   - Check ML memory allocation
   - Verify internet connectivity for model download

### Monitoring

```bash
# View logs
docker-compose logs -f elasticsearch
docker-compose logs -f fscrawler

# Check cluster health
curl -k -u elastic:changeme "https://localhost:9200/_cluster/health?pretty"

# Monitor ML deployments
curl -k -u elastic:changeme "https://localhost:9200/_ml/trained_models?pretty"
```

### Performance Tuning

For production environments, consider:

- Increasing heap size based on available memory
- Adjusting ML allocations and threads
- Setting up index templates for consistent mappings
- Configuring index lifecycle management
- Adding multiple Elasticsearch nodes for scaling

## Features Achieved

✅ **Full-text search** with Elasticsearch
✅ **Document crawling** with FSCrawler  
✅ **Semantic search** with E5 embeddings
✅ **SSL security** with self-signed certificates
✅ **ML capabilities** for natural language processing
✅ **REST API access** for programmatic integration
✅ **Kibana interface** for data visualization

## Next Steps

- Set up index templates for consistent mappings
- Configure index lifecycle management
- Add monitoring with Elastic APM
- Implement authentication with roles
- Scale with additional Elasticsearch nodes
- Integrate with applications via client libraries

---

## Configuration Summary

| Component | Memory | Purpose |
|-----------|---------|---------|
| Elasticsearch | 20GB | Search engine + ML models |
| Kibana | 8GB | Web interface |
| FSCrawler | Default | Document crawler |
| E5 Model | ~500MB | Semantic embeddings |

**Total Recommended RAM:** 30GB+ for optimal performance