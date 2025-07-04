# GitLab CE (Community Edition) Template

Self-hosted Git repository manager with CI/CD, issue tracking, and more.

## Features

- GitLab Community Edition (latest)
- Web-based Git repository management
- Built-in CI/CD pipelines
- Issue tracking and project management
- Wiki and documentation
- Container registry
- Merge requests and code review
- Persistent storage for all data

## Requirements

- **Minimum 4GB RAM** (8GB recommended)
- **2 CPU cores** (4 recommended)
- **10GB disk space** minimum

## Usage

```bash
# Prepare the environment (pull image, create directories)
./Rediaccfile prep

# Start GitLab CE
./Rediaccfile up

# Stop GitLab CE
./Rediaccfile down
```

## Configuration

Edit `.env` file to customize:

- `CONTAINER_NAME`: Container name (default: gitlab)
- `GITLAB_HOSTNAME`: Hostname for GitLab (default: localhost)
- `GITLAB_HTTP_PORT`: HTTP port (default: 80)
- `GITLAB_HTTPS_PORT`: HTTPS port (default: 443)
- `GITLAB_SSH_PORT`: SSH port for Git operations (default: 2222)
- `GITLAB_OMNIBUS_CONFIG`: Additional Omnibus GitLab configuration

## Initial Setup

1. Start GitLab with `./Rediaccfile up`
2. Wait 5-10 minutes for initial setup (monitor with `docker logs -f gitlab`)
3. Get the initial root password:
   ```bash
   docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
   ```
4. Access GitLab at http://localhost
5. Login with username `root` and the initial password
6. Change the root password immediately

## Access

### Web Interface
- URL: http://localhost (or configured port)
- Default username: root
- Initial password: See `./config/initial_root_password`

### Git SSH Access
```bash
# Clone via SSH (port 2222)
git clone ssh://git@localhost:2222/username/project.git

# Add SSH key to GitLab user settings first
```

### Git HTTP Access
```bash
# Clone via HTTP
git clone http://localhost/username/project.git
```

## Common Tasks

### Create a New Project
1. Login to GitLab web interface
2. Click "New project"
3. Choose "Create blank project"
4. Enter project name and settings
5. Clone and start coding!

### Enable Container Registry
Add to `GITLAB_OMNIBUS_CONFIG` in `.env`:
```
registry_external_url 'http://localhost:5000'; gitlab_rails['registry_enabled'] = true;
```

### Configure Email
Add to `GITLAB_OMNIBUS_CONFIG` in `.env`:
```
gitlab_rails['smtp_enable'] = true; gitlab_rails['smtp_address'] = 'smtp.gmail.com'; gitlab_rails['smtp_port'] = 587; gitlab_rails['smtp_user_name'] = 'your-email@gmail.com'; gitlab_rails['smtp_password'] = 'your-password'; gitlab_rails['smtp_authentication'] = 'login'; gitlab_rails['smtp_enable_starttls_auto'] = true;
```

### Backup GitLab
```bash
# Create backup
docker exec -t gitlab gitlab-backup create

# Backups stored in ./data/backups/
```

### Restore Backup
```bash
# Stop processes
docker exec -it gitlab gitlab-ctl stop puma
docker exec -it gitlab gitlab-ctl stop sidekiq

# Restore
docker exec -it gitlab gitlab-backup restore BACKUP=timestamp_of_backup

# Restart
docker exec -it gitlab gitlab-ctl restart
```

## Performance Tuning

### Reduce Memory Usage
Add to `GITLAB_OMNIBUS_CONFIG`:
```
postgresql['shared_buffers'] = '256MB'; postgresql['max_worker_processes'] = 8; sidekiq['concurrency'] = 5; prometheus_monitoring['enable'] = false;
```

### Disable Unused Services
Add to `GITLAB_OMNIBUS_CONFIG`:
```
grafana['enable'] = false; prometheus['enable'] = false; alertmanager['enable'] = false; node_exporter['enable'] = false;
```

## GitLab Runner

To add CI/CD runners:
```bash
# Install GitLab Runner
docker run -d --name gitlab-runner --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v gitlab-runner-config:/etc/gitlab-runner \
  gitlab/gitlab-runner:latest

# Register runner
docker exec -it gitlab-runner gitlab-runner register
# Follow prompts with GitLab URL and registration token
```

## Security Notes

- Change the root password immediately after first login
- The initial root password file is automatically deleted after 24 hours
- Enable 2FA for all users
- Regularly update GitLab for security patches
- Configure firewall rules for production use

## Files

- `Rediaccfile`: Main control script for GitLab operations
- `.env`: Environment variables and port configuration
- `config/`: GitLab configuration files
- `logs/`: GitLab logs
- `data/`: GitLab data (repositories, uploads, etc.)