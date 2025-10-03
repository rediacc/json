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

### CI Integration

The test workflow runs on:
- Pull requests to main/master
- Pushes to main/master
- Manual workflow dispatch

Failed tests will:
- Block PR merges
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

```bash
prep() {
  docker pull postgres
  mkdir -p data
  return $?
}
```

**`up()` - Highly recommended**
- Starts services gracefully
- Should handle correct initialization order
- Recommended for proper service startup

```bash
up() {
  docker compose up -d
  return $?
}
```

**`down()` - Highly recommended**
- Stops services gracefully
- **Must use `-v` flag** to clean up anonymous volumes
- Ensures proper shutdown and cleanup

```bash
down() {
  docker compose down -v  # -v flag is critical!
  return $?
}
```

#### Why These Functions Matter

- **`prep()`**: Ensures environment is ready before first run
- **`up()`**: Provides consistent, reproducible startup behavior
- **`down()`**: Prevents orphaned Docker volumes and ensures clean teardown

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

### Quick Checklist

- [ ] All volumes use relative paths (`./data`, `./config`, etc.)
- [ ] No `volumes:` section at root level of docker-compose.yaml
- [ ] Images with built-in VOLUMEs explicitly override them with tmpfs or bind mounts
- [ ] `down()` function uses `docker compose down -v`
- [ ] Port mappings use container-only format (`"5432"` not `"5432:5432"`)
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
