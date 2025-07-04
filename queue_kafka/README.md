# Apache Kafka Streaming Platform Template

Distributed event streaming platform with Zookeeper, REST proxy, and Topics UI.

## Features

- Apache Kafka 7.5.0 (Confluent)
- Zookeeper for coordination
- Kafka REST Proxy for HTTP access
- Kafka Topics UI for visualization
- Single broker configuration (development)
- Persistent data storage
- Auto topic creation
- Health checks

## Usage

```bash
# Prepare the environment (pull images, create directories)
./Rediaccfile prep

# Start Kafka cluster
./Rediaccfile up

# Stop Kafka cluster
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

### Zookeeper Settings
- `ZOOKEEPER_PORT`: Client port (default: 2181)

### Kafka Broker Settings
- `KAFKA_PORT`: Broker port (default: 9092)
- `KAFKA_AUTO_CREATE_TOPICS`: Auto-create topics (default: true)
- `KAFKA_LOG_RETENTION_HOURS`: Message retention time (default: 168 hours)
- `KAFKA_LOG_SEGMENT_BYTES`: Log segment size (default: 1GB)
- `KAFKA_COMPRESSION_TYPE`: Compression type (default: producer)

### Kafka REST Proxy Settings
- `KAFKA_REST_PORT`: REST API port (default: 8082)

### Kafka Topics UI Settings
- `KAFKA_TOPICS_UI_PORT`: Web UI port (default: 8000)

## Access

### Kafka Broker
- Bootstrap server: localhost:9092

### Kafka Topics UI
- URL: http://localhost:8000
- Browse topics, partitions, and messages

### REST Proxy
- URL: http://localhost:8082
- HTTP API for Kafka operations

## Client Examples

### Using Kafka CLI Tools
```bash
# Create a topic
docker exec -it kafka-broker kafka-topics --create --topic test-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# List topics
docker exec -it kafka-broker kafka-topics --list --bootstrap-server localhost:9092

# Produce messages
docker exec -it kafka-broker kafka-console-producer --topic test-topic --bootstrap-server localhost:9092
# Type messages and press Enter, Ctrl+C to exit

# Consume messages
docker exec -it kafka-broker kafka-console-consumer --topic test-topic --from-beginning --bootstrap-server localhost:9092
```

### Using REST Proxy
```bash
# Get topics
curl http://localhost:8082/topics

# Produce a message
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records":[{"value":{"name":"test","value":123}}]}' \
  http://localhost:8082/topics/test-topic

# Create a consumer
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
  --data '{"name": "my_consumer", "format": "json", "auto.offset.reset": "earliest"}' \
  http://localhost:8082/consumers/my_consumer_group

# Subscribe to topic
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
  --data '{"topics":["test-topic"]}' \
  http://localhost:8082/consumers/my_consumer_group/instances/my_consumer/subscription

# Consume messages
curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
  http://localhost:8082/consumers/my_consumer_group/instances/my_consumer/records
```

### Python Client Example
```python
from kafka import KafkaProducer, KafkaConsumer
import json

# Producer
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)
producer.send('test-topic', {'key': 'value'})
producer.flush()

# Consumer
consumer = KafkaConsumer(
    'test-topic',
    bootstrap_servers=['localhost:9092'],
    auto_offset_reset='earliest',
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)
for message in consumer:
    print(message.value)
```

## Common Operations

### Topic Management
```bash
# Delete a topic
docker exec -it kafka-broker kafka-topics --delete --topic test-topic --bootstrap-server localhost:9092

# Describe topic
docker exec -it kafka-broker kafka-topics --describe --topic test-topic --bootstrap-server localhost:9092

# Alter topic partitions
docker exec -it kafka-broker kafka-topics --alter --topic test-topic --partitions 5 --bootstrap-server localhost:9092
```

### Consumer Groups
```bash
# List consumer groups
docker exec -it kafka-broker kafka-consumer-groups --list --bootstrap-server localhost:9092

# Describe consumer group
docker exec -it kafka-broker kafka-consumer-groups --describe --group my-group --bootstrap-server localhost:9092

# Reset consumer group offset
docker exec -it kafka-broker kafka-consumer-groups --reset-offsets --group my-group --topic test-topic --to-earliest --execute --bootstrap-server localhost:9092
```

## Files

- `Rediaccfile`: Main control script for Kafka operations
- `docker-compose.yaml`: Container configuration for entire Kafka stack
- `.env`: Environment variables and settings
- `data/`: Persistent storage directories for Kafka and Zookeeper