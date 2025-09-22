# PostgreSQL Template

High-performance PostgreSQL database template with comprehensive benchmarking tools and dynamic configuration.

## Features
- **Dynamic Container Naming**: Automatic container detection from Docker Compose
- **Auto Port Assignment**: Docker automatically assigns available ports (32xxx range)
- **CPU-Optimized Threading**: Automatically detects CPU cores (max 8 threads)
- **Bulk Data Generation**: High-speed custom table creation with realistic test data
- **Integrated Sysbench**: Complete OLTP performance testing suite
- **Host Setup Automation**: One-command installation of required tools

## Quick Start

### 1. Install Required Tools
```bash
./postgres.sh host_setup  # Installs postgresql-client and sysbench
```

### 2. Start PostgreSQL
```bash
./Rediaccfile prep  # Pull image and create data directory
./Rediaccfile up    # Start PostgreSQL with dynamic port
```

### 3. Initialize Database
```bash
source ./postgres.sh           # Load environment and detect port
./postgres.sh create_database   # Create sysbench_test database
```

### 4. Run Benchmarks
```bash
# Standard sysbench performance tests
./postgres.sh initialize_sysbench  # Prepare benchmark tables
./postgres.sh benchmark_qps        # Run QPS benchmark
./postgres.sh cleanup_sysbench     # Clean up test data

# Create custom test data
./postgres.sh create_custom_table my_users 100000 users     # 100K users in ~1.4s
./postgres.sh create_custom_table inventory 50000 products  # 50K products in ~0.3s
./postgres.sh create_custom_table sales 25000 orders        # 25K orders with dates
```

## Dynamic Configuration

### Automatic Port Detection
- Docker assigns available ports (typically 32xxx range)
- `postgres.sh` automatically detects the assigned port
- No manual port configuration needed

### CPU-Optimized Performance
- Thread count automatically set to `min(CPU_cores, 8)`
- Optimizes performance without over-threading
- Current system: **24 cores → 8 threads** (optimal)

### Container Management
- Container name: `postgres_sysbench_template`
- Dynamically detected via `docker compose ps`
- No hardcoded dependencies

## Custom Table Creation

High-performance bulk insert using PostgreSQL's native functions:

### Table Types Available:
```bash
# Users table (id, name, email, age, created_at)
./postgres.sh create_custom_table my_users 100000 users

# Products table (id, product_name, price, category, in_stock, created_at)
./postgres.sh create_custom_table inventory 50000 products

# Orders table (id, customer_id, order_date, total_amount, status, notes)
./postgres.sh create_custom_table sales 25000 orders

# Generic table (id, data_field_1, data_field_2, data_field_3, created_at)
./postgres.sh create_custom_table test_data 1000000 generic
```

### Performance Benchmarks:
- **100,000 users**: ~1.4 seconds (72K rows/sec)
- **50,000 products**: ~0.3 seconds (147K rows/sec)
- **1,000,000 generic**: ~3-5 seconds

## Environment Variables

The `.env` file contains:
```bash
# PostgreSQL connection (port auto-detected)
PGHOST=127.0.0.1
PGUSER=postgres
PGPASSWORD=mysecretpassword
DBNAME=sysbench_test

# Sysbench configuration
TABLES=8
TABLE_SIZE=1000000
# THREADS - automatically set to CPU core count (max 8)
```

## Available Functions

### Rediaccfile Management:
- `./Rediaccfile prep` - Pull PostgreSQL image and create data directory
- `./Rediaccfile up` - Start PostgreSQL container with dynamic naming
- `./Rediaccfile down` - Stop and remove PostgreSQL container

### postgres.sh Functions:
- `host_setup` - Install postgresql-client and sysbench packages
- `create_database` - Create test database if it doesn't exist
- `initialize_sysbench` - Prepare sysbench tables (8 tables × 1M rows each)
- `benchmark_qps` - Run QPS (Queries Per Second) benchmark for 60 seconds
- `cleanup_sysbench` - Clean up sysbench test data
- `create_custom_table <name> [rows] [type]` - Create custom tables with bulk data

## Performance Testing Workflow

### Complete Sysbench Test:
```bash
./postgres.sh host_setup           # One-time setup
./Rediaccfile prep && ./Rediaccfile up
source ./postgres.sh               # Load dynamic config
./postgres.sh create_database
./postgres.sh initialize_sysbench  # ~2-3 minutes for 8M rows
./postgres.sh benchmark_qps        # 60-second benchmark
./postgres.sh cleanup_sysbench     # Clean up
```

### Custom Data Testing:
```bash
source ./postgres.sh
./postgres.sh create_custom_table test_users 500000 users    # 500K users
./postgres.sh create_custom_table test_products 250000 products
# Run your custom queries and tests
```

## System Requirements

- **Docker & Docker Compose**: Container orchestration
- **Linux/Unix Environment**: bash, nproc, standard utilities
- **Available Memory**: Recommended 2GB+ for large datasets
- **CPU**: Multi-core recommended (automatically optimized)

## Files Overview

- **README.md** - This comprehensive documentation
- **Rediaccfile** - Container management functions (prep, up, down)
- **docker-compose.yaml** - PostgreSQL service with dynamic container naming
- **postgres.sh** - Complete database automation and benchmarking suite
- **.env** - Environment configuration (auto-enhanced with dynamic values)

## Advanced Usage

### Multiple Concurrent Instances
Each template instance gets:
- Unique container name: `postgres_sysbench_template`
- Unique auto-assigned port: 32768, 32769, etc.
- Independent data directories and configurations

### Performance Tuning Tips
1. **Large Datasets**: Use `TABLE_SIZE=10000000` for 10M row tables
2. **Thread Optimization**: System automatically uses optimal thread count
3. **Custom Benchmarks**: Create specific table structures for your use case
4. **Memory Management**: Monitor Docker memory limits for large datasets

This template provides enterprise-grade PostgreSQL testing with minimal configuration and maximum performance.