#!/bin/bash
# siat-wait-approval.sh - Wait for approval via GitHub Issue comment
# Posts result to GitHub Issue and polls for /approve or /feedback response
#
# Usage: siat-wait-approval.sh <spec_path> [--poll-interval=10] [--timeout=3600]
# Environment:
#   SIAT_REMOTE=true (required to enable this script)
# Output: JSON with approval result
#
# Expected GitHub Issue comment commands:
#   /approve              - Proceed to next step
#   /approve with comment - Proceed with note
#   /feedback: message    - Retry with feedback
#   /reject               - Stop workflow

set -e

# Skip if not in remote mode
if [[ "${SIAT_REMOTE}" != "true" ]]; then
    echo '{"skipped": true, "reason": "SIAT_REMOTE not enabled"}' | jq .
    exit 0
fi

SPEC_PATH="$1"
POLL_INTERVAL=10
TIMEOUT=3600  # 1 hour default

# Parse optional arguments
for arg in "${@:2}"; do
    case $arg in
        --poll-interval=*) POLL_INTERVAL="${arg#*=}" ;;
        --timeout=*) TIMEOUT="${arg#*=}" ;;
    esac
done

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

extract_issue_number() {
    echo "$1" | grep -oE '[0-9]+$'
}

# ============================================================================
# Main Logic
# ============================================================================

if [[ ! -f "$SPEC_PATH" ]]; then
    echo '{"error": "spec file not found", "path": "'"$SPEC_PATH"'"}' | jq .
    exit 1
fi

# Get issue or PR URL from spec frontmatter (PR also uses issue comments API)
ISSUE_URL=$(get_frontmatter_field "$SPEC_PATH" "github_issue")
PR_URL=$(get_frontmatter_field "$SPEC_PATH" "github_pr")

if [[ -n "$PR_URL" ]]; then
    TARGET_URL="$PR_URL"
    TARGET_TYPE="pr"
elif [[ -n "$ISSUE_URL" ]]; then
    TARGET_URL="$ISSUE_URL"
    TARGET_TYPE="issue"
else
    echo '{"error": "no github_issue or github_pr found in spec frontmatter", "path": "'"$SPEC_PATH"'"}' | jq .
    exit 1
fi

ISSUE_NUMBER=$(extract_issue_number "$TARGET_URL")
TASK_ID=$(get_frontmatter_field "$SPEC_PATH" "id")
STEP=$(basename "$SPEC_PATH" .md)

# Post approval request comment
APPROVAL_MSG="## ⏳ Awaiting Approval

**Step**: \`${STEP}\`
**Task**: \`${TASK_ID}\`

Please review and respond with one of:

| Command | Action |
|---------|--------|
| \`/approve\` | Proceed to next step |
| \`/feedback: your message\` | Retry with feedback |
| \`/reject\` | Stop workflow |

---
*Waiting for response...*"

COMMENT_URL=$(gh issue comment "$ISSUE_NUMBER" --body "$APPROVAL_MSG" 2>&1 | tail -1)
COMMENT_ID=$(echo "$COMMENT_URL" | grep -oE '[0-9]+$')

echo "Waiting for approval on issue #${ISSUE_NUMBER}..." >&2

# Get timestamp of our comment to only check newer comments
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ELAPSED=0

while [[ $ELAPSED -lt $TIMEOUT ]]; do
    sleep "$POLL_INTERVAL"
    ELAPSED=$((ELAPSED + POLL_INTERVAL))

    # Fetch comments after our comment
    RESPONSE=$(gh api "repos/{owner}/{repo}/issues/${ISSUE_NUMBER}/comments" \
        --jq ".[] | select(.created_at > \"${START_TIME}\") | {body: .body, user: .user.login, created_at: .created_at}" \
        2>/dev/null | head -1)

    if [[ -n "$RESPONSE" ]]; then
        BODY=$(echo "$RESPONSE" | jq -r '.body' 2>/dev/null)
        USER=$(echo "$RESPONSE" | jq -r '.user' 2>/dev/null)

        # Check for approval
        if echo "$BODY" | grep -qi "^/approve"; then
            NOTE=$(echo "$BODY" | sed 's|^/approve[[:space:]]*||i')

            # Post acknowledgment and close issue
            gh issue comment "$ISSUE_NUMBER" --body "✅ **Approved** by @${USER}. Proceeding to next step." >/dev/null 2>&1
            gh issue close "$ISSUE_NUMBER" >/dev/null 2>&1

            jq -n \
                --arg action "approve" \
                --arg user "$USER" \
                --arg note "$NOTE" \
                --arg spec_path "$SPEC_PATH" \
                --arg issue_number "$ISSUE_NUMBER" \
                '{
                    success: true,
                    action: $action,
                    user: $user,
                    note: $note,
                    spec_path: $spec_path,
                    issue_number: $issue_number
                }'
            exit 0
        fi

        # Check for feedback
        if echo "$BODY" | grep -qi "^/feedback:"; then
            FEEDBACK=$(echo "$BODY" | sed 's|^/feedback:[[:space:]]*||i')

            # Post acknowledgment
            gh issue comment "$ISSUE_NUMBER" --body "🔄 **Feedback received** from @${USER}. Retrying step with feedback." >/dev/null 2>&1

            jq -n \
                --arg action "feedback" \
                --arg user "$USER" \
                --arg feedback "$FEEDBACK" \
                --arg spec_path "$SPEC_PATH" \
                --arg issue_number "$ISSUE_NUMBER" \
                '{
                    success: true,
                    action: $action,
                    user: $user,
                    feedback: $feedback,
                    spec_path: $spec_path,
                    issue_number: $issue_number
                }'
            exit 0
        fi

        # Check for reject
        if echo "$BODY" | grep -qi "^/reject"; then
            REASON=$(echo "$BODY" | sed 's|^/reject[[:space:]]*||i')

            # Post acknowledgment
            gh issue comment "$ISSUE_NUMBER" --body "❌ **Rejected** by @${USER}. Workflow stopped." >/dev/null 2>&1

            jq -n \
                --arg action "reject" \
                --arg user "$USER" \
                --arg reason "$REASON" \
                --arg spec_path "$SPEC_PATH" \
                --arg issue_number "$ISSUE_NUMBER" \
                '{
                    success: true,
                    action: $action,
                    user: $user,
                    reason: $reason,
                    spec_path: $spec_path,
                    issue_number: $issue_number
                }'
            exit 0
        fi
    fi

    echo "Still waiting... (${ELAPSED}s / ${TIMEOUT}s)" >&2
done

# Timeout
gh issue comment "$ISSUE_NUMBER" --body "⏰ **Timeout** - No response received within ${TIMEOUT}s. Workflow paused." >/dev/null 2>&1

jq -n \
    --arg spec_path "$SPEC_PATH" \
    --arg issue_number "$ISSUE_NUMBER" \
    --argjson timeout "$TIMEOUT" \
    '{
        success: false,
        action: "timeout",
        timeout_seconds: $timeout,
        spec_path: $spec_path,
        issue_number: $issue_number
    }'
exit 1
