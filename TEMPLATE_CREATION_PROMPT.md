# Template Creation Prompt

Use this prompt to create new templates for the Rediacc template catalog.

---

## Prompt

```
I need you to create a new Rediacc template based on the following project:

**Project URL:** [INSERT URL HERE - e.g., https://github.com/nextcloud/all-in-one]

**Instructions:**

1. **Research Phase:**
   - Navigate to the project URL and thoroughly understand the project
   - Read the official documentation, README, and deployment guides
   - Identify the recommended deployment method (Docker, docker-compose, etc.)
   - Understand required configuration, environment variables, and dependencies
   - Note any special requirements (ports, volumes, networks, health checks)

2. **Follow Template Guidelines:**
   - Read and follow the guidelines in `README.md` in the templates repository root
   - Pay special attention to:
     - Rediaccfile structure (prep, up, down functions)
     - Docker volume best practices (relative paths, no named volumes)
     - Anonymous volume prevention (tmpfs for images with built-in VOLUMEs)
     - Proper cleanup with `docker compose down -v`
     - **Health check requirements for ALL services** (see README.md)
     - **Environment variables** (REPO_NETWORK_ID, REPO_NETWORK_MODE) available in execution context

3. **Template Structure:**
   Create a complete template with:
   - **README.md** - Concise documentation following standard format (see below)
     - First `#` header becomes the template title
     - First paragraph becomes the template description
   - **docker-compose.yaml** - Service definitions following volume best practices
   - **Rediaccfile** - Lifecycle functions (prep, up, down)
   - **.env** - Default environment variables with comments

4. **Critical Requirements:**
   - ✅ **Data must stay in repo folder** - use either approach:
     - **Approach 1** (preferred): Direct bind mounts (`./data`, `./config`)
     - **Approach 2**: Named volumes with local bind driver (for apps requiring specific volume names)
       ```yaml
       volumes:
         volume_name:
           driver: local
           driver_opts:
             type: none
             o: bind
             device: ${PWD}/data
       ```
   - ❌ **Avoid external named volumes** (without driver_opts binding to repo folder)
   - ✅ Override anonymous volumes with tmpfs if needed
   - ✅ Use `docker compose down -v` in down() function
     - **Exception**: Omit `-v` for orchestration systems that manage external containers (e.g., Nextcloud AIO)
   - ✅ **CRITICAL: All Rediaccfile functions must return docker compose exit codes, not echo exit codes**
     - Capture `docker compose` exit code immediately: `local exit_code=$?`
     - Return the captured exit code, not the exit code of subsequent echo statements
     - See README.md "Return Value Requirements" section for examples
   - ✅ **NO fixed host port mappings** - Use container-only ports
     - ✅ Good: `ports: - "5432"` (Docker assigns random host port)
     - ❌ Bad: `ports: - "5432:5432"` or `- "${PORT}:5432"` (conflicts when cloning)
   - ✅ **Use `network_mode` OR `networks`, never both** (mutually exclusive)
     - ✅ Good: `network_mode: "${REPO_NETWORK_MODE:-bridge}"` (uses system-provided variable)
     - ❌ Bad: Both `network_mode` AND `networks:` defined (invalid compose)
   - ✅ **Use system-provided environment variables**:
     - `REPO_NETWORK_MODE`: Docker network mode (bridge, host, none, overlay, ipvlan, macvlan)
     - `REPO_NETWORK_ID`: Unique network identifier (integer, 2816-16777215)
       - Calculate base IP: `BASE_IP="127.$((REPO_NETWORK_ID / 65536)).$((REPO_NETWORK_ID / 256 % 256)).$((REPO_NETWORK_ID % 256))"`
       - Each repository has unique IP addresses based on its network ID
     - See README.md "Environment Variables" section for details
   - ✅ **REQUIRED: Define healthcheck for EVERY service in docker-compose.yaml**
     - All services must have `healthcheck:` with test, interval, timeout, retries, start_period
     - Use appropriate health check commands (pg_isready, curl, redis-cli, etc.)
     - Set proper `start_period` based on service initialization time
     - Use `depends_on` with `condition: service_healthy` for service dependencies
     - See README.md "Health Check Requirements" section for examples
   - ✅ Document all required ports and dependencies
   - ✅ Provide clear setup instructions

5. **README.md Standard Format:**
   Keep README files **concise** and link to official documentation for details.

   **Required Structure:**
   ```markdown
   # [Project Name]

   [One-sentence description - becomes template description in catalog]

   ## Features
   - [3-5 key features, one line each]
   - [Focus on what makes this template useful]

   ## Usage
   ```bash
   source Rediaccfile
   prep  # Pull images and create directories
   up    # Start [service name]
   down  # Stop [service name]
   ```

   ## Configuration
   Edit `.env` to customize:
   - `VARIABLE_NAME`: Brief description (default: value)
   - `ANOTHER_VAR`: Brief description (default: value)

   ## Access
   - **Port**: [port number] (Docker auto-assigns host port)
   - **Credentials**: Check `.env` file
   - **Find assigned port**: `docker compose ps`

   ## Resources
   - [Official Docker Hub](https://hub.docker.com/_/[image-name])
   - [Official Documentation](https://[project-site])
   ```

   **Guidelines:**
   - Keep it under 100 lines total
   - Link to Docker Hub and official docs instead of duplicating information
   - Focus on template-specific usage, not general project documentation
   - No need to explain what the project is in detail (link to docs)
   - Avoid lengthy configuration examples (keep it minimal)

6. **Template Discovery:**
   - Templates are auto-discovered by `generate.sh` based on folder structure
   - Category is extracted from parent folder name
   - Title is extracted from first `#` header in README.md
   - Description is extracted from first paragraph in README.md
   - Tags are auto-generated from category and template name
   - No metadata.json needed!

7. **Template Location:**
   - Place in appropriate category: `templates/{category}/{project-name}/`
   - Use lowercase, hyphenated names (e.g., `nextcloud-aio`, `gitlab-ce`)

8. **Validation:**
   After creating the template:
   - **Approach 1**: Verify `ls ./data` shows container data (no volumes in `docker volume ls`)
   - **Approach 2**: Verify `docker volume inspect <name>` shows Mountpoint in repo folder
   - Confirm data stays in repo folder, portable when cloning
   - Verify all data persists in repo directories
   - Confirm `down()` function cleans up properly
   - **Verify ALL services have health checks defined in docker-compose.yaml**
   - **Confirm `docker compose ps` shows ALL services as "healthy"** (not just "Up")
   - Wait for health checks to pass (may take 30-60s depending on start_period)
   - If any service shows "Up (health: starting)" for too long, increase start_period

**Example Template Categories:**
- **databases**: PostgreSQL, MySQL, MongoDB, Redis, Elasticsearch
- **platforms**: WordPress, GitLab, Nextcloud, Discourse
- **monitoring**: Prometheus, Grafana, Uptime Kuma
- **messaging**: Kafka, RabbitMQ, MQTT
- **caching**: Redis, Memcached
- **api-gateway**: Kong, Traefik
- **management**: Portainer, Rancher
- **security**: Keycloak, Vault
- **networking**: VPN, DNS, Proxy
- **search**: Elasticsearch, Meilisearch
- **tooling**: CI/CD, Dev tools

**Project to implement:** [PROJECT NAME]
**Project URL:** [INSERT URL]
**Suggested category:** [CATEGORY]

Please proceed with researching the project and creating a complete, production-ready template.
```

---

## Usage Example

```
I need you to create a new Rediacc template based on the following project:

**Project URL:** https://github.com/nextcloud/all-in-one

**Project to implement:** Nextcloud All-in-One
**Suggested category:** platforms

Please proceed with researching the project and creating a complete, production-ready template.
```

---

## Notes

- The AI will research the project URL first
- It will read the README.md guidelines automatically
- It will follow volume best practices
- It will create all necessary files
- It will validate the template works correctly

This ensures consistent, high-quality templates that follow Rediacc standards.
