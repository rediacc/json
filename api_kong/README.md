# Kong API Gateway Template

Cloud-native, fast, scalable API gateway with admin UI.

## Features

- Kong API Gateway (latest)
- PostgreSQL 13 database backend
- Konga admin UI
- Load balancing
- Rate limiting
- Authentication & authorization
- Request/response transformations
- Analytics & monitoring
- Plugin ecosystem
- Health checks

## Usage

```bash
# Prepare the environment (pull images, create network)
./Rediaccfile prep

# Start Kong API Gateway
./Rediaccfile up

# Stop all services
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

### Database Settings
- `POSTGRES_DB`: Database name (default: kong)
- `POSTGRES_USER`: Database username (default: kong)
- `POSTGRES_PASSWORD`: Database password (default: kong)

### Kong Ports
- `KONG_PROXY_PORT`: HTTP proxy port (default: 8000)
- `KONG_PROXY_SSL_PORT`: HTTPS proxy port (default: 8443)
- `KONG_ADMIN_PORT`: Admin API port (default: 8001)
- `KONG_ADMIN_SSL_PORT`: Admin API SSL port (default: 8444)

### Konga Settings
- `KONGA_PORT`: Admin UI port (default: 1337)
- `KONGA_TOKEN_SECRET`: JWT secret for Konga

## Access

### Kong Proxy
- HTTP: http://localhost:8000
- HTTPS: https://localhost:8443
- This is where your API traffic goes

### Kong Admin API
- URL: http://localhost:8001
- Used for configuring Kong

### Konga Admin UI
- URL: http://localhost:1337
- Visual interface for Kong management
- Create admin account on first access

## Quick Start Examples

### 1. Add a Service
```bash
curl -i -X POST http://localhost:8001/services/ \
  --data "name=example-service" \
  --data "url=http://httpbin.org"
```

### 2. Add a Route
```bash
curl -i -X POST http://localhost:8001/services/example-service/routes \
  --data "paths[]=/example"
```

### 3. Test the Route
```bash
curl -i http://localhost:8000/example/get
```

### 4. Enable Rate Limiting
```bash
curl -i -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=5" \
  --data "config.policy=local"
```

## Common Plugins

### Authentication

**Basic Auth:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=basic-auth"
```

**JWT:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=jwt"
```

**API Key:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=key-auth"
```

### Security

**CORS:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET,POST"
```

**IP Restriction:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=ip-restriction" \
  --data "config.allow=192.168.1.0/24"
```

### Traffic Control

**Rate Limiting:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=rate-limiting" \
  --data "config.second=5" \
  --data "config.hour=10000"
```

**Request Size Limiting:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=request-size-limiting" \
  --data "config.allowed_payload_size=128"
```

### Transformations

**Request Transformer:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=request-transformer" \
  --data "config.add.headers=X-Custom-Header:value"
```

**Response Transformer:**
```bash
curl -X POST http://localhost:8001/services/example-service/plugins \
  --data "name=response-transformer" \
  --data "config.add.headers=X-Another-Header:value"
```

## Load Balancing

Create an upstream:
```bash
curl -X POST http://localhost:8001/upstreams \
  --data "name=example-upstream"

# Add targets
curl -X POST http://localhost:8001/upstreams/example-upstream/targets \
  --data "target=server1.example.com:80" \
  --data "weight=100"

curl -X POST http://localhost:8001/upstreams/example-upstream/targets \
  --data "target=server2.example.com:80" \
  --data "weight=100"

# Create service using upstream
curl -X POST http://localhost:8001/services/ \
  --data "name=load-balanced-service" \
  --data "host=example-upstream" \
  --data "port=80"
```

## Using Konga Admin UI

1. Access http://localhost:1337
2. Create admin account
3. Add Kong connection:
   - Name: Local Kong
   - Kong Admin URL: http://kong:8001
4. Manage services, routes, and plugins visually

## Backup and Restore

### Backup Configuration
```bash
# Export all Kong configuration
curl -X GET http://localhost:8001/ | jq . > kong-backup.json

# Export specific entities
curl -X GET http://localhost:8001/services | jq . > services-backup.json
curl -X GET http://localhost:8001/routes | jq . > routes-backup.json
curl -X GET http://localhost:8001/plugins | jq . > plugins-backup.json
```

### Restore Configuration
Use declarative configuration or restore via Admin API.

## Monitoring

### Health Checks
```bash
# Kong health
curl http://localhost:8001/status

# Database connectivity
curl http://localhost:8001/status/database
```

### Metrics
Enable Prometheus plugin:
```bash
curl -X POST http://localhost:8001/plugins \
  --data "name=prometheus"

# Access metrics
curl http://localhost:8001/metrics
```

## Production Considerations

- Use Kong cluster mode for high availability
- Enable SSL/TLS for all endpoints
- Implement proper authentication
- Regular backups of configuration
- Monitor performance metrics
- Use external PostgreSQL cluster
- Configure proper logging

## Files

- `Rediaccfile`: Main control script for Kong operations
- `docker-compose.yaml`: Container configuration
- `.env`: Environment variables and settings
- `data/`: PostgreSQL data directory