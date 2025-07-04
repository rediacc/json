# Portainer Container Management Template

Web-based Docker management interface for easy container administration.

## Features

- Portainer CE (Community Edition)
- Docker socket access for full control
- HTTPS support
- Persistent data storage
- Multi-user support
- Container logs and stats
- Image management
- Network and volume management

## Usage

```bash
# Prepare the environment (pull images, create volume)
./Rediaccfile prep

# Start Portainer
./Rediaccfile up

# Stop Portainer
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

- `CONTAINER_NAME`: Container name (default: portainer)
- `PORTAINER_HTTP_PORT`: HTTP port (default: 9000)
- `PORTAINER_HTTPS_PORT`: HTTPS port (default: 9443)

## Initial Setup

1. Access Portainer at http://localhost:9000
2. Create an admin account (required on first access)
3. Choose "Docker" environment (local)
4. Start managing your containers!

## Access

- HTTP: http://localhost:9000
- HTTPS: https://localhost:9443 (self-signed certificate)

## Features Overview

### Container Management
- Start/stop/restart containers
- View logs and stats
- Execute commands in containers
- Inspect container details
- Create new containers

### Image Management
- Pull images from registries
- Build images from Dockerfile
- Push images to registries
- Remove unused images

### Network Management
- Create custom networks
- Connect/disconnect containers
- Inspect network details

### Volume Management
- Create and manage volumes
- Browse volume contents
- Backup/restore volumes

### Stack Management
- Deploy Docker Compose stacks
- Manage stack services
- View stack logs

### System Information
- Docker version and info
- Resource usage
- Event logs
- Registry management

## Security Notes

- Portainer has full access to Docker socket
- Always set a strong admin password
- Consider using HTTPS in production
- Limit network access in production environments

## Advanced Configuration

### Using External TLS Certificates
Place your certificates in a volume and mount them:
```bash
docker run -d \
  --name portainer \
  -p 9443:9443 \
  -v /path/to/certs:/certs \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest \
  --sslcert /certs/cert.pem \
  --sslkey /certs/key.pem
```

### Restricting Container Access
Use Portainer's built-in RBAC (Role-Based Access Control) to:
- Create teams and users
- Assign specific permissions
- Limit container/stack access

## Files

- `Rediaccfile`: Main control script for Portainer operations
- `.env`: Environment variables and port configuration
- `portainer_data`: Docker volume for persistent data