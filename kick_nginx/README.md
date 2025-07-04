# Nginx Template

Minimal Nginx web server deployment.

## Features
- Latest Nginx stable release
- Quick deployment with single command
- Port 80 exposed for HTTP traffic

## Usage
```bash
source Rediaccfile
up    # Start Nginx server
down  # Stop Nginx server
```

## Configuration
- HTTP Port: 80
- Runs in detached mode
- Auto-removes container on stop

## Access
Open http://localhost in your browser to see the default Nginx welcome page.