# MySQL/MariaDB Template

MariaDB database with phpMyAdmin web interface.

## Features
- MariaDB 10.3 database server
- phpMyAdmin for web-based administration
- Persistent data storage
- Isolated Docker network

## Usage
```bash
source Rediaccfile
prep  # Create data directory and network
up    # Start MariaDB and phpMyAdmin
down  # Stop all services
```

## Access
- MySQL Port: 3306 (customizable via MYSQL_PORT)
- phpMyAdmin: http://localhost:8080 (customizable via PHPMYADMIN_PORT)
- Default root password: rootpassword

## Connect
```bash
mysql -h localhost -P 3306 -u root -prootpassword
```

## Files in this template

- **README.md** - This documentation file
- **Rediaccfile** - Bash script with functions to manage MariaDB and phpMyAdmin:
  - `prep()` - Pulls MariaDB and phpMyAdmin images, creates data directory
  - `up()` - Starts both services using docker-compose
  - `down()` - Stops and removes all containers
- **docker-compose.yaml** - Docker Compose configuration with:
  - MariaDB service with persistent storage
  - phpMyAdmin service for web-based database management
  - Custom Docker network for service isolation
  - Environment variables from .env file
- **.env** - Environment variables file (create this with your configuration)