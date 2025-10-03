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

3. **Template Structure:**
   Create a complete template with:
   - **README.md** - Project description, features, usage instructions
     - First `#` header becomes the template title
     - First paragraph becomes the template description
   - **docker-compose.yaml** - Service definitions following volume best practices
   - **Rediaccfile** - Lifecycle functions (prep, up, down)
   - **.env** - Default environment variables with comments

4. **Critical Requirements:**
   - ✅ Use relative path bind mounts only (`./data`, `./config`)
   - ❌ Never use named volumes
   - ✅ Override anonymous volumes with tmpfs if needed
   - ✅ Use `docker compose down -v` in down() function
   - ✅ Include proper health checks where applicable
   - ✅ Document all required ports and dependencies
   - ✅ Provide clear setup instructions

5. **Template Discovery:**
   - Templates are auto-discovered by `generate.sh` based on folder structure
   - Category is extracted from parent folder name
   - Title is extracted from first `#` header in README.md
   - Description is extracted from first paragraph in README.md
   - Tags are auto-generated from category and template name
   - No metadata.json needed!

6. **Template Location:**
   - Place in appropriate category: `templates/{category}/{project-name}/`
   - Use lowercase, hyphenated names (e.g., `nextcloud-aio`, `gitlab-ce`)

7. **Validation:**
   After creating the template:
   - Test that `docker volume ls` shows NO volumes after starting services
   - Verify all data persists in relative directories
   - Confirm `down()` function cleans up properly
   - Check that services start and health checks pass

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
