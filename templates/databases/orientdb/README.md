# OrientDB Multi-Model Database

Multi-model database supporting graph, document, key/value, and object models with a built-in Studio web interface.

## Features

- Multi-model support (graph, document, key/value, object)
- OrientDB Studio web interface for database management
- Binary protocol (2424) and HTTP REST API (2480)
- Persistent storage for databases, backups, and configuration
- Built-in authentication and health checks

## Usage

```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start OrientDB server
down  # Stop and cleanup
```

## Configuration

Edit `.env` to customize:
- `CONTAINER_NAME`: Container name (default: orientdb-server)
- `ORIENTDB_ROOT_PASSWORD`: Root user password (required for security)

Data is persisted in:
- `./databases/`: Database files
- `./backup/`: Backup files
- `./config/`: Configuration files (optional)

## Access

### OrientDB Studio (Web Interface)
- **Port**: 2480 (Docker auto-assigns host port)
- **Username**: root
- **Password**: Check `.env` file
- **Find assigned port**: `docker compose ps`

### Binary Protocol Connection
- **Port**: 2424 (Docker auto-assigns host port)
- **Connection string**: `remote:localhost/mydb`
- **Credentials**: root / (password from `.env`)

### Docker Console
```bash
# Access OrientDB console
docker exec -it orientdb-server /orientdb/bin/console.sh

# Create database
docker exec -it orientdb-server /orientdb/bin/console.sh \
  "CREATE DATABASE remote:localhost/mydb root yourPassword plocal graph"

# Backup database
docker exec -it orientdb-server /orientdb/bin/console.sh \
  "CONNECT remote:localhost/mydb root yourPassword; \
   BACKUP DATABASE /orientdb/backup/mydb-backup.zip"
```

### REST API Examples
```bash
# List databases
curl -u root:yourPassword http://localhost:2480/listDatabases

# Query database
curl -u root:yourPassword \
  -H "Content-Type: application/json" \
  http://localhost:2480/command/mydb/sql \
  -d '{"command":"SELECT FROM V"}'
```

## Resources

- [Docker Hub - OrientDB](https://hub.docker.com/_/orientdb)
- [OrientDB Documentation](https://orientdb.org/docs/3.2.x/)
- [OrientDB SQL Reference](https://orientdb.org/docs/3.2.x/sql/)
- [OrientDB Studio Guide](https://orientdb.org/docs/3.2.x/studio/)
