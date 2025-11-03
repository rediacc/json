# Template Catalog

Self-contained infrastructure template repository with GitHub Pages catalog.

**Live Catalog:** https://json.rediacc.com

## Usage

```bash
./generate.sh
```

Generates:
- Interactive website at `build/index.html`
- JSON catalog at `build/catalog.json`
- Individual template JSON files in `build/templates/`

## GitHub Pages

This repository automatically deploys to GitHub Pages via GitHub Actions.

## Testing Templates

### Automated Testing

All templates are automatically tested in CI via GitHub Actions. The test script validates each template's lifecycle:

1. **prep()** - Verifies image pulls and directory creation (4 minute timeout)
2. **up()** - Starts services with docker compose (4 minute timeout)
3. **Health Checks** - Monitors container health (2 minute timeout if defined)
4. **down()** - Stops services and cleans up volumes (4 minute timeout)

Functions that timeout will be reported with specific timeout errors.

### Running Tests Locally

```bash
# Test all templates
./test-templates.sh

# Test specific category
./test-templates.sh --category databases

# Test specific template
./test-templates.sh --template databases/postgresql

# Skip problematic templates
./test-templates.sh --skip databases/mssql --skip databases/crate

# Verbose output for debugging
./test-templates.sh --verbose

# Keep Docker images for debugging (don't cleanup)
./test-templates.sh --no-cleanup
```

### Test Output

Results are saved to `test-results.json` with detailed information:

```json
{
  "summary": {
    "total": 29,
    "passed": 27,
    "failed": 2,
    "duration": "15m30s"
  },
  "results": [
    {
      "name": "databases/postgresql",
      "prep": {"status": "passed", "duration": "5s"},
      "up": {"status": "passed", "duration": "10s"},
      "health": {"status": "passed", "duration": "15s"},
      "down": {"status": "passed", "duration": "3s"},
      "overall": "passed"
    }
  ]
}
```

### Failure Diagnostics

When a template fails at any lifecycle stage, the test harness now captures a full diagnostic snapshot in `test-artifacts/`:

- Docker Compose config (`docker-compose.config`)
- `docker compose ps` output (text + JSON)
- Aggregated `docker compose logs`
- Per-container logs and `docker inspect` details

Artifacts are grouped by template and timestamp so each failure is isolated. The directory is ignored by git locally and uploaded to the `test-results` artifact in CI for easy download. You can override the destination with `ARTIFACTS_DIR=/custom/path ./test-templates.sh`.

> Note: If a template does not set `NETWORK_MODE`, the harness automatically provisions a temporary user-defined bridge network to ensure modern Docker DNS resolution. The network is deleted during cleanup.

### CI Integration

The test workflow runs on:
- Pull requests to main/master
- Pushes to main/master
- Manual workflow dispatch (see below)

**Smart Testing:**
- Tests only run when files in `templates/` folder are changed
- Only changed templates are tested (not all 29 templates)
- Other changes (docs, workflows, etc.) skip tests entirely
- Deployment only proceeds if tests pass or are skipped

**Example:** If you modify `templates/databases/postgresql/Rediaccfile`, only the PostgreSQL template will be tested (~30s) instead of all templates (~30min).

**Manual Workflow Dispatch:**

You can manually trigger the workflow from GitHub Actions with options:

1. **Test All Templates** - Run all 29 templates (~30 minutes)
   - Go to Actions → "Test and Deploy Template Catalog" → Run workflow
   - Select "Test scope: all"

2. **Test Specific Template** - Run a single template (~30 seconds)
   - Go to Actions → "Test and Deploy Template Catalog" → Run workflow
   - Select "Test scope: specific"
   - Enter template path (e.g., `databases/postgresql`)

3. **Skip Tests** - Only deploy without testing
   - Go to Actions → "Test and Deploy Template Catalog" → Run workflow
   - Select "Test scope: skip"

**Failed tests will:**
- Block PR merges
- Prevent deployment to GitHub Pages
- Post detailed results as PR comments
- Upload test results as artifacts

---

## Template Structure

### Rediaccfile

Each template includes a `Rediaccfile` - a bash script that defines the lifecycle of services.

#### Functions

**`prep()` - Optional, recommended**
- Prepares the environment (pull images, create directories, etc.)
- Runs once before initial setup
- Good for one-time initialization tasks
- **Must return the exit code of the last critical command**

```bash
prep() {
  docker pull postgres
  mkdir -p data
  return $?  # Returns exit code of mkdir
}
```

**`up()` - Highly recommended**
- Starts services gracefully
- Should handle correct initialization order
- Recommended for proper service startup
- **CRITICAL: Must return docker compose exit code, not echo's exit code**

```bash
# ✅ CORRECT - Captures docker compose exit code
up() {
  docker compose up -d
  return $?  # Returns docker compose exit code
}

# ❌ WRONG - Returns echo exit code (always 0)
up() {
  docker compose up -d
  echo "Services started"
  return $?  # Returns echo's exit code, not docker compose!
}

# ✅ CORRECT - Multiple commands with explicit exit code capture
up() {
  docker compose up -d
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "Failed to start services"
    return $exit_code
  fi
  echo "Services started successfully"
  return 0
}
```

**`down()` - Highly recommended**
- Stops services gracefully
- **Must use `-v` flag** to clean up anonymous volumes
- Ensures proper shutdown and cleanup
- **Must return docker compose exit code**

```bash
down() {
  docker compose down -v  # -v flag is critical!
  return $?  # Returns docker compose exit code
}
```

#### Why These Functions Matter

- **`prep()`**: Ensures environment is ready before first run
- **`up()`**: Provides consistent, reproducible startup behavior
- **`down()`**: Prevents orphaned Docker volumes and ensures clean teardown

#### Critical: Return Value Requirements

**All functions MUST return the exit code of their primary command (usually docker compose).**

The CI pipeline and production systems rely on these exit codes to detect failures:
- `return 0` = Success
- `return non-zero` = Failure

**Common Mistake:** Returning the exit code of `echo` instead of `docker compose`:

```bash
# ❌ WRONG - CI thinks this succeeded even if docker compose failed!
up() {
  docker compose up -d
  echo "Waiting for services..."
  sleep 10
  echo "Services ready"
  return $?  # Returns exit code of last echo (always 0)
}

# ✅ CORRECT - Capture docker compose exit code first
up() {
  docker compose up -d
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    return $exit_code
  fi
  echo "Waiting for services..."
  sleep 10
  echo "Services ready"
  return 0
}
```

---

## Health Check Requirements

**Critical:** All services in docker-compose.yaml must define healthcheck configurations to ensure proper container validation in CI/CD.

### Why Health Checks Matter

The CI pipeline validates that **ALL containers** are running and healthy before marking a template as passed. Without health checks:
- Templates fall back to weak validation (any container running = pass)
- Partial failures can go undetected (e.g., 1 of 3 containers failed but test passes)
- Production deployments may fail in ways not caught by CI

### ✅ DO: Define Health Checks for All Services

```yaml
services:
  db:
    image: postgres:16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    volumes:
      - ./data:/var/lib/postgresql/data

  web:
    image: nginx:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 10s
    depends_on:
      db:
        condition: service_healthy  # Wait for db to be healthy
```

### Health Check Parameters Explained

- **`test`**: Command to check service health
  - `CMD-SHELL`: Run command in shell (use for complex commands)
  - `CMD`: Run command directly (more efficient)
  - Exit code 0 = healthy, non-zero = unhealthy
- **`interval`**: Time between health checks (default: 30s)
  - Use 10s for fast-starting services
  - Use 30s for slower services
- **`timeout`**: Max time for health check command to complete (default: 30s)
  - Use 5s for local checks (database ready, HTTP ping)
  - Use longer for remote checks
- **`retries`**: Consecutive failures before marking unhealthy (default: 3)
  - Use 3-5 for most services
  - Use more for services with slow initialization
- **`start_period`**: Grace period during container startup (default: 0s)
  - Use 30-60s for databases
  - Use 10-20s for web services
  - Use 120s+ for heavy applications (GitLab, etc.)

### Common Health Check Patterns

```yaml
# Database services (use service-specific CLI tools)
healthcheck:
  test: ["CMD-SHELL", "<service-cli-check-command>"]  # e.g., pg_isready, mysqladmin ping, redis-cli ping
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s

# Web/HTTP services (use curl, wget, or nc)
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:<port>/"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 15s

# Services with health endpoints
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:<port>/-/health"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 15s

# TCP port check (when no HTTP tools available)
healthcheck:
  test: ["CMD-SHELL", "nc -z localhost <port> || exit 1"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 10s
```

### Using depends_on with Health Checks

Always use `condition: service_healthy` when services depend on each other:

```yaml
services:
  database:
    image: <database-image>
    healthcheck:
      test: ["CMD-SHELL", "<health-check-command>"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  application:
    image: <app-image>
    depends_on:
      database:
        condition: service_healthy  # Wait for database to be healthy first
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:<port>/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 20s
```

### Health Check Checklist

- [ ] Every service has a `healthcheck:` definition
- [ ] Health check commands are appropriate for the service type
- [ ] `start_period` accounts for service initialization time
- [ ] `depends_on` uses `condition: service_healthy` where applicable
- [ ] Health checks validated with `docker compose ps` (Status shows "healthy")
- [ ] CI tests pass with all containers reported as healthy

### Testing Health Checks Locally

```bash
# Start services
docker compose up -d

# Watch health status (repeat until all show "healthy")
docker compose ps

# Example output:
# NAME                    STATUS
# myapp-db-1             Up 30 seconds (healthy)
# myapp-web-1            Up 15 seconds (healthy)

# If a service is unhealthy, check logs
docker compose logs [service-name]

# View detailed health check results
docker inspect [container-name] | jq '.[].State.Health'
```

### ❌ What NOT to Do

```yaml
# BAD: No health check defined
services:
  myservice:
    image: <image>
    # ❌ Missing healthcheck - CI will use weak validation

# BAD: Missing start_period for slow-starting services
services:
  myservice:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 10s
      timeout: 5s
      retries: 3
      # ❌ Missing start_period - service may be marked unhealthy during startup

# BAD: Using depends_on without health condition
services:
  app:
    depends_on:
      - database  # ❌ Only waits for container start, not readiness
```

---

## Docker Volume Best Practices

### Core Principle
**Always use relative path bind mounts (like `./data`). Never use named volumes or allow anonymous volumes.**

### ✅ DO: Use Relative Path Bind Mounts

```yaml
services:
  db:
    image: postgres
    volumes:
      - ./data:/var/lib/postgresql/data  # ✅ Relative bind mount
      - ./config:/etc/postgresql          # ✅ All data stays local
```

**Why:** Data stays in the same directory as docker-compose.yaml, ensuring portability when repositories are cloned.

### ❌ DON'T: Use Named Volumes

```yaml
services:
  db:
    image: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data  # ❌ External volume

volumes:
  postgres_data:  # ❌ Creates orphaned volume
```

**Why:** Named volumes are stored in Docker's volume directory (usually `/var/lib/docker/volumes/`) and become orphaned when repositories are cloned.

### ⚠️ WATCH OUT: Anonymous Volumes

Some Docker images (like `postgres`, `mysql`, `mongo`) declare `VOLUME` in their Dockerfile, creating anonymous volumes even when you mount elsewhere.

#### Problem Example (PostgreSQL)
```yaml
services:
  db:
    image: postgres
    environment:
      - PGDATA=/pgdata
    volumes:
      - ./data:/pgdata  # ✅ Safe bind mount
    # ❌ BUT: Postgres Dockerfile has VOLUME /var/lib/postgresql
    #    This creates an anonymous external volume!
```

#### Solution: Use tmpfs (Recommended)
```yaml
services:
  db:
    image: postgres
    environment:
      - PGDATA=/pgdata
    volumes:
      - ./data:/pgdata
    tmpfs:
      - /var/lib/postgresql  # ✅ Temporary, not a volume
```

### Rediaccfile `down()` Function

Always use `-v` flag to remove anonymous volumes:

```bash
down() {
  docker compose down -v  # ✅ Removes anonymous volumes
  return $?
}
```

**Not:**
```bash
down() {
  docker compose down  # ❌ Leaves orphaned volumes
  return $?
}
```

### Port Mapping Best Practices

**Critical:** Never use fixed host port mappings to allow repository cloning without conflicts.

```yaml
# ✅ GOOD - Container-only port (Docker assigns random host port)
services:
  db:
    ports:
      - "5432"  # Docker will map to random available host port

# ❌ BAD - Fixed host port (conflicts when cloning repos)
services:
  db:
    ports:
      - "5432:5432"      # Hard-coded host port
      - "${PORT}:5432"   # Environment variable still causes conflicts
```

**Why:** When repositories are cloned on the same machine, fixed host ports would conflict. Docker's automatic port assignment ensures each clone gets unique ports.

### Network Configuration

**Critical:** Use `network_mode` OR `networks`, never both. They are mutually exclusive in Docker Compose.

```yaml
# ✅ GOOD - Using network_mode for simple bridge networking
services:
  app:
    network_mode: "${NETWORK_MODE:-bridge}"
    # No 'networks:' section

# ❌ BAD - Both network_mode and networks (invalid)
services:
  app:
    network_mode: "${NETWORK_MODE:-bridge}"
    networks:
      - mynetwork  # ❌ Conflicts with network_mode
```

**When to use:**
- **`network_mode`**: Simple cases, checkpoint/restore support, host networking
- **`networks`**: Custom networks, service isolation, DNS resolution between services

### Quick Checklist

- [ ] All volumes use relative paths (`./data`, `./config`, etc.)
- [ ] No `volumes:` section at root level of docker-compose.yaml
- [ ] Images with built-in VOLUMEs explicitly override them with tmpfs or bind mounts
- [ ] `down()` function uses `docker compose down -v`
- [ ] Port mappings use container-only format (`"5432"` not `"5432:5432"`)
- [ ] Using `network_mode` OR `networks`, not both
- [ ] Test with volume detection: warning should NOT appear

### Testing Your Template

1. Create repository from template
2. Start services with `docker compose up -d`
3. Check for external volumes: `docker volume ls`
   - **Should see: No volumes** (bind mounts don't appear in volume list) ✅
   - **If you see volumes:** Something is wrong - check for anonymous volumes ❌
4. In Rediacc system:
   - CLI will warn about external volumes during startup
   - Console UI shows volume status in repository details

### Summary

1. **Use bind mounts** (`./path`) for all persistent data
2. **Prevent anonymous volumes** with tmpfs or explicit bind mounts
3. **Clean up properly** with `docker compose down -v`
4. **Test before committing** - no volume warnings should appear
