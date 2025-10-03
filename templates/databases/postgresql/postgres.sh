#!/bin/bash
set -e

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set THREADS to CPU core count but cap at 8
if [ -z "$THREADS" ]; then
    THREADS=$(($(nproc) > 8 ? 8 : $(nproc)))
fi

# Detect container name from docker compose
CONTAINER_NAME=$(docker inspect $(docker compose ps -q db) --format '{{.Name}}' 2>/dev/null | sed 's/^\/*//')

# Extract the Docker-assigned port
PGPORT=$(docker port "$CONTAINER_NAME" 5432 2>/dev/null | cut -d: -f2)

# Fallback to default port if container is not running
: "${PGPORT:=5432}"

export PGHOST PGPORT PGUSER PGPASSWORD

# Function to install required packages for PostgreSQL sysbench testing
host_setup() {
    echo "Installing required packages for PostgreSQL sysbench testing..."

    # Update package list
    sudo apt-get update

    # Install PostgreSQL client tools
    sudo apt-get install -y postgresql-client

    # Install sysbench
    sudo apt-get install -y sysbench

    # Verify installations
    echo "Checking installed versions:"
    psql --version
    sysbench --version

    echo "Host setup completed successfully!"
    return $?
}

# Function to execute PostgreSQL commands using psql
pg_exec() {
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DBNAME" -c "$1"
}

# Function to check and create database if it does not exist
create_database() {
    if ! pg_exec "SELECT 1 FROM pg_database WHERE datname = '$DBNAME'" | grep -q 1; then
        echo "Database $DBNAME does not exist. Creating..."
        psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -c "CREATE DATABASE $DBNAME"
    else
        echo "Database $DBNAME already exists, not creating."
    fi
}

# Function to prepare the database for sysbench
initialize_sysbench() {
    sysbench /usr/share/sysbench/oltp_write_only.lua --db-driver=pgsql \
        --pgsql-host=$PGHOST --pgsql-port=$PGPORT --pgsql-user=$PGUSER --pgsql-password=$PGPASSWORD \
        --pgsql-db=$DBNAME --threads=$THREADS --tables=$TABLES --table-size=$TABLE_SIZE prepare
}

# Benchmark Query Per Second (QPS)
benchmark_qps() {
    echo "Starting Query Per Second (QPS) benchmark..."
    sysbench /usr/share/sysbench/oltp_point_select.lua --db-driver=pgsql \
        --pgsql-host="$PGHOST" --pgsql-port=$PGPORT --pgsql-user="$PGUSER" --pgsql-password="$PGPASSWORD" \
        --pgsql-db="$DBNAME" --threads="$THREADS" --tables="$TABLES" --table-size="$TABLE_SIZE" \
        --time=60 --report-interval=10 run
}

# Cleanup the database from sysbench
cleanup_sysbench() {
    sysbench /usr/share/sysbench/oltp_write_only.lua --db-driver=pgsql \
        --pgsql-host=$PGHOST --pgsql-port=$PGPORT --pgsql-user=$PGUSER --pgsql-password=$PGPASSWORD \
        --pgsql-db=$DBNAME --threads=$THREADS --tables=$TABLES --table-size=$TABLE_SIZE cleanup
}

# Create custom table with random data using bulk insert
# Usage: create_custom_table <table_name> [row_count] [table_type]
# Table types: users, products, orders, generic
# Example: create_custom_table my_users 100000 users
create_custom_table() {
    local table_name=${1:-"custom_table"}
    local row_count=${2:-10000}
    local table_type=${3:-"users"}

    echo "Creating custom table '$table_name' of type '$table_type' with $row_count rows..."

    # Drop existing table
    pg_exec "DROP TABLE IF EXISTS $table_name"

    case $table_type in
        "users")
            echo "Creating users table with bulk random data..."
            pg_exec "CREATE TABLE $table_name (
                id SERIAL PRIMARY KEY,
                name VARCHAR(50),
                email VARCHAR(100),
                age INTEGER,
                created_at TIMESTAMP DEFAULT NOW()
            )"

            # Bulk insert using PostgreSQL's generate_series and random functions
            pg_exec "INSERT INTO $table_name (name, email, age)
                SELECT
                    'User_' || (random() * 10000)::int,
                    'user' || generate_series || '@domain' || (random() * 10 + 1)::int || '.com',
                    (random() * 80 + 18)::int
                FROM generate_series(1, $row_count)"
            ;;

        "products")
            echo "Creating products table with bulk random data..."
            pg_exec "CREATE TABLE $table_name (
                id SERIAL PRIMARY KEY,
                product_name VARCHAR(100),
                price DECIMAL(10,2),
                category VARCHAR(50),
                in_stock BOOLEAN DEFAULT true,
                created_at TIMESTAMP DEFAULT NOW()
            )"

            pg_exec "INSERT INTO $table_name (product_name, price, category, in_stock)
                SELECT
                    'Product_' || generate_series,
                    (random() * 1000 + 10)::decimal(10,2),
                    'Category_' || (random() * 5 + 1)::int,
                    random() > 0.1
                FROM generate_series(1, $row_count)"
            ;;

        "orders")
            echo "Creating orders table with bulk random data..."
            pg_exec "CREATE TABLE $table_name (
                id SERIAL PRIMARY KEY,
                customer_id INTEGER,
                order_date TIMESTAMP DEFAULT NOW(),
                total_amount DECIMAL(12,2),
                status VARCHAR(20),
                notes TEXT
            )"

            pg_exec "INSERT INTO $table_name (customer_id, order_date, total_amount, status, notes)
                SELECT
                    (random() * 1000 + 1)::int,
                    NOW() - (random() * interval '365 days'),
                    (random() * 5000 + 50)::decimal(12,2),
                    CASE (random() * 4)::int
                        WHEN 0 THEN 'pending'
                        WHEN 1 THEN 'processing'
                        WHEN 2 THEN 'shipped'
                        ELSE 'delivered'
                    END,
                    'Order notes for #' || generate_series
                FROM generate_series(1, $row_count)"
            ;;

        *)
            echo "Creating generic table with bulk random data..."
            pg_exec "CREATE TABLE $table_name (
                id SERIAL PRIMARY KEY,
                data_field_1 VARCHAR(100),
                data_field_2 INTEGER,
                data_field_3 DECIMAL(10,2),
                created_at TIMESTAMP DEFAULT NOW()
            )"

            pg_exec "INSERT INTO $table_name (data_field_1, data_field_2, data_field_3)
                SELECT
                    'Data_' || generate_series,
                    (random() * 1000000)::int,
                    (random() * 10000)::decimal(10,2)
                FROM generate_series(1, $row_count)"
            ;;
    esac

    echo "Custom table '$table_name' created successfully with $row_count rows!"
    echo "Table structure:"
    pg_exec "\d $table_name"
    echo "Row count verification:"
    pg_exec "SELECT COUNT(*) FROM $table_name"
    echo "Sample data:"
    pg_exec "SELECT * FROM $table_name LIMIT 5"
}

