# Template Catalog

Self-contained infrastructure template repository with GitHub Pages catalog.

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

### Quick Checklist

- [ ] All volumes use relative paths (`./data`, `./config`, etc.)
- [ ] No `volumes:` section at root level of docker-compose.yaml
- [ ] Images with built-in VOLUMEs explicitly override them with tmpfs or bind mounts
- [ ] `down()` function uses `docker compose down -v`
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
