# WordPress Template

Full WordPress installation with MySQL database.

## Features
- Latest WordPress version
- MySQL 8.0 database backend
- Persistent storage for uploads and content
- Auto-restart on failure

## Usage
```bash
source Rediaccfile
up    # Start WordPress and MySQL
down  # Stop all services
```

## Access
- WordPress: http://localhost:8000
- Database: localhost:3306

## Default Credentials
- MySQL Root Password: somewordpress
- WordPress DB User: wordpress
- WordPress DB Password: wordpress
- WordPress DB Name: wordpress

## Setup
1. Run `up` to start services
2. Visit http://localhost:8000
3. Complete WordPress installation wizard
4. Your site is ready!

## Files in this template

- **README.md** - This documentation file
- **Rediaccfile** - Bash script with functions to manage WordPress and MySQL:
  - `prep()` - Pulls WordPress and MySQL images, creates data directories
  - `up()` - Starts both services using docker-compose
  - `down()` - Stops and removes all containers
- **docker-compose.yaml** - Docker Compose configuration with:
  - WordPress service with environment variables for database connection
  - MySQL 8.0 service with database initialization
  - Persistent volumes for both WordPress content and MySQL data
  - Auto-restart policy for reliability