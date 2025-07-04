# Elasticsearch Search Engine Template

Full-text search and analytics engine with Kibana visualization interface.

## Features

- Elasticsearch 8.11.0
- Kibana 8.11.0 web UI
- Single-node configuration (development)
- Configurable heap size
- Security disabled by default
- Persistent data storage
- Health checks
- Isolated network

## Usage

```bash
# Prepare the environment (pull images, create directories)
./Rediaccfile prep

# Start Elasticsearch and Kibana
./Rediaccfile up

# Stop all services
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

### Elasticsearch Settings
- `CONTAINER_NAME`: Container name (default: elasticsearch)
- `ES_PORT`: HTTP API port (default: 9200)
- `ES_TRANSPORT_PORT`: Transport port (default: 9300)
- `ES_CLUSTER_NAME`: Cluster name (default: docker-cluster)
- `ES_HEAP_SIZE`: JVM heap size (default: 512m)
- `ES_SECURITY_ENABLED`: Enable security (default: false)

### Kibana Settings
- `KIBANA_PORT`: Web UI port (default: 5601)
- `KIBANA_SERVER_NAME`: Server name (default: kibana)

## Access

### Elasticsearch API
```bash
# Check cluster health
curl http://localhost:9200/_cluster/health?pretty

# Get cluster info
curl http://localhost:9200/

# Create an index
curl -X PUT "localhost:9200/my-index" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}'

# Index a document
curl -X POST "localhost:9200/my-index/_doc" -H 'Content-Type: application/json' -d'
{
  "title": "Sample Document",
  "content": "This is a test document for Elasticsearch"
}'

# Search documents
curl -X GET "localhost:9200/my-index/_search?q=test&pretty"
```

### Kibana Web Interface
- URL: http://localhost:5601
- No authentication required (security disabled)

## Common Operations

### Index Management
```bash
# List all indices
curl http://localhost:9200/_cat/indices?v

# Delete an index
curl -X DELETE "localhost:9200/my-index"
```

### Bulk Operations
```bash
# Bulk index documents
curl -X POST "localhost:9200/_bulk" -H 'Content-Type: application/json' -d'
{"index":{"_index":"test","_id":"1"}}
{"name":"John Doe","age":30}
{"index":{"_index":"test","_id":"2"}}
{"name":"Jane Smith","age":25}
'
```

## Files

- `Rediaccfile`: Main control script for Elasticsearch operations
- `docker-compose.yaml`: Container configuration for Elasticsearch and Kibana
- `.env`: Environment variables and settings
- `data/`: Persistent storage directory (created on first run)