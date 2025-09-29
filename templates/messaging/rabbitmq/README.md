# RabbitMQ Message Queue Template

Advanced message queuing protocol (AMQP) broker with management interface.

## Features

- RabbitMQ 3 with Management Plugin
- Alpine-based (lightweight)
- Web-based management UI
- Configurable memory limits
- Persistent message storage
- Health checks
- Isolated network

## Usage

```bash
# Prepare the environment (pull images, create directories)
./Rediaccfile prep

# Start RabbitMQ server
./Rediaccfile up

# Stop RabbitMQ server
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

- `CONTAINER_NAME`: Container name (default: rabbitmq-server)
- `RABBITMQ_PORT`: AMQP port (default: 5672)
- `RABBITMQ_MANAGEMENT_PORT`: Management UI port (default: 15672)
- `RABBITMQ_DEFAULT_USER`: Admin username (default: admin)
- `RABBITMQ_DEFAULT_PASS`: Admin password
- `RABBITMQ_DEFAULT_VHOST`: Default virtual host (default: /)
- `RABBITMQ_MEMORY_LIMIT`: Memory high watermark (default: 0.4)

## Access

### Management UI
- URL: http://localhost:15672
- Username: admin
- Password: adminPassword123!

### AMQP Connection
```python
# Python example using pika
import pika

credentials = pika.PlainCredentials('admin', 'adminPassword123!')
connection = pika.BlockingConnection(
    pika.ConnectionParameters('localhost', 5672, '/', credentials)
)
channel = connection.channel()
```

### Using Docker
```bash
# Access RabbitMQ CLI
docker exec -it rabbitmq-server rabbitmqctl status

# List queues
docker exec -it rabbitmq-server rabbitmqctl list_queues

# Create a new user
docker exec -it rabbitmq-server rabbitmqctl add_user myuser mypassword
docker exec -it rabbitmq-server rabbitmqctl set_permissions -p / myuser ".*" ".*" ".*"
```

## Common Operations

### Queue Management
```bash
# Declare a queue
docker exec -it rabbitmq-server rabbitmqadmin declare queue name=myqueue durable=true

# List exchanges
docker exec -it rabbitmq-server rabbitmqadmin list exchanges

# Publish a message
docker exec -it rabbitmq-server rabbitmqadmin publish exchange=amq.default routing_key=myqueue payload="Hello World"
```

### Monitoring
```bash
# Check node health
docker exec -it rabbitmq-server rabbitmq-diagnostics check_running

# Memory usage
docker exec -it rabbitmq-server rabbitmq-diagnostics memory_breakdown
```

## Files

- `Rediaccfile`: Main control script for RabbitMQ operations
- `docker-compose.yaml`: Container configuration
- `.env`: Environment variables and credentials
- `rabbitmq.conf`: RabbitMQ configuration file
- `data/`: Persistent storage directory (created on first run)