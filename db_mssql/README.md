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