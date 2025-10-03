# Apache Kafka Streaming Platform Template

Distributed event streaming platform with Zookeeper, REST proxy, and Topics UI.

## Features

- Apache Kafka 7.5.0 (Confluent Platform) with single broker setup
- Zookeeper coordination service with persistent storage
- REST Proxy for HTTP-based Kafka operations
- Topics UI for visual management and monitoring
- Auto topic creation and configurable retention policies

## Usage

```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start Kafka cluster
down  # Stop and cleanup
```

## Configuration

Edit `.env` to customize:

- `ZOOKEEPER_PORT`: Zookeeper client port (default: 2181)
- `KAFKA_PORT`: Kafka broker port (default: 9092)
- `KAFKA_AUTO_CREATE_TOPICS`: Enable auto topic creation (default: true)
- `KAFKA_LOG_RETENTION_HOURS`: Message retention period (default: 168)
- `KAFKA_LOG_SEGMENT_BYTES`: Log segment size (default: 1073741824)
- `KAFKA_COMPRESSION_TYPE`: Message compression (default: producer)
- `KAFKA_REST_PORT`: REST Proxy port (default: 8082)
- `KAFKA_TOPICS_UI_PORT`: Topics UI port (default: 8000)

## Access

- **Kafka Broker**: Bootstrap server at `localhost:9092`
- **Topics UI**: `http://localhost:8000` - Browse topics, partitions, and messages
- **REST Proxy**: `http://localhost:8082` - HTTP API for Kafka operations
- **Find assigned ports**: `docker compose ps`

### Quick Start Examples

```bash
# Create and list topics
docker exec -it kafka-broker kafka-topics --create --topic test-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
docker exec -it kafka-broker kafka-topics --list --bootstrap-server localhost:9092

# Produce and consume messages
docker exec -it kafka-broker kafka-console-producer --topic test-topic --bootstrap-server localhost:9092
docker exec -it kafka-broker kafka-console-consumer --topic test-topic --from-beginning --bootstrap-server localhost:9092

# Using REST Proxy
curl http://localhost:8082/topics
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
  --data '{"records":[{"value":{"name":"test"}}]}' \
  http://localhost:8082/topics/test-topic
```

### Python Client

```python
from kafka import KafkaProducer, KafkaConsumer
import json

# Producer
producer = KafkaProducer(
    bootstrap_servers=['localhost:9092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)
producer.send('test-topic', {'key': 'value'})

# Consumer
consumer = KafkaConsumer('test-topic', bootstrap_servers=['localhost:9092'])
for message in consumer:
    print(message.value)
```

## Resources

- [Confluent Kafka Docker Hub](https://hub.docker.com/r/confluentinc/cp-kafka)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [Confluent Platform Documentation](https://docs.confluent.io/platform/current/overview.html)
- [Kafka REST Proxy API](https://docs.confluent.io/platform/current/kafka-rest/api.html)