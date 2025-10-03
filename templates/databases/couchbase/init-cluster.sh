#!/bin/bash
set -e

# Couchbase Cluster Initialization Script
# This script automatically configures a single-node Couchbase cluster

echo "Waiting for Couchbase Server to be ready..."

# Wait for Couchbase to be available (max 2 minutes)
TIMEOUT=120
ELAPSED=0
until curl -s http://localhost:8091/pools > /dev/null 2>&1; do
    sleep 2
    ELAPSED=$((ELAPSED + 2))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERROR: Couchbase Server did not start within ${TIMEOUT} seconds"
        exit 1
    fi
    echo "Waiting... (${ELAPSED}s/${TIMEOUT}s)"
done

echo "Couchbase Server is ready!"

# Check if cluster is already initialized
if curl -s http://localhost:8091/pools/default | grep -q "Unauthorized"; then
    echo "Cluster already initialized, skipping setup"
    exit 0
fi

# Load environment variables
source /docker-entrypoint-initdb.d/.env 2>/dev/null || true

# Set defaults if not provided
COUCHBASE_ADMINISTRATOR_USERNAME=${COUCHBASE_ADMINISTRATOR_USERNAME:-Administrator}
COUCHBASE_ADMINISTRATOR_PASSWORD=${COUCHBASE_ADMINISTRATOR_PASSWORD:-password}
COUCHBASE_BUCKET=${COUCHBASE_BUCKET:-default}
COUCHBASE_BUCKET_RAMSIZE=${COUCHBASE_BUCKET_RAMSIZE:-512}
CLUSTER_RAMSIZE=${CLUSTER_RAMSIZE:-2048}
INDEX_RAMSIZE=${INDEX_RAMSIZE:-512}
FTS_RAMSIZE=${FTS_RAMSIZE:-512}

echo "Initializing Couchbase cluster..."

# Initialize the cluster
/opt/couchbase/bin/couchbase-cli cluster-init \
    --cluster localhost:8091 \
    --cluster-username "${COUCHBASE_ADMINISTRATOR_USERNAME}" \
    --cluster-password "${COUCHBASE_ADMINISTRATOR_PASSWORD}" \
    --services data,index,query,fts \
    --cluster-ramsize "${CLUSTER_RAMSIZE}" \
    --cluster-index-ramsize "${INDEX_RAMSIZE}" \
    --cluster-fts-ramsize "${FTS_RAMSIZE}" \
    --cluster-name "DockerCluster" \
    --index-storage-setting default

if [ $? -eq 0 ]; then
    echo "Cluster initialization successful!"
else
    echo "ERROR: Cluster initialization failed"
    exit 1
fi

# Wait a moment for cluster to stabilize
sleep 5

# Create default bucket
echo "Creating bucket: ${COUCHBASE_BUCKET}..."

/opt/couchbase/bin/couchbase-cli bucket-create \
    --cluster localhost:8091 \
    --username "${COUCHBASE_ADMINISTRATOR_USERNAME}" \
    --password "${COUCHBASE_ADMINISTRATOR_PASSWORD}" \
    --bucket "${COUCHBASE_BUCKET}" \
    --bucket-type couchbase \
    --bucket-ramsize "${COUCHBASE_BUCKET_RAMSIZE}" \
    --bucket-replica 0 \
    --wait

if [ $? -eq 0 ]; then
    echo "Bucket '${COUCHBASE_BUCKET}' created successfully!"
else
    echo "WARNING: Bucket creation may have failed or bucket already exists"
fi

# Wait for bucket to be ready
sleep 5

# Create a primary index for N1QL queries
echo "Creating primary index for bucket: ${COUCHBASE_BUCKET}..."

/opt/couchbase/bin/cbq \
    -u "${COUCHBASE_ADMINISTRATOR_USERNAME}" \
    -p "${COUCHBASE_ADMINISTRATOR_PASSWORD}" \
    -e "http://localhost:8093" \
    --script="CREATE PRIMARY INDEX ON \`${COUCHBASE_BUCKET}\`" || echo "Primary index may already exist"

echo "Couchbase cluster setup complete!"
echo "Access the web console at: http://localhost:8091"
echo "Username: ${COUCHBASE_ADMINISTRATOR_USERNAME}"
