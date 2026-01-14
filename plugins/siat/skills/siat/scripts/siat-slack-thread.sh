#!/bin/bash
# siat-slack-thread.sh - Interactive Slack thread for siat workflow
# Enables real-time conversation in Slack threads for interactive steps
#
# Usage:
#   siat-slack-thread.sh <spec_path> --init              # Create thread with default message
#   siat-slack-thread.sh <spec_path> --init "message"    # Create thread with custom message
#   siat-slack-thread.sh <spec_path> --init --task-id=foo --step=specify  # With explicit task info
#   siat-slack-thread.sh <spec_path> --send "<message>"  # Post to thread (simple message)
#   echo "message" | siat-slack-thread.sh <spec_path> --send  # Post via stdin (special chars safe)
#   siat-slack-thread.sh <spec_path> --poll              # Poll for new replies
#   siat-slack-thread.sh <spec_path> --type=questions    # Gateway mode: ask questions
#   siat-slack-thread.sh <spec_path> --type=feedback     # Gateway mode: get feedback
#
# Required environment variables:
#   SLACK_BOT_TOKEN   - Bot User OAuth Token (xoxb-...)
#   SLACK_USER_ID     - User ID to open DM with (preferred, auto-resolves channel)
#   SLACK_CHANNEL_ID  - Channel ID to post in (fallback if USER_ID not set)
#
# Optional:
#   SIAT_SLACK_POLL_INTERVAL - Poll interval in seconds (default: 5)
#   SIAT_SLACK_POLL_TIMEOUT  - Poll timeout in seconds (default: 300)

set -e

SPEC_PATH="$1"
shift

# Parse arguments
ACTION=""
MESSAGE=""
GATEWAY_TYPE=""
CLI_TASK_ID=""
CLI_STEP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --init)
            ACTION="init"
            # Check if next arg exists and is not another flag
            if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                MESSAGE="$2"
                shift 2
            else
                MESSAGE=""
                shift
            fi
            ;;
        --send)
            ACTION="send"
            # Check if next arg exists and is not another flag
            if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                MESSAGE="$2"
                shift 2
            else
                # Read message from stdin (handles special characters safely)
                MESSAGE=""
                shift
            fi
            ;;
        --poll)
            ACTION="poll"
            shift
            ;;
        --type=*)
            GATEWAY_TYPE="${1#--type=}"
            ACTION="gateway"
            shift
            ;;
        --task-id=*)
            CLI_TASK_ID="${1#--task-id=}"
            shift
            ;;
        --step=*)
            CLI_STEP="${1#--step=}"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Read from stdin if --send was used without message argument
if [[ "$ACTION" == "send" && -z "$MESSAGE" ]]; then
    if [[ ! -t 0 ]]; then
        MESSAGE=$(cat)
    else
        echo '{"error": "No message provided. Use --send \"message\" or pipe message via stdin"}' | jq .
        exit 1
    fi
fi

# Read from stdin if --init was used without message argument (optional - uses default if empty)
if [[ "$ACTION" == "init" && -z "$MESSAGE" && ! -t 0 ]]; then
    MESSAGE=$(cat)
fi

# Validate environment
if [[ -z "$SLACK_BOT_TOKEN" ]]; then
    echo '{"error": "SLACK_BOT_TOKEN not set"}' | jq .
    exit 1
fi

# Resolve channel ID from user ID if needed
if [[ -z "$SLACK_CHANNEL_ID" && -n "$SLACK_USER_ID" ]]; then
    # Use conversations.open to get/create DM channel
    OPEN_RESPONSE=$(curl -s -X POST "https://slack.com/api/conversations.open" \
        -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
        -H "Content-Type: application/json; charset=utf-8" \
        -d "{\"users\":\"$SLACK_USER_ID\"}")

    if [[ "$(echo "$OPEN_RESPONSE" | jq -r '.ok')" == "true" ]]; then
        SLACK_CHANNEL_ID=$(echo "$OPEN_RESPONSE" | jq -r '.channel.id')
    else
        echo "$OPEN_RESPONSE" | jq '{error: "failed to open DM channel", response: .}'
        exit 1
    fi
fi

if [[ -z "$SLACK_CHANNEL_ID" ]]; then
    echo '{"error": "SLACK_CHANNEL_ID or SLACK_USER_ID must be set"}' | jq .
    exit 1
fi

# Config
POLL_INTERVAL="${SIAT_SLACK_POLL_INTERVAL:-5}"
POLL_TIMEOUT="${SIAT_SLACK_POLL_TIMEOUT:-300}"

# Thread state file (stored alongside spec)
SPEC_DIR=$(dirname "$SPEC_PATH")
THREAD_STATE="${SPEC_DIR}/.slack_thread.json"

# ============================================================================
# Helper Functions
# ============================================================================

slack_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    if [[ "$method" == "GET" ]]; then
        curl -s -X GET \
            -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
            -H "Content-Type: application/json" \
            "https://slack.com/api/${endpoint}"
    else
        curl -s -X POST \
            -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "https://slack.com/api/${endpoint}"
    fi
}

get_thread_ts() {
    if [[ -f "$THREAD_STATE" ]]; then
        jq -r '.thread_ts // empty' "$THREAD_STATE"
    fi
}

get_last_ts() {
    if [[ -f "$THREAD_STATE" ]]; then
        jq -r '.last_ts // empty' "$THREAD_STATE"
    fi
}

save_thread_state() {
    local thread_ts="$1"
    local last_ts="$2"
    jq -n \
        --arg thread_ts "$thread_ts" \
        --arg last_ts "$last_ts" \
        --arg channel "$SLACK_CHANNEL_ID" \
        --arg spec_path "$SPEC_PATH" \
        '{
            thread_ts: $thread_ts,
            last_ts: $last_ts,
            channel: $channel,
            spec_path: $spec_path,
            updated_at: now | todate
        }' > "$THREAD_STATE"
}

extract_spec_info() {
    local spec_path="$1"
    local task_id=""
    local step=""

    # CLI arguments take precedence over spec file
    if [[ -n "$CLI_TASK_ID" ]]; then
        task_id="$CLI_TASK_ID"
    elif [[ -f "$spec_path" ]]; then
        task_id=$(awk '/^---$/{if(in_fm)exit;in_fm=1;next} in_fm&&/^id:/{gsub(/^id:[[:space:]]*/,"");gsub(/"/,"");print;exit}' "$spec_path")
    fi

    if [[ -n "$CLI_STEP" ]]; then
        step="$CLI_STEP"
    elif [[ -f "$spec_path" ]]; then
        step=$(awk '/^---$/{if(in_fm)exit;in_fm=1;next} in_fm&&/^step:/{gsub(/^step:[[:space:]]*/,"");gsub(/"/,"");print;exit}' "$spec_path")
    fi

    echo "${task_id:-unknown}|${step:-unknown}"
}

# ============================================================================
# Actions
# ============================================================================

do_init() {
    local spec_info
    spec_info=$(extract_spec_info "$SPEC_PATH")
    local task_id="${spec_info%|*}"
    local step="${spec_info#*|}"

    # Use custom message if provided, otherwise use default
    local init_message
    if [[ -n "$MESSAGE" ]]; then
        init_message="$MESSAGE"
    else
        init_message="*[${task_id}][${step}]*

Interactive step started. Please respond in this thread.

---
_Waiting for questions..._"
    fi

    local response
    response=$(slack_api "POST" "chat.postMessage" "$(jq -n \
        --arg channel "$SLACK_CHANNEL_ID" \
        --arg text "$init_message" \
        '{channel: $channel, text: $text, mrkdwn: true}'
    )")

    local ok
    ok=$(echo "$response" | jq -r '.ok')

    if [[ "$ok" != "true" ]]; then
        echo "$response" | jq '{error: .error, response: .}'
        exit 1
    fi

    local thread_ts
    thread_ts=$(echo "$response" | jq -r '.ts')

    save_thread_state "$thread_ts" "$thread_ts"

    jq -n \
        --arg thread_ts "$thread_ts" \
        --arg channel "$SLACK_CHANNEL_ID" \
        --arg task_id "$task_id" \
        --arg step "$step" \
        '{
            success: true,
            thread_ts: $thread_ts,
            channel: $channel,
            task_id: $task_id,
            step: $step
        }'
}

do_send() {
    local thread_ts
    thread_ts=$(get_thread_ts)

    if [[ -z "$thread_ts" ]]; then
        echo '{"error": "No thread initialized. Run --init first."}' | jq .
        exit 1
    fi

    local response
    response=$(slack_api "POST" "chat.postMessage" "$(jq -n \
        --arg channel "$SLACK_CHANNEL_ID" \
        --arg text "$MESSAGE" \
        --arg thread_ts "$thread_ts" \
        '{channel: $channel, text: $text, thread_ts: $thread_ts, mrkdwn: true}'
    )")

    local ok
    ok=$(echo "$response" | jq -r '.ok')

    if [[ "$ok" != "true" ]]; then
        echo "$response" | jq '{error: .error, response: .}'
        exit 1
    fi

    local msg_ts
    msg_ts=$(echo "$response" | jq -r '.ts')

    # Update last_ts
    save_thread_state "$thread_ts" "$msg_ts"

    jq -n \
        --arg ts "$msg_ts" \
        --arg thread_ts "$thread_ts" \
        '{success: true, ts: $ts, thread_ts: $thread_ts}'
}

do_poll() {
    local thread_ts
    thread_ts=$(get_thread_ts)

    if [[ -z "$thread_ts" ]]; then
        echo '{"error": "No thread initialized. Run --init first."}' | jq .
        exit 1
    fi

    local last_ts
    last_ts=$(get_last_ts)
    last_ts="${last_ts:-$thread_ts}"

    local start_time
    start_time=$(date +%s)

    while true; do
        local now
        now=$(date +%s)
        local elapsed=$((now - start_time))

        if [[ $elapsed -ge $POLL_TIMEOUT ]]; then
            jq -n '{timeout: true, elapsed: '$elapsed'}'
            exit 0
        fi

        # Get thread replies
        local response
        response=$(slack_api "GET" "conversations.replies?channel=${SLACK_CHANNEL_ID}&ts=${thread_ts}&oldest=${last_ts}")

        local ok
        ok=$(echo "$response" | jq -r '.ok')

        if [[ "$ok" != "true" ]]; then
            echo "$response" | jq '{error: .error, response: .}'
            exit 1
        fi

        # Find new messages (not from bot, after last_ts)
        local bot_id
        bot_id=$(slack_api "GET" "auth.test" | jq -r '.user_id')

        local new_messages
        new_messages=$(echo "$response" | jq --arg last_ts "$last_ts" --arg bot_id "$bot_id" '
            .messages
            | map(select(.ts > $last_ts and .user != $bot_id and .bot_id == null))
        ')

        local count
        count=$(echo "$new_messages" | jq 'length')

        if [[ "$count" -gt 0 ]]; then
            # Get the latest message
            local latest
            latest=$(echo "$new_messages" | jq '.[0]')
            local latest_ts
            latest_ts=$(echo "$latest" | jq -r '.ts')
            local latest_text
            latest_text=$(echo "$latest" | jq -r '.text')
            local latest_user
            latest_user=$(echo "$latest" | jq -r '.user')

            # Update last_ts
            save_thread_state "$thread_ts" "$latest_ts"

            jq -n \
                --arg text "$latest_text" \
                --arg user "$latest_user" \
                --arg ts "$latest_ts" \
                --argjson all_new "$new_messages" \
                '{
                    success: true,
                    message: {
                        text: $text,
                        user: $user,
                        ts: $ts
                    },
                    all_messages: $all_new
                }'
            exit 0
        fi

        sleep "$POLL_INTERVAL"
    done
}

do_gateway() {
    local thread_ts
    thread_ts=$(get_thread_ts)

    # Initialize thread if not exists
    if [[ -z "$thread_ts" ]]; then
        do_init > /dev/null
        thread_ts=$(get_thread_ts)
    fi

    case "$GATEWAY_TYPE" in
        questions)
            # Read questions from stdin or spec file
            # For now, just poll for response
            do_poll
            ;;
        feedback)
            # Post completion message and wait for feedback
            do_send <<< "Step completed. Please review and respond:
- \`/approve\` - Accept and continue
- \`/revise <feedback>\` - Request changes
- \`/reject\` - Stop workflow"

            # Poll for feedback response
            local response
            response=$(do_poll)

            local text
            text=$(echo "$response" | jq -r '.message.text // empty')

            if [[ -z "$text" ]]; then
                echo "$response"
                exit 0
            fi

            # Parse feedback commands
            if [[ "$text" =~ ^/approve ]]; then
                jq -n '{action: "approve", raw: "'"$text"'"}'
            elif [[ "$text" =~ ^/revise[[:space:]]*(.*) ]]; then
                local feedback="${text#/revise}"
                feedback="${feedback#"${feedback%%[![:space:]]*}"}"
                jq -n --arg feedback "$feedback" '{action: "revise", feedback: $feedback, raw: "'"$text"'"}'
            elif [[ "$text" =~ ^/reject ]]; then
                jq -n '{action: "reject", raw: "'"$text"'"}'
            else
                # Treat as general feedback for revision
                jq -n --arg feedback "$text" '{action: "feedback", feedback: $feedback, raw: "'"$text"'"}'
            fi
            ;;
        *)
            echo '{"error": "Unknown gateway type: '"$GATEWAY_TYPE"'"}' | jq .
            exit 1
            ;;
    esac
}

# ============================================================================
# Main
# ============================================================================

case "$ACTION" in
    init)
        do_init
        ;;
    send)
        do_send
        ;;
    poll)
        do_poll
        ;;
    gateway)
        do_gateway
        ;;
    *)
        echo '{"error": "No action specified. Use --init, --send, --poll, or --type=<questions|feedback>"}' | jq .
        exit 1
        ;;
esac
