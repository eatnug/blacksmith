#!/bin/bash
# siat-migrate.sh - Migrate from v6.x to v7.x
# Handles:
#   1. Config format: hooks.pre-step → hooks.pre_step, execution.mode → gateway
#   2. Old steps: clarify, prd, design... → specify, plan, implement, review
#   3. Frontmatter: children, parent, steps → prev, next, status
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

# Read steps into array
STEPS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && STEPS+=("$line")
done < <(get_steps_array "$CONFIG_PATH")

ACTIONS=""
MIGRATED_FILES=""
WARNINGS=""

# ============================================================================
# 1. Detect v6.x config format
# ============================================================================

CONFIG_MIGRATED=false

# Check for old hook format (pre-step, post-step with hyphens)
if grep -q "pre-step:" "$CONFIG_PATH" 2>/dev/null || \
   grep -q "post-step:" "$CONFIG_PATH" 2>/dev/null || \
   grep -q "post-workflow:" "$CONFIG_PATH" 2>/dev/null; then
    ACTIONS="${ACTIONS}convert_config_hooks\n"
    CONFIG_MIGRATED=true
fi

# Check for old execution.mode format
if grep -q "execution:" "$CONFIG_PATH" 2>/dev/null; then
    ACTIONS="${ACTIONS}convert_execution_to_gateway\n"
    CONFIG_MIGRATED=true
fi

# Check for workflow.name format (v5/v6)
if grep -q "workflow:" "$CONFIG_PATH" 2>/dev/null; then
    ACTIONS="${ACTIONS}remove_workflow_section\n"
    CONFIG_MIGRATED=true
fi

# Check for old steps
OLD_STEPS_DETECTED=false
for old_step in "clarify" "reproduce" "root-cause" "prd" "design" "visual-design" "fix" "verify"; do
    if grep -q "- $old_step" "$CONFIG_PATH" 2>/dev/null; then
        OLD_STEPS_DETECTED=true
        break
    fi
done

if [[ "$OLD_STEPS_DETECTED" == "true" ]]; then
    ACTIONS="${ACTIONS}convert_old_steps\n"
    CONFIG_MIGRATED=true
fi

# ============================================================================
# 2. Count existing spec files (for info only - NOT modified)
# ============================================================================

EXISTING_SPECS_COUNT=0

if [[ -d "$OUTPUT_PATH" ]]; then
    EXISTING_SPECS_COUNT=$(find "$OUTPUT_PATH" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
fi

# NOTE: 기존 specs 문서의 frontmatter는 절대 건드리지 않음
# 구조만 맞으면 ({output.path}/{task-id}/{step}.md) 호환됨

# ============================================================================
# 3. Remove old scripts folder (v5.x cleanup)
# ============================================================================

OLD_SCRIPTS_DIR="${SIAT_DIR}/scripts"
if [[ -d "$OLD_SCRIPTS_DIR" ]]; then
    ACTIONS="${ACTIONS}remove_old_scripts\n"

    if [[ "$DRY_RUN" == "false" ]]; then
        rm -rf "$OLD_SCRIPTS_DIR"
    fi
fi

# ============================================================================
# Output
# ============================================================================

ACTIONS_JSON=$(echo -e "$ACTIONS" | grep -v '^$' | jq -R . | jq -s . 2>/dev/null || echo '[]')
WARNINGS_JSON=$(echo -e "$WARNINGS" | grep -v '^$' | jq -R . | jq -s . 2>/dev/null || echo '[]')

jq -n \
    --argjson dry_run "$DRY_RUN" \
    --argjson actions "$ACTIONS_JSON" \
    --argjson warnings "$WARNINGS_JSON" \
    --argjson config_migrated "$CONFIG_MIGRATED" \
    --argjson old_steps "$OLD_STEPS_DETECTED" \
    --argjson existing_specs "$EXISTING_SPECS_COUNT" \
    --arg output_path "$OUTPUT_PATH" \
    '{
        dry_run: $dry_run,
        version: "v6.x → v7.0",
        actions: $actions,
        warnings: $warnings,
        output_path: $output_path,
        details: {
            config_needs_migration: $config_migrated,
            old_steps_detected: $old_steps,
            existing_specs_count: $existing_specs
        },
        summary: {
            actions_needed: ($actions | length)
        },
        note: "기존 specs 문서는 변경하지 않음. 구조만 맞으면 호환됨."
    }'
