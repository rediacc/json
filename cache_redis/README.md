# Redis Cache Template

High-performance, in-memory data structure store used as a database, cache, and message broker.

## Features

- Redis 7 Alpine (lightweight)
- Password authentication
- Configurable memory limits
- LRU eviction policy
- Persistent data storage
- Health checks
- Isolated network

## Usage

```bash
# Prepare the environment (pull images)
./Rediaccfile prep

# Start Redis server
./Rediaccfile up

# Stop Redis server
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

- `CONTAINER_NAME`: Container name (default: redis-server)
- `REDIS_PORT`: Port mapping (default: 6379)
- `REDIS_PASSWORD`: Authentication password (required)
- `REDIS_MAXMEMORY`: Memory limit (default: 256mb)
- `REDIS_MAXMEMORY_POLICY`: Eviction policy (default: allkeys-lru)

## Access

Connect to Redis:

```bash
# Using redis-cli
redis-cli -h localhost -p 6379 -a yourSecurePasswordHere123!

# Using Docker
docker exec -it redis-server redis-cli -a yourSecurePasswordHere123!
```

Common commands:
```
SET key value
GET key
INCR counter
LPUSH list value
HSET hash field value
```

## Files

- `Rediaccfile`: Main control script for Redis operations
- `docker-compose.yaml`: Container configuration
- `.env`: Environment variables and Redis settings
- `data/`: Persistent storage directory (created on first run)