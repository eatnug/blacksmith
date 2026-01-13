#!/bin/bash
# siat-post.sh - Post-step hook for siat workflow
# Validates output and computes next step deterministically
#
# Usage: siat-post.sh <spec_path> <config_path>
# Output: JSON with validation results and next step info

set -e

SPEC_PATH="$1"
CONFIG_PATH="${2:-.claude/siat/config.yml}"

# ============================================================================
# Helper Functions
# ============================================================================

get_frontmatter() {
    local file="$1"
    awk '
        /^---$/ {
            if (in_fm) { exit }
            in_fm=1
            next
        }
        in_fm { print }
    ' "$file"
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

get_open_questions() {
    local file="$1"

    # Parse open_questions array with nested fields
    awk '
        /^---$/ { if (in_fm) exit; in_fm=1; next }
        in_fm && /^open_questions:/ { in_oq=1; next }
        in_fm && in_oq && /^[a-z]/ { exit }
        in_fm && in_oq && /^[[:space:]]+-[[:space:]]*question:/ {
            if (current_q != "") print_question()
            gsub(/^[[:space:]]+-[[:space:]]*question:[[:space:]]*/, "")
            gsub(/"/, "")
            current_q = $0
            resolved = "false"
        }
        in_fm && in_oq && /^[[:space:]]+resolved:/ {
            gsub(/.*resolved:[[:space:]]*/, "")
            resolved = $0
        }
        in_fm && in_oq && /^[[:space:]]+context:/ {
            gsub(/.*context:[[:space:]]*/, "")
            gsub(/"/, "")
            context = $0
        }
        END { if (current_q != "") print_question() }

        function print_question() {
            printf "{\"question\":\"%s\",\"resolved\":%s,\"context\":\"%s\"}\n", current_q, resolved, context
        }
    ' "$file"
}

get_body_length() {
    local file="$1"

    # Count lines after frontmatter
    awk '
        /^---$/ {
            if (in_fm) { in_fm=0; next }
            in_fm=1
            next
        }
        !in_fm { count++ }
        END { print count+0 }
    ' "$file"
}

# ============================================================================
# Validation
# ============================================================================

ERRORS=()
WARNINGS=()

# Check file exists
if [[ ! -f "$SPEC_PATH" ]]; then
    echo '{"valid": false, "errors": ["spec file not found: '"$SPEC_PATH"'"]}' | jq .
    exit 1
fi

# Parse spec info
TASK_ID=$(get_frontmatter_field "$SPEC_PATH" "id")
STEP=$(basename "$SPEC_PATH" .md)
PARENT=$(get_frontmatter_field "$SPEC_PATH" "parent")

# macOS bash 3.x compatible array reading (no mapfile)
STEPS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && STEPS+=("$line")
done < <(get_frontmatter_array "$SPEC_PATH" "steps")

CHILDREN=()
while IFS= read -r line; do
    [[ -n "$line" ]] && CHILDREN+=("$line")
done < <(get_frontmatter_array "$SPEC_PATH" "children")

# Required fields validation
if [[ -z "$TASK_ID" ]]; then
    ERRORS+=("missing required field: id")
fi

if [[ ${#STEPS[@]} -eq 0 ]]; then
    ERRORS+=("missing required field: steps")
fi

# Body content validation
BODY_LENGTH=$(get_body_length "$SPEC_PATH")
if [[ "$BODY_LENGTH" -lt 5 ]]; then
    ERRORS+=("spec body is too short (${BODY_LENGTH} lines)")
fi

# ============================================================================
# Open Questions Processing
# ============================================================================

UNRESOLVED_QUESTIONS=()
while IFS= read -r q; do
    if [[ -n "$q" ]]; then
        resolved=$(echo "$q" | jq -r '.resolved')
        if [[ "$resolved" == "false" ]]; then
            UNRESOLVED_QUESTIONS+=("$q")
        fi
    fi
done < <(get_open_questions "$SPEC_PATH")

if [[ ${#UNRESOLVED_QUESTIONS[@]} -gt 0 ]]; then
    WARNINGS+=("${#UNRESOLVED_QUESTIONS[@]} unresolved questions")
fi

# ============================================================================
# Next Step Calculation
# ============================================================================

NEXT_STEP=""
NEXT_TASK_ID=""
IS_COMPLETE=false
IS_FORK=false

if [[ ${#CHILDREN[@]} -eq 0 ]]; then
    # No children defined - check remaining steps
    if [[ ${#STEPS[@]} -gt 1 ]]; then
        NEXT_STEP="${STEPS[1]}"
        NEXT_TASK_ID="$TASK_ID"
    else
        IS_COMPLETE=true
    fi
elif [[ ${#CHILDREN[@]} -eq 1 ]]; then
    # Single child
    CHILD="${CHILDREN[0]}"
    NEXT_STEP="${CHILD%%/*}"
    NEXT_TASK_ID="${CHILD#*/}"
else
    # Multiple children = fork
    IS_FORK=true
fi

# ============================================================================
# Output JSON
# ============================================================================

ERRORS_JSON=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
CHILDREN_JSON=$(printf '%s\n' "${CHILDREN[@]}" | jq -R . | jq -s .)
STEPS_JSON=$(printf '%s\n' "${STEPS[@]}" | jq -R . | jq -s .)
QUESTIONS_JSON=$(printf '%s\n' "${UNRESOLVED_QUESTIONS[@]}" | jq -s '.')

VALID=true
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    VALID=false
fi

jq -n \
    --argjson valid "$VALID" \
    --argjson errors "$ERRORS_JSON" \
    --argjson warnings "$WARNINGS_JSON" \
    --arg task_id "$TASK_ID" \
    --arg step "$STEP" \
    --arg spec_path "$SPEC_PATH" \
    --arg parent "$PARENT" \
    --argjson steps "$STEPS_JSON" \
    --argjson children "$CHILDREN_JSON" \
    --arg next_step "$NEXT_STEP" \
    --arg next_task_id "$NEXT_TASK_ID" \
    --argjson is_complete "$IS_COMPLETE" \
    --argjson is_fork "$IS_FORK" \
    --argjson unresolved_questions "$QUESTIONS_JSON" \
    '{
        valid: $valid,
        errors: $errors,
        warnings: $warnings,
        spec: {
            task_id: $task_id,
            step: $step,
            path: $spec_path,
            parent: (if $parent == "" then null else $parent end),
            steps: $steps,
            children: $children
        },
        next: {
            step: (if $next_step == "" then null else $next_step end),
            task_id: (if $next_task_id == "" then null else $next_task_id end),
            is_complete: $is_complete,
            is_fork: $is_fork,
            fork_children: (if $is_fork then $children else [] end)
        },
        unresolved_questions: $unresolved_questions
    }'
