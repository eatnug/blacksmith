#!/bin/bash
# siat-pre.sh - Pre-step hook for siat workflow (v7.0)
# Generates deterministic metadata before AI step execution
#
# Usage: siat-pre.sh <config_path> <step> <request_or_task_id>
# Output: JSON with all computed metadata
#
# Frontmatter format (v7.0):
#   id, step, prev, next, status, open_questions

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
    local latest
    latest=$(ls -t "${task_dir}"/*.md 2>/dev/null | head -1)
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

get_step_index() {
    local target="$1"
    shift
    local steps=("$@")
    local i=0
    for s in "${steps[@]}"; do
        if [[ "$s" == "$target" ]]; then
            echo "$i"
            return
        fi
        ((i++))
    done
    echo "-1"
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

# Get all steps from config
ALL_STEPS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && ALL_STEPS+=("$line")
done < <(get_steps_array "$CONFIG_PATH")

# Default steps if not found in config
if [[ ${#ALL_STEPS[@]} -eq 0 ]]; then
    ALL_STEPS=("specify" "plan" "implement" "review")
fi

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

# Calculate prev/next and determine current step
PREV=""
NEXT=""
COMPLETED_STEPS=()

if [[ "$IS_NEW_TASK" == "true" ]]; then
    # New task: start from first step (or specified step)
    if [[ -z "$STEP" ]]; then
        STEP="${ALL_STEPS[0]}"
    fi

    # Calculate prev/next for new task
    STEP_IDX=$(get_step_index "$STEP" "${ALL_STEPS[@]}")

    if [[ "$STEP_IDX" -gt 0 ]]; then
        PREV_STEP="${ALL_STEPS[$((STEP_IDX-1))]}"
        PREV="${TASK_ID}/${PREV_STEP}"
    fi

    if [[ "$STEP_IDX" -lt $((${#ALL_STEPS[@]}-1)) ]]; then
        NEXT_STEP="${ALL_STEPS[$((STEP_IDX+1))]}"
        NEXT="${TASK_ID}/${NEXT_STEP}"
    fi
else
    # Continuing task: find latest spec and determine next step
    LATEST_SPEC=$(find_latest_spec "$OUTPUT_PATH" "$TASK_ID")

    if [[ -n "$LATEST_SPEC" ]]; then
        # Get current step from latest spec
        LATEST_STEP=$(basename "$LATEST_SPEC" .md)
        LATEST_STATUS=$(get_frontmatter_field "$LATEST_SPEC" "status")

        # Calculate completed steps
        for f in "${TASK_DIR}"/*.md; do
            if [[ -f "$f" ]]; then
                local_step=$(basename "$f" .md)
                local_status=$(get_frontmatter_field "$f" "status")
                if [[ "$local_status" == "approved" ]]; then
                    COMPLETED_STEPS+=("$local_step")
                fi
            fi
        done

        # Only auto-determine STEP if not explicitly provided
        if [[ -z "$STEP" ]]; then
            # If latest is approved, move to next step
            if [[ "$LATEST_STATUS" == "approved" ]]; then
                STEP_IDX=$(get_step_index "$LATEST_STEP" "${ALL_STEPS[@]}")
                if [[ "$STEP_IDX" -lt $((${#ALL_STEPS[@]}-1)) ]]; then
                    STEP="${ALL_STEPS[$((STEP_IDX+1))]}"
                else
                    STEP=""  # Task complete
                fi
            else
                # Continue from latest step
                STEP="$LATEST_STEP"
            fi
        fi
    fi

    # Calculate prev/next for continuing task
    if [[ -n "$STEP" ]]; then
        STEP_IDX=$(get_step_index "$STEP" "${ALL_STEPS[@]}")

        if [[ "$STEP_IDX" -gt 0 ]]; then
            PREV_STEP="${ALL_STEPS[$((STEP_IDX-1))]}"
            PREV="${TASK_ID}/${PREV_STEP}"
        fi

        if [[ "$STEP_IDX" -lt $((${#ALL_STEPS[@]}-1)) ]]; then
            NEXT_STEP="${ALL_STEPS[$((STEP_IDX+1))]}"
            NEXT="${TASK_ID}/${NEXT_STEP}"
        fi
    fi
fi

# Spec file path
SPEC_PATH="${TASK_DIR}/${STEP}.md"

# Generate JSON arrays
STEPS_JSON=$(printf '%s\n' "${ALL_STEPS[@]}" | jq -R . | jq -s .)
COMPLETED_JSON=$(printf '%s\n' "${COMPLETED_STEPS[@]}" | jq -R . | jq -s .)

# Output JSON with v7.0 frontmatter format
jq -n \
    --arg task_id "$TASK_ID" \
    --arg step "$STEP" \
    --arg spec_path "$SPEC_PATH" \
    --arg task_dir "$TASK_DIR" \
    --arg output_path "$OUTPUT_PATH" \
    --arg prev "$PREV" \
    --arg next "$NEXT" \
    --arg request "$REQUEST" \
    --argjson is_new "$IS_NEW_TASK" \
    --argjson steps "$STEPS_JSON" \
    --argjson completed "$COMPLETED_JSON" \
    '{
        task_id: $task_id,
        step: $step,
        spec_path: $spec_path,
        task_dir: $task_dir,
        output_path: $output_path,
        prev: (if $prev == "" then null else $prev end),
        next: (if $next == "" then null else $next end),
        request: (if $request == "" then null else $request end),
        is_new_task: $is_new,
        steps: $steps,
        completed: $completed,
        frontmatter: {
            id: $task_id,
            step: $step,
            prev: (if $prev == "" then null else $prev end),
            next: (if $next == "" then null else $next end),
            status: "pending_feedback",
            open_questions: []
        }
    }'
