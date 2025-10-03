# Kong API Gateway Template

Cloud-native, fast, scalable API gateway with admin UI.

## Features
- Full Kong API Gateway with PostgreSQL backend
- Konga admin UI for visual management
- Built-in plugins for auth, rate limiting, and transformations
- Load balancing and traffic control
- Health checks and monitoring support

## Usage
```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start Kong API Gateway
down  # Stop and cleanup
```

## Configuration
Edit `.env` to customize:
- `POSTGRES_DB`: Database name (default: kong)
- `POSTGRES_USER`: Database username (default: kong)
- `POSTGRES_PASSWORD`: Database password (default: kong)
- `KONG_PROXY_PORT`: HTTP proxy port (default: 8000)
- `KONG_ADMIN_PORT`: Admin API port (default: 8001)
- `KONGA_PORT`: Admin UI port (default: 1337)
- `KONGA_TOKEN_SECRET`: JWT secret for Konga sessions

## Access
- **Proxy (API Traffic)**: Port 8000/8443 (Docker auto-assigns host port)
- **Admin API**: Port 8001 (configure Kong via REST)
- **Konga UI**: Port 1337 (visual management interface)
- **Find assigned ports**: `docker compose ps`

### Quick Start Example
```bash
# Add a service and route
curl -X POST http://localhost:8001/services/ \
  --data "name=example" --data "url=http://httpbin.org"
curl -X POST http://localhost:8001/services/example/routes \
  --data "paths[]=/api"

# Test the route
curl http://localhost:8000/api/get

# Enable rate limiting plugin
curl -X POST http://localhost:8001/services/example/plugins \
  --data "name=rate-limiting" --data "config.minute=5"
```

### Using Konga
1. Open http://localhost:1337 and create admin account
2. Add connection: Name "Local Kong", URL "http://kong:8001"
3. Manage services, routes, consumers, and plugins visually

## Resources
- [Official Docker Hub](https://hub.docker.com/_/kong)
- [Kong Documentation](https://docs.konghq.com/)
- [Kong Plugin Hub](https://docs.konghq.com/hub/)
- [Konga GitHub](https://github.com/pantsel/konga)