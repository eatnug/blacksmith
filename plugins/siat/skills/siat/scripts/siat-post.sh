#!/bin/bash
# siat-post.sh - Post-step hook for siat workflow (v7.0)
# Validates output and computes next step deterministically
#
# Usage: siat-post.sh <spec_path> <config_path>
# Output: JSON with validation results and next step info
#
# Frontmatter format (v7.0):
#   id, step, prev, next, status, open_questions

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
            context = ""
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
# Validation
# ============================================================================

ERRORS=()
WARNINGS=()

# Check file exists
if [[ ! -f "$SPEC_PATH" ]]; then
    echo '{"valid": false, "errors": ["spec file not found: '"$SPEC_PATH"'"]}' | jq .
    exit 1
fi

# Parse spec info (v7.0 frontmatter)
TASK_ID=$(get_frontmatter_field "$SPEC_PATH" "id")
STEP=$(get_frontmatter_field "$SPEC_PATH" "step")
PREV=$(get_frontmatter_field "$SPEC_PATH" "prev")
NEXT=$(get_frontmatter_field "$SPEC_PATH" "next")
STATUS=$(get_frontmatter_field "$SPEC_PATH" "status")

# If step not in frontmatter, get from filename
if [[ -z "$STEP" ]]; then
    STEP=$(basename "$SPEC_PATH" .md)
fi

# Required fields validation
if [[ -z "$TASK_ID" ]]; then
    ERRORS+=("missing required field: id")
fi

if [[ -z "$STEP" ]]; then
    ERRORS+=("missing required field: step")
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
# Next Step Calculation (v7.0 - linear flow, no fork)
# ============================================================================

NEXT_STEP=""
NEXT_TASK_ID=""
IS_COMPLETE=false

# Get steps from config
ALL_STEPS=()
if [[ -f "$CONFIG_PATH" ]]; then
    while IFS= read -r line; do
        [[ -n "$line" ]] && ALL_STEPS+=("$line")
    done < <(get_steps_array "$CONFIG_PATH")
fi

# Default steps if not found
if [[ ${#ALL_STEPS[@]} -eq 0 ]]; then
    ALL_STEPS=("specify" "plan" "implement" "review")
fi

# Calculate next step based on current position
STEP_IDX=$(get_step_index "$STEP" "${ALL_STEPS[@]}")

if [[ "$STEP_IDX" -ge 0 ]] && [[ "$STEP_IDX" -lt $((${#ALL_STEPS[@]}-1)) ]]; then
    NEXT_STEP="${ALL_STEPS[$((STEP_IDX+1))]}"
    NEXT_TASK_ID="$TASK_ID"
else
    IS_COMPLETE=true
fi

# ============================================================================
# Output JSON
# ============================================================================

ERRORS_JSON=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
STEPS_JSON=$(printf '%s\n' "${ALL_STEPS[@]}" | jq -R . | jq -s .)
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
    --arg prev "$PREV" \
    --arg next "$NEXT" \
    --arg status "$STATUS" \
    --argjson steps "$STEPS_JSON" \
    --arg next_step "$NEXT_STEP" \
    --arg next_task_id "$NEXT_TASK_ID" \
    --argjson is_complete "$IS_COMPLETE" \
    --argjson unresolved_questions "$QUESTIONS_JSON" \
    '{
        valid: $valid,
        errors: $errors,
        warnings: $warnings,
        spec: {
            task_id: $task_id,
            step: $step,
            path: $spec_path,
            prev: (if $prev == "" then null else $prev end),
            next: (if $next == "" then null else $next end),
            status: $status,
            steps: $steps
        },
        next: {
            step: (if $next_step == "" then null else $next_step end),
            task_id: (if $next_task_id == "" then null else $next_task_id end),
            is_complete: $is_complete
        },
        unresolved_questions: $unresolved_questions
    }'
