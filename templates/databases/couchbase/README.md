# Couchbase NoSQL Database

Distributed NoSQL cloud database with enterprise-grade features including flexible JSON document model, powerful SQL-like query language (N1QL), full-text search, and built-in caching.

## Features

- Couchbase Server 7.6 with automatic cluster initialization
- N1QL query language (SQL for JSON) with query workbench
- Full-text search and secondary indexing
- Web-based administration console on port 8091
- Persistent data storage in `./data` directory

## Usage

```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start Couchbase Server
down  # Stop and cleanup
```

## Configuration

Edit `.env` to customize:

- `CONTAINER_NAME`: Container name (default: couchbase-server)
- `COUCHBASE_ADMINISTRATOR_USERNAME`: Admin username (default: Administrator)
- `COUCHBASE_ADMINISTRATOR_PASSWORD`: Admin password (change this!)
- `COUCHBASE_BUCKET`: Initial bucket name (default: default)
- `COUCHBASE_BUCKET_RAMSIZE`: Bucket RAM quota in MB (default: 512)
- `CLUSTER_RAMSIZE`: Data service RAM quota in MB (default: 2048)
- `INDEX_RAMSIZE`: Index service RAM quota in MB (default: 512)
- `FTS_RAMSIZE`: Full-text search RAM quota in MB (default: 512)

**System Requirements**: Minimum 4GB RAM, recommended 8GB+ for production.

## Access

- **Web Console**: Port 8091 (Docker auto-assigns host port)
- **Credentials**: See `COUCHBASE_ADMINISTRATOR_USERNAME` and `COUCHBASE_ADMINISTRATOR_PASSWORD` in `.env`
- **Find assigned port**: `docker compose ps`
- **Connection string**: `couchbase://localhost` or `couchbase://Administrator:password@localhost/default`

### CLI Access

```bash
# Couchbase CLI
docker exec -it couchbase-server couchbase-cli server-list -c localhost:8091 -u Administrator -p SecurePassword123!

# N1QL Query Shell
docker exec -it couchbase-server cbq -u Administrator -p SecurePassword123! -e couchbase://localhost
```

### Quick N1QL Examples

```sql
CREATE PRIMARY INDEX ON `default`;
INSERT INTO `default` (KEY, VALUE) VALUES ("user::1", {"name": "John", "age": 30});
SELECT * FROM `default` WHERE type = "user";
```

## Resources

- [Official Docker Hub](https://hub.docker.com/_/couchbase)
- [Couchbase Documentation](https://docs.couchbase.com/)
- [N1QL Query Language](https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/index.html)
