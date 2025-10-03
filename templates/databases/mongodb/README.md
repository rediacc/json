# MongoDB Database Template

NoSQL document database with optional web-based admin interface (Mongo Express).

## Features

- MongoDB 7.0 with authentication enabled
- Mongo Express web UI for database management
- Database initialization script support
- Persistent data storage with health checks

## Usage

```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start MongoDB and Mongo Express
down  # Stop and cleanup
```

## Configuration

Edit `.env` to customize:

**MongoDB Settings:**
- `CONTAINER_NAME`: Container name (default: mongodb-server)
- `MONGO_PORT`: MongoDB port (default: 27017)
- `MONGO_ROOT_USERNAME`: Root username (default: admin)
- `MONGO_ROOT_PASSWORD`: Root password (change this!)
- `MONGO_DATABASE`: Initial database name (default: myapp)

**Mongo Express Settings:**
- `ME_PORT`: Web UI port (default: 8081)
- `ME_USERNAME`: Web UI username (default: admin)
- `ME_PASSWORD`: Web UI password (change this!)

## Access

**MongoDB Connection:**
```bash
# Using mongosh client
mongosh "mongodb://admin:yourSecurePasswordHere123!@localhost:27017"

# Connection string for applications
mongodb://appuser:appPassword123!@localhost:27017/myapp
```

**Mongo Express Web UI:**
- URL: http://localhost:8081
- Credentials: Check `.env` file for `ME_USERNAME` and `ME_PASSWORD`

**Docker Shell Access:**
```bash
docker exec -it mongodb-server mongosh -u admin -p yourSecurePasswordHere123!
```

**Find Assigned Ports:**
```bash
docker compose ps
```

## Resources

- [MongoDB Docker Hub](https://hub.docker.com/_/mongo)
- [MongoDB Official Documentation](https://www.mongodb.com/docs/)
- [Mongo Express GitHub](https://github.com/mongo-express/mongo-express)