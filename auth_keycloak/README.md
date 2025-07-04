# Keycloak Authentication Template

Open-source identity and access management solution with SSO support.

## Features

- Keycloak (latest version)
- PostgreSQL 15 database backend
- Single Sign-On (SSO)
- Identity brokering and social login
- User federation (LDAP, Active Directory)
- Fine-grained authorization
- Admin console and account management
- Health checks and metrics
- Persistent storage

## Usage

```bash
# Prepare the environment (pull images, create directories)
./Rediaccfile prep

# Start Keycloak with PostgreSQL
./Rediaccfile up

# Stop all services
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

### Database Settings
- `DB_DATABASE`: Database name (default: keycloak)
- `DB_USER`: Database username (default: keycloak)
- `DB_PASSWORD`: Database password (default: keycloak)

### Keycloak Settings
- `KEYCLOAK_PORT`: HTTP port (default: 8080)
- `KEYCLOAK_HTTPS_PORT`: HTTPS port (default: 8443)
- `KEYCLOAK_ADMIN`: Admin username (default: admin)
- `KEYCLOAK_ADMIN_PASSWORD`: Admin password (default: admin)

### Hostname Settings
- `KC_HOSTNAME`: Public hostname (default: localhost)
- `KC_HOSTNAME_STRICT`: Strict hostname checking (default: false)
- `KC_PROXY`: Proxy mode for reverse proxy setups (default: edge)

## Access

### Admin Console
- URL: http://localhost:8080/admin
- Username: admin
- Password: admin

### Account Console
- URL: http://localhost:8080/realms/{realm}/account
- Users can manage their own accounts

### Health Endpoints
- Ready: http://localhost:8080/health/ready
- Live: http://localhost:8080/health/live
- Metrics: http://localhost:8080/metrics

## Quick Start Guide

### 1. Create a Realm
1. Login to admin console
2. Click "Create Realm"
3. Enter realm name (e.g., "my-app")
4. Click "Create"

### 2. Create a Client
1. Go to Clients → Create client
2. Client type: OpenID Connect
3. Client ID: my-app-client
4. Click Next → Next → Save

### 3. Create a User
1. Go to Users → Add user
2. Fill in username and email
3. Click "Create"
4. Go to Credentials tab
5. Set password and toggle "Temporary" off

### 4. Test Login
```bash
# Get access token
curl -X POST "http://localhost:8080/realms/my-app/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser" \
  -d "password=password" \
  -d "grant_type=password" \
  -d "client_id=my-app-client"
```

## Integration Examples

### Spring Boot Integration
```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8080/realms/my-app
```

### Node.js Integration
```javascript
const Keycloak = require('keycloak-connect');

const keycloak = new Keycloak({}, {
  realm: 'my-app',
  'auth-server-url': 'http://localhost:8080/',
  'ssl-required': 'external',
  resource: 'my-app-client',
  'public-client': true
});
```

### React Integration
```javascript
import Keycloak from 'keycloak-js';

const keycloak = new Keycloak({
  url: 'http://localhost:8080',
  realm: 'my-app',
  clientId: 'my-app-client'
});

keycloak.init({ onLoad: 'login-required' });
```

## Common Configurations

### Enable HTTPS
1. Generate or obtain SSL certificates
2. Mount certificates in container
3. Set environment variables:
```env
KC_HTTPS_CERTIFICATE_FILE=/path/to/cert.pem
KC_HTTPS_CERTIFICATE_KEY_FILE=/path/to/key.pem
```

### Configure Email
1. Go to Realm Settings → Email
2. Configure SMTP settings:
   - Host: smtp.gmail.com
   - Port: 587
   - From: your-email@gmail.com
   - Enable StartTLS
   - Set authentication

### Enable Social Login
1. Go to Identity Providers
2. Add provider (Google, Facebook, GitHub, etc.)
3. Configure with OAuth app credentials
4. Map attributes as needed

### LDAP Integration
1. Go to User Federation → Add provider → LDAP
2. Configure connection settings
3. Set up attribute mappings
4. Configure sync settings

## Backup and Restore

### Export Realm
```bash
docker exec -it keycloak /opt/keycloak/bin/kc.sh export \
  --file /tmp/realm-export.json \
  --realm my-app

docker cp keycloak:/tmp/realm-export.json ./realm-backup.json
```

### Import Realm
```bash
docker cp ./realm-backup.json keycloak:/tmp/realm-import.json

docker exec -it keycloak /opt/keycloak/bin/kc.sh import \
  --file /tmp/realm-import.json
```

## Security Best Practices

- Change default admin password immediately
- Use HTTPS in production
- Enable brute force detection
- Configure password policies
- Set up proper CORS settings
- Regular security updates
- Enable 2FA for admin accounts

## Files

- `Rediaccfile`: Main control script for Keycloak operations
- `docker-compose.yaml`: Container configuration
- `.env`: Environment variables and settings
- `data/`: PostgreSQL data directory