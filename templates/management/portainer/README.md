# Portainer Container Management Template

Web-based Docker management interface for easy container administration.

## Features
- Complete Docker environment management through web UI
- Container, image, network, and volume management
- Docker Compose stack deployment and monitoring
- Multi-user support with role-based access control
- Real-time logs, stats, and system monitoring

## Usage
```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start Portainer
down  # Stop and cleanup
```

## Configuration
Edit `.env` to customize:
- `CONTAINER_NAME`: Container name (default: portainer)
- `PORTAINER_HTTP_PORT`: HTTP port (default: 9000)
- `PORTAINER_HTTPS_PORT`: HTTPS port (default: 9443)

## Initial Setup
1. Access Portainer via HTTP or HTTPS
2. Create admin account on first visit (required)
3. Select "Docker" environment to manage local Docker
4. Start managing containers, images, networks, and volumes

## Access
- **HTTP Port**: 9000 (Docker auto-assigns host port)
- **HTTPS Port**: 9443 (self-signed certificate)
- **Credentials**: Set on first access
- **Find assigned ports**: `docker compose ps`
- **Docker socket**: Full access to Docker daemon

## Security Notes
- Portainer requires full Docker socket access
- Always set a strong admin password on first setup
- Use HTTPS in production environments
- Limit network access in production deployments

## Resources
- [Docker Hub - Portainer CE](https://hub.docker.com/r/portainer/portainer-ce)
- [Official Documentation](https://docs.portainer.io/)
- [Installation Guide](https://docs.portainer.io/start/install-ce/server/docker/linux)