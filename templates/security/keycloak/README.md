# Keycloak Authentication Template

Open-source identity and access management solution with SSO support.

## Features

- Single Sign-On (SSO) and identity brokering
- User federation (LDAP, Active Directory, social login)
- Fine-grained authorization with role-based access control
- PostgreSQL 15 backend with persistent storage
- Built-in admin console and account management

## Usage

```bash
source Rediaccfile
prep  # Pull images and create directories
up    # Start Keycloak with PostgreSQL
down  # Stop and cleanup
```

## Configuration

Edit `.env` to customize:

- `KEYCLOAK_ADMIN`: Admin username (default: admin)
- `KEYCLOAK_ADMIN_PASSWORD`: Admin password (default: admin)
- `DB_DATABASE`: Database name (default: keycloak)
- `DB_USER`: Database username (default: keycloak)
- `DB_PASSWORD`: Database password (default: keycloak)
- `KC_HOSTNAME`: Public hostname (default: localhost)
- `KC_PROXY`: Proxy mode for reverse proxy setups (default: edge)

## Access

- **Admin Console**: Port 8080 (Docker auto-assigns host port) - `/admin`
- **Account Console**: `/realms/{realm}/account`
- **Health Endpoints**: `/health/ready`, `/health/live`, `/metrics`
- **Credentials**: Check `.env` file (default: admin/admin)
- **Find assigned port**: `docker compose ps`

## Quick Setup

1. **Create a Realm**: Admin Console → Create Realm → Enter name → Create
2. **Create a Client**: Clients → Create client → Set Client ID → Save
3. **Create a User**: Users → Add user → Set username/email → Create → Set password in Credentials tab
4. **Test Login**: Use OAuth2/OIDC token endpoint with client credentials

For detailed configuration (HTTPS, email, social login, LDAP, backup/restore), see the [official documentation](https://www.keycloak.org/documentation).

## Security Notes

- Change default admin password immediately
- Use HTTPS in production environments
- Enable brute force detection and 2FA for admin accounts
- Configure proper password policies and CORS settings

## Resources

- [Official Docker Hub](https://hub.docker.com/r/keycloak/keycloak)
- [Official Documentation](https://www.keycloak.org/documentation)
- [Getting Started Guide](https://www.keycloak.org/getting-started)
- [Server Administration](https://www.keycloak.org/docs/latest/server_admin/)