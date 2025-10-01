#!/bin/bash

# Self-Contained Template Catalog Generator
# Processes template directories and generates JSON catalog with GitHub Pages website
#
# Features:
# - Converts template directories to individual JSON files
# - Generates master catalog.json with all templates
# - Creates GitHub Pages website with interactive catalog
# - Minifies JSON files for optimal performance
# - Supports nested template organization by category
#
# Usage: ./generate.sh
#
# Dependencies: python3, jq

set -e  # Exit on any error

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"
BUILD_DIR="$SCRIPT_DIR/build"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Template Processing Functions
# Converts template directories to JSON format

# Function to escape JSON strings
json_escape() {
    local string="$1"
    string="${string//\\/\\\\}"
    string="${string//\"/\\\"}"
    string="${string//$'\n'/\\n}"
    string="${string//$'\r'/\\r}"
    string="${string//$'\t'/\\t}"
    echo "$string"
}

# Function to read file content and escape for JSON
read_file_content() {
    local file="$1"
    if [[ -f "$file" ]]; then
        json_escape "$(cat "$file")"
    else
        echo ""
    fi
}

# Function to get template metadata from README
extract_template_metadata() {
    local template_dir="$1"
    local template_name="$(basename "$template_dir")"
    local readme_file="$template_dir/README.md"

    # Extract title (first header)
    local title="$template_name"
    if [[ -f "$readme_file" ]]; then
        title=$(grep -m1 '^#[^#]' "$readme_file" 2>/dev/null | sed 's/^# *//' || echo "$template_name")
    fi

    # Extract description (first paragraph after title)
    local description=""
    if [[ -f "$readme_file" ]]; then
        description=$(awk '/^#[^#]/{found=1; next} found && /^$/{next} found && /^[^#]/ {print; exit}' "$readme_file" 2>/dev/null | head -1 || echo "")
    fi

    # Default description if empty
    if [[ -z "$description" ]]; then
        description="Template for $template_name"
    fi

    echo "$title|$description"
}

# Function to check if directory should be excluded
should_exclude_directory() {
    local dir_name="$1"
    local exclude_dirs=("build" "assets" "catalog" "config" "templates" ".github")

    # Check if it's a hidden directory
    if [[ "$dir_name" =~ ^\..*$ ]]; then
        return 0  # Should exclude
    fi

    # Check if it's a file (ends with extension)
    if [[ "$dir_name" == *.* ]]; then
        return 0  # Should exclude files
    fi

    # Check against exclude list
    for exclude in "${exclude_dirs[@]}"; do
        if [[ "$dir_name" == "$exclude" ]]; then
            return 0  # Should exclude
        fi
    done

    return 1  # Should not exclude
}

# Function to get file type based on extension
get_file_type() {
    local filename="$1"
    case "${filename##*.}" in
        md) echo "markdown" ;;
        yaml|yml) echo "yaml" ;;
        json) echo "json" ;;
        sh) echo "script" ;;
        env) echo "environment" ;;
        dockerfile|Dockerfile) echo "dockerfile" ;;
        *) echo "text" ;;
    esac
}

# Function to generate individual template JSON file
generate_template_json() {
    local template_dir="$1"
    local output_file="$2"
    local template_name="$(basename "$template_dir")"
    local category="$(basename $(dirname "$template_dir"))"

    echo "Processing template: $category/$template_name"

    # Extract metadata
    local metadata=$(extract_template_metadata "$template_dir")
    local title="$(echo "$metadata" | cut -d'|' -f1)"
    local description="$(echo "$metadata" | cut -d'|' -f2)"

    # Create template ID from category and name
    local template_id="${category}_${template_name}"

    # Start JSON structure
    cat > "$output_file" << EOF
{
  "id": "$template_id",
  "name": "$title",
  "description": "$(json_escape "$description")",
  "category": "$category",
  "tags": ["$category", "$template_name"],
  "files": [
EOF

    local first=true

    # Process all files in template directory
    while IFS= read -r -d '' file; do
        local relative_path="${file#$template_dir/}"
        local filename=$(basename "$file")

        # Skip hidden files and directories
        if [[ "$filename" =~ ^\..*$ ]] || [[ -d "$file" ]]; then
            continue
        fi

        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$output_file"
        fi

        # Add file to JSON
        cat >> "$output_file" << EOF
    {
      "name": "$(json_escape "$filename")",
      "path": "$(json_escape "$relative_path")",
      "type": "$(get_file_type "$filename")",
      "content": "$(read_file_content "$file")"
    }
EOF

    done < <(find "$template_dir" -maxdepth 1 -type f -print0 | sort -z)

    # Close JSON structure
    cat >> "$output_file" << EOF

  ],
  "readme": "$(read_file_content "$template_dir/README.md")",
  "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# Function to generate master catalog JSON
generate_catalog_json() {
    local templates_dir="$1"
    local output_file="$2"

    echo "Generating template catalog..."

    # Count valid templates by finding all template directories recursively
    local template_count=0
    for template_dir in $(find "$templates_dir" -mindepth 2 -maxdepth 2 -type d); do
        if [[ -f "$template_dir/README.md" ]] || [[ -f "$template_dir/docker-compose.yaml" ]] || [[ -f "$template_dir/Rediaccfile" ]]; then
            template_count=$((template_count + 1))
        fi
    done

    # Start catalog structure
    cat > "$output_file" << EOF
{
  "version": "1.0",
  "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "total_templates": $template_count,
  "categories": [],
  "templates": [
EOF

    local first=true
    local categories=()

    # Process each template directory recursively
    while IFS= read -r -d '' template_dir; do
        if [[ -f "$template_dir/README.md" ]] || [[ -f "$template_dir/docker-compose.yaml" ]] || [[ -f "$template_dir/Rediaccfile" ]]; then
            local template_name="$(basename "$template_dir")"
            local category_path="$(dirname "$template_dir" | sed 's|.*/templates||' | sed 's|^/||')"
            local category="$(echo "$category_path" | cut -d'/' -f1)"

            local metadata=$(extract_template_metadata "$template_dir")
            local title="$(echo "$metadata" | cut -d'|' -f1)"
            local description="$(echo "$metadata" | cut -d'|' -f2)"
            local template_id="${category}_${template_name}"

            # Track categories
            if [[ ! " ${categories[@]} " =~ " ${category} " ]]; then
                categories+=("$category")
            fi

            # Count files in template
            local file_count=$(find "$template_dir" -maxdepth 1 -type f | wc -l)
            local has_readme=$([ -f "$template_dir/README.md" ] && echo "true" || echo "false")
            local has_docker=$([ -f "$template_dir/docker-compose.yaml" ] && echo "true" || echo "false")

            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo "," >> "$output_file"
            fi

            # Add template to catalog
            cat >> "$output_file" << EOF
    {
      "id": "$template_id",
      "name": "$title",
      "description": "$(json_escape "$description")",
      "category": "$category",
      "tags": ["$category", "$template_name"],
      "file_count": $file_count,
      "has_readme": $has_readme,
      "has_docker": $has_docker,
      "download_url": "templates/$template_id.json",
      "readme": "$(read_file_content "$template_dir/README.md")"
    }
EOF
        fi
    done < <(find "$templates_dir" -mindepth 2 -maxdepth 2 -type d -print0 | sort -z)

    # Close templates array and add categories
    echo "" >> "$output_file"
    echo "  ]," >> "$output_file"
    echo '  "categories": [' >> "$output_file"

    local first=true
    for category in $(printf '%s\n' "${categories[@]}" | sort); do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo "," >> "$output_file"
        fi
        echo "    \"$category\"" >> "$output_file"
    done

    echo "" >> "$output_file"
    echo "  ]" >> "$output_file"
    echo "}" >> "$output_file"
}

# Function to copy template assets to build directory
copy_template_assets() {
    local templates_dir="$1"
    local assets_output_dir="$2"

    echo "Copying template assets..."

    # Copy any assets found in template directories
    find "$templates_dir" -name "assets" -type d | while read -r assets_dir; do
        if [[ -d "$assets_dir" ]]; then
            local template_path="${assets_dir%/assets}"
            local template_name="$(basename "$template_path")"
            local category_path="$(dirname "$template_path" | sed 's|.*/templates/||')"
            local category="$(echo "$category_path" | cut -d'/' -f1)"

            mkdir -p "$assets_output_dir/$category"
            cp -r "$assets_dir"/* "$assets_output_dir/$category/" 2>/dev/null || true
        fi
    done

    echo "Template assets copied"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean build directory
clean_build() {
    log_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"/{templates,configs,assets}
    log_success "Build directory cleaned"
}

# Function to process templates
process_templates() {
    log_info "Processing templates..."


    local templates_dir="$SOURCE_DIR/templates"
    local output_dir="$BUILD_DIR/templates"

    # Exclude generator, config, and build directories from template processing
    local exclude_dirs=("build" "assets" "catalog" "config" ".github")

    local processed=0

    # Process each template directory recursively (category/template structure)
    for template_dir in $(find "$templates_dir" -mindepth 2 -maxdepth 2 -type d); do
        if [[ -f "$template_dir/README.md" ]] || [[ -f "$template_dir/docker-compose.yaml" ]] || [[ -f "$template_dir/Rediaccfile" ]]; then
            local template_name="$(basename "$template_dir")"
            local category="$(basename $(dirname "$template_dir"))"
            local template_id="${category}_${template_name}"

            local output_file="$output_dir/$template_id.json"
            generate_template_json "$template_dir" "$output_file"
            processed=$((processed + 1))
        fi
    done

    log_success "Processed $processed templates"

    # Generate master templates index
    log_info "Generating templates index..."
    generate_catalog_json "$templates_dir" "$BUILD_DIR/templates.json"
    log_success "Templates index generated"

    # Copy assets
    copy_template_assets "$templates_dir" "$BUILD_DIR/assets"
    log_success "Template assets copied"
}

# Function to process configuration files
process_configs() {
    log_info "Processing configuration files..."

    local configs_dir="$SOURCE_DIR/config"
    local output_dir="$BUILD_DIR/configs"

    local processed=0

    # Copy config files from config directory
    for config_file in "$configs_dir"/*.json; do
        if [[ -f "$config_file" ]]; then
            local filename="$(basename "$config_file")"
            # Only copy config files (pricing, services, tiers)
            if [[ "$filename" == "pricing.json" ]] || [[ "$filename" == "services.json" ]] || [[ "$filename" == "tiers.json" ]]; then
                cp "$config_file" "$output_dir/$filename"
                processed=$((processed + 1))
            fi
        fi
    done

    log_success "Processed $processed configuration files"
}

# Function to generate GitHub Pages website
generate_website() {
    log_info "Generating GitHub Pages website..."

    # Create index.html
    cat > "$BUILD_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Template Catalog</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; background: #f5f7fa; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        header { text-align: center; margin-bottom: 40px; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; font-size: 2.5rem; margin-bottom: 10px; }
        .subtitle { color: #7f8c8d; font-size: 1.1rem; }
        .stats { display: flex; justify-content: center; gap: 30px; margin-top: 20px; }
        .stat { text-align: center; }
        .stat-number { font-size: 2rem; font-weight: bold; color: #3498db; }
        .stat-label { color: #7f8c8d; font-size: 0.9rem; }
        .filters { background: white; padding: 20px; border-radius: 10px; margin-bottom: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .filter-group { display: flex; gap: 15px; align-items: center; flex-wrap: wrap; }
        .filter-group label { font-weight: 500; color: #2c3e50; }
        input, select { padding: 8px 12px; border: 2px solid #e0e6ed; border-radius: 5px; font-size: 14px; }
        input:focus, select:focus { outline: none; border-color: #3498db; }
        .templates-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 25px; }
        .template-card { background: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); transition: transform 0.2s, box-shadow 0.2s; }
        .template-card:hover { transform: translateY(-2px); box-shadow: 0 4px 20px rgba(0,0,0,0.15); }
        .template-header { padding: 20px; border-bottom: 1px solid #e0e6ed; }
        .template-title { font-size: 1.3rem; font-weight: 600; color: #2c3e50; margin-bottom: 8px; }
        .template-meta { display: flex; gap: 10px; align-items: center; margin-bottom: 10px; }
        .template-category { background: #3498db; color: white; padding: 4px 8px; border-radius: 15px; font-size: 0.8rem; font-weight: 500; }
        .template-files { background: #ecf0f1; color: #7f8c8d; padding: 4px 8px; border-radius: 15px; font-size: 0.8rem; }
        .template-description { color: #7f8c8d; line-height: 1.5; }
        .template-actions { padding: 20px; background: #f8f9fa; }
        .btn { display: inline-block; padding: 10px 20px; background: #3498db; color: white; text-decoration: none; border-radius: 5px; font-weight: 500; transition: background 0.2s; }
        .btn:hover { background: #2980b9; }
        .btn-secondary { background: #95a5a6; }
        .btn-secondary:hover { background: #7f8c8d; }
        .no-results { text-align: center; color: #7f8c8d; font-size: 1.2rem; margin-top: 60px; }
        .api-docs { background: white; padding: 30px; border-radius: 10px; margin-top: 40px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .api-title { font-size: 1.5rem; color: #2c3e50; margin-bottom: 20px; }
        .endpoint { background: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 15px; font-family: 'Monaco', 'Menlo', monospace; }
        .method { background: #27ae60; color: white; padding: 2px 8px; border-radius: 3px; font-size: 0.8rem; margin-right: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Template Catalog</h1>
            <p class="subtitle">Discover and download infrastructure templates</p>
            <div class="stats">
                <div class="stat">
                    <div class="stat-number" id="total-templates">0</div>
                    <div class="stat-label">Templates</div>
                </div>
                <div class="stat">
                    <div class="stat-number" id="total-categories">0</div>
                    <div class="stat-label">Categories</div>
                </div>
            </div>
        </header>

        <div class="filters">
            <div class="filter-group">
                <label>Search:</label>
                <input type="text" id="search" placeholder="Search templates...">
                <label>Category:</label>
                <select id="category-filter">
                    <option value="">All Categories</option>
                </select>
                <label>Docker:</label>
                <select id="docker-filter">
                    <option value="">All Templates</option>
                    <option value="true">With Docker</option>
                    <option value="false">Without Docker</option>
                </select>
            </div>
        </div>

        <div id="templates-container">
            <div class="templates-grid" id="templates-grid"></div>
            <div class="no-results" id="no-results" style="display: none;">
                No templates found matching your criteria.
            </div>
        </div>

        <div class="api-docs">
            <h2 class="api-title">API Endpoints</h2>
            <div class="endpoint">
                <span class="method">GET</span> /templates.json - Complete templates index
            </div>
            <div class="endpoint">
                <span class="method">GET</span> /templates/{template-id}.json - Individual template
            </div>
            <div class="endpoint">
                <span class="method">GET</span> /configs/pricing.json - Pricing configuration
            </div>
            <div class="endpoint">
                <span class="method">GET</span> /configs/services.json - Services configuration
            </div>
        </div>
    </div>

    <script>
        let allTemplates = [];
        let filteredTemplates = [];

        // Load templates data
        fetch('templates.json')
            .then(response => response.json())
            .then(data => {
                allTemplates = data.templates;
                filteredTemplates = [...allTemplates];

                // Update stats
                document.getElementById('total-templates').textContent = data.total_templates;
                document.getElementById('total-categories').textContent = data.categories.length;

                // Populate category filter
                const categorySelect = document.getElementById('category-filter');
                data.categories.forEach(category => {
                    const option = document.createElement('option');
                    option.value = category;
                    option.textContent = category.charAt(0).toUpperCase() + category.slice(1);
                    categorySelect.appendChild(option);
                });

                // Initial render
                renderTemplates();

                // Setup event listeners
                setupFilters();
            })
            .catch(error => console.error('Error loading templates:', error));

        function renderTemplates() {
            const grid = document.getElementById('templates-grid');
            const noResults = document.getElementById('no-results');

            if (filteredTemplates.length === 0) {
                grid.style.display = 'none';
                noResults.style.display = 'block';
                return;
            }

            grid.style.display = 'grid';
            noResults.style.display = 'none';

            grid.innerHTML = filteredTemplates.map(template => `
                <div class="template-card">
                    <div class="template-header">
                        <h3 class="template-title">${template.name}</h3>
                        <div class="template-meta">
                            <span class="template-category">${template.category}</span>
                            <span class="template-files">${template.file_count} files</span>
                            ${template.has_docker ? '<span class="template-files">Docker</span>' : ''}
                        </div>
                        <p class="template-description">${template.description}</p>
                    </div>
                    <div class="template-actions">
                        <a href="${template.download_url}" class="btn">Download JSON</a>
                        <a href="#" onclick="viewTemplate('${template.id}')" class="btn btn-secondary">View Details</a>
                    </div>
                </div>
            `).join('');
        }

        function setupFilters() {
            const searchInput = document.getElementById('search');
            const categoryFilter = document.getElementById('category-filter');
            const dockerFilter = document.getElementById('docker-filter');

            function applyFilters() {
                const searchTerm = searchInput.value.toLowerCase();
                const selectedCategory = categoryFilter.value;
                const dockerRequirement = dockerFilter.value;

                filteredTemplates = allTemplates.filter(template => {
                    const matchesSearch = template.name.toLowerCase().includes(searchTerm) ||
                                        template.description.toLowerCase().includes(searchTerm) ||
                                        template.tags.some(tag => tag.toLowerCase().includes(searchTerm));

                    const matchesCategory = !selectedCategory || template.category === selectedCategory;

                    const matchesDocker = !dockerRequirement ||
                                        (dockerRequirement === 'true' && template.has_docker) ||
                                        (dockerRequirement === 'false' && !template.has_docker);

                    return matchesSearch && matchesCategory && matchesDocker;
                });

                renderTemplates();
            }

            searchInput.addEventListener('input', applyFilters);
            categoryFilter.addEventListener('change', applyFilters);
            dockerFilter.addEventListener('change', applyFilters);
        }

        function viewTemplate(templateId) {
            // For now, just download the template JSON
            // In a more advanced version, this could show a modal with details
            window.open(`templates/${templateId}.json`, '_blank');
        }
    </script>
</body>
</html>
EOF

    # Create _config.yml for GitHub Pages
    cat > "$BUILD_DIR/_config.yml" << 'EOF'
# GitHub Pages configuration
title: Template Catalog
description: Infrastructure template catalog and configuration repository
baseurl: ""
url: ""

# Build settings
markdown: kramdown
highlighter: rouge
theme: minima

# Include/exclude files
include:
  - "*.json"
  - "templates/"
  - "configs/"
  - "assets/"

exclude:
  - "README.md"
  - "Gemfile"
  - "Gemfile.lock"

# Enable directory indexes
plugins:
  - jekyll-optional-front-matter

# MIME types for JSON files
defaults:
  - scope:
      path: "**/*.json"
    values:
      layout: null
EOF

    # Create API documentation page
    cat > "$BUILD_DIR/api.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Documentation - Template Catalog</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; max-width: 1000px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .endpoint { background: #f8f9fa; padding: 20px; margin: 20px 0; border-radius: 8px; border-left: 4px solid #007bff; }
        .method { background: #28a745; color: white; padding: 4px 8px; border-radius: 4px; font-size: 0.8rem; font-weight: bold; }
        .url { font-family: 'Monaco', 'Menlo', monospace; background: #e9ecef; padding: 2px 6px; border-radius: 3px; }
        code { background: #f1f3f4; padding: 2px 4px; border-radius: 3px; font-family: 'Monaco', 'Menlo', monospace; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .back-link { display: inline-block; margin-bottom: 20px; color: #007bff; text-decoration: none; }
    </style>
</head>
<body>
    <a href="index.html" class="back-link">← Back to Catalog</a>

    <div class="header">
        <h1>API Documentation</h1>
        <p>RESTful JSON API for accessing template and configuration data</p>
    </div>

    <div class="endpoint">
        <h3><span class="method">GET</span> <span class="url">/templates.json</span></h3>
        <p>Returns the complete templates index with metadata for all available templates.</p>
        <h4>Response Format:</h4>
        <pre><code>{
  "version": "1.0",
  "generated": "2024-01-01T00:00:00Z",
  "total_templates": 22,
  "categories": ["api", "auth", "cache", "db", ...],
  "templates": [
    {
      "id": "template_name",
      "name": "Display Name",
      "description": "Template description",
      "category": "category_name",
      "tags": ["tag1", "tag2"],
      "file_count": 4,
      "has_readme": true,
      "has_docker": true,
      "download_url": "templates/template_name.json"
    }
  ]
}</code></pre>
    </div>

    <div class="endpoint">
        <h3><span class="method">GET</span> <span class="url">/templates/{template-id}.json</span></h3>
        <p>Returns detailed information and file contents for a specific template.</p>
        <h4>Example URLs:</h4>
        <ul>
            <li><code>/templates/api-gateway_kong.json</code></li>
            <li><code>/templates/databases_mysql.json</code></li>
            <li><code>/templates/caching_redis.json</code></li>
        </ul>
        <h4>Response Format:</h4>
        <pre><code>{
  "id": "template_name",
  "name": "Display Name",
  "description": "Template description",
  "category": "category_name",
  "tags": ["tag1", "tag2"],
  "files": [
    {
      "name": "docker-compose.yaml",
      "path": "docker-compose.yaml",
      "type": "yaml",
      "content": "file contents here..."
    }
  ],
  "readme": "README.md contents...",
  "generated": "2024-01-01T00:00:00Z"
}</code></pre>
    </div>

    <div class="endpoint">
        <h3><span class="method">GET</span> <span class="url">/configs/pricing.json</span></h3>
        <p>Returns pricing configuration data including tiers and professional services.</p>
    </div>

    <div class="endpoint">
        <h3><span class="method">GET</span> <span class="url">/configs/services.json</span></h3>
        <p>Returns services configuration data.</p>
    </div>

    <div class="endpoint">
        <h3><span class="method">GET</span> <span class="url">/configs/tiers.json</span></h3>
        <p>Returns tier configuration data.</p>
    </div>

    <h2>Usage Examples</h2>
    <h3>JavaScript/Fetch</h3>
    <pre><code>// Load templates index
const templates = await fetch('/templates.json').then(r => r.json());

// Load specific template
const template = await fetch(`/templates/${templateId}.json`).then(r => r.json());

// Get file content
const dockerCompose = template.files.find(f => f.name === 'docker-compose.yaml')?.content;</code></pre>

    <h3>curl</h3>
    <pre><code># Get templates index
curl https://json.rediacc.com/templates.json

# Get specific template
curl https://json.rediacc.com/templates/api-gateway_kong.json</code></pre>
</body>
</html>
EOF

    log_success "GitHub Pages website generated"
}

# Function to validate generated files
validate_output() {
    log_info "Validating generated files..."

    local errors=0

    # Check required files exist
    local required_files=(
        "$BUILD_DIR/index.html"
        "$BUILD_DIR/templates.json"
        "$BUILD_DIR/_config.yml"
        "$BUILD_DIR/api.html"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file missing: $file"
            ((errors++))
        fi
    done

    # Check templates.json is valid JSON
    if [[ -f "$BUILD_DIR/templates.json" ]]; then
        if ! python3 -m json.tool "$BUILD_DIR/templates.json" >/dev/null 2>&1; then
            log_error "templates.json is not valid JSON"
            ((errors++))
        fi
    fi

    # Check template JSON files
    local template_files=0
    for template_file in "$BUILD_DIR/templates"/*.json; do
        if [[ -f "$template_file" ]]; then
            if ! python3 -m json.tool "$template_file" >/dev/null 2>&1; then
                log_error "Invalid JSON: $(basename "$template_file")"
                ((errors++))
            fi
            ((template_files++))
        fi
    done

    log_info "Found $template_files template JSON files"

    if [[ $errors -eq 0 ]]; then
        log_success "All files validated successfully"
        return 0
    else
        log_error "Found $errors validation errors"
        return 1
    fi
}

# Function to minify JSON files
minify_json_files() {
    log_info "Minifying JSON files..."

    local minified=0
    local total_size_before=0
    local total_size_after=0

    # Find all JSON files in build directory
    while IFS= read -r -d '' json_file; do
        if [[ -f "$json_file" ]]; then
            local size_before=$(stat -f%z "$json_file" 2>/dev/null || stat -c%s "$json_file" 2>/dev/null || echo "0")
            total_size_before=$((total_size_before + size_before))

            # Create temporary file and minify
            local temp_file="${json_file}.tmp"
            if jq -c . "$json_file" > "$temp_file" 2>/dev/null; then
                mv "$temp_file" "$json_file"
                local size_after=$(stat -f%z "$json_file" 2>/dev/null || stat -c%s "$json_file" 2>/dev/null || echo "0")
                total_size_after=$((total_size_after + size_after))
                minified=$((minified + 1))
            else
                log_warning "Failed to minify: $(basename "$json_file")"
                rm -f "$temp_file"
                total_size_after=$((total_size_after + size_before))
            fi
        fi
    done < <(find "$BUILD_DIR" -name "*.json" -type f -print0)

    if [[ $minified -gt 0 ]]; then
        local savings=$((total_size_before - total_size_after))
        local percentage=0
        if [[ $total_size_before -gt 0 ]]; then
            percentage=$((savings * 100 / total_size_before))
        fi
        log_success "Minified $minified JSON files (saved ${savings} bytes, ${percentage}% reduction)"
    else
        log_warning "No JSON files were minified"
    fi
}

# Function to display summary
show_summary() {
    log_info "Generation Summary"
    echo "===================="
    echo "Build Directory: $BUILD_DIR"
    echo ""
    echo "Generated Files:"
    echo "  - index.html          (Main website)"
    echo "  - templates.json      (Templates index API)"
    echo "  - api.html           (API documentation)"
    echo "  - _config.yml        (GitHub Pages config)"
    echo ""

    if [[ -d "$BUILD_DIR/templates" ]]; then
        local template_count=$(find "$BUILD_DIR/templates" -name "*.json" | wc -l)
        echo "  - templates/         ($template_count template JSON files)"
    fi

    if [[ -d "$BUILD_DIR/configs" ]]; then
        local config_count=$(find "$BUILD_DIR/configs" -name "*.json" | wc -l)
        echo "  - configs/           ($config_count config JSON files)"
    fi

    if [[ -d "$BUILD_DIR/assets" ]]; then
        local asset_count=$(find "$BUILD_DIR/assets" -type f | wc -l)
        echo "  - assets/            ($asset_count asset files)"
    fi

    echo ""
    echo "Next Steps:"
    echo "  1. Test locally: cd $BUILD_DIR && python3 -m http.server 8000"
    echo "  2. Deploy: Copy build/ contents to your GitHub Pages repository"
    echo "  3. Access: Visit your GitHub Pages URL"
    echo ""
}

# Main execution
main() {
    log_info "Starting JSON Config Generator"
    echo "=============================="

    # Check dependencies
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python 3 is required for JSON validation"
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required for JSON minification"
        exit 1
    fi

    # Run generation steps
    clean_build
    process_templates
    process_configs
    generate_website

    # Validate output before minification
    if validate_output; then
        # Minify JSON files to reduce size
        minify_json_files

        show_summary
        log_success "Generation completed successfully!"
        exit 0
    else
        log_error "Generation completed with errors"
        exit 1
    fi
}

# Run main function
main "$@"