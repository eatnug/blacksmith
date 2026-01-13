#!/bin/bash
# siat-pre.sh - Pre-step hook for siat workflow (v7.1)
# Generates deterministic metadata before AI step execution
# Parses flags (--remote, --local) and provides gateway/hooks settings
#
# Usage: siat-pre.sh <config_path> <step> <request_or_task_id_with_flags>
# Output: JSON with all computed metadata including gateway settings
#
# Frontmatter format (v7.0):
#   id, step, prev, next, status, open_questions

set -e

CONFIG_PATH="${1:-.claude/siat/config.yml}"
STEP="$2"
RAW_INPUT="$3"

# ============================================================================
# Parse Flags from Input
# ============================================================================

REMOTE_MODE=false
INPUT="$RAW_INPUT"

# Parse --remote flag
if [[ "$RAW_INPUT" =~ ^--remote[[:space:]]* ]]; then
    REMOTE_MODE=true
    INPUT="${RAW_INPUT#--remote}"
    INPUT="${INPUT#"${INPUT%%[![:space:]]*}"}"  # trim leading whitespace
elif [[ "$RAW_INPUT" =~ ^--local[[:space:]]* ]]; then
    REMOTE_MODE=false
    INPUT="${RAW_INPUT#--local}"
    INPUT="${INPUT#"${INPUT%%[![:space:]]*}"}"  # trim leading whitespace
fi

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

is_step_interactive() {
    local config_path="$1"
    local step="$2"
    local config_dir
    config_dir=$(dirname "$config_path")
    local instruction_path="${config_dir}/steps/${step}/instruction.md"

    if [[ -f "$instruction_path" ]]; then
        local interactive_value
        interactive_value=$(get_frontmatter_field "$instruction_path" "interactive")
        if [[ "$interactive_value" == "true" ]]; then
            echo "true"
            return
        fi
    fi
    echo "false"
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

get_hooks_array() {
    local file="$1"
    local hook_name="$2"
    local parent="${3:-hooks}"  # default to top-level hooks, or presets.remote.hooks

    awk -v parent="$parent" -v hook="$hook_name" '
        BEGIN { in_parent=0; in_hook=0; depth=0 }
        $0 ~ "^"parent":" || $0 ~ "^[[:space:]]+"parent":" { in_parent=1; next }
        in_parent && /^[a-z]/ && !/^[[:space:]]/ { in_parent=0 }
        in_parent && $0 ~ "[[:space:]]+"hook":" { in_hook=1; next }
        in_hook && /^[[:space:]]+-[[:space:]]*script:/ {
            gsub(/^[[:space:]]+-[[:space:]]*/, "")
            gsub(/"/, "")
            print
        }
        in_hook && /^[[:space:]]+[a-z_]+:/ && $0 !~ hook { in_hook=0 }
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

# ============================================================================
# Parse Interactive Settings
# ============================================================================

STEP_INTERACTIVE=$(is_step_interactive "$CONFIG_PATH" "$STEP")

# Default interactive settings
INTERACTIVE_CHANNEL=$(parse_yaml_nested "$CONFIG_PATH" "interactive" "channel")
INTERACTIVE_CHANNEL="${INTERACTIVE_CHANNEL:-local}"
INTERACTIVE_SLACK_BOT_TOKEN=$(parse_yaml_nested "$CONFIG_PATH" "interactive" "slack_bot_token")
INTERACTIVE_SLACK_CHANNEL_ID=$(parse_yaml_nested "$CONFIG_PATH" "interactive" "slack_channel_id")

# ============================================================================
# Parse Gateway and Hooks (based on mode)
# ============================================================================

# Default gateway settings
GATEWAY_QUESTIONS=$(parse_yaml_nested "$CONFIG_PATH" "gateway" "questions")
GATEWAY_FEEDBACK=$(parse_yaml_nested "$CONFIG_PATH" "gateway" "feedback")
GATEWAY_QUESTIONS="${GATEWAY_QUESTIONS:-local}"
GATEWAY_FEEDBACK="${GATEWAY_FEEDBACK:-local}"

# Default hooks (from top-level)
HOOKS_PRE_STEP=()
HOOKS_ON_PROCESSED=()
HOOKS_ON_APPROVE=()
HOOKS_ON_REJECT=()
HOOKS_ON_REVISE=()
HOOKS_ON_COMPLETE=()

# Read hooks from config (simplified - just get on_processed for now)
while IFS= read -r line; do
    [[ -n "$line" ]] && HOOKS_ON_PROCESSED+=("$line")
done < <(get_hooks_array "$CONFIG_PATH" "on_processed")

while IFS= read -r line; do
    [[ -n "$line" ]] && HOOKS_ON_APPROVE+=("$line")
done < <(get_hooks_array "$CONFIG_PATH" "on_approve")

# If remote mode, override with presets.remote
if [[ "$REMOTE_MODE" == "true" ]]; then
    # Parse presets.remote.interactive.channel
    REMOTE_INTERACTIVE_CHANNEL=$(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { in_presets=0 }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /^[[:space:]]{4}[a-z]/ && !/interactive/ { next }
        in_remote && /interactive:/ { in_interactive=1; next }
        in_interactive && /channel:/ {
            gsub(/.*channel:[[:space:]]*/, "")
            gsub(/"/, "")
            print
            exit
        }
    ' "$CONFIG_PATH")

    [[ -n "$REMOTE_INTERACTIVE_CHANNEL" ]] && INTERACTIVE_CHANNEL="$REMOTE_INTERACTIVE_CHANNEL"

    # Parse presets.remote.interactive.slack_bot_token
    REMOTE_SLACK_BOT_TOKEN=$(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { in_presets=0 }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /interactive:/ { in_interactive=1; next }
        in_interactive && /^[[:space:]]+[a-z]/ && !/slack/ { next }
        in_interactive && /slack_bot_token:/ {
            gsub(/.*slack_bot_token:[[:space:]]*/, "")
            gsub(/"/, "")
            if ($0 != "null") print
            exit
        }
    ' "$CONFIG_PATH")

    # Parse presets.remote.interactive.slack_channel_id
    REMOTE_SLACK_CHANNEL_ID=$(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { in_presets=0 }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /interactive:/ { in_interactive=1; next }
        in_interactive && /^[[:space:]]+[a-z]/ && !/slack/ { next }
        in_interactive && /slack_channel_id:/ {
            gsub(/.*slack_channel_id:[[:space:]]*/, "")
            gsub(/"/, "")
            if ($0 != "null") print
            exit
        }
    ' "$CONFIG_PATH")

    # Override slack settings if remote preset has values
    [[ -n "$REMOTE_SLACK_BOT_TOKEN" ]] && INTERACTIVE_SLACK_BOT_TOKEN="$REMOTE_SLACK_BOT_TOKEN"
    [[ -n "$REMOTE_SLACK_CHANNEL_ID" ]] && INTERACTIVE_SLACK_CHANNEL_ID="$REMOTE_SLACK_CHANNEL_ID"

    # Parse presets.remote.gateway
    REMOTE_QUESTIONS=$(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { in_presets=0 }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /^[[:space:]]{4}[a-z]/ && !/gateway/ { in_remote=0 }
        in_remote && /gateway:/ { in_gateway=1; next }
        in_gateway && /questions:/ {
            gsub(/.*questions:[[:space:]]*/, "")
            gsub(/"/, "")
            print
            exit
        }
    ' "$CONFIG_PATH")

    REMOTE_FEEDBACK=$(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { in_presets=0 }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /^[[:space:]]{4}[a-z]/ && !/gateway/ { in_remote=0 }
        in_remote && /gateway:/ { in_gateway=1; next }
        in_gateway && /feedback:/ {
            gsub(/.*feedback:[[:space:]]*/, "")
            gsub(/"/, "")
            print
            exit
        }
    ' "$CONFIG_PATH")

    # Override gateway if remote preset has values
    [[ -n "$REMOTE_QUESTIONS" ]] && GATEWAY_QUESTIONS="$REMOTE_QUESTIONS"
    [[ -n "$REMOTE_FEEDBACK" ]] && GATEWAY_FEEDBACK="$REMOTE_FEEDBACK"

    # Parse presets.remote.hooks.on_processed
    REMOTE_ON_PROCESSED=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && REMOTE_ON_PROCESSED+=("$line")
    done < <(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { exit }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /^[[:space:]]{4}[a-z]/ && !/hooks/ { next }
        in_remote && /hooks:/ { in_hooks=1; next }
        in_hooks && /on_processed:/ { in_op=1; next }
        in_op && /^[[:space:]]+-/ {
            gsub(/^[[:space:]]+-[[:space:]]*/, "")
            gsub(/"/, "")
            print
        }
        in_op && /^[[:space:]]+[a-z_]+:/ { exit }
    ' "$CONFIG_PATH")

    # If remote preset has on_processed hooks, use them (override)
    if [[ ${#REMOTE_ON_PROCESSED[@]} -gt 0 ]]; then
        HOOKS_ON_PROCESSED=("${REMOTE_ON_PROCESSED[@]}")
    fi

    # Parse presets.remote.hooks.on_approve
    REMOTE_ON_APPROVE=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && REMOTE_ON_APPROVE+=("$line")
    done < <(awk '
        /^presets:/ { in_presets=1; next }
        in_presets && /^[a-z]/ && !/^[[:space:]]/ { exit }
        in_presets && /remote:/ { in_remote=1; next }
        in_remote && /^[[:space:]]{4}[a-z]/ && !/hooks/ { next }
        in_remote && /hooks:/ { in_hooks=1; next }
        in_hooks && /on_approve:/ { in_oa=1; next }
        in_oa && /^[[:space:]]+-/ {
            gsub(/^[[:space:]]+-[[:space:]]*/, "")
            gsub(/"/, "")
            print
        }
        in_oa && /^[[:space:]]+[a-z_]+:/ { exit }
    ' "$CONFIG_PATH")

    if [[ ${#REMOTE_ON_APPROVE[@]} -gt 0 ]]; then
        HOOKS_ON_APPROVE=("${REMOTE_ON_APPROVE[@]}")
    fi
fi

# Generate JSON arrays
STEPS_JSON=$(printf '%s\n' "${ALL_STEPS[@]}" | jq -R . | jq -s .)
COMPLETED_JSON=$(printf '%s\n' "${COMPLETED_STEPS[@]}" | jq -R . | jq -s .)
HOOKS_ON_PROCESSED_JSON=$(printf '%s\n' "${HOOKS_ON_PROCESSED[@]}" | jq -R . | jq -s .)
HOOKS_ON_APPROVE_JSON=$(printf '%s\n' "${HOOKS_ON_APPROVE[@]}" | jq -R . | jq -s .)

# Output JSON with v7.2 format (includes gateway, hooks, and interactive)
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
    --argjson remote_mode "$REMOTE_MODE" \
    --argjson steps "$STEPS_JSON" \
    --argjson completed "$COMPLETED_JSON" \
    --arg gw_questions "$GATEWAY_QUESTIONS" \
    --arg gw_feedback "$GATEWAY_FEEDBACK" \
    --argjson hooks_on_processed "$HOOKS_ON_PROCESSED_JSON" \
    --argjson hooks_on_approve "$HOOKS_ON_APPROVE_JSON" \
    --argjson step_interactive "$STEP_INTERACTIVE" \
    --arg interactive_channel "$INTERACTIVE_CHANNEL" \
    --arg interactive_slack_bot_token "$INTERACTIVE_SLACK_BOT_TOKEN" \
    --arg interactive_slack_channel_id "$INTERACTIVE_SLACK_CHANNEL_ID" \
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
        remote_mode: $remote_mode,
        steps: $steps,
        completed: $completed,
        interactive: {
            enabled: $step_interactive,
            channel: $interactive_channel,
            slack_bot_token: (if $interactive_slack_bot_token == "" or $interactive_slack_bot_token == "null" then null else $interactive_slack_bot_token end),
            slack_channel_id: (if $interactive_slack_channel_id == "" or $interactive_slack_channel_id == "null" then null else $interactive_slack_channel_id end)
        },
        gateway: {
            mode: (if $remote_mode then "remote" else "local" end),
            questions: $gw_questions,
            feedback: $gw_feedback
        },
        hooks: {
            on_processed: $hooks_on_processed,
            on_approve: $hooks_on_approve
        },
        frontmatter: {
            id: $task_id,
            step: $step,
            prev: (if $prev == "" then null else $prev end),
            next: (if $next == "" then null else $next end),
            status: "pending_feedback",
            open_questions: []
        }
    }'
