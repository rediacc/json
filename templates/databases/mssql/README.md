# Microsoft SQL Server Template

Quick deployment of Microsoft SQL Server 2022 using Docker.

## Features
- SQL Server 2022 Developer Edition
- Persistent storage for data, logs, and secrets
- SQL Server Agent enabled
- Configurable SA password

## Usage
```bash
source Rediaccfile
prep  # Create necessary directories
up    # Start SQL Server
down  # Stop SQL Server
```

## Configuration
- Port: 1433 (customizable via MSSQL_PORT)
- Default SA password: yourStrong(!)Password
- Data persisted in: ./data, ./log, ./secrets

## Connect
```bash
sqlcmd -S localhost,1433 -U sa -P 'yourStrong(!)Password'
```

## Files in this template

- **README.md** - This documentation file
- **Rediaccfile** - Bash script with functions to manage the SQL Server container:
  - `prep()` - Pulls the SQL Server image and creates data directories
  - `up()` - Starts SQL Server using docker-compose
  - `down()` - Stops and removes the SQL Server container
- **docker-compose.yaml** - Docker Compose configuration for SQL Server with:
  - Environment variables from .env file
  - Port mapping for SQL Server (1433)
  - Volume mounts for data persistence
- **.env** - Environment variables file (create this with your configuration)