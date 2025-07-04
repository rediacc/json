# PostgreSQL Template

PostgreSQL database with performance benchmarking tools.

## Features
- PostgreSQL database server
- Integrated sysbench for performance testing
- Automated benchmark scripts
- Persistent data storage

## Usage
```bash
source Rediaccfile
prep  # Create data directory
up    # Start PostgreSQL
down  # Stop PostgreSQL

# Benchmarking
source postgres.sh
create_db  # Create test database
benchmark  # Run performance tests
```

## Configuration
- Port: 5432 (customizable via POSTGRES_PORT)
- Default password: password
- Data directory: ./data

## Benchmarking
The included `postgres.sh` provides automated performance testing:
- QPS (Queries Per Second) measurement
- Sysbench OLTP read/write tests
- Automated test database creation and cleanup