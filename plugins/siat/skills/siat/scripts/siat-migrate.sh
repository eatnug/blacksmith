#!/bin/bash
# siat-migrate.sh - Migrate from v5.x to v6.x
# Handles:
#   1. Remove old scripts folder (now included in skill)
#   2. Convert step-centric to feature-centric structure
#
# Usage: siat-migrate.sh <config_path> [--dry-run]
# Output: JSON with migration results

set -e

CONFIG_PATH="${1:-.claude/siat/config.yml}"
DRY_RUN=false
[[ "$2" == "--dry-run" ]] && DRY_RUN=true

# ============================================================================
# Helper Functions
# ============================================================================

parse_yaml_nested() {
    local file="$1"
    local parent="$2"
    local key="$3"
    awk -v parent="$parent" -v key="$key" '
        $0 ~ "^"parent":" { in_parent=1; next }
        in_parent && /^[a-z]/ { in_parent=0 }
        in_parent && $0 ~ "^[[:space:]]+"key":" {
            gsub(/^[[:space:]]+/, "")
            gsub(/^[^:]+:[[:space:]]*/, "")
            gsub(/"/, "")
            print
            exit
        }
    ' "$file"
}

get_steps_array() {
    local file="$1"
    awk '
        /^steps:/ || /^[[:space:]]+steps:/ { in_steps=1; next }
        in_steps && /^[a-z]/ { exit }
        in_steps && /^[[:space:]]+-/ {
            gsub(/^[[:space:]]+-[[:space:]]*/, "")
            gsub(/#.*/, "")
            gsub(/[[:space:]]+$/, "")
            if (length($0) > 0) print
        }
    ' "$file"
}

# ============================================================================
# Main Logic
# ============================================================================

if [[ ! -f "$CONFIG_PATH" ]]; then
    echo '{"error": "config not found", "path": "'"$CONFIG_PATH"'"}' | jq .
    exit 1
fi

OUTPUT_PATH=$(parse_yaml_nested "$CONFIG_PATH" "output" "path")
OUTPUT_PATH="${OUTPUT_PATH:-.claude/siat/specs}"
SIAT_DIR=$(dirname "$CONFIG_PATH")

# Read steps into array (macOS compatible)
STEPS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && STEPS+=("$line")
done < <(get_steps_array "$CONFIG_PATH")

ACTIONS=""
MIGRATED_FILES=""
REMOVED_DIRS=""

# ============================================================================
# 1. Remove old scripts folder
# ============================================================================

OLD_SCRIPTS_DIR="${SIAT_DIR}/scripts"
if [[ -d "$OLD_SCRIPTS_DIR" ]]; then
    ACTIONS="${ACTIONS}remove_old_scripts\n"

    if [[ "$DRY_RUN" == "false" ]]; then
        rm -rf "$OLD_SCRIPTS_DIR"
    fi
    REMOVED_DIRS="${REMOVED_DIRS}${OLD_SCRIPTS_DIR}\n"
fi

# ============================================================================
# 2. Detect and convert step-centric to feature-centric
# ============================================================================

STEP_CENTRIC_DETECTED=false

for step in "${STEPS[@]}"; do
    STEP_DIR="${OUTPUT_PATH}/${step}"
    if [[ -d "$STEP_DIR" ]]; then
        if ls "${STEP_DIR}"/*.md 1>/dev/null 2>&1; then
            STEP_CENTRIC_DETECTED=true
            break
        fi
    fi
done

if [[ "$STEP_CENTRIC_DETECTED" == "true" ]]; then
    ACTIONS="${ACTIONS}convert_to_feature_centric\n"

    # Collect all task IDs from step folders (using temp file for macOS compat)
    TASK_IDS_FILE=$(mktemp)
    trap "rm -f $TASK_IDS_FILE" EXIT

    for step in "${STEPS[@]}"; do
        STEP_DIR="${OUTPUT_PATH}/${step}"
        if [[ -d "$STEP_DIR" ]]; then
            for file in "${STEP_DIR}"/*.md; do
                if [[ -f "$file" ]]; then
                    basename "$file" .md >> "$TASK_IDS_FILE"
                fi
            done
        fi
    done

    # Get unique task IDs
    UNIQUE_TASK_IDS=$(sort -u "$TASK_IDS_FILE")

    # Migrate each task
    while IFS= read -r task_id; do
        [[ -z "$task_id" ]] && continue
        TASK_DIR="${OUTPUT_PATH}/${task_id}"

        if [[ "$DRY_RUN" == "false" ]]; then
            mkdir -p "$TASK_DIR"
        fi

        for step in "${STEPS[@]}"; do
            OLD_FILE="${OUTPUT_PATH}/${step}/${task_id}.md"
            NEW_FILE="${TASK_DIR}/${step}.md"

            if [[ -f "$OLD_FILE" ]]; then
                if [[ "$DRY_RUN" == "false" ]]; then
                    mv "$OLD_FILE" "$NEW_FILE"
                fi
                MIGRATED_FILES="${MIGRATED_FILES}${step}/${task_id}.md -> ${task_id}/${step}.md\n"
            fi
        done
    done <<< "$UNIQUE_TASK_IDS"

    # Remove empty step directories
    for step in "${STEPS[@]}"; do
        STEP_DIR="${OUTPUT_PATH}/${step}"
        if [[ -d "$STEP_DIR" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                rmdir "$STEP_DIR" 2>/dev/null || true
            fi
            REMOVED_DIRS="${REMOVED_DIRS}${STEP_DIR}\n"
        fi
    done
fi

# ============================================================================
# Output
# ============================================================================

# Convert newline-separated strings to JSON arrays
ACTIONS_JSON=$(echo -e "$ACTIONS" | grep -v '^$' | jq -R . | jq -s . 2>/dev/null || echo '[]')
MIGRATED_JSON=$(echo -e "$MIGRATED_FILES" | grep -v '^$' | jq -R . | jq -s . 2>/dev/null || echo '[]')
REMOVED_JSON=$(echo -e "$REMOVED_DIRS" | grep -v '^$' | jq -R . | jq -s . 2>/dev/null || echo '[]')

jq -n \
    --argjson dry_run "$DRY_RUN" \
    --argjson actions "$ACTIONS_JSON" \
    --argjson migrated "$MIGRATED_JSON" \
    --argjson removed "$REMOVED_JSON" \
    --arg output_path "$OUTPUT_PATH" \
    '{
        dry_run: $dry_run,
        actions: $actions,
        migrated_files: $migrated,
        removed_dirs: $removed,
        output_path: $output_path,
        summary: {
            files_migrated: ($migrated | length),
            dirs_removed: ($removed | length)
        }
    }'
