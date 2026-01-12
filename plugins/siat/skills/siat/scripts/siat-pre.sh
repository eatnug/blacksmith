#!/bin/bash
# siat-pre.sh - Pre-step hook for siat workflow
# Generates deterministic metadata before AI step execution
#
# Usage: siat-pre.sh <config_path> <step> <request_or_task_id>
# Output: JSON with all computed metadata

set -e

CONFIG_PATH="${1:-.claude/siat/config.yml}"
STEP="$2"
INPUT="$3"

# ============================================================================
# Helper Functions
# ============================================================================

slugify() {
    echo "$1" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9가-힣]/-/g' | \
        sed 's/--*/-/g' | \
        sed 's/^-//' | \
        sed 's/-$//' | \
        cut -c1-50
}

parse_yaml_value() {
    local file="$1"
    local key="$2"
    grep "^${key}:" "$file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | tr -d '"' || echo ""
}

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

find_latest_spec() {
    local output_path="$1"
    local task_id="$2"
    local task_dir="${output_path}/${task_id}"

    if [[ ! -d "$task_dir" ]]; then
        echo ""
        return
    fi

    # Find the most recently modified .md file
    local latest=$(ls -t "${task_dir}"/*.md 2>/dev/null | head -1)
    if [[ -n "$latest" ]]; then
        echo "$latest"
    fi
}

get_frontmatter_field() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        /^---$/ { if (in_fm) exit; in_fm=1; next }
        in_fm && $0 ~ "^"field":" {
            gsub(/^[^:]+:[[:space:]]*/, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print
            exit
        }
    ' "$file"
}

get_frontmatter_array() {
    local file="$1"
    local field="$2"

    awk -v field="$field" '
        /^---$/ { if (in_fm) exit; in_fm=1; next }
        in_fm && $0 ~ "^"field":" { in_field=1; next }
        in_fm && in_field && /^[a-z]/ { exit }
        in_fm && in_field && /^[[:space:]]+-/ {
            gsub(/^[[:space:]]+-[[:space:]]*/, "")
            gsub(/"/, "")
            print
        }
    ' "$file"
}

# ============================================================================
# Main Logic
# ============================================================================

# Check config exists
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo '{"error": "config not found", "path": "'"$CONFIG_PATH"'"}' | jq .
    exit 1
fi

# Parse config
OUTPUT_PATH=$(parse_yaml_nested "$CONFIG_PATH" "output" "path")
OUTPUT_PATH="${OUTPUT_PATH:-.claude/siat/specs}"
EXEC_MODE=$(parse_yaml_nested "$CONFIG_PATH" "execution" "mode")
EXEC_MODE="${EXEC_MODE:-manual}"

# Get all steps from config
mapfile -t ALL_STEPS < <(get_steps_array "$CONFIG_PATH")

# Determine if this is a new task or continuing
IS_NEW_TASK=false
TASK_ID=""
REQUEST=""

# Check if input matches existing task folder
if [[ -d "${OUTPUT_PATH}/${INPUT}" ]]; then
    TASK_ID="$INPUT"
    IS_NEW_TASK=false
elif [[ -n "$INPUT" ]]; then
    # Check if it looks like a task-id (no spaces, lowercase)
    if [[ "$INPUT" =~ ^[a-z0-9가-힣-]+$ ]] && [[ -d "${OUTPUT_PATH}/${INPUT}" ]]; then
        TASK_ID="$INPUT"
        IS_NEW_TASK=false
    else
        # It's a new request
        REQUEST="$INPUT"
        TASK_ID=$(slugify "$INPUT")
        IS_NEW_TASK=true
    fi
fi

# Create task directory
TASK_DIR="${OUTPUT_PATH}/${TASK_ID}"
mkdir -p "$TASK_DIR"

# Find parent and calculate remaining steps
PARENT=""
REMAINING_STEPS=()
COMPLETED_STEPS=()

if [[ "$IS_NEW_TASK" == "true" ]]; then
    # New task: start from first step (or specified step)
    if [[ -z "$STEP" ]]; then
        STEP="${ALL_STEPS[0]}"
    fi

    # Remaining steps from current step onwards
    found_current=false
    for s in "${ALL_STEPS[@]}"; do
        if [[ "$s" == "$STEP" ]]; then
            found_current=true
        fi
        if [[ "$found_current" == "true" ]]; then
            REMAINING_STEPS+=("$s")
        fi
    done
else
    # Continuing task: find latest spec and determine next step
    LATEST_SPEC=$(find_latest_spec "$OUTPUT_PATH" "$TASK_ID")

    if [[ -n "$LATEST_SPEC" ]]; then
        # Get parent from latest spec path
        PARENT="${TASK_ID}/$(basename "$LATEST_SPEC" .md)"

        # Get children from latest spec
        mapfile -t CHILDREN < <(get_frontmatter_array "$LATEST_SPEC" "children")

        if [[ ${#CHILDREN[@]} -gt 0 ]]; then
            # Has children - next step is first child's step
            NEXT_CHILD="${CHILDREN[0]}"
            STEP="${NEXT_CHILD%%/*}"  # Extract step from "step/task_id"
        else
            # No children - check remaining steps
            mapfile -t SPEC_STEPS < <(get_frontmatter_array "$LATEST_SPEC" "steps")
            if [[ ${#SPEC_STEPS[@]} -gt 1 ]]; then
                STEP="${SPEC_STEPS[1]}"  # Next step after current
            else
                STEP=""  # Task complete
            fi
        fi

        # Calculate completed steps
        for f in "${TASK_DIR}"/*.md; do
            if [[ -f "$f" ]]; then
                COMPLETED_STEPS+=("$(basename "$f" .md)")
            fi
        done
    fi

    # Calculate remaining steps
    if [[ -n "$STEP" ]]; then
        found_current=false
        for s in "${ALL_STEPS[@]}"; do
            if [[ "$s" == "$STEP" ]]; then
                found_current=true
            fi
            if [[ "$found_current" == "true" ]]; then
                REMAINING_STEPS+=("$s")
            fi
        done
    fi
fi

# Spec file path
SPEC_PATH="${TASK_DIR}/${STEP}.md"

# Generate frontmatter template
STEPS_JSON=$(printf '%s\n' "${REMAINING_STEPS[@]}" | jq -R . | jq -s .)
COMPLETED_JSON=$(printf '%s\n' "${COMPLETED_STEPS[@]}" | jq -R . | jq -s .)

# Output JSON
jq -n \
    --arg task_id "$TASK_ID" \
    --arg step "$STEP" \
    --arg spec_path "$SPEC_PATH" \
    --arg task_dir "$TASK_DIR" \
    --arg output_path "$OUTPUT_PATH" \
    --arg parent "$PARENT" \
    --arg request "$REQUEST" \
    --arg exec_mode "$EXEC_MODE" \
    --argjson is_new "$IS_NEW_TASK" \
    --argjson steps "$STEPS_JSON" \
    --argjson completed "$COMPLETED_JSON" \
    '{
        task_id: $task_id,
        step: $step,
        spec_path: $spec_path,
        task_dir: $task_dir,
        output_path: $output_path,
        parent: (if $parent == "" then null else $parent end),
        request: (if $request == "" then null else $request end),
        is_new_task: $is_new,
        execution_mode: $exec_mode,
        steps: $steps,
        completed: $completed,
        frontmatter: {
            id: $task_id,
            steps: $steps,
            parent: (if $parent == "" then null else $parent end),
            children: []
        }
    }'
