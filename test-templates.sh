#!/bin/bash

# Template Testing Script
# Tests all Rediaccfile templates by executing prep/up/down lifecycle
# Monitors health checks and cleans up resources for CI environments
#
# Usage: ./test-templates.sh [OPTIONS]
#
# Options:
#   --category <name>     Test only templates in specified category
#   --template <path>     Test only specific template (relative to templates/)
#   --skip <path>         Skip specific template (can be used multiple times)
#   --verbose             Show detailed output
#   --no-cleanup          Don't cleanup Docker images (for debugging)
#   --output <file>       Output file for JSON results (default: test-results.json)
#   --help                Show this help message

set -euo pipefail

# Configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-240}  # 4 minutes max per function
HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-360}  # 6 minutes for slow-starting services like GitLab
RESULTS_FILE=${RESULTS_FILE:-test-results.json}
VERBOSE=${VERBOSE:-0}
CLEANUP_IMAGES=${CLEANUP_IMAGES:-1}
CONTINUE_ON_ERROR=${CONTINUE_ON_ERROR:-1}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Arrays for storing results
declare -a TEST_RESULTS=()
declare -a SKIP_TEMPLATES=()
declare -a FILTER_TEMPLATES=()

# Filter options
FILTER_CATEGORY=""

# Timestamps
START_TIME=$(date +%s)

#==============================================================================
# Helper Functions
#==============================================================================

print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}" >&2
}

log_info() {
    print_color "$BLUE" "[INFO] $*"
}

log_success() {
    print_color "$GREEN" "[PASS] $*"
}

log_error() {
    print_color "$RED" "[FAIL] $*"
}

log_warn() {
    print_color "$YELLOW" "[WARN] $*"
}

log_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        print_color "$CYAN" "[VERBOSE] $*"
    fi
}

show_help() {
    cat << 'EOF'
Template Testing Script

Tests all Rediaccfile templates by executing prep/up/down lifecycle

Usage: ./test-templates.sh [OPTIONS]

Options:
  --category <name>     Test only templates in specified category
  --template <path>     Test only specific template (relative to templates/)
  --skip <path>         Skip specific template (can be used multiple times)
  --verbose             Show detailed output
  --no-cleanup          Don't cleanup Docker images (for debugging)
  --output <file>       Output file for JSON results (default: test-results.json)
  --help                Show this help message

Environment Variables:
  TEST_TIMEOUT              Max time per function in seconds (default: 240)
  HEALTH_CHECK_TIMEOUT      Max wait for health checks in seconds (default: 360)
  RESULTS_FILE              Output file for JSON results
  VERBOSE                   Set to 1 for detailed output
  CLEANUP_IMAGES            Set to 0 to skip image cleanup

Examples:
  ./test-templates.sh                           # Test all templates
  ./test-templates.sh --category databases      # Test only database templates
  ./test-templates.sh --template databases/postgresql  # Test specific template
  ./test-templates.sh --skip databases/mssql --verbose # Skip MSSQL, verbose output
EOF
}

#==============================================================================
# Template Discovery Functions
#==============================================================================

discover_templates() {
    log_info "Discovering templates in $TEMPLATES_DIR"

    local templates=()

    # Find all directories with Rediaccfile
    while IFS= read -r -d '' rediaccfile; do
        local template_dir=$(dirname "$rediaccfile")
        local relative_path=${template_dir#$TEMPLATES_DIR/}

        # Apply filters
        if [[ -n "$FILTER_CATEGORY" ]]; then
            local category=$(echo "$relative_path" | cut -d'/' -f1)
            if [[ "$category" != "$FILTER_CATEGORY" ]]; then
                continue
            fi
        fi

        if [[ ${#FILTER_TEMPLATES[@]} -gt 0 ]]; then
            local template_matches=0
            for filter_template in "${FILTER_TEMPLATES[@]}"; do
                if [[ "$relative_path" == "$filter_template" ]]; then
                    template_matches=1
                    break
                fi
            done
            if [[ $template_matches -eq 0 ]]; then
                continue
            fi
        fi

        # Check if template should be skipped
        local should_skip=0
        for skip in "${SKIP_TEMPLATES[@]}"; do
            if [[ "$relative_path" == "$skip" ]]; then
                should_skip=1
                break
            fi
        done

        if [[ $should_skip -eq 0 ]]; then
            templates+=("$relative_path")
        else
            log_verbose "Skipping template: $relative_path"
            ((SKIPPED_TESTS++)) || true
        fi
    done < <(find "$TEMPLATES_DIR" -name "Rediaccfile" -type f -print0 2>/dev/null | sort -z)

    if [[ ${#templates[@]} -eq 0 ]]; then
        log_error "No templates found matching criteria"
        exit 1
    fi

    log_info "Found ${#templates[@]} templates to test"

    printf '%s\n' "${templates[@]}"
}

#==============================================================================
# Health Check Functions
#==============================================================================

check_health() {
    local template_dir=$1
    local timeout=$HEALTH_CHECK_TIMEOUT
    local interval=5
    local elapsed=0

    log_verbose "Checking container health in $template_dir"

    # Check if docker-compose.yaml has health checks defined
    local compose_file="$template_dir/docker-compose.yaml"
    if [[ ! -f "$compose_file" ]]; then
        compose_file="$template_dir/docker-compose.yml"
    fi

    local has_healthcheck=0
    if [[ -f "$compose_file" ]] && grep -q "healthcheck:" "$compose_file"; then
        has_healthcheck=1
        log_verbose "Health checks defined in compose file"
    fi

    cd "$template_dir" || return 1

    if [[ $has_healthcheck -eq 1 ]]; then
        # Wait for health checks to pass
        while [[ $elapsed -lt $timeout ]]; do
            local unhealthy=0
            local container_count=0

            # Check container status using docker compose ps with JSON format
            local ps_output=$(docker compose ps --format json 2>/dev/null)

            if [[ -z "$ps_output" ]]; then
                log_verbose "No containers found"
                return 1
            fi

            while IFS= read -r container_json; do
                ((container_count++)) || true

                local name=$(echo "$container_json" | jq -r '.Name')
                local status=$(echo "$container_json" | jq -r '.Status')
                local health=$(echo "$container_json" | jq -r '.Health // empty')

                # Check if container is not running (status should start with "Up")
                if [[ ! "$status" =~ ^Up ]]; then
                    log_verbose "Container not up: $name ($status)"
                    unhealthy=1
                    break
                fi

                # Check health status if health checks are defined
                if [[ -n "$health" ]] && [[ "$health" != "healthy" ]]; then
                    log_verbose "Container health not ready: $name ($health)"
                    unhealthy=1
                    break
                fi
            done < <(echo "$ps_output" | jq -c '.')

            if [[ $container_count -eq 0 ]]; then
                log_verbose "No containers found"
                return 1
            fi

            if [[ $unhealthy -eq 0 ]]; then
                log_verbose "All containers healthy ($container_count container(s))"
                return 0
            fi

            sleep $interval
            elapsed=$((elapsed + interval))
            log_verbose "Waiting for health checks... ${elapsed}s/${timeout}s"
        done

        log_verbose "Health check timeout after ${timeout}s"
        return 1
    else
        # No health checks defined, just verify containers are running
        log_verbose "No health checks defined, verifying containers are running"
        sleep 10

        local running=$(docker compose ps --format "{{.Status}}" 2>/dev/null | grep -c "Up" || true)
        if [[ $running -gt 0 ]]; then
            log_verbose "Containers are running"
            return 0
        else
            log_verbose "No running containers found"
            return 1
        fi
    fi
}

#==============================================================================
# Cleanup Functions
#==============================================================================

cleanup_images() {
    local template_dir=$1

    if [[ $CLEANUP_IMAGES -eq 0 ]]; then
        log_verbose "Skipping image cleanup (--no-cleanup)"
        return 0
    fi

    log_verbose "Cleaning up Docker images for $template_dir"

    # Extract images from docker-compose.yaml
    local compose_file="$template_dir/docker-compose.yaml"
    if [[ ! -f "$compose_file" ]]; then
        compose_file="$template_dir/docker-compose.yml"
    fi

    if [[ ! -f "$compose_file" ]]; then
        log_verbose "No compose file found, skipping image cleanup"
        return 0
    fi

    local images=()
    while IFS= read -r image; do
        # Remove any variable substitution or quotes
        image=$(echo "$image" | sed 's/\${[^}]*}//g' | tr -d '"' | tr -d "'" | xargs)
        if [[ -n "$image" ]] && [[ "$image" != *"$"* ]]; then
            images+=("$image")
        fi
    done < <(grep -E "^\s*image:" "$compose_file" | awk '{print $2}')

    # Remove images
    for image in "${images[@]}"; do
        log_verbose "Removing image: $image"
        docker rmi -f "$image" >/dev/null 2>&1 || true
    done

    return 0
}

cleanup_directories() {
    local template_dir=$1

    log_verbose "Cleaning up directories in $template_dir"

    # Remove common data directories
    cd "$template_dir" || return 1

    rm -rf data >/dev/null 2>&1 || true
    rm -rf ./data >/dev/null 2>&1 || true

    # Remove any directories created during testing
    find . -maxdepth 1 -type d -name "data*" -exec rm -rf {} \; 2>/dev/null || true

    return 0
}

cleanup_volumes() {
    log_verbose "Pruning Docker volumes"
    docker volume prune -f >/dev/null 2>&1 || true
    return 0
}

#==============================================================================
# Test Execution Functions
#==============================================================================

test_template() {
    local template_path=$1
    local template_dir="$TEMPLATES_DIR/$template_path"

    log_info "Testing template: $template_path"

    # Initialize result structure
    local result='{"name":"'"$template_path"'","category":"'"$(dirname "$template_path")"'"'
    local test_start=$(date +%s)
    local overall_status="passed"
    local error_msg=""

    # Check if template directory exists
    if [[ ! -d "$template_dir" ]]; then
        log_error "Template directory not found: $template_dir"
        result+=',"prep":{"status":"failed","duration":"0s","error":"Directory not found"}'
        result+=',"overall":"failed","duration":"0s"}'
        TEST_RESULTS+=("$result")
        ((FAILED_TESTS++)) || true
        return 1
    fi

    # Check if Rediaccfile exists
    if [[ ! -f "$template_dir/Rediaccfile" ]]; then
        log_error "Rediaccfile not found in $template_dir"
        result+=',"prep":{"status":"failed","duration":"0s","error":"Rediaccfile not found"}'
        result+=',"overall":"failed","duration":"0s"}'
        TEST_RESULTS+=("$result")
        ((FAILED_TESTS++)) || true
        return 1
    fi

    cd "$template_dir" || {
        log_error "Failed to change directory to $template_dir"
        result+=',"prep":{"status":"failed","duration":"0s","error":"Cannot cd to directory"}'
        result+=',"overall":"failed","duration":"0s"}'
        TEST_RESULTS+=("$result")
        ((FAILED_TESTS++)) || true
        return 1
    }

    # Source Rediaccfile
    log_verbose "Sourcing Rediaccfile"
    # shellcheck source=/dev/null
    if ! source ./Rediaccfile; then
        log_error "Failed to source Rediaccfile"
        result+=',"prep":{"status":"failed","duration":"0s","error":"Failed to source Rediaccfile"}'
        result+=',"overall":"failed","duration":"0s"}'
        TEST_RESULTS+=("$result")
        ((FAILED_TESTS++)) || true
        return 1
    fi

    # Test prep function
    local prep_start=$(date +%s)
    log_verbose "Running prep()"
    if timeout "$TEST_TIMEOUT" bash -c 'source ./Rediaccfile && prep' >/dev/null 2>&1; then
        local prep_duration=$(($(date +%s) - prep_start))
        log_verbose "prep() passed (${prep_duration}s)"
        result+=',"prep":{"status":"passed","duration":"'"${prep_duration}s"'"}'
    else
        local prep_exit_code=$?
        local prep_duration=$(($(date +%s) - prep_start))
        local prep_error="prep function failed"
        if [[ $prep_exit_code -eq 124 ]]; then
            prep_error="prep function timed out after ${TEST_TIMEOUT}s"
            log_error "prep() timed out"
        else
            log_error "prep() failed with exit code $prep_exit_code"
        fi
        result+=',"prep":{"status":"failed","duration":"'"${prep_duration}s"'","error":"'"$prep_error"'"}'
        overall_status="failed"
        error_msg="prep() failed"
    fi

    # Test up function (only if prep passed or CONTINUE_ON_ERROR is set)
    if [[ "$overall_status" == "passed" ]] || [[ $CONTINUE_ON_ERROR -eq 1 ]]; then
        local up_start=$(date +%s)
        log_verbose "Running up()"
        if timeout "$TEST_TIMEOUT" bash -c 'source ./Rediaccfile && up' >/dev/null 2>&1; then
            local up_duration=$(($(date +%s) - up_start))
            log_verbose "up() passed (${up_duration}s)"
            result+=',"up":{"status":"passed","duration":"'"${up_duration}s"'"}'
        else
            local up_exit_code=$?
            local up_duration=$(($(date +%s) - up_start))
            local up_error="up function failed"
            if [[ $up_exit_code -eq 124 ]]; then
                up_error="up function timed out after ${TEST_TIMEOUT}s"
                log_error "up() timed out"
            else
                log_error "up() failed with exit code $up_exit_code"
            fi
            result+=',"up":{"status":"failed","duration":"'"${up_duration}s"'","error":"'"$up_error"'"}'
            overall_status="failed"
            error_msg="up() failed"
        fi

        # Check health (only if up passed or CONTINUE_ON_ERROR is set)
        if [[ "$overall_status" == "passed" ]] || [[ $CONTINUE_ON_ERROR -eq 1 ]]; then
            local health_start=$(date +%s)
            log_verbose "Checking health"
            if check_health "$template_dir"; then
                local health_duration=$(($(date +%s) - health_start))
                log_verbose "Health check passed (${health_duration}s)"
                result+=',"health":{"status":"passed","duration":"'"${health_duration}s"'"}'
            else
                local health_duration=$(($(date +%s) - health_start))
                log_error "Health check failed"
                result+=',"health":{"status":"failed","duration":"'"${health_duration}s"'","error":"Health check timeout or containers not healthy"}'
                overall_status="failed"
                error_msg="Health check failed"
            fi
        fi

        # Always try to run down() for cleanup
        local down_start=$(date +%s)
        log_verbose "Running down()"
        if timeout "$TEST_TIMEOUT" bash -c 'source ./Rediaccfile && down' >/dev/null 2>&1; then
            local down_duration=$(($(date +%s) - down_start))
            log_verbose "down() passed (${down_duration}s)"
            result+=',"down":{"status":"passed","duration":"'"${down_duration}s"'"}'
        else
            local down_exit_code=$?
            local down_duration=$(($(date +%s) - down_start))
            local down_error="down function failed"
            if [[ $down_exit_code -eq 124 ]]; then
                down_error="down function timed out after ${TEST_TIMEOUT}s"
                log_error "down() timed out"
            else
                log_error "down() failed with exit code $down_exit_code"
            fi
            result+=',"down":{"status":"failed","duration":"'"${down_duration}s"'","error":"'"$down_error"'"}'
            overall_status="failed"
            if [[ -z "$error_msg" ]]; then
                error_msg="down() failed"
            fi
        fi
    fi

    # Cleanup
    local cleanup_start=$(date +%s)
    log_verbose "Cleaning up"
    cleanup_images "$template_dir"
    cleanup_directories "$template_dir"
    cleanup_volumes
    local cleanup_duration=$(($(date +%s) - cleanup_start))
    result+=',"cleanup":{"status":"passed","duration":"'"${cleanup_duration}s"'"}'

    # Calculate total duration
    local test_duration=$(($(date +%s) - test_start))

    # Finalize result
    result+=',"overall":"'"$overall_status"'","duration":"'"${test_duration}s"'"'
    if [[ -n "$error_msg" ]]; then
        result+=',"error":"'"$error_msg"'"'
    else
        result+=',"error":null'
    fi
    result+='}'

    # Store result
    TEST_RESULTS+=("$result")

    # Update counters
    if [[ "$overall_status" == "passed" ]]; then
        ((PASSED_TESTS++)) || true
        log_success "Template passed: $template_path (${test_duration}s)"
    else
        ((FAILED_TESTS++)) || true
        log_error "Template failed: $template_path (${test_duration}s)"
    fi

    # Return to script directory
    cd "$SCRIPT_DIR" || true

    return 0
}

#==============================================================================
# Reporting Functions
#==============================================================================

generate_report() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    local duration_formatted="${total_duration}s"

    # Calculate minutes if duration is significant
    if [[ $total_duration -ge 60 ]]; then
        local minutes=$((total_duration / 60))
        local seconds=$((total_duration % 60))
        duration_formatted="${minutes}m${seconds}s"
    fi

    log_info "Generating test report"

    # Create JSON report
    cat > "$RESULTS_FILE" << EOF
{
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "skipped": $SKIPPED_TESTS,
    "duration": "$duration_formatted",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  },
  "results": [
EOF

    # Add results
    local first=1
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $first -eq 1 ]]; then
            first=0
        else
            echo "," >> "$RESULTS_FILE"
        fi
        echo "    $result" >> "$RESULTS_FILE"
    done

    cat >> "$RESULTS_FILE" << EOF

  ]
}
EOF

    log_info "Test report saved to $RESULTS_FILE"
}

print_summary() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    local duration_formatted="${total_duration}s"

    if [[ $total_duration -ge 60 ]]; then
        local minutes=$((total_duration / 60))
        local seconds=$((total_duration % 60))
        duration_formatted="${minutes}m${seconds}s"
    fi

    echo "" >&2
    echo "==========================================" >&2
    echo "          TEST SUMMARY" >&2
    echo "==========================================" >&2
    echo "Total tests:    $TOTAL_TESTS" >&2
    print_color "$GREEN" "Passed:         $PASSED_TESTS"
    print_color "$RED" "Failed:         $FAILED_TESTS"
    print_color "$YELLOW" "Skipped:        $SKIPPED_TESTS"
    echo "Duration:       $duration_formatted" >&2
    echo "==========================================" >&2
    echo "" >&2

    if [[ $FAILED_TESTS -gt 0 ]]; then
        print_color "$RED" "Some tests failed. Check $RESULTS_FILE for details."
        return 1
    else
        print_color "$GREEN" "All tests passed!"
        return 0
    fi
}

#==============================================================================
# Main Function
#==============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --category)
                FILTER_CATEGORY="$2"
                shift 2
                ;;
            --template)
                FILTER_TEMPLATES+=("$2")
                shift 2
                ;;
            --skip)
                SKIP_TEMPLATES+=("$2")
                shift 2
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --no-cleanup)
                CLEANUP_IMAGES=0
                shift
                ;;
            --output)
                RESULTS_FILE="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    log_info "Starting template tests"
    log_info "Templates directory: $TEMPLATES_DIR"
    log_info "Results file: $RESULTS_FILE"

    if [[ -n "$FILTER_CATEGORY" ]]; then
        log_info "Filter category: $FILTER_CATEGORY"
    fi

    if [[ ${#FILTER_TEMPLATES[@]} -gt 0 ]]; then
        log_info "Filter templates: ${FILTER_TEMPLATES[*]}"
    fi

    if [[ ${#SKIP_TEMPLATES[@]} -gt 0 ]]; then
        log_info "Skipping templates: ${SKIP_TEMPLATES[*]}"
    fi

    # Discover templates
    mapfile -t templates < <(discover_templates)
    TOTAL_TESTS=${#templates[@]}

    # Test each template
    for template in "${templates[@]}"; do
        test_template "$template"
        echo "" >&2
    done

    # Generate report
    generate_report

    # Print summary
    print_summary

    local exit_code=$?
    exit $exit_code
}

# Run main function
main "$@"
