# MongoDB Database Template

NoSQL document database with optional web-based admin interface (Mongo Express).

## Features

- MongoDB 7.0
- Mongo Express web UI
- Authentication enabled
- Persistent data storage
- Database initialization script
- Health checks
- Isolated network

## Usage

```bash
# Prepare the environment (pull images, create directories)
./Rediaccfile prep

# Start MongoDB and Mongo Express
./Rediaccfile up

# Stop all services
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

### MongoDB Settings
- `CONTAINER_NAME`: Container name (default: mongodb-server)
- `MONGO_PORT`: MongoDB port (default: 27017)
- `MONGO_ROOT_USERNAME`: Root username (default: admin)
- `MONGO_ROOT_PASSWORD`: Root password
- `MONGO_DATABASE`: Initial database name (default: myapp)

### Mongo Express Settings
- `ME_PORT`: Web UI port (default: 8081)
- `ME_USERNAME`: Web UI username (default: admin)
- `ME_PASSWORD`: Web UI password

## Access

### MongoDB Connection
```bash
# Using mongosh
mongosh "mongodb://admin:yourSecurePasswordHere123!@localhost:27017"

# Connection string for applications
mongodb://appuser:appPassword123!@localhost:27017/myapp
```

### Web Interface
- URL: http://localhost:8081
- Username: admin
- Password: expressPassword123!

### Using Docker
```bash
# Access MongoDB shell
docker exec -it mongodb-server mongosh -u admin -p yourSecurePasswordHere123!

# Run commands
use myapp
db.users.find()
```

## Files

- `Rediaccfile`: Main control script for MongoDB operations
- `docker-compose.yaml`: Container configuration for MongoDB and Mongo Express
- `.env`: Environment variables and credentials
- `init-mongo.js`: Database initialization script
- `data/`: Persistent storage directory (created on first run)