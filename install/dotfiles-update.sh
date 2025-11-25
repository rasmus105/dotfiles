#!/bin/bash
#
# Post-update script for dotfiles
# This script is called after git pull to apply changes
#
# Usage:
#   dotfiles-update.sh [OLD_COMMIT] [NEW_COMMIT]
#
# Arguments:
#   OLD_COMMIT: Git commit hash before update (optional)
#   NEW_COMMIT: Git commit hash after update (optional, defaults to HEAD)
#
# When called without arguments (development mode):
#   - Runs stow and system refresh
#   - Skips migrations
#
# When called with commit arguments (from system-dotfiles-update):
#   - Runs stow, migrations, and system refresh
#
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")

# Parse arguments
OLD_COMMIT="${1:-}"
NEW_COMMIT="${2:-$(cd "$DOTFILES_DIR" && git rev-parse HEAD)}"

# Source helper functions
source "$HOME/.local/lib/shell/common.sh"

# Initialize logging with consistent log file name
LOG_FILE="/tmp/gum-log/dotfiles-update.log"
log_init

# ==== Migration System ====

run_migrations() {
    local OLD_COMMIT="$1"
    local NEW_COMMIT="$2"
    local MIGRATIONS_DIR="$SCRIPT_DIR/migrations"
    local STATE_DIR="$HOME/.local/share/dotfiles"
    local STATE_FILE="$STATE_DIR/last-update-commit"

    # Ensure state directory exists
    mkdir -p "$STATE_DIR"

    # Change to dotfiles directory for git operations
    cd "$DOTFILES_DIR"

    # Validate commit hashes
    if ! git rev-parse --verify "$OLD_COMMIT" &>/dev/null; then
        gum_warning "Invalid old commit hash: $OLD_COMMIT"
        return 0
    fi

    if ! git rev-parse --verify "$NEW_COMMIT" &>/dev/null; then
        gum_warning "Invalid new commit hash: $NEW_COMMIT"
        return 0
    fi

    # Check if we actually moved between commits
    if [[ "$OLD_COMMIT" == "$NEW_COMMIT" ]]; then
        gum_info "No new commits, skipping migrations"
        return 0
    fi

    # Get all tags between OLD_COMMIT and NEW_COMMIT (inclusive of NEW_COMMIT)
    local MIGRATION_TAGS
    MIGRATION_TAGS=$(git tag --merged "$NEW_COMMIT" --no-merged "$OLD_COMMIT" 2>/dev/null | sort -V || echo "")

    if [[ -z "$MIGRATION_TAGS" ]]; then
        gum_info "No tagged releases between commits, no migrations needed"
        echo "$NEW_COMMIT" >"$STATE_FILE"
        return 0
    fi

    # Check if migrations directory exists
    if [[ ! -d "$MIGRATIONS_DIR" ]]; then
        gum_info "No migrations directory found, skipping"
        echo "$NEW_COMMIT" >"$STATE_FILE"
        return 0
    fi

    # Display which tags we found
    local TAG_COUNT
    TAG_COUNT=$(echo "$MIGRATION_TAGS" | wc -l)
    gum_info "Found $TAG_COUNT tagged release(s) in range: ${OLD_COMMIT:0:7}..${NEW_COMMIT:0:7}"

    # Run migrations for each tag (in order, oldest first)
    local MIGRATIONS_RUN=0
    while IFS= read -r tag; do
        local MIGRATION_SCRIPT="$MIGRATIONS_DIR/${tag}.sh"

        if [[ -f "$MIGRATION_SCRIPT" ]]; then
            gum_info "Running migration for tag: $tag"

            if bash "$MIGRATION_SCRIPT"; then
                gum_success "Migration $tag completed"
                MIGRATIONS_RUN=$((MIGRATIONS_RUN + 1))
            else
                gum_error "Migration $tag failed!"
                exit 1
            fi
        else
            gum_info "Tag $tag has no migration script (okay)"
        fi
    done <<<"$MIGRATION_TAGS"

    if [[ $MIGRATIONS_RUN -eq 0 ]]; then
        gum_info "No migration scripts to run"
    else
        gum_success "Ran $MIGRATIONS_RUN migration(s)"
    fi

    # Update state file with new commit
    echo "$NEW_COMMIT" >"$STATE_FILE"
}

# ==== Main Update Process ====

if [[ -n "$OLD_COMMIT" ]]; then
    gum_header "Applying Dotfiles Updates" "Updating from ${OLD_COMMIT:0:7} to ${NEW_COMMIT:0:7}"
else
    gum_header "Applying Dotfiles Updates" "Development mode - skipping migrations"
fi

# 1. Stow configurations (relink everything)
gum_section "Updating symlinks..."
source "$SCRIPT_DIR/stow.sh"
log_run "Updating symlinks" "stow_dotfiles"
echo

# 2. Update system configurations (requires sudo)
gum_section "Updating system configurations..."
log_run "Updating system configurations" "cp_system_configs"

echo

# 3. Run migrations (tag-based, only if commit range provided)
if [[ -n "$OLD_COMMIT" ]]; then
    gum_section "Checking for migrations..."
    run_migrations "$OLD_COMMIT" "$NEW_COMMIT"
    echo
else
    gum_muted "Development mode: Skipping migration check"
    echo
fi

# 4. Refresh running services
gum_section "Refreshing system..."
if command_exists system-refresh; then
    timeout 10s system-refresh || gum_warning "system-refresh timed out! (you may want to refresh system manually)"
else
    gum_warning "system-refresh not found, skipping service refresh"
fi
echo

gum_success "Dotfiles update complete!"

# Allow running individual functions
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Script is being run directly
    :
fi
