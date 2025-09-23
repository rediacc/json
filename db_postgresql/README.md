# PostgreSQL Template

High-performance PostgreSQL setup with benchmarking and automated configuration.

## Features
- **Dynamic Containers**: Auto-detected via Docker Compose  
- **Auto Port Assignment**: Uses available 32xxx ports  
- **CPU Optimization**: Auto-detects cores, max 8 threads  
- **Bulk Data Gen**: Fast table creation with realistic data  
- **Sysbench Integration**: OLTP benchmarks included  
- **One-Command Host Setup**: Installs required tools  

## Quick Start
```bash
# 1. Install tools
./postgres.sh host_setup

# 2. Start PostgreSQL
./Rediaccfile prep && ./Rediaccfile up

# 3. Init database
source ./postgres.sh
./postgres.sh create_database

# 4. Run benchmarks
./postgres.sh initialize_sysbench
./postgres.sh benchmark_qps
./postgres.sh cleanup_sysbench
```

### Custom Data
```bash
./postgres.sh create_custom_table my_users 100000 users
./postgres.sh create_custom_table inventory 50000 products
./postgres.sh create_custom_table sales 25000 orders
```
- **100K users**: ~1.4s (72K rows/s)  
- **50K products**: ~0.3s (147K rows/s)  
- **1M generic**: ~3–5s  

## Configuration
- Ports auto-detected  
- Threads = `min(CPU cores, 8)`  
- Container name auto-detected  

`.env` example:
```bash
PGHOST=127.0.0.1
PGUSER=postgres
PGPASSWORD=mysecretpassword
DBNAME=sysbench_test
TABLES=8
TABLE_SIZE=1000000
```

## Commands
**Rediaccfile**: `prep | up | down`  
**postgres.sh**:  
- `host_setup` – Install tools  
- `create_database` – Init DB  
- `initialize_sysbench` – Load 8×1M tables  
- `benchmark_qps` – Run QPS test  
- `cleanup_sysbench` – Remove test data  
- `create_custom_table <name> [rows] [type]` – Bulk insert  