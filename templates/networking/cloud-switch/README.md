# Cloudflare Tunnel Template

Secure tunnel to expose local services via Cloudflare with demo Flask application.

## Features
- Cloudflare tunnel (cloudflared) integration
- Demo Flask web application with SQLite database
- Auto-polling web interface
- QUIC protocol optimization
- Automated tunnel management

## Components
- **Flask App**: Simple web app with database operations
- **Cloudflared**: Creates secure tunnel to Cloudflare network
- **Web Interface**: Real-time data display with auto-refresh

## Usage
```bash
source Rediaccfile
prep    # Build Docker image and set permissions
up      # Start services and create tunnel
down    # Stop services and cleanup tunnel
```

## Configuration
- Web App Port: 5000
- Tunnel configurable via NAMESPACE variable
- UDP buffer sizes optimized for QUIC

## Tunnel Management
The `tunnel.sh` script handles:
- Creating Cloudflare tunnels with unique names
- Configuring ingress rules
- Cleaning up tunnels on shutdown
- Automatic URL generation

## Demo Application
The included Flask app demonstrates:
- SQLite database integration
- REST API endpoints
- Dynamic data generation
- Web interface with periodic updates

## Files in this template

- **README.md** - This documentation file
- **Rediaccfile** - Main script with functions to manage the application:
  - `prep()` - Sets UDP buffer sizes, builds Docker image, sets up tunnel
  - `up()` - Starts the Flask application container
  - `down()` - Stops the container and cleans up tunnel
- **tunnel.sh** - Cloudflare tunnel management script with functions:
  - `setup()` - Initial Cloudflare authentication and configuration
  - `up()` - Creates and starts a Cloudflare tunnel
  - `down()` - Stops and deletes the tunnel
  - `get_tunnel_id()` - Retrieves tunnel ID by name
- **web/** - Flask application directory:
  - **Dockerfile** - Container configuration for Python Flask app
  - **app.py** - Flask application with SQLite database and API endpoints
  - **requirements.txt** - Python dependencies (Flask)