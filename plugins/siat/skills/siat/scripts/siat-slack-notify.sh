#!/bin/bash
# siat-slack-notify.sh - Send Slack notification for siat workflow events
# Sends a message to Slack webhook when approval is needed
#
# Usage: siat-slack-notify.sh <spec_path> [--config=path]
# Config: remote.slack_webhook_url in config.yml
# Environment:
#   SIAT_REMOTE=true (required to enable this script)
#   SIAT_SLACK_WEBHOOK_URL (fallback if not in config)
# Output: JSON with notification result

set -e

# Skip if not in remote mode
if [[ "${SIAT_REMOTE}" != "true" ]]; then
    echo '{"skipped": true, "reason": "SIAT_REMOTE not enabled"}' | jq .
    exit 0
fi

SPEC_PATH="$1"
CONFIG_PATH=".claude/siat/config.yml"

# Parse optional arguments
for arg in "${@:2}"; do
    case $arg in
        --config=*) CONFIG_PATH="${arg#*=}" ;;
    esac
done

# Read webhook URL from config.yml (remote.slack_webhook_url)
get_config_value() {
    local file="$1"
    local key="$2"
    # Extract value after "key:" - preserve URLs with colons
    awk -v key="$key" '
        /^remote:/ { in_remote=1; next }
        in_remote && /^[a-z]/ && !/^[[:space:]]/ { exit }
        in_remote && $0 ~ key":" {
            sub(/^[[:space:]]*[^:]+:[[:space:]]*/, "")
            gsub(/"/, ""); gsub(/'"'"'/, "")
            print
            exit
        }
    ' "$file"
}

WEBHOOK_URL=""
if [[ -f "$CONFIG_PATH" ]]; then
    WEBHOOK_URL=$(get_config_value "$CONFIG_PATH" "slack_webhook_url")
fi

# Fallback to environment variable
if [[ -z "$WEBHOOK_URL" ]]; then
    WEBHOOK_URL="${SIAT_SLACK_WEBHOOK_URL:-}"
fi

# ============================================================================
# Helper Functions
# ============================================================================

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

get_section() {
    local file="$1"
    local header="$2"

    awk -v header="$header" '
        /^---$/ { if (!past_fm) { past_fm=1; next } }
        past_fm && $0 ~ "^##[[:space:]]+"header {
            in_section=1
            next
        }
        in_section && /^##[[:space:]]/ { exit }
        in_section { print }
    ' "$file" | head -10 | sed '/^$/N;/^\n$/d'
}

# ============================================================================
# Main Logic
# ============================================================================

if [[ -z "$WEBHOOK_URL" ]]; then
    echo '{"error": "No Slack webhook URL. Set remote.slack_webhook_url in config.yml or SIAT_SLACK_WEBHOOK_URL env"}' | jq .
    exit 1
fi

if [[ ! -f "$SPEC_PATH" ]]; then
    echo '{"error": "spec file not found", "path": "'"$SPEC_PATH"'"}' | jq .
    exit 1
fi

# Extract metadata
TASK_ID=$(get_frontmatter_field "$SPEC_PATH" "id")
STEP=$(basename "$SPEC_PATH" .md)
ISSUE_URL=$(get_frontmatter_field "$SPEC_PATH" "github_issue")
SUMMARY=$(get_section "$SPEC_PATH" "Summary\|요약\|Overview\|개요" | head -3)

# Build Slack message
if [[ -n "$ISSUE_URL" ]]; then
    ISSUE_LINK="<${ISSUE_URL}|GitHub Issue>"
else
    ISSUE_LINK="_No issue linked_"
fi

PAYLOAD=$(jq -n \
    --arg task_id "$TASK_ID" \
    --arg step "$STEP" \
    --arg issue_link "$ISSUE_LINK" \
    --arg summary "$SUMMARY" \
    --arg spec_path "$SPEC_PATH" \
    '{
        blocks: [
            {
                type: "header",
                text: {
                    type: "plain_text",
                    text: ("⏳ Approval Needed: " + $step),
                    emoji: true
                }
            },
            {
                type: "section",
                fields: [
                    {
                        type: "mrkdwn",
                        text: ("*Task:*\n`" + $task_id + "`")
                    },
                    {
                        type: "mrkdwn",
                        text: ("*Step:*\n`" + $step + "`")
                    }
                ]
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: ("*Summary:*\n" + (if $summary == "" then "_No summary_" else $summary end))
                }
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: ("📎 " + $issue_link)
                }
            },
            {
                type: "context",
                elements: [
                    {
                        type: "mrkdwn",
                        text: ("Reply on GitHub with `/approve`, `/feedback: message`, or `/reject`")
                    }
                ]
            },
            {
                type: "divider"
            }
        ]
    }')

# Send to Slack
RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$WEBHOOK_URL")

if [[ "$RESPONSE" == "ok" ]]; then
    jq -n \
        --arg spec_path "$SPEC_PATH" \
        --arg task_id "$TASK_ID" \
        --arg step "$STEP" \
        '{
            success: true,
            message: "Slack notification sent",
            spec_path: $spec_path,
            task_id: $task_id,
            step: $step
        }'
else
    jq -n \
        --arg error "$RESPONSE" \
        --arg spec_path "$SPEC_PATH" \
        '{
            success: false,
            error: $error,
            spec_path: $spec_path
        }'
    exit 1
fi
