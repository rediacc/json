# Prometheus + Grafana Monitoring Template

Complete monitoring stack with Prometheus metrics collection and Grafana visualization.

## Features

- Prometheus time-series database
- Grafana visualization platform
- Node Exporter for system metrics
- Pre-configured data source
- Persistent data storage
- Ready for custom metrics
- Isolated network

## Usage

```bash
# Prepare the environment (pull images, create directories)
./Rediaccfile prep

# Start monitoring stack
./Rediaccfile up

# Stop monitoring stack
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

### Prometheus Settings
- `PROMETHEUS_PORT`: Web UI port (default: 9090)
- `PROMETHEUS_RETENTION`: Data retention period (default: 15d)

### Grafana Settings
- `GRAFANA_PORT`: Web UI port (default: 3000)
- `GRAFANA_ADMIN_USER`: Admin username (default: admin)
- `GRAFANA_ADMIN_PASSWORD`: Admin password (default: admin)
- `GRAFANA_ALLOW_SIGN_UP`: Allow user registration (default: false)
- `GRAFANA_PLUGINS`: Comma-separated plugin list

### Node Exporter Settings
- `NODE_EXPORTER_PORT`: Metrics port (default: 9100)

## Access

### Prometheus
- URL: http://localhost:9090
- No authentication required
- Query metrics using PromQL

### Grafana
- URL: http://localhost:3000
- Username: admin
- Password: admin (change on first login)

### Node Exporter Metrics
- URL: http://localhost:9100/metrics
- Provides system-level metrics

## Adding Custom Metrics

### 1. Configure Prometheus Targets
Edit `prometheus/prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['host.docker.internal:8080']
```

### 2. Reload Prometheus Configuration
```bash
curl -X POST http://localhost:9090/-/reload
```

### 3. Expose Metrics in Your Application
Example (Python with prometheus_client):
```python
from prometheus_client import Counter, Histogram, generate_latest

# Define metrics
request_count = Counter('app_requests_total', 'Total requests')
request_duration = Histogram('app_request_duration_seconds', 'Request duration')

# Use in your app
@request_duration.time()
def handle_request():
    request_count.inc()
    # Your logic here
```

## Creating Grafana Dashboards

1. Login to Grafana at http://localhost:3000
2. Click "+" → "Create Dashboard"
3. Add panels with Prometheus queries:
   - CPU Usage: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
   - Memory Usage: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
   - Disk Usage: `100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)`

## Useful Prometheus Queries

```promql
# System metrics
up{job="node-exporter"}
node_load1
rate(node_cpu_seconds_total[5m])
node_memory_MemAvailable_bytes
node_filesystem_size_bytes

# Application metrics (example)
rate(http_requests_total[5m])
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

## Files

- `Rediaccfile`: Main control script
- `docker-compose.yaml`: Container configuration
- `.env`: Environment variables
- `prometheus/prometheus.yml`: Prometheus configuration
- `prometheus/data/`: Prometheus data storage
- `grafana/provisioning/`: Grafana auto-provisioning
- `grafana/data/`: Grafana data storage