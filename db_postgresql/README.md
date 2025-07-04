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

## Files in this template

- **README.md** - This documentation file
- **Rediaccfile** - Bash script with functions to manage PostgreSQL:
  - `prep()` - Pulls PostgreSQL image and creates data directory
  - `up()` - Starts PostgreSQL using docker-compose
  - `down()` - Stops and removes the PostgreSQL container
- **docker-compose.yaml** - Docker Compose configuration for PostgreSQL with:
  - Environment variables from .env file
  - Port mapping for PostgreSQL (5432)
  - Volume mount for data persistence
- **postgres.sh** - Performance benchmarking script with functions:
  - `create_database()` - Creates test database if it doesn't exist
  - `initialize_sysbench()` - Prepares database for benchmarking
  - `benchmark_qps()` - Runs QPS (Queries Per Second) benchmark
  - `cleanup_sysbench()` - Cleans up benchmark data
- **.env** - Environment variables file (create this with your configuration)